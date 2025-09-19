const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Shared Module ---
    const frame_module = b.createModule(.{
        .root_source_file = b.path("src/Frame.zig"),
    });

    // --- Sender Executable ---
    const sender_exe = b.addExecutable(.{
        .name = "ethernet_send",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/sender.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "Frame", .module = frame_module }},
        }),
    });
    sender_exe.linkSystemLibrary("c");
    b.installArtifact(sender_exe);

    const run_sender_cmd = b.addRunArtifact(sender_exe);
    run_sender_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_sender_cmd.addArgs(args);
    }
    const run_sender_step = b.step("run-sender", "Run the sender");
    run_sender_step.dependOn(&run_sender_cmd.step);

    // --- Listener Executable ---
    const listener_exe = b.addExecutable(.{
        .name = "ethernet_listen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/listen.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "Frame", .module = frame_module }},
        }),
    });
    listener_exe.linkSystemLibrary("c");
    b.installArtifact(listener_exe);

    const run_listener_cmd = b.addRunArtifact(listener_exe);
    run_listener_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_listener_cmd.addArgs(args);
    }
    const run_listener_step = b.step("run-listener", "Run the listener");
    run_listener_step.dependOn(&run_listener_cmd.step);
}
