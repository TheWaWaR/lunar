
const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const Value = w.Value;
const Ptr = w.Ptr;
const Renderer = jok.Renderer;

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

};

// fn renderer_clear_ffi(renderer_ptr: UInt64, color_ptr: Int) -> Bool = "lunar" "renderer_clear"
fn clear(args: []const Value, _: []Value) ?Ptr {
    _ = args[0].to_host_ptr(Renderer);
    _ = c.readColorArg(args[1]);
    return null;
}
