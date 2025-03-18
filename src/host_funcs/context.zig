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
const newptr = Value.newPtr;

pub const FUNCS = [_]c.FuncDef{
    .{ "debug_print", debugPrint, &.{ I32, I32, I32, I32 }, &.{} },
    .{ "kill", kill, &.{}, &.{} },
    .{ "delta_seconds", deltaSeconds, &.{}, &.{F32} },
    .{ "get_canvas_size", getCanvasSize, &.{ I32, I32 }, &.{} },
    .{ "get_renderer", getRenderer, &.{}, &.{I64} },
    .{ "display_stats", displayStats, &.{}, &.{} },
};

// NOTE: for native host function
pub export fn debug_print(text_ptr: i32, text_len: i32, pos_ptr: i32, color_ptr: i32) void {
    const params: []const Value = &.{
        newi32(text_ptr),
        newi32(text_len),
        newi32(pos_ptr),
        newi32(color_ptr),
    };
    _ = debugPrint(params, &.{});
}
// [moonbit]
// fn debug_print_ffi(
//   text_ptr: Int, text_len: Int,
//   pos_ptr: Int, color_ptr: Int,
// ) = "lunar" "debug_print"
fn debugPrint(args: []const Value, _: []Value) ?Ptr {
    const text = c.readFromUtf16StrWithApp(args[0..2]) orelse return null;
    const pos = c.readPointArg(&args[2]);
    const color = c.readColorArg(&args[3]);
    get_app().ctx.debugPrint(text, .{ .pos = pos, .color = color });
    return null;
}

fn kill(_: []const Value, _: []Value) ?Ptr {
    get_app().ctx.kill();
    return null;
}

// [moonbit] fn delta_seconds_ffi() -> Float = "lunar" "delta_seconds"
fn deltaSeconds(_: []const Value, results: []Value) ?Ptr {
    results[0] = newf32(get_app().ctx.deltaSeconds());
    return null;
}

// [moonbit] fn get_canvas_size(width_ptr: Int, height_ptr: Int) = "lunar" "get_canvas_size"
fn getCanvasSize(args: []const Value, _: []Value) ?Ptr {
    const size = get_app().ctx.getCanvasSize();
    _ = c.writeNumberArg(&args[0], size.width);
    _ = c.writeNumberArg(&args[1], size.height);
    return null;
}

// NOTE: for native host function
pub export fn get_renderer() u64 {
    var results: [1]Value = undefined;
    _ = getRenderer(&.{}, &results);
    return results[0].toNumber(u64);
}
// [moonbit] fn get_renderer_ffi() -> UInt64 = "lunar" "get_renderer"
fn getRenderer(_: []const Value, results: []Value) ?Ptr {
    results[0] = newptr(get_app().get_renderer());
    return null;
}

// [moonbit] fn display_stats_ffi() = "lunar" "display_stats"
fn displayStats(_: []const Value, _: []Value) ?Ptr {
    get_app().ctx.displayStats(.{});
    return null;
}
