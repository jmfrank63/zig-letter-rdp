const std = @import("std");
const c = @cImport({
    @cInclude("jq.h");
});
const stdout = std.io.getStdOut().writer();

pub fn prettyPrintJson(json_output: []const u8, allocator: *std.mem.Allocator) ![]const u8 {
    var jq = c.jq_init();
    defer c.jq_teardown(&jq);
    // Create an empty jv array
    const args = c.jv_array();

    // Compile the jq program
    const jq_program = c.jq_compile_args(jq, ".", args);

    if (jq_program == 0) {
        std.debug.print("Failed to compile jq program.\n", .{});
        return error.FailedToCompileJqProgram;
    }

    // Convert the JSON output to a jv object
    const json_jv = c.jv_parse_sized(json_output.ptr, @as(c_int, @intCast(json_output.len)));
    if (c.jv_is_valid(json_jv) == 0) {
        std.debug.print("Invalid JSON output.\n", .{});
        return error.InvalidJsonOutput;
    }

    // Start the jq program with the JSON output
    c.jq_start(jq, json_jv, 0);

    var result = std.ArrayList(u8).init(allocator.*);
    defer result.deinit();
    // Print the formatted JSON output
    var output = c.jq_next(jq);
    while (c.jv_is_valid(output) != 0) {
        const output_str = c.jv_dump_string(output, c.JV_PRINT_PRETTY | c.JV_PRINT_SPACE1);
        const str_output = c.jv_string_value(output_str);
        const c_output_str = std.mem.span(str_output);
        try result.appendSlice(c_output_str);
        output = c.jq_next(jq);
    }
    return result.toOwnedSlice();
}
