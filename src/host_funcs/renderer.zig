const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const Renderer = jok.Renderer;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn( "renderer_clear", clear),
};

fn clear(renderer: *Renderer, color_ptr: usize) bool {
    const mem = get_app().guest_mem_data();
    const color, _ = c.readColorPtr(mem, color_ptr);
    renderer.*.clear(color) catch |err| {
        std.log.err("renderer.clear() error: {}", .{err});
        return false;
    };
    return true;
}
