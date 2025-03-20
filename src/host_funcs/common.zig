const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Value = w.Value;
const Mat = jok.zmath.Mat;
const Sprite = jok.j2d.Sprite;
const SpriteOption = jok.j2d.Batch.SpriteOption;
const AnimationSystem = jok.j2d.AnimationSystem;
const DrawCmd = jok.j2d.DrawCmd;
const FrameData = AnimationSystem.Frame.Data;

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
    const str = buf.items;
    // For also used as: [*:0]u8
    try buf.append(0);
    return str;
}

pub fn readBytes(args: []const Value) []const u8 {
    const ptr = args[0].toGuestPtr();
    const len: usize = @intCast(args[1].of.i32);
    const mem_data = get_app().guest_mem_data();
    return mem_data[ptr .. ptr + len];
}

pub fn readPointArg(arg: *const Value) jok.Point {
    const mem = get_app().guest_mem_data();
    return readPointPtr(mem, arg.toGuestPtr())[0];
}

pub fn readPointPtr(mem: [*]u8, init_guest_ptr: usize) struct { jok.Point, usize } {
    var guest_ptr = init_guest_ptr;
    var p: jok.Point = undefined;
    guest_ptr = readNumber(f32, mem, guest_ptr, &p.x);
    guest_ptr = readNumber(f32, mem, guest_ptr, &p.y);
    return .{ p, guest_ptr };
}

pub fn writePointArg(arg: *const Value, point: jok.Point) void {
    const mem = get_app().guest_mem_data();
    _ = writePointPtr(mem, arg.toGuestPtr(), point);
}

pub fn writePointPtr(mem: [*]u8, init_guest_ptr: usize, point: jok.Point) usize {
    var guest_ptr = init_guest_ptr;
    guest_ptr = writeNumber(mem, guest_ptr, point.x);
    guest_ptr = writeNumber(mem, guest_ptr, point.y);
    return guest_ptr;
}

pub fn readColorArg(arg: *const Value) jok.Color {
    const mem = get_app().guest_mem_data();
    return readColorPtr(mem, arg.toGuestPtr())[0];
}

pub fn readColorPtr(mem: [*]u8, guest_ptr: usize) struct { jok.Color, usize } {
    const r: u8 = mem[guest_ptr + 0];
    const g: u8 = mem[guest_ptr + 1];
    const b: u8 = mem[guest_ptr + 2];
    const a: u8 = mem[guest_ptr + 3];
    return .{ jok.Color.rgba(r, g, b, a), guest_ptr + 4 };
}

pub fn readFrameDataArg(arg: *const Value) FrameData {
    const mem = get_app().guest_mem_data();
    return readFrameDataPtr(mem, arg.toGuestPtr())[0];
}

pub fn readFrameDataPtr(mem: [*]u8, init_guest_ptr: usize) struct { FrameData, usize } {
    var guest_ptr = init_guest_ptr;
    const enum_tag = mem[guest_ptr];
    guest_ptr += 1;
    var data: FrameData = undefined;
    switch (enum_tag) {
        // sp: Sprite,
        1 => {
            const sprite, guest_ptr = readSpritePtr(mem, guest_ptr);
            data = .{ .sp = sprite };
        },
        // dcmd: internal.DrawCmd,
        2 => {
            const dcmd, guest_ptr = readDrawCmdPtr(mem, guest_ptr);
            data = .{ .dcmd = dcmd };
        },
        else => unreachable,
    }
    return .{ data, guest_ptr };
}

pub fn writeFrameDataArg(arg: *const Value, data: *const FrameData) void {
    const mem = get_app().guest_mem_data();
    _ = writeFrameDataPtr(mem, arg.toGuestPtr(), data);
}

pub fn writeFrameDataPtr(mem: [*]u8, init_guest_ptr: usize, data: *const FrameData) usize {
    var guest_ptr = init_guest_ptr + 1;
    var enum_tag: u8 = 0;
    switch (data.*) {
        .sp => |sp| {
            enum_tag = 1;
            guest_ptr = writeSpritePtr(mem, guest_ptr, &sp);
        },
        .dcmd => |dcmd| {
            enum_tag = 2;
            guest_ptr = writeDrawCmdPtr(mem, guest_ptr, &dcmd);
        },
    }
    mem[init_guest_ptr] = enum_tag;
    return guest_ptr;
}

pub fn readSpriteArg(arg: *const Value) Sprite {
    const mem = get_app().guest_mem_data();
    return readSpritePtr(mem, arg.toGuestPtr())[0];
}

pub fn readSpritePtr(mem: [*]u8, init_guest_ptr: usize) struct { Sprite, usize } {
    var guest_ptr = init_guest_ptr;
    var sprite: Sprite = undefined;
    inline for (.{
        &sprite.width,
        &sprite.height,
        &sprite.uv0.x,
        &sprite.uv0.y,
        &sprite.uv1.x,
        &sprite.uv1.y,
    }) |host_ptr| {
        guest_ptr = readNumber(f32, mem, guest_ptr, host_ptr);
    }
    guest_ptr = readPtrPtr(mem, guest_ptr, &sprite.tex.ptr);
    return .{ sprite, guest_ptr };
}

pub fn readDrawCmdPtr(mem: [*]u8, init_guest_ptr: usize) struct { DrawCmd, usize } {
    var guest_ptr = init_guest_ptr;
    const enum_tag = mem[guest_ptr];
    guest_ptr += 1;
    var dcmd: DrawCmd = undefined;
    switch (enum_tag) {
        // quad_image: QuadImageCmd
        1 => unreachable,
        // image_rounded: ImageRoundedCmd,
        2 => unreachable,
        // line: LineCmd,
        3 => unreachable,
        // rect_rounded: RectRoundedCmd,
        4 => unreachable,
        // rect_rounded_fill: RectFillRoundedCmd,
        5 => unreachable,
        // quad: QuadCmd,
        6 => unreachable,
        // quad_fill: QuadFillCmd,
        7 => unreachable,
        // triangle: TriangleCmd,
        8 => unreachable,
        // triangle_fill: TriangleFillCmd,
        9 => unreachable,
        // circle: CircleCmd,
        10 => {
            dcmd.cmd = .{ .circle = undefined };
            inline for (.{
                &dcmd.cmd.circle.p.x,
                &dcmd.cmd.circle.p.x,
                &dcmd.cmd.circle.radius,
                &dcmd.cmd.circle.color,
                &dcmd.cmd.circle.thickness,
                &dcmd.cmd.circle.num_segments,
            }) |host_ptr| {
                const ptr_ty = @TypeOf(host_ptr);
                const ty = @typeInfo(ptr_ty).pointer.child;
                guest_ptr = readNumber(ty, mem, guest_ptr, host_ptr);
            }
        },
        // circle_fill: CircleFillCmd,
        11 => unreachable,
        // ngon: NgonCmd,
        12 => unreachable,
        // ngon_fill: NgonFillCmd,
        13 => unreachable,
        // convex_polygon: ConvexPolyCmd,
        14 => unreachable,
        // convex_polygon_fill: ConvexPolyFillCmd,
        15 => unreachable,
        // bezier_cubic: BezierCubicCmd,
        16 => unreachable,
        // bezier_quadratic: BezierQuadraticCmd,
        17 => unreachable,
        // polyline: PolylineCmd,
        18 => unreachable,
        // path: PathCmd,
        19 => unreachable,
        else => unreachable,
    }
    guest_ptr = readNumber(f32, mem, guest_ptr, &dcmd.depth);
    return .{ dcmd, guest_ptr };
}

pub fn writeDrawCmdPtr(mem: [*]u8, init_guest_ptr: usize, cmd: *const DrawCmd) usize {
    var guest_ptr = init_guest_ptr + 1;
    var enum_tag: u8 = 0;
    switch (cmd.cmd) {
        .circle => {
            enum_tag = 10;
            inline for (.{
                cmd.cmd.circle.p.x,
                cmd.cmd.circle.p.x,
                cmd.cmd.circle.radius,
                cmd.cmd.circle.color,
                cmd.cmd.circle.thickness,
                cmd.cmd.circle.num_segments,
            }) |value| {
                guest_ptr = writeNumber(mem, guest_ptr, value);
            }
        },
        else => @panic("TODO"),
    }
    mem[init_guest_ptr] = enum_tag;
    guest_ptr = writeNumber(mem, guest_ptr, cmd.depth);
    return guest_ptr;
}

pub fn readPtrArg(arg: *const Value, host_ptr: *(*anyopaque)) void {
    const mem = get_app().guest_mem_data();
    _ = readPointPtr(mem, arg.toGuestPtr(), host_ptr);
}

pub fn readPtrPtr(mem: [*]u8, init_guest_ptr: usize, host_ptr: *(*anyopaque)) usize {
    var guest_ptr = init_guest_ptr;
    var ptr_int: usize = 0;
    guest_ptr = readNumber(usize, mem, guest_ptr, &ptr_int);
    host_ptr.* = @ptrFromInt(ptr_int);
    return guest_ptr;
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
            guest_ptr = readNumber(f32, guest_ptr, host_ptr);
        }
        var ptr_int: usize = 0;
        guest_ptr = readNumber(usize, guest_ptr, &ptr_int);
        item.tex.ptr = @ptrFromInt(ptr_int);
    }
}

pub fn writeSpriteArg(arg: *const Value, sp: *const Sprite) void {
    const mem = get_app().guest_mem_data();
    _ = writeSpritePtr(mem, arg.toGuestPtr(), sp);
}

pub fn writeSpritePtr(mem: [*]u8, init_guest_ptr: usize, sp: *const Sprite) usize {
    var guest_ptr = init_guest_ptr;
    inline for (.{
        sp.width,
        sp.height,
        sp.uv0.x,
        sp.uv0.y,
        sp.uv1.x,
        sp.uv1.y,
        @intFromPtr(sp.tex.ptr),
    }) |val| {
        guest_ptr = writeNumber(mem, guest_ptr, val);
    }
    return guest_ptr;
}

pub fn readNumberArg(comptime T: type, arg: *const Value, ptr: *T) usize {
    const mem = get_app().guest_mem_data();
    return readNumber(T, mem, arg.toGuestPtr(), ptr);
}

pub fn readNumber(comptime T: type, mem: [*]u8, guest_ptr: usize, ptr: *T) usize {
    const size = @sizeOf(T);
    if (size != 4 and size != 8) {
        @compileError("Invalid size of type value");
    }
    const IT = if (size == 4) u32 else u64;
    const int_value = std.mem.readInt(IT, @ptrCast(mem[guest_ptr..]), .little);
    ptr.* = @bitCast(int_value);
    return guest_ptr + size;
}

pub fn writeNumberArg(arg: *const Value, val: anytype) void {
    const mem = get_app().guest_mem_data();
    _ = writeNumber(mem, arg.toGuestPtr(), val);
}

pub fn writeNumber(mem: [*]u8, guest_ptr: usize, val: anytype) usize {
    const size = @sizeOf(@TypeOf(val));
    comptime assert(size == 4 or size == 8);
    const T = if (size == 4) u32 else u64;
    std.mem.writeInt(T, @ptrCast(mem[guest_ptr..]), @bitCast(val), .little);
    return guest_ptr + size;
}

pub fn writeMatArg(arg: *const Value, mat: Mat) void {
    const mem = get_app().guest_mem_data();
    _ = writeMatPtr(mem, arg.toGuestPtr(), mat);
}

pub fn writeMatPtr(mem: [*]u8, init_guest_ptr: usize, mat: Mat) usize {
    var guest_ptr = init_guest_ptr;
    for (mat) |item| {
        for (0..4) |idx| {
            guest_ptr = writeNumber(mem, guest_ptr, item[idx]);
        }
    }
    return guest_ptr;
}

pub fn readMatArg(arg: *const Value) Mat {
    const mem = get_app().guest_mem_data();
    return readMatPtr(mem, arg.toGuestPtr())[0];
}

pub fn readMatPtr(mem: [*]u8, init_guest_ptr: usize) struct { Mat, usize } {
    var guest_ptr = init_guest_ptr;
    var mat: Mat = undefined;
    for (0..4) |mat_idx| {
        var arr: [4]f32 = undefined;
        for (0..4) |idx| {
            guest_ptr = readNumber(f32, mem, guest_ptr, &arr[idx]);
        }
        mat[mat_idx] = arr;
    }
    return .{ mat, guest_ptr };
}

pub fn readSpriteOptionArg(arg: *const Value) SpriteOption {
    const mem = get_app().guest_mem_data();
    return readSpriteOption(mem, arg.toGuestPtr())[0];
}

pub fn readSpriteOption(mem: [*]u8, init_guest_ptr: usize) struct { SpriteOption, usize } {
    const flags = mem[init_guest_ptr];
    var guest_ptr = init_guest_ptr + 1;
    var opt: SpriteOption = .{ .pos = .{ .x = 0, .y = 0 } };
    guest_ptr = readNumber(f32, mem, guest_ptr, &opt.pos.x);
    guest_ptr = readNumber(f32, mem, guest_ptr, &opt.pos.y);
    if (flags & (1 << 1) > 0) {
        opt.tint_color, guest_ptr = readColorPtr(mem, guest_ptr);
    }
    if (flags & (1 << 2) > 0) {
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.scale.x);
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.scale.y);
    }
    if (flags & (1 << 3) > 0) {
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.rotate_degree);
    }
    if (flags & (1 << 4) > 0) {
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.anchor_point.x);
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.anchor_point.y);
    }
    if (flags & (1 << 5) > 0) {
        opt.flip_h = mem[guest_ptr] > 0;
        guest_ptr += 1;
    }
    if (flags & (1 << 6) > 0) {
        opt.flip_v = mem[guest_ptr] > 0;
        guest_ptr += 1;
    }
    if (flags & (1 << 7) > 0) {
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.depth);
    }
    return .{ opt, guest_ptr };
}

pub fn writeBoolArg(arg: *const Value, val: bool) void {
    get_app().guest_mem_data()[arg.toGuestPtr()] = @intFromBool(val);
}
