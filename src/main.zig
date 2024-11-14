const std = @import("std");
const lib = @import("lib.zig");
const Allocator = std.mem.Allocator;
const Queue = lib.Queue;
const Thread = std.Thread;
const Mpsc = lib.mpsc.Mpsc;
const Producer = lib.mpsc.Producer;

fn runProducer(producer: *Producer(u8), value: u8) void {
    producer.send(value) catch |err| {
        std.log.err("[THREAD] Error: {}", .{err});
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var mpsc = Mpsc(u8).init(allocator);
    var channel = mpsc.channel();

    const thread = try Thread.spawn(.{}, runProducer, .{ &channel.producer, 42 });
    try channel.consumer.recv();
    thread.join();
}
