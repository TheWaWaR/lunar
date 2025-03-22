const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("sprite_get_sub_sprite", getSubSprite),
};

fn getSubSprite(
    sp_in_ptr: usize,
    offset_x: f32,
    offset_y: f32,
    width: f32,
    height: f32,
    sp_out_ptr: usize,
) void {
    const mem = get_app().guest_mem_data();
    const sp, _ = c.readSpritePtr(mem, sp_in_ptr);
    const sub_sp = sp.getSubSprite(offset_x, offset_y, width, height);
    _ = c.writeSpritePtr(mem, sp_out_ptr, &sub_sp);
}
