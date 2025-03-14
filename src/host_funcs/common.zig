const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

const Allocator = std.mem.Allocator;
const Value = w.Value;

pub fn readFromUtf16StrWithApp(args: []const Value) ?[]u8 {
    const app = get_app();
    const mem_data = app.guest_mem_data();
    const text = readFromUtf16Str(&app.bytes_buffer, mem_data, args) catch |err| {
        std.log.err("read utf16 string err: {}", .{err});
        return null;
    };
    app.bytes_buffer.clearRetainingCapacity();
    return text;
}

pub fn readFromUtf16StrWithApp2(args1: []const Value, args2: []const Value) ?struct { []u8, []u8 } {
    const app = get_app();
    const mem_data = app.guest_mem_data();
    const text1 = readFromUtf16Str(&app.bytes_buffer, mem_data, args1) catch |err| {
        std.log.err("read #1 utf16 string err: {}", .{err});
        return null;
    };
    const text2 = readFromUtf16Str(&app.bytes_buffer, mem_data, args2) catch |err| {
        std.log.err("read #2 utf16 string err: {}", .{err});
        return null;
    };
    app.bytes_buffer.clearRetainingCapacity();
    return .{ text1, text2[text1.len + 1 ..] };
}

pub fn readFromUtf16StrAlloc(args: []const Value) ?[]u8 {
    const ptr = args[0].to_guest_ptr();
    const len: usize = @intCast(args[1].of.i32);
    const app = get_app();
    const mem_data = app.guest_mem_data();
    const text = std.unicode.utf16LeToUtf8Alloc(
        app.ctx.allocator(),
        @alignCast(@ptrCast(mem_data[ptr .. ptr + len * 2])),
    ) catch |err| {
        std.log.err("read utf16 string alloc err: {}", .{err});
        return null;
    };
    return text;
}

// The returned string have a `\x00` appended to the end.
pub fn readFromUtf16Str(
    buf: *std.ArrayList(u8),
    mem_data: [*]u8,
    args: []const Value,
) ![]u8 {
    const ptr = args[0].to_guest_ptr();
    const len: usize = @intCast(args[1].of.i32);
    try std.unicode.utf16LeToUtf8ArrayList(
        buf,
        @alignCast(@ptrCast(mem_data[ptr .. ptr + len * 2])),
    );
    // For also used as: [*:0]u8
    try buf.append(0);
    return buf.items;
}

pub fn readBytes(mem_data: [*]const u8, args: []const Value) []const u8 {
    const ptr = args[0].to_guest_ptr();
    const len: usize = @intCast(args[1].of.i32);
    return mem_data[ptr .. ptr + len];
}

pub fn readPoint(args: []const Value) jok.Point {
    const x: f32 = args[0].of.f32;
    const y: f32 = args[1].of.f32;
    return jok.Point{ .x = x, .y = y };
}

pub fn readColor(args: []const Value) jok.Color {
    const r: u8 = @intCast(args[0].of.i32);
    const g: u8 = @intCast(args[1].of.i32);
    const b: u8 = @intCast(args[2].of.i32);
    const a: u8 = @intCast(args[3].of.i32);
    return jok.Color.rgba(r, g, b, a);
}
