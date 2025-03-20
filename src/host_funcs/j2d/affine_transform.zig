const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{ "affine_transform_init_2d", init, &.{I32}, &.{} },
    .{ "affine_transform_translate_2d", translate, &.{ I32, I32, I32 }, &.{} },
};

// [moonbit] fn affine_transform_init_2d_ffi(mat_ptr: Int)  = "lunar" "affine_transform_init_2d"
fn init(args: []const Value, _: []Value) ?Ptr {
    c.writeMatArg(&args[0], j2d.AffineTransform.init().mat);
    return null;
}

// [moonbit] fn affine_transform_translate_2d_ffi(
//   mat_in_ptr: Int, pos_ptr: Int, mat_out_ptr: Int,
// )  = "lunar" "affine_transform_translate_2d"
fn translate(args: []const Value, _: []Value) ?Ptr {
    const in = j2d.AffineTransform{ .mat = c.readMatArg(&args[0]) };
    const pos = c.readPointArg(&args[1]);
    const out = in.translate(pos);
    c.writeMatArg(&args[2], out.mat);
    return null;
}
