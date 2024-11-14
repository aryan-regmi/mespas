const std = @import("std");
const lib = @import("lib.zig");
const Allocator = std.mem.Allocator;
const Queue = lib.Queue;
const Thread = std.Thread;

// TODO: Anything can enqueue but only consumer can dequeue
//
/// Multiple producer, single consumer FIFO queue.
pub fn Mpsc(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,

        queue: Queue(T),

        mutex: Thread.Mutex,

        received: bool,

        recv_cond: Thread.Condition,

        /// Creates a multiple producer single consumer queue.
        pub fn init(
            allocator: Allocator,
        ) Self {
            return Self{
                .allocator = allocator,
                .queue = Queue(T).init(allocator),
                .mutex = Thread.Mutex{},
                .received = false,
                .recv_cond = Thread.Condition{},
            };
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

pub fn Producer(comptime T: type) type {
    return struct {
        const Self = @This();

        mpsc: *Mpsc(T),

        /// Sends a message to the consumer without blocking.
        pub fn send(self: *Self, value: T) !void {
            var mutex = self.mpsc.mutex;
            mutex.lock();
            defer mutex.unlock();

            // TODO: send logic here!
            std.log.debug("Sending {any}", .{value});

            self.mpsc.received = true;
            self.mpsc.recv_cond.signal(); // change .signal() to .broadcast()?
        }

        /// Creates a new producer by copying `self`.
        pub fn clone(self: Self) Self {
            return Self{ .mpsc = self.mpsc };
        }
    };
}

pub fn Consumer(comptime T: type) type {
    return struct {
        const Self = @This();

        mpsc: *Mpsc(T),

        /// Blocks until a message is available.
        pub fn recv(self: *Self) !void {
            var mutex = self.mpsc.mutex;
            mutex.lock();
            defer mutex.unlock();

            while (self.mpsc.received == false) {
                self.mpsc.recv_cond.wait(&mutex);
            }

            // TODO: recv logic here!
            std.log.debug("Received", .{});
        }
    };
}

pub fn Channel(comptime T: type) type {
    return struct {
        producer: Producer(T),
        consumer: Consumer(T),
    };
}
