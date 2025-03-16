const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const animation_system = @import("j2d/animation_system.zig");
const affine_transform = @import("j2d/affine_transform.zig");
const sprite_sheet = @import("j2d/sprite_sheet.zig");
const sprite = @import("j2d/sprite.zig");

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;
const Batch = j2d.Batch;
const Frame = j2d.AnimationSystem.Frame;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const newptr = Value.newPtr;

pub const FUNCS = [_]c.FuncDef{
    .{ "batch_new_2d", batchNew, &.{}, &.{I64} },
    .{ "batch_submit_2d", batchSubmit, &.{I64}, &.{} },
    .{ "batch_push_transform_2d", batchPushTransform, &.{I64}, &.{I32} },
    .{ "batch_pop_transform_2d", batchPopTransform, &.{I64}, &.{} },
    .{ "batch_sprite_2d", batchSprite, &.{ I64, I32, I32 }, &.{I32} },
} ++ animation_system.FUNCS ++ affine_transform.FUNCS ++ sprite_sheet.FUNCS ++ sprite.FUNCS;

// [moonbit] fn batch_new_2d_ffi() -> UInt64 = "lunar" "batch_new_2d"
fn batchNew(_: []const Value, results: []Value) ?Ptr {
    results[0] = newi64(0);
    const batch = get_app().batchpool_2d.new(.{}) catch |err| {
        std.log.err("new 2d batch error: {}", .{err});
        return null;
    };
    results[0] = newptr(batch);
    return null;
}

// [moonbit] fn batch_submit_2d_ffi(batch_ptr: UInt64)  = "lunar" "batch_submit_2d"
fn batchSubmit(args: []const Value, _: []Value) ?Ptr {
    const batch = args[0].to_host_ptr(Batch);
    batch.submit();
    return null;
}

// [moonbit] fn batch_push_transform_2d_ffi(batch_ptr: UInt64) -> Bool  = "lunar" "batch_push_transform_2d"
fn batchPushTransform(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const batch = args[0].to_host_ptr(Batch);
    batch.pushTransform() catch |err| {
        std.log.err("Batch.pushTransform error: {}", .{err});
    };
    results[0] = newi32(1);
    return null;
}

// [moonbit] fn batch_pop_transform_2d_ffi(batch_ptr: UInt64)  = "lunar" "batch_pop_transform_2d"
fn batchPopTransform(args: []const Value, _: []Value) ?Ptr {
    const batch = args[0].to_host_ptr(Batch);
    batch.popTransform();
    return null;
}
// [moonbit] fn batch_sprite_2d_ffi(
//   batch_ptr: UInt64, sp_ptr: Int, opt_ptr: Int,
// ) -> Bool = "lunar" "batch_sprite_2d"
fn batchSprite(args: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(0);
    const batch = args[0].to_host_ptr(Batch);
    const sp = c.readSprite(&args[1]);
    const opt = c.readSpriteOption(args[2].to_guest_ptr());
    batch.sprite(sp, opt) catch |err| {
        std.log.err("Batch.sprite, error: {}", .{err});
        return null;
    };
    results[0] = newi32(1);
    return null;
}
