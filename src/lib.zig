const std = @import("std");
const testing = std.testing;

pub const Queue = @import("queue.zig").Queue;

test {
    comptime {
        testing.refAllDecls(@This());
    }
}
