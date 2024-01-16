const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "letter-rdp",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/include" });
    lib.addLibraryPath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/lib" });
    lib.linkSystemLibrary("jq");

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "letter-rdp",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/include" });
    exe.addLibraryPath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/lib" });
    exe.linkSystemLibrary("jq");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.addIncludePath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/include" });
    lib_unit_tests.addLibraryPath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/lib" });
    lib_unit_tests.linkSystemLibrary("jq");

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.addIncludePath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/include" });
    exe_unit_tests.addLibraryPath(.{ .path = "/opt/homebrew/Cellar/jq/1.7.1/lib" });
    exe_unit_tests.linkSystemLibrary("jq");

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
