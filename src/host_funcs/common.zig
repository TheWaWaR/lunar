const std = @import("std");
const jok = @import("jok");
const get_app = @import("../main.zig").get_app;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;

const Color = jok.Color;
const Point = jok.Point;
const Mat = jok.zmath.Mat;
const Sprite = jok.j2d.Sprite;
const SpriteOption = jok.j2d.Batch.SpriteOption;
const AnimationSystem = jok.j2d.AnimationSystem;
const DrawCmd = jok.j2d.DrawCmd;
const FrameData = AnimationSystem.Frame.Data;

pub fn readFromUtf16StrWithApp(ptr: usize, len_u32: u32) ?[]u8 {
    const app = get_app();
    const mem_data = app.guest_mem_data();
    const text = readFromUtf16Str(&app.bytes_buffer, mem_data, ptr, len_u32) catch |err| {
        std.log.err("read utf16 string err: {}", .{err});
        return null;
    };
    app.bytes_buffer.clearRetainingCapacity();
    return text;
}

pub fn readFromUtf16StrWithApp2(ptr1: usize, len1: u32, ptr2: usize, len2: u32) ?struct { []u8, []u8 } {
    const app = get_app();
    const mem_data = app.guest_mem_data();
    const text1 = readFromUtf16Str(&app.bytes_buffer, mem_data, ptr1, len1) catch |err| {
        std.log.err("read #1 utf16 string err: {}", .{err});
        return null;
    };
    const text2 = readFromUtf16Str(&app.bytes_buffer, mem_data, ptr2, len2) catch |err| {
        std.log.err("read #2 utf16 string err: {}", .{err});
        return null;
    };
    app.bytes_buffer.clearRetainingCapacity();
    return .{ text1, text2[text1.len + 1 ..] };
}

pub fn readFromUtf16StrAlloc(ptr: usize, len_u32: u32) ?[]u8 {
    const len: usize = @intCast(len_u32);
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
    ptr: usize,
    len_u32: u32,
) ![]u8 {
    const len: usize = @intCast(len_u32);
    try std.unicode.utf16LeToUtf8ArrayList(
        buf,
        @alignCast(@ptrCast(mem_data[ptr .. ptr + len * 2])),
    );
    const str = buf.items;
    // For also used as: [*:0]u8
    try buf.append(0);
    return str;
}

pub fn readPointPtr(mem: [*]u8, init_guest_ptr: usize) struct { Point, usize } {
    var guest_ptr = init_guest_ptr;
    var p: Point = undefined;
    guest_ptr = readNumber(f32, mem, guest_ptr, &p.x);
    guest_ptr = readNumber(f32, mem, guest_ptr, &p.y);
    return .{ p, guest_ptr };
}

pub fn writePointPtr(mem: [*]u8, init_guest_ptr: usize, point: *const Point) usize {
    var guest_ptr = init_guest_ptr;
    guest_ptr = writeNumber(mem, guest_ptr, point.x);
    guest_ptr = writeNumber(mem, guest_ptr, point.y);
    return guest_ptr;
}

pub fn readColorPtr(mem: [*]u8, guest_ptr: usize) struct { Color, usize } {
    const r: u8 = mem[guest_ptr + 0];
    const g: u8 = mem[guest_ptr + 1];
    const b: u8 = mem[guest_ptr + 2];
    const a: u8 = mem[guest_ptr + 3];
    return .{ Color.rgba(r, g, b, a), guest_ptr + 4 };
}

pub fn writeColorPtr(mem: [*]u8, guest_ptr: usize, color: *const Color) usize {
    mem[guest_ptr + 0] = color.r;
    mem[guest_ptr + 1] = color.g;
    mem[guest_ptr + 2] = color.b;
    mem[guest_ptr + 3] = color.a;
    return guest_ptr + 4;
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
                &dcmd.cmd.circle.p.y,
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
                cmd.cmd.circle.p.y,
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

pub fn readPtrPtr(mem: [*]u8, init_guest_ptr: usize, host_ptr: *(*anyopaque)) usize {
    var guest_ptr = init_guest_ptr;
    var ptr_int: usize = 0;
    guest_ptr = readNumber(usize, mem, guest_ptr, &ptr_int);
    host_ptr.* = @ptrFromInt(ptr_int);
    return guest_ptr;
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

pub fn writeNumber(mem: [*]u8, guest_ptr: usize, val: anytype) usize {
    const size = @sizeOf(@TypeOf(val));
    comptime assert(size == 4 or size == 8);
    const T = if (size == 4) u32 else u64;
    std.mem.writeInt(T, @ptrCast(mem[guest_ptr..]), @bitCast(val), .little);
    return guest_ptr + size;
}

pub fn writeMatPtr(mem: [*]u8, init_guest_ptr: usize, mat: *const Mat) usize {
    var guest_ptr = init_guest_ptr;
    for (mat) |item| {
        for (0..4) |idx| {
            guest_ptr = writeNumber(mem, guest_ptr, item[idx]);
        }
    }
    return guest_ptr;
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

pub fn readSpriteOptionPtr(mem: [*]u8, init_guest_ptr: usize) struct { SpriteOption, usize } {
    const flags = mem[init_guest_ptr];
    var guest_ptr = init_guest_ptr + 1;
    var opt: SpriteOption = .{ .pos = .{ .x = 0, .y = 0 } };
    opt.pos, guest_ptr = readPointPtr(mem, guest_ptr);
    if (flags & (1 << 1) > 0) {
        opt.tint_color, guest_ptr = readColorPtr(mem, guest_ptr);
    }
    if (flags & (1 << 2) > 0) {
        opt.scale, guest_ptr = readPointPtr(mem, guest_ptr);
    }
    if (flags & (1 << 3) > 0) {
        guest_ptr = readNumber(f32, mem, guest_ptr, &opt.rotate_degree);
    }
    if (flags & (1 << 4) > 0) {
        opt.anchor_point, guest_ptr = readPointPtr(mem, guest_ptr);
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

pub fn writeSpriteOptionPtr(mem: [*]u8, init_guest_ptr: usize, opt: *const SpriteOption) usize {
    const flags: u8 = 0xFF;
    mem[init_guest_ptr] = flags;
    var guest_ptr = init_guest_ptr + 1;
    guest_ptr = writePointPtr(mem, guest_ptr, &opt.pos);
    guest_ptr = writeColorPtr(mem, guest_ptr, &opt.tint_color);
    guest_ptr = writePointPtr(mem, guest_ptr, &opt.scale);
    guest_ptr = writeNumber(mem, guest_ptr, opt.rotate_degree);
    guest_ptr = writePointPtr(mem, guest_ptr, &opt.anchor_point);
    mem[guest_ptr] = @intFromBool(opt.flip_h);
    mem[guest_ptr] = @intFromBool(opt.flip_v);
    guest_ptr += 2;
    guest_ptr = writeNumber(mem, guest_ptr, opt.depth);
    return guest_ptr;
}

pub fn writeBoolPtr(mem: [*]u8, host_ptr: usize, val: bool) void {
    mem[host_ptr] = @intFromBool(val);
}

fn readFn(comptime T: type) type {
    return *const fn ([*]u8, usize) struct { T, usize };
}
fn writeFn(comptime T: type) type {
    return *const fn ([*]u8, usize, *const T) usize;
}
// fn extraAssert(comptime T: type) type {
//     return *const fn
// }
fn testSerde(comptime T: type, write: writeFn(T), read: readFn(T), value: T, size: usize) !void {
    var mem_data: [512]u8 = undefined;
    const mem: [*]u8 = mem_data[0..].ptr;
    const next1_ptr = write(mem, 0, &value);
    try expectEqual(size, next1_ptr);
    const v, const next2_ptr = read(mem, 0);
    try expectEqual(value, v);
    try expectEqual(size, next2_ptr);
}

test "serde: point" {
    try testSerde(
        Point,
        writePointPtr,
        readPointPtr,
        Point{ .x = 33.3, .y = 44.4 },
        8,
    );
}

test "serde: color" {
    try testSerde(
        Color,
        writeColorPtr,
        readColorPtr,
        Color.rgba(2, 5, 6, 7),
        4,
    );
}

test "serde: mat" {
    try testSerde(
        Mat,
        writeMatPtr,
        readMatPtr,
        Mat{
            .{ 1.0, 2.0, 3.0, 4.0 },
            .{ 1.1, 2.1, 3.1, 4.1 },
            .{ 1.2, 2.2, 3.2, 4.2 },
            .{ 1.3, 2.3, 3.3, 4.3 },
        },
        64,
    );
}

test "serde: sprite" {
    const sprite = Sprite{
        .width = 33,
        .height = 44,
        .uv0 = .{ .x = 55, .y = 66 },
        .uv1 = .{ .x = 77, .y = 88 },
        .tex = .{ .ptr = @ptrFromInt(99) },
    };
    try testSerde(Sprite, writeSpritePtr, readSpritePtr, sprite, 32);
}

test "serde: sprite option" {
    const opt = SpriteOption{
        .pos = .{ .x = 11, .y = 22 },
        .tint_color = Color.rgba(5, 6, 7, 8),
        .scale = .{ .x = 33, .y = 44 },
        .rotate_degree = 43.22,
        .anchor_point = .{ .x = 55, .y = 66 },
        .flip_h = true,
        .flip_v = true,
        .depth = 0.344,
    };
    try testSerde(SpriteOption, writeSpriteOptionPtr, readSpriteOptionPtr, opt, 39);
}

test "serde: FrameData" {
    const sp_data = FrameData{
        .sp = Sprite{
            .width = 33,
            .height = 44,
            .uv0 = .{ .x = 55, .y = 66 },
            .uv1 = .{ .x = 77, .y = 88 },
            .tex = .{ .ptr = @ptrFromInt(99) },
        },
    };
    try testSerde(FrameData, writeFrameDataPtr, readFrameDataPtr, sp_data, 33);

    const cmd_data = FrameData{
        .dcmd = DrawCmd{
            .cmd = .{
                .circle = .{
                    .p = .{ .x = 11, .y = 22 },
                    .radius = 99.12,
                    .color = 533,
                    .thickness = 34.33,
                    .num_segments = 5,
                },
            },
            .depth = 23.4,
        },
    };
    try testSerde(FrameData, writeFrameDataPtr, readFrameDataPtr, cmd_data, 30);
}
