const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const Value = w.Value;
const Ptr = w.Ptr;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{ "debug_print", debugPrint, &.{ I32, I32, F32, F32, I32, I32, I32, I32 }, &.{} },
    .{ "delta_seconds", deltaSeconds, &.{}, &.{F32} },
    .{ "get_canvas_size", getCanvasSize, &.{ I32, I32 }, &.{} },
};

// [moonbit]
// fn debug_print_ffi(
//   text_ptr: Int, text_len: Int,
//   pos_x: Float, pos_y: Float,
//   r: Byte, g: Byte, b: Byte, a: Byte,
// ) = "lunar" "debug_print"
pub fn debugPrint(args: []const Value, _: []Value) ?Ptr {
    const text = c.readFromUtf16StrWithApp(args[0..2]) orelse return null;
    const pos = c.readPoint(args[2..4]);
    const color = c.readColor(args[4..8]);
    get_app().ctx.debugPrint(text, .{ .pos = pos, .color = color });
    return null;
}

// [moonbit] fn get_canvas_size(width_ptr: Int, height_ptr: Int) = "lunar" "get_canvas_size"
pub fn getCanvasSize(args: []const Value, _: []Value) ?Ptr {
    const size = get_app().ctx.getCanvasSize();
    _ = c.writeNumberArg(&args[0], size.width);
    _ = c.writeNumberArg(&args[1], size.height);
    return null;
}

// [moonbit] fn delta_seconds_ffi() -> Float = "lunar" "delta_seconds"
pub fn deltaSeconds(_: []const Value, results: []Value) ?Ptr {
    results[0] = newf32(get_app().ctx.deltaSeconds());
    return null;
}
