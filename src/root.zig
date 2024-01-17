const std = @import("std");
const JqHelper = @import("jq_helper.zig");

const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();



const AstNode = union(enum) {
    NumericLiteral: NumericLiteral,
};

const NumericLiteral = struct {
    value: u64,

    pub fn toJson(self: NumericLiteral, allocator: *Allocator) ![]u8 {
        return std.json.stringifyAlloc(allocator.*, self, .{ .whitespace = .indent_4 });
    }
};

const Program = struct {
    body: NumericLiteral,


    pub fn toJson(self: Program, allocator: *Allocator) ![]const u8 {
        return std.json.stringifyAlloc(allocator.*, self, .{ .whitespace = .indent_4 });
    }
};

pub fn parse(input: []const u8) !Program {
    const value = try std.fmt.parseInt(u64, input, 10);
    return Program{ .body = NumericLiteral{ .value = value } };
}

pub fn main() void {
    var allocator = std.heap.page_allocator;
    const input = "42";

    const program = parse(input) catch {
        stdout.print("Error parsing input: {s}\n", .{input}) catch return;
        return;
    };

    const json_output = program.toJson(&allocator) catch {
        stdout.print("Error generating JSON: {s}\n", .{input}) catch return;
        return;
    };
    defer allocator.free(json_output);

    stdout.print("JSON output:\n{s}\n", .{json_output}) catch return;

    const pretty_json = JqHelper.prettyPrintJson(json_output, &allocator) catch |err| {
        stdout.print("Error pretty printing JSON: {}\n", .{err}) catch return;
        return;
    };
    stdout.print("Jq output: \n{s}\n", .{pretty_json}) catch return;
}
