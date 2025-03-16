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
    .{ "affine_transform_translate_2d", translate, &.{ I32, F32, F32, I32 }, &.{} },
};

// [moonbit] fn affine_transform_init_2d_ffi(mat_ptr: Int)  = "lunar" "affine_transform_init_2d"
fn init(args: []const Value, _: []Value) ?Ptr {
    c.writeMat(args[0].to_guest_ptr(), j2d.AffineTransform.init().mat);
    return null;
}

// [moonbit] fn affine_transform_translate_2d_ffi(
//   mat_in_ptr: Int, pos_x: f32, pos_y: f32, mat_out_ptr: Int,
// )  = "lunar" "affine_transform_translate_2d"
fn translate(args: []const Value, _: []Value) ?Ptr {
    const in = j2d.AffineTransform{ .mat = c.readMat(args[0].to_guest_ptr()) };
    const pos = c.readPoint(args[1..3]);
    const out = in.translate(pos);
    c.writeMat(args[3].to_guest_ptr(), out.mat);
    return null;
}
