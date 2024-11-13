const std = @import("std");
const lib = @import("lib.zig");
const Allocator = std.mem.Allocator;
const Queue = lib.Queue;

// TODO: Anything can enqueue but only consumer can dequeue
//
/// Multiple producer, single consumer FIFO queue.
pub fn Mpsc(comptime T: type) type {
    return struct {
        const Self = @This();

        queue: Queue(T),

        pub fn init() Self {}

        /// Creates a new asynchronous channel.
        pub fn channel() Channel {}
    };
}

pub fn Producer(comptime T: type) type {
    _ = T;
    return struct {
        const Self = @This();

        /// Sends a message to the consumer without blocking.
        pub fn send() !void {}

        /// Creates a new producer by copying `self`.
        pub fn clone(_: Self) !Self {}
    };
}

pub fn Consumer(comptime T: type) type {
    _ = T;
    return struct {
        const Self = @This();
    };
}

pub fn Channel(comptime T: type) type {
    return struct {
        producer: Producer(T),
        consumer: Consumer(T),
    };
}
