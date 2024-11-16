const std = @import("std");
const lib = @import("lib.zig");
const Allocator = std.mem.Allocator;
const Queue = lib.Queue;
const Thread = std.Thread;

/// Multiple producer, single consumer FIFO queue.
pub fn Mpsc(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,

        queue: Queue(T),

        mutex: Thread.Mutex,

        received: bool = false,

        recv_cond: Thread.Condition,

        /// Creates a multiple producer single consumer queue.
        pub fn init(
            allocator: Allocator,
        ) Self {
            return Self{
                .allocator = allocator,
                .queue = Queue(T).init(allocator),
                .mutex = Thread.Mutex{},
                .recv_cond = Thread.Condition{},
            };
        }

        /// Creates a multiple producer single consumer queue with the specified capacity.
        pub fn initCapacity(
            allocator: Allocator,
            capacity: usize,
        ) !Self {
            return Self{
                .allocator = allocator,
                .queue = try Queue(T).initCapacity(allocator, capacity),
                .mutex = Thread.Mutex{},
                .recv_cond = Thread.Condition{},
            };
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
        }

        /// Creates a new asynchronous channel.
        pub fn channel(self: *Self) Channel(T) {
            return Channel(T){
                .producer = Producer(T){ .mpsc = self },
                .consumer = Consumer(T){ .mpsc = self },
            };
        }
    };
}

/// The part of `Channel` that's responsible for sending.
///
/// Messages can be sent through this channel with `send`.
pub fn Producer(comptime T: type) type {
    return struct {
        const Self = @This();

        mpsc: *Mpsc(T),

        /// Sends a message to the consumer without blocking.
        pub fn send(self: *Self, value: T) !void {
            var mutex = self.mpsc.mutex;
            mutex.lock();
            defer mutex.unlock();

            // Add to the queue
            try self.mpsc.queue.enqueue(value);
            self.mpsc.received = true;

            // Signal receiver to not block
            self.mpsc.recv_cond.signal(); // change .signal() to .broadcast()?
        }

        /// Creates a new producer by copying `self`.
        pub fn clone(self: Self) Self {
            return Self{ .mpsc = self.mpsc };
        }
    };
}

/// The receiving half of `Channel`.
/// This half can only be owned by one thread.
///
/// Messages sent to the channel can be retrieved using `recv`.
pub fn Consumer(comptime T: type) type {
    return struct {
        const Self = @This();

        mpsc: *Mpsc(T),

        /// Blocks until a message is available.
        pub fn recv(self: *Self) !T {
            var mutex = self.mpsc.mutex;
            mutex.lock();
            defer mutex.unlock();

            while (self.mpsc.received == false) {
                self.mpsc.recv_cond.wait(&mutex);
            }

            // Grab message from queue
            const received = try self.mpsc.queue.dequeue();
            return received;
        }

        /// Attempts to return a pending value without blocking.
        pub fn tryRecv(self: *Self) !T {
            var mutex = self.mpsc.mutex;
            mutex.lock();
            defer mutex.unlock();
            const received = self.mpsc.queue.dequeue() catch return error.EmptyMessageBuffer;
            return received;
        }
    };
}

pub fn Channel(comptime T: type) type {
    return struct {
        producer: Producer(T),
        consumer: Consumer(T),
    };
}
