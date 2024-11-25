const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("mespas", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    // Library
    // ==========================
    const lib = b.addStaticLibrary(.{
        .name = "mespas",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Executable
    // ============================
    const example = b.addExecutable(.{
        .name = "mespas-bin",
        .root_source_file = b.path("example.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(example);
    const run_cmd = b.addRunArtifact(example);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run");
    run_step.dependOn(&run_cmd.step);

    // Tests
    // ==========================
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
