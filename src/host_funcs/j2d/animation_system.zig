const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;
const AnimationSystem = j2d.AnimationSystem;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("animation_system_create", create),
    w.wrapHostFn("connect_signal", connectSignal),
    w.wrapHostFn("add_simple_animation", addSimple),
    w.wrapHostFn("animation_system_is_over", isOver),
    w.wrapHostFn("animation_system_is_stopped", isStopped),
    w.wrapHostFn("animation_system_reset", reset),
    w.wrapHostFn("animation_system_set_stop", setStop),
    w.wrapHostFn("animation_system_get_current_frame", getCurrentFrame),
    w.wrapHostFn("animation_system_update", update),
};

pub fn create(name_ptr: usize, name_len: u32) ?*AnimationSystem {
    const app = get_app();
    const name = c.readFromUtf16StrAlloc(name_ptr, name_len) orelse return null;
    const as = AnimationSystem.create(app.ctx.allocator()) catch |err| {
        std.log.err("j2d.AnimationSystem.create() for {s} error: {}", .{ name, err });
        return null;
    };
    app.as_map_2d.put(name, as) catch @panic("OOM");
    return as;
}

fn animation_system_signal(animation_name: []const u8) void {
    _ = animation_name;
    const app = get_app();
    // FIXME: how to distinguish difference AnimationSystem and signal functions
    app.guest.emit() catch |err| {
        std.log.err("call guest.lunar_init error: {}", .{err});
    };
}

pub fn connectSignal(as: *AnimationSystem) bool {
    const app = get_app();
    var it = app.as_map_2d.iterator();
    var name: ?[]const u8 = null;
    while (it.next()) |entry| {
        if (entry.value_ptr.* == as) {
            name = entry.key_ptr.*;
        }
    }
    if (name == null) {
        std.log.err("No AnimationSystem found for ptr={}", .{@intFromPtr(as)});
        return false;
    }
    // FIXME: name actually unused
    as.sig.connect(animation_system_signal) catch @panic("OOM");
    return true;
}

pub fn addSimple(
    as: *AnimationSystem,
    name_ptr: usize,
    name_len: u32,
    frame_datas_start_ptr: usize,
    frame_data_count: u32,
    fps: f32,
    wait_time: f32,
    is_loop: bool,
    reverse: bool,
) bool {
    const app = get_app();
    const mem = app.guest_mem_data();
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    const frames: []Frame.Data = app.ctx.allocator().alloc(Frame.Data, @intCast(frame_data_count)) catch @panic("OOM");
    defer app.ctx.allocator().free(frames);
    var guest_ptr = frame_datas_start_ptr;
    for (0..frame_data_count) |idx| {
        frames[idx], guest_ptr = c.readFrameDataPtr(mem, guest_ptr);
    }
    var opt = AnimationSystem.AnimOption{};
    opt.wait_time = wait_time;
    opt.loop = is_loop;
    opt.reverse = reverse;
    as.addSimple(name, frames, fps, opt) catch |err| {
        std.log.err("AnimationSystem.addSimple({s}) error: {}", .{ name, err });
        return false;
    };
    return true;
}

fn isOver(as: *AnimationSystem, name_ptr: usize, name_len: u32, is_over_ptr: usize) bool {
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    const is_over = as.isOver(name) catch |err| {
        std.log.err("AnimationSystem.isOver({s}) error: {}", .{ name, err });
        return false;
    };
    const mem = get_app().guest_mem_data();
    c.writeBoolPtr(mem, is_over_ptr, is_over);
    return true;
}

fn isStopped(as: *AnimationSystem, name_ptr: usize, name_len: u32, is_stopped_ptr: usize) bool {
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    const is_stopped = as.isStopped(name) catch |err| {
        std.log.err("AnimationSystem.isStopped({s}) error: {}", .{ name, err });
        return false;
    };
    const mem = get_app().guest_mem_data();
    c.writeBoolPtr(mem, is_stopped_ptr, is_stopped);
    return true;
}

fn reset(as: *AnimationSystem, name_ptr: usize, name_len: u32) bool {
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    as.reset(name) catch |err| {
        std.log.err("AnimationSystem.reset({s}) error: {}", .{ name, err });
        return false;
    };
    return true;
}

fn setStop(as: *AnimationSystem, name_ptr: usize, name_len: u32, stop: bool) bool {
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    as.setStop(name, stop) catch |err| {
        std.log.err("AnimationSystem.setStop({s}, {}) error: {}", .{ name, stop, err });
        return false;
    };
    return true;
}

fn getCurrentFrame(as: *AnimationSystem, name_ptr: usize, name_len: u32, frame_data_ptr: usize) bool {
    const mem = get_app().guest_mem_data();
    const name = c.readFromUtf16StrWithApp(name_ptr, name_len) orelse return false;
    const frame = as.getCurrentFrame(name) catch |err| {
        std.log.err("AnimationSystem.getCurrentFrame({s}) error: {}", .{ name, err });
        return false;
    };
    _ = c.writeFrameDataPtr(mem, frame_data_ptr, &frame);
    return true;
}

fn update(as: *AnimationSystem, delta_tick: f32) void {
    as.update(delta_tick);
}
