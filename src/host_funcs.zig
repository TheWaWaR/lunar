const std = @import("std");
const w = @import("wasmtime.zig");

const io = @import("host_funcs/io.zig");
const ctx = @import("host_funcs/context.zig");
const physfs = @import("host_funcs/physfs.zig");
const j2d = @import("host_funcs/j2d.zig");
const renderer = @import("host_funcs/renderer.zig");

const MODULE: []const u8 = "lunar";
const FUNCS = j2d.FUNCS ++ physfs.FUNCS ++ io.FUNCS ++ ctx.FUNCS ++ renderer.FUNCS;

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    inline for (FUNCS, 1..) |func, func_idx| {
        std.log.info(
            "define host #{} {s}({}) -> {}",
            .{ func_idx, func.name, func.params.len, func.results.len },
        );
        try linker.defineFunc(
            MODULE,
            func.name,
            func.callback,
            func.params,
            func.results,
            &env_data,
        );
    }
}

test {
    std.testing.refAllDecls(@This());
}
