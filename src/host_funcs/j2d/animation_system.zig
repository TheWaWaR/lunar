const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{ "create_animation_system", create, &.{ I32, I32 }, &.{I64} },
    .{ "connect_signal", connectSignal, &.{I64}, &.{I32} },
    .{ "add_simple_animation", addSimple, &.{ I64, I32, I32, I32, I32, I32 }, &.{I32} },
};

// [moonbit]
// fn create_animation_system_ffi(
//   name_ptr: Int, name_len: Int,
// ) -> UInt64 = "lunar" "create_animation_system"
pub fn create(args: []const Value, results: []Value) ?Ptr {
    var as_ptr: i64 = 0;
    defer results[0] = newi64(as_ptr);
    const app = get_app();
    const name = c.readFromUtf16StrAlloc(args[0..2]) orelse return null;
    const as = j2d.AnimationSystem.create(app.ctx.allocator()) catch |err| {
        std.log.err("j2d.AnimationSystem.create() for {s} error: {}", .{ name, err });
        return null;
    };
    app.as_map_2d.put(name, as) catch @panic("OOM");
    as_ptr = @intCast(@intFromPtr(as));
    return null;
}

fn animation_system_signal(animation_name: []const u8) void {
    _ = animation_name;
    const app = get_app();
    // FIXME: how to distinguish difference AnimationSystem and signal functions
    app.guest.emit() catch |err| {
        std.log.err("call guest.lunar_init error: {}", .{err});
    };
}

// [moonbit]
// fn connect_signal_ffi(as_ptr: UInt64) -> Bool = "lunar" "connect_signal"
pub fn connectSignal(args: []const Value, results: []Value) ?Ptr {
    var success: bool = false;
    defer results[0] = newi32(@intFromBool(success));
    const as: *j2d.AnimationSystem = @ptrFromInt(@as(usize, @intCast(args[0].of.i64)));
    const app = get_app();
    var it = app.as_map_2d.iterator();
    var name: ?[]const u8 = null;
    while (it.next()) |entry| {
        if (entry.value_ptr.* == as) {
            name = entry.key_ptr.*;
        }
    }
    if (name == null) {
        std.log.err("No AnimationSystem found for ptr={}", .{args[0].of.i64});
        return null;
    }
    // FIXME: name actually unused
    as.sig.connect(animation_system_signal) catch @panic("OOM");
    success = true;
    return null;
}

// [moonbit]
// fn add_simple_animation_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   sp_start_ptr: Int, sp_count: Int,
//   fps: Float,
// ) -> Bool = "lunar" "add_simple_animation"
pub fn addSimple(args: []const Value, results: []Value) ?Ptr {
    var success: bool = false;
    defer results[0] = newi32(@intFromBool(success));

    const as = args[0].to_host_ptr(j2d.AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const sp_count: usize = @intCast(args[4].of.i32);
    const app = get_app();
    const sp_items: []Sprite = app.ctx.allocator().alloc(Sprite, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(sp_items);
    const frames: []Frame.Data = app.ctx.allocator().alloc(Frame.Data, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(frames);
    c.readSpritesArg(args[3], sp_items);
    for (0..sp_count) |idx| {
        var frame = &frames[idx];
        frame.sp = sp_items[idx];
    }
    const fps: f32 = @bitCast(args[5].of.i32);
    as.addSimple(name, frames, fps, .{}) catch |err| {
        std.log.err("AnimationSystem.addSimple({s}) error: {}", .{ name, err });
        return null;
    };
    success = true;
    return null;
}
