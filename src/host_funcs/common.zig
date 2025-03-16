const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Value = w.Value;
const Sprite = jok.j2d.Sprite;
const SpriteOption = jok.j2d.Batch.SpriteOption;
const Mat = jok.zmath.Mat;

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
    const ptr = args[0].toGuestPtr();
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
    const ptr = args[0].toGuestPtr();
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
    const ptr = args[0].toGuestPtr();
    const len: usize = @intCast(args[1].of.i32);
    const mem_data = get_app().guest_mem_data();
    return mem_data[ptr .. ptr + len];
}

pub fn readPointArg(arg: *const Value) jok.Point {
    var guest_ptr = arg.toGuestPtr();
    var p: jok.Point = undefined;
    guest_ptr += readNumber(f32, guest_ptr, &p.x);
    guest_ptr += readNumber(f32, guest_ptr, &p.y);
    return p;
}

pub fn writePointArg(arg: *const Value, point: jok.Point) usize {
    const guest_ptr = arg.toGuestPtr();
    _ = writeNumber(guest_ptr + 0, point.x);
    _ = writeNumber(guest_ptr + 4, point.y);
    return 8;
}

pub fn readColorArg(arg: *const Value) jok.Color {
    const guest_ptr = arg.toGuestPtr();
    const mem_data = get_app().guest_mem_data();
    const r: u8 = mem_data[guest_ptr + 0];
    const g: u8 = mem_data[guest_ptr + 1];
    const b: u8 = mem_data[guest_ptr + 2];
    const a: u8 = mem_data[guest_ptr + 3];
    return jok.Color.rgba(r, g, b, a);
}

pub fn readSpriteArg(arg: *const Value) Sprite {
    var sprites: [1]Sprite = undefined;
    readSpritesArg(arg, sprites[0..]);
    return sprites[0];
}

pub fn readSpritesArg(arg: *const Value, items: []Sprite) void {
    var guest_ptr = arg.toGuestPtr();
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

pub fn writeSpriteArg(arg: *const Value, sp: Sprite) usize {
    const guest_ptr = arg.toGuestPtr();
    var size: usize = 0;
    inline for (.{
        sp.width,
        sp.height,
        sp.uv0.x,
        sp.uv0.y,
        sp.uv1.x,
        sp.uv1.y,
        @intFromPtr(sp.tex.ptr),
    }) |val| {
        size += writeNumber(guest_ptr + size, val);
    }
    return size;
}

pub fn readNumberArg(comptime T: type, arg: *const Value, ptr: *T) usize {
    return readNumber(T, arg.toGuestPtr(), ptr);
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
    return writeNumber(arg.toGuestPtr(), val);
}

pub fn writeNumber(guest_ptr: usize, val: anytype) usize {
    const size = @sizeOf(@TypeOf(val));
    comptime assert(size == 4 or size == 8);
    const T = if (size == 4) u32 else u64;
    const mem_data = get_app().guest_mem_data();
    std.mem.writeInt(T, @ptrCast(mem_data[guest_ptr..]), @bitCast(val), .little);
    return size;
}

pub fn writeMat(_guest_ptr: usize, mat: Mat) void {
    var guest_ptr = _guest_ptr;
    for (mat) |item| {
        for (0..4) |idx| {
            guest_ptr += writeNumber(guest_ptr, item[idx]);
        }
    }
}

pub fn readMat(_guest_ptr: usize) Mat {
    var guest_ptr = _guest_ptr;
    var mat: Mat = undefined;
    for (0..4) |mat_idx| {
        var arr: [4]f32 = undefined;
        for (0..4) |idx| {
            guest_ptr += readNumber(f32, guest_ptr, &arr[idx]);
        }
        mat[mat_idx] = arr;
    }
    return mat;
}

pub fn readSpriteOptionArg(arg: *const Value) SpriteOption {
    return readSpriteOption(arg.toGuestPtr());
}

pub fn readSpriteOption(_guest_ptr: usize) SpriteOption {
    const mem_data = get_app().guest_mem_data();
    const flags = mem_data[_guest_ptr];
    var guest_ptr = _guest_ptr + 1;
    var opt: SpriteOption = undefined;
    if (flags & (1 << 0) > 0) {
        guest_ptr += readNumber(f32, guest_ptr, &opt.pos.x);
        guest_ptr += readNumber(f32, guest_ptr, &opt.pos.y);
    }
    if (flags & (1 << 1) > 0) {
        opt.tint_color.r = mem_data[guest_ptr + 0];
        opt.tint_color.g = mem_data[guest_ptr + 1];
        opt.tint_color.b = mem_data[guest_ptr + 2];
        opt.tint_color.a = mem_data[guest_ptr + 3];
        guest_ptr += 4;
    }
    if (flags & (1 << 2) > 0) {
        guest_ptr += readNumber(f32, guest_ptr, &opt.scale.x);
        guest_ptr += readNumber(f32, guest_ptr, &opt.scale.y);
    }
    if (flags & (1 << 3) > 0) {
        guest_ptr += readNumber(f32, guest_ptr, &opt.rotate_degree);
    }
    if (flags & (1 << 4) > 0) {
        guest_ptr += readNumber(f32, guest_ptr, &opt.anchor_point.x);
        guest_ptr += readNumber(f32, guest_ptr, &opt.anchor_point.y);
    }
    if (flags & (1 << 5) > 0) {
        opt.flip_h = mem_data[guest_ptr] > 0;
        guest_ptr += 1;
    }
    if (flags & (1 << 6) > 0) {
        opt.flip_v = mem_data[guest_ptr] > 0;
        guest_ptr += 1;
    }
    if (flags & (1 << 7) > 0) {
        guest_ptr += readNumber(f32, guest_ptr, &opt.depth);
    }
    return opt;
}
