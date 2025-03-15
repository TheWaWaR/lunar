const std = @import("std");
const w = @import("wasmtime.zig");
const c = @import("host_funcs/common.zig");

const io = @import("host_funcs/io.zig");
const ctx = @import("host_funcs/context.zig");
const physfs = @import("host_funcs/physfs.zig");
const j2d = @import("host_funcs/j2d.zig");

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const MODULE: []const u8 = "lunar";

const FUNCS = j2d.FUNCS ++ physfs.FUNCS ++ io.FUNCS ++ ctx.FUNCS;

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(w.Value) != 24) {
        @compileError("The size of Value MUST be 24 bytes!");
    }

    var params_buf: [16]w.ValType = undefined;
    var results_buf: [1]w.ValType = undefined;
    inline for (FUNCS) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define host func: {s}", .{func_name});
        inline for (params, 0..) |param, idx| {
            params_buf[idx] = w.ValType.new(param);
        }
        inline for (results, 0..) |result, idx| {
            results_buf[idx] = w.ValType.new(result);
        }
        try linker.defineFunc(
            MODULE,
            func_name,
            w.wrapHostFn(callback),
            params_buf[0..params.len],
            results_buf[0..results.len],
            &env_data,
        );
    }
}
