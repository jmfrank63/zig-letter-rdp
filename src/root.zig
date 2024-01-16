const std = @import("std");
const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

const c = @cImport({
    @cInclude("jq.h");
});

const AstNode = union(enum) {
    NumericLiteral: NumericLiteral,
};

const NumericLiteral = struct {
    value: u64,

    // Custom function to serialize as JSON
    pub fn toJson(self: NumericLiteral, allocator: *Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator.*, "{{\"type\": \"NumericLiteral\", \"value\": {}}}", .{self.value});
    }
};

const Program = struct {
    body: NumericLiteral,

    pub fn toJson(self: Program, allocator: *Allocator) ![]u8 {
        const body_json = try self.body.toJson(allocator);
        defer allocator.free(body_json);

        // Ensure to use {s} for body_json which is a slice
        return std.fmt.allocPrint(allocator.*, "{{\"body\": {s}}}", .{body_json});
    }
};

pub fn parse(input: []const u8) !Program {
    const value = try std.fmt.parseInt(u64, input, 10);
    return Program{ .body = NumericLiteral{ .value = value } };
}

pub fn main() void {
    var allocator = std.heap.page_allocator;
    const input = "42";
    var jq = c.jq_init();
    defer c.jq_teardown(&jq);

    const program = parse(input) catch {
        stdout.print("Error parsing input: {s}\n", .{input}) catch return;
        return;
    };

    const json_output = program.toJson(&allocator) catch {
        stdout.print("Error generating JSON: {s}\n", .{input}) catch return;
        return;
    };
    defer allocator.free(json_output);

    // Create an empty jv array
    const args = c.jv_array();

    // Compile the jq program
    const jq_program = c.jq_compile_args(jq, ".", args);

    if (jq_program == 0) {
        std.debug.print("Failed to compile jq program.\n", .{});
        return;
    }

    // Convert the JSON output to a jv object
    const json_jv = c.jv_parse_sized(json_output.ptr, @as(c_int, @intCast(json_output.len)));
    if (c.jv_is_valid(json_jv) == 0) {
        std.debug.print("Invalid JSON output.\n", .{});
        return;
    }

    // Start the jq program with the JSON output
    c.jq_start(jq, json_jv, 0);

    // Print the formatted JSON output
    var output = c.jq_next(jq);
    while (c.jv_is_valid(output) != 0) {
        const output_str = c.jv_dump_string(output, c.JV_PRINT_PRETTY | c.JV_PRINT_SPACE1);
        const str_output = c.jv_string_value(output_str);
        stdout.print("{s}", .{str_output}) catch return;
        output = c.jq_next(jq);
    }
}
