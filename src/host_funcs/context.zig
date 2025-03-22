const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("debug_print", debugPrint),
    w.wrapHostFn("kill", kill),
    w.wrapHostFn("delta_seconds", deltaSeconds),
    w.wrapHostFn("get_canvas_size", getCanvasSize),
    w.wrapHostFn("get_renderer", getRenderer),
    w.wrapHostFn("display_stats", displayStats),
};

fn debugPrint(text_ptr: usize, text_len: u32, pos_ptr: usize, color_ptr: usize) void {
    const text = c.readFromUtf16StrWithApp(text_ptr, text_len) orelse return;
    const mem = get_app().guest_mem_data();
    const pos, _ = c.readPointPtr(mem, pos_ptr);
    const color, _ = c.readColorPtr(mem, color_ptr);
    get_app().ctx.debugPrint(text, .{ .pos = pos, .color = color });
}

fn kill() void {
    get_app().ctx.kill();
}

fn deltaSeconds() f32 {
    return get_app().ctx.deltaSeconds();
}

fn getCanvasSize(width_ptr: usize, height_ptr: usize) void {
    const mem = get_app().guest_mem_data();
    const size = get_app().ctx.getCanvasSize();
    _ = c.writeNumber(mem, width_ptr, size.width);
    _ = c.writeNumber(mem, height_ptr, size.height);
}

fn getRenderer() *jok.Renderer {
    return get_app().get_renderer();
}

fn displayStats() void {
    // FIXME: provider DisplayStats
    get_app().ctx.displayStats(.{});
}
