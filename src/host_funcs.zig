const std = @import("std");
const w = @import("wasmtime.zig");
const c = @import("host_funcs/common.zig");

const io = @import("host_funcs/io.zig");
const ctx = @import("host_funcs/context.zig");
const physfs = @import("host_funcs/physfs.zig");
const j2d = @import("host_funcs/j2d.zig");
const renderer = @import("host_funcs/renderer.zig");

const MODULE: []const u8 = "lunar";
const FUNCS = j2d.FUNCS ++ physfs.FUNCS ++ io.FUNCS ++ ctx.FUNCS ++ renderer.FUNCS;

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(w.Value) != 24) {
        @compileError("The size of Value MUST be 24 bytes!");
    }

    var params_buf: [16]w.ValType = undefined;
    var results_buf: [1]w.ValType = undefined;
    inline for (FUNCS, 1..) |item, func_idx| {
        const func_name, const callback, const params, const results = item;

        std.log.info(
            "define host #{} {s}({}) -> {}",
            .{ func_idx, func_name, params.len, results.len },
        );
        inline for (params, 0..) |param, idx| {
            params_buf[idx] = w.ValType.new(param);
        }
        inline for (results, 0..) |result, idx| {
            results_buf[idx] = w.ValType.new(result);
        }
        try linker.defineFunc(
            MODULE,
            func_name,
            callback,
            params_buf[0..params.len],
            results_buf[0..results.len],
            &env_data,
        );
    }
}

test {
    std.testing.refAllDecls(@This());
}
