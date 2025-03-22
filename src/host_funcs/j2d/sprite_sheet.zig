const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Sprite = j2d.Sprite;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("sprite_sheet_from_pictures_in_dir", fromPicturesInDir),
    w.wrapHostFn("get_sprite_by_name", getSpriteByName),
};

pub fn fromPicturesInDir(
    name_ptr: usize,
    name_len: u32,
    dir_ptr: usize,
    dir_len: u32,
    width: u32,
    height: u32,
) ?*j2d.SpriteSheet {
    const name = c.readFromUtf16StrAlloc(name_ptr, name_len) orelse return null;
    const dir = c.readFromUtf16StrWithApp(dir_ptr, dir_len) orelse return null;
    const app = get_app();
    const sheet = j2d.SpriteSheet.fromPicturesInDir(app.ctx, @ptrCast(dir), width, height, .{}) catch |err| {
        std.log.err(
            "Call j2d.SpriteSheet.fromPicturesInDir({s}, {}, {}) error: {}",
            .{ dir, width, height, err },
        );
        return null;
    };
    get_app().sheet_map_2d.put(name, sheet) catch @panic("OOM");
    return sheet;
}

pub fn getSpriteByName(sheet: *j2d.SpriteSheet, name_ptr: usize, name_len: u32, sp_ptr: usize) bool {
    const mem = get_app().guest_mem_data();
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    const sp = sheet.getSpriteByName(name) orelse return false;
    _ = c.writeSpritePtr(mem, sp_ptr, &sp);
    return true;
}
