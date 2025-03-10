const std = @import("std");
const w = @import("wasmtime.zig");
const get_init_ctx = @import("main.zig").get_init_ctx;

pub fn spectest_print_char(
    env: *anyopaque,
    caller: *anyopaque,
    args: [*c]const w.Value,
    nargs: usize,
    results: [*c]w.Value,
    nresults: usize,
) callconv(.C) ?*anyopaque {
    _ = env;
    _ = caller;
    _ = results;
    _ = nresults;

    _ = args;
    _ = nargs;
    // std.log.info(
    //     "spectest_print_char(): args({})={}, size={any}",
    //     .{ nargs, args[0].of.i32, get_init_ctx().getCanvasSize() },
    // );
    return null;
}
