const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

pub const animation_system = @import("j2d/animation_system.zig");
pub const affine_transform = @import("j2d/affine_transform.zig");
pub const sprite_sheet = @import("j2d/sprite_sheet.zig");
pub const sprite = @import("j2d/sprite.zig");

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;

const I64 = w.WasmValKind.i64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const newptr = Value.newPtr;
const to_host_byte_slice = Value.to_host_byte_slice;

pub const FUNCS = [_]c.FuncDef{
    .{ "new_batch", newBatch, &.{}, &.{I64} },
} ++ animation_system.FUNCS ++ affine_transform.FUNCS ++ sprite_sheet.FUNCS ++ sprite.FUNCS;

// [moonbit] fn new_batch_ffi() -> UInt64 = "lunar" "new_batch"
pub fn newBatch(_: []const Value, results: []Value) ?Ptr {
    results[0] = newi64(0);
    const batch = get_app().batchpool_2d.new(.{}) catch |err| {
        std.log.err("new 2d batch error: {}", .{err});
        return null;
    };
    results[0] = newptr(batch);
    return null;
}
