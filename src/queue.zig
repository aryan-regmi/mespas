const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

/// A linear data structure that serves as a container for objects.
///
/// The objects are inserted and removed in FIFO (first in first out).
pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Allocator used for internal memory management.
        allocator: Allocator,

        /// All items stored in the queue.
        items: []T = undefined,

        /// The max number of items the queue has storage for.
        capacity: usize = 0,

        /// The number of items in the queue.
        size: usize = 0,

        /// Index of the front of the queue.
        head: usize = 0,

        /// Index of the back of the queue.
        tail: usize = undefined,

        /// Creates a new, empty queue.
        pub fn init(allocator: Allocator) Self {
            return Self{ .allocator = allocator };
        }

        /// Initialize with capacity to hold `capacity` items.
        pub fn initCapacity(allocator: Allocator, capacity: usize) !Self {
            return Self{
                .allocator = allocator,
                .capacity = capacity,
                .items = try allocator.alloc(T, capacity),
            };
        }

        /// Release all allocated memory.
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        /// Returns `true` if the queue has no items.
        pub fn isEmpty(self: Self) bool {
            return self.size == 0;
        }

        /// Returns `true` if the queue has no free space.
        pub fn isFull(self: Self) bool {
            return self.size == self.capacity;
        }

        /// Remove the first element from the queue.
        pub fn dequeue(self: *Self) !T {
            if (self.isEmpty()) {
                return error.EmptyQueue;
            }

            // Update head and remove item
            const removed = self.items[self.head];
            self.head = (self.head + 1) % self.capacity;
            self.size -= 1;

            return removed;
        }

        /// Add an item to the end of the queue.
        pub fn enqueue(self: *Self, item: T) !void {
            // Allocate space if the capacity is 0
            if (self.capacity == 0) {
                self.items = try self.allocator.alloc(T, 1);
                self.capacity = 1;
            }

            // Resize if the queue is full
            if (self.isFull()) {
                // Allocate new list of items and copy over data
                const new_capacity = self.capacity * 2;
                const resized = try self.allocator.alloc(T, new_capacity);
                @memcpy(resized[0..self.items.len], self.items);

                // Replace old item list
                self.allocator.free(self.items);
                self.items = resized;
                self.capacity = new_capacity;
            }

            // Update tail and insert item
            if (self.tail == undefined) {
                self.tail = 0;
            } else {
                self.tail = (self.tail + 1) % self.capacity;
            }
            self.items[self.tail] = item;
            self.size += 1;
        }

        /// Returns the first element without removing it from the queue.
        pub fn peek(self: *Self) !T {
            if (self.isEmpty()) {
                return error.EmptyQueue;
            }
            return self.items[self.head];
        }
    };
}

test "Create queue" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var queue = Queue(u8).init(allocator);
    defer queue.deinit();

    try testing.expectEqual(0, queue.size);
    try testing.expectEqual(0, queue.capacity);
    try testing.expect(queue.isEmpty());
    try testing.expectError(error.EmptyQueue, queue.dequeue());

    try queue.enqueue(42);
    try testing.expectEqual(1, queue.size);
    try testing.expectEqual(1, queue.capacity);
    try testing.expectEqual(42, queue.peek());
    try testing.expect(queue.isFull());

    try queue.enqueue(55);
    try testing.expectEqual(2, queue.size);
    try testing.expectEqual(2, queue.capacity);
    try testing.expectEqual(42, queue.peek());
    try testing.expect(queue.isFull());

    const removed = try queue.dequeue();
    try testing.expectEqual(removed, 42);
    try testing.expectEqual(1, queue.size);
    try testing.expectEqual(2, queue.capacity);
    try testing.expectEqual(55, queue.peek());
    try testing.expect(!queue.isFull());
}

test "Create queue with capacity" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var queue = try Queue(u8).initCapacity(allocator, 5);
    defer queue.deinit();

    try testing.expectEqual(0, queue.size);
    try testing.expectEqual(5, queue.capacity);
    try testing.expect(queue.isEmpty());
    try testing.expectError(error.EmptyQueue, queue.dequeue());

    try queue.enqueue(42);
    try testing.expectEqual(1, queue.size);
    try testing.expectEqual(5, queue.capacity);
    try testing.expectEqual(42, queue.peek());
    try testing.expect(!queue.isFull());

    try queue.enqueue(55);
    try testing.expectEqual(2, queue.size);
    try testing.expectEqual(5, queue.capacity);
    try testing.expectEqual(42, queue.peek());
    try testing.expect(!queue.isFull());

    const removed = try queue.dequeue();
    try testing.expectEqual(removed, 42);
    try testing.expectEqual(1, queue.size);
    try testing.expectEqual(5, queue.capacity);
    try testing.expectEqual(55, queue.peek());
    try testing.expect(!queue.isFull());
}
