const std = @import("std");
const lib = @import("lib.zig");
const Allocator = std.mem.Allocator;
const Queue = lib.Queue;
const Thread = std.Thread;
const Mpsc = lib.mpsc.Mpsc;
const Producer = lib.mpsc.Producer;

fn runProducer(producer: *Producer(u8), value: u8) void {
    producer.send(value) catch |err| {
        std.log.err("[Producer] error: {}", .{err});
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var mpsc = try Mpsc(u8).initCapacity(allocator, 10);
    defer mpsc.deinit();

    var channel = mpsc.channel();
    const num_threads = 4;
    var thread_handles: [num_threads]Thread = undefined;
    for (0..num_threads) |i| {
        thread_handles[i] = try Thread.spawn(.{}, runProducer, .{ &channel.producer, 42 });
    }
    for (thread_handles) |thread| {
        thread.join();
    }

    for (0..num_threads) |_| {
        _ = channel.consumer.recv() catch |err| {
            std.log.err("[Consumer] error: {}", .{err});
        };
    }
}
