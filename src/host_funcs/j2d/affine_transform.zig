const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Sprite = j2d.Sprite;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("affine_transform_init_2d", init),
    w.wrapHostFn("affine_transform_translate_2d", translate),
};

fn init(mat_ptr: usize) void {
    const mem = get_app().guest_mem_data();
    _ = c.writeMatPtr(mem, mat_ptr, &j2d.AffineTransform.init().mat);
}

fn translate(mat_in_ptr: usize, pos_ptr: usize, mat_out_ptr: usize) void {
    const mem = get_app().guest_mem_data();
    const in = j2d.AffineTransform{ .mat = c.readMatPtr(mem, mat_in_ptr)[0] };
    const pos, _ = c.readPointPtr(mem, pos_ptr);
    const out = in.translate(pos);
    _ = c.writeMatPtr(mem, mat_out_ptr, &out.mat);
}
