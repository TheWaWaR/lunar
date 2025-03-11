const std = @import("std");
const w = @import("wasmtime.zig");
const get_init_ctx = @import("main.zig").get_init_ctx;

pub fn getKeyboardState(
    env: *anyopaque,
    caller: *anyopaque,
    args: [*c]const w.Value,
    nargs: usize,
    results: [*c]w.Value,
    nresults: usize,
) callconv(.C) ?*anyopaque {
    _ = env;
    _ = caller;
    _ = args;
    _ = nargs;
    _ = results;
    _ = nresults;
    return null;
}
