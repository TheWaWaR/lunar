const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Value = w.Value;
const Sprite = jok.j2d.Sprite;

pub const FuncDef = struct {
    []const u8,
    w.HostFn,
    []const w.WasmValKind,
    []const w.WasmValKind,
};

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

pub fn readBytes(args: []const Value) []const u8 {
    const ptr = args[0].to_guest_ptr();
    const len: usize = @intCast(args[1].of.i32);
    const mem_data = get_app().guest_mem_data();
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

pub fn readSprites(arg: *const Value, items: []Sprite) void {
    var guest_ptr = arg.to_guest_ptr();
    for (0..items.len) |idx| {
        var item = &items[idx];
        inline for (.{
            &item.width,
            &item.height,
            &item.uv0.x,
            &item.uv0.y,
            &item.uv1.x,
            &item.uv1.y,
        }) |host_ptr| {
            guest_ptr += readNumber(f32, guest_ptr, host_ptr);
        }
        var ptr_int: usize = 0;
        guest_ptr += readNumber(usize, guest_ptr, &ptr_int);
        item.tex.ptr = @ptrFromInt(ptr_int);
    }
}

pub fn writeSprite(arg: *const Value, sp: Sprite) void {
    var guest_ptr = arg.to_guest_ptr();
    inline for (.{
        sp.width,
        sp.height,
        sp.uv0.x,
        sp.uv0.y,
        sp.uv1.x,
        sp.uv1.y,
        @intFromPtr(sp.tex.ptr),
    }) |val| {
        guest_ptr += writeNumber(guest_ptr, val);
    }
}

pub fn readNumberArg(comptime T: type, arg: *const Value, ptr: *T) usize {
    return readNumber(T, arg.to_guest_ptr(), ptr);
}

pub fn readNumber(comptime T: type, guest_ptr: usize, ptr: *T) usize {
    const size = @sizeOf(T);
    if (size != 4 and size != 8) {
        @compileError("Invalid size of type value");
    }
    const IT = if (size == 4) u32 else u64;
    const mem_data = get_app().guest_mem_data();
    const int_value = std.mem.readInt(IT, @ptrCast(mem_data[guest_ptr..]), .little);
    ptr.* = @bitCast(int_value);
    return size;
}

pub fn writeNumberArg(arg: *const Value, val: anytype) usize {
    return writeNumber(arg.to_guest_ptr(), val);
}

pub fn writeNumber(guest_ptr: usize, val: anytype) usize {
    const size = @sizeOf(@TypeOf(val));
    comptime assert(size == 4 or size == 8);
    const T = if (size == 4) u32 else u64;
    const mem_data = get_app().guest_mem_data();
    std.mem.writeInt(T, @ptrCast(mem_data[guest_ptr..]), @bitCast(val), .little);
    return size;
}
