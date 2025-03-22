const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const animation_system = @import("j2d/animation_system.zig");
const affine_transform = @import("j2d/affine_transform.zig");
const sprite_sheet = @import("j2d/sprite_sheet.zig");
const sprite = @import("j2d/sprite.zig");

const j2d = jok.j2d;
const Sprite = j2d.Sprite;
const Batch = j2d.Batch;
const Frame = j2d.AnimationSystem.Frame;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("batch_new_2d", batchNew),
    w.wrapHostFn("batch_submit_2d", batchSubmit),
    w.wrapHostFn("batch_push_transform_2d", batchPushTransform),
    w.wrapHostFn("batch_pop_transform_2d", batchPopTransform),
    w.wrapHostFn("batch_set_transform_2d", batchSetTransform),
    w.wrapHostFn("batch_sprite_2d", batchSprite),
    w.wrapHostFn("batch_push_draw_cmd_2d", batchPushDrawCmd),
} ++ animation_system.FUNCS ++ affine_transform.FUNCS ++ sprite_sheet.FUNCS ++ sprite.FUNCS;

fn batchNew() ?*Batch {
    const batch = get_app().batchpool_2d.new(.{}) catch |err| {
        std.log.err("new 2d batch error: {}", .{err});
        return null;
    };
    return batch;
}

fn batchSubmit(batch: *Batch) void {
    batch.submit();
}

fn batchPushTransform(batch: *Batch) bool {
    batch.pushTransform() catch |err| {
        std.log.err("Batch.pushTransform error: {}", .{err});
        return false;
    };
    return true;
}

fn batchPopTransform(batch: *Batch) void {
    batch.popTransform();
}

fn batchSetTransform(batch: *Batch, mat_ptr: usize) void {
    const mem = get_app().guest_mem_data();
    const mat, _ = c.readMatPtr(mem, mat_ptr);
    batch.trs = .{ .mat = mat };
}

fn batchSprite(batch: *Batch, sp_ptr: usize, opt_ptr: usize) bool {
    const mem = get_app().guest_mem_data();
    const sp, _ = c.readSpritePtr(mem, sp_ptr);
    const opt, _ = c.readSpriteOptionPtr(mem, opt_ptr);
    batch.sprite(sp, opt) catch |err| {
        std.log.err("Batch.sprite, error: {}", .{err});
        return false;
    };
    return true;
}

fn batchPushDrawCmd(batch: *Batch, frame_data_ptr: usize) bool {
    const mem = get_app().guest_mem_data();
    const data, _ = c.readFrameDataPtr(mem, frame_data_ptr);
    batch.pushDrawCommand(data.dcmd) catch |err| {
        std.log.err("Batch.pushDrawCommand, error: {}", .{err});
        return false;
    };
    return true;
}
