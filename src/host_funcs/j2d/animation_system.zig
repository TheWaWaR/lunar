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
const AnimationSystem = j2d.AnimationSystem;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{ "animation_system_create", create, &.{ I32, I32 }, &.{I64} },
    .{ "connect_signal", connectSignal, &.{I64}, &.{I32} },
    .{ "add_simple_animation", addSimple, &.{ I64, I32, I32, I32, I32, I32 }, &.{I32} },
    .{ "animation_system_is_over", isOver, &.{ I64, I32, I32, I32 }, &.{I32} },
    .{ "animation_system_is_stopped", isStopped, &.{ I64, I32, I32, I32 }, &.{I32} },
    .{ "animation_system_reset", reset, &.{ I64, I32, I32 }, &.{I32} },
    .{ "animation_system_set_stop", setStop, &.{ I64, I32, I32, I32 }, &.{I32} },
    .{ "animation_system_get_current_frame", getCurrentFrame, &.{ I64, I32, I32, I32 }, &.{I32} },
};

// [moonbit]
// fn animation_system_create_ffi(
//   name_ptr: Int, name_len: Int,
// ) -> UInt64 = "lunar" "animation_system_create"
pub fn create(args: []const Value, results: []Value) ?Ptr {
    var as_ptr: i64 = 0;
    defer results[0] = newi64(as_ptr);
    const app = get_app();
    const name = c.readFromUtf16StrAlloc(args[0..2]) orelse return null;
    const as = AnimationSystem.create(app.ctx.allocator()) catch |err| {
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
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
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
    results[0] = newi32(1);
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
    results[0] = newi32(0);

    const app = get_app();
    const as = args[0].toHostPtr(j2d.AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const sp_count = args[4].toNumber(usize);
    const sp_items: []Sprite = app.ctx.allocator().alloc(Sprite, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(sp_items);
    const frames: []Frame.Data = app.ctx.allocator().alloc(Frame.Data, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(frames);
    c.readSpritesArg(&args[3], sp_items);
    for (0..sp_count) |idx| {
        var frame = &frames[idx];
        frame.sp = sp_items[idx];
    }
    const fps = args[5].toNumber(f32);
    as.addSimple(name, frames, fps, .{}) catch |err| {
        std.log.err("AnimationSystem.addSimple({s}) error: {}", .{ name, err });
        return null;
    };
    results[0] = newi32(1);
    return null;
}

// [moonbit]
// fn animation_system_is_over_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   is_over_ptr: Int,
// ) -> Bool = "lunar" "animation_system_is_over"
fn isOver(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const is_over = as.isOver(name) catch |err| {
        std.log.err("AnimationSystem.isOver({s}) error: {}", .{ name, err });
        return null;
    };
    c.writeBoolArg(&args[3], is_over);
    results[0] = newi32(1);
    return null;
}

// [moonbit]
// fn animation_system_is_stopped_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   is_stopped_ptr: Int,
// ) -> Bool = "lunar" "animation_system_is_stopped"
fn isStopped(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const is_over = as.isOver(name) catch |err| {
        std.log.err("AnimationSystem.isStopped({s}) error: {}", .{ name, err });
        return null;
    };
    c.writeBoolArg(&args[3], is_over);
    results[0] = newi32(1);
    return null;
}

// [moonbit]
// fn animation_system_reset_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
// ) -> Bool = "lunar" "animation_system_reset"
fn reset(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    as.reset(name) catch |err| {
        std.log.err("AnimationSystem.reset({s}) error: {}", .{ name, err });
        return null;
    };
    results[0] = newi32(1);
    return null;
}

// [moonbit]
// fn animation_system_set_stop_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   stop: Bool,
// ) -> Bool = "lunar" "animation_system_set_stop"
fn setStop(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const stop = args[3].toBool();
    as.setStop(name, stop) catch |err| {
        std.log.err("AnimationSystem.setStop({s}, {}) error: {}", .{ name, stop, err });
        return null;
    };
    results[0] = newi32(1);
    return null;
}

// [moonbit]
// fn animation_system_get_current_frame_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   sprite_ptr: Int,
// ) -> Bool = "lunar" "animation_system_get_current_frame"
fn getCurrentFrame(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const as = args[0].toHostPtr(AnimationSystem);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const frame = as.getCurrentFrame(name) catch |err| {
        std.log.err("AnimationSystem.getCurrentFrame({s}) error: {}", .{ name, err });
        return null;
    };
    _ = c.writeSpriteArg(&args[3], frame.sp);
    results[0] = newi32(1);
    return null;
}
