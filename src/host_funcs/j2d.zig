const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

// [moonbit]
// fn create_animation_system_ffi(
//   name_ptr: Int, name_len: Int,
// ) -> UInt64 = "lunar" "create_animation_system"
pub fn createAnimationSystem(args: []const Value, results: []Value) ?Ptr {
    var as_ptr: i64 = 0;
    defer results[0] = newi64(as_ptr);
    const app = get_app();
    const name = c.readFromUtf16StrAlloc(args[0..2]) orelse return null;
    const as = j2d.AnimationSystem.create(app.ctx.allocator()) catch |err| {
        std.log.err("j2d.AnimationSystem.create() for {s} error: {}", .{ name, err });
        return null;
    };
    app.as_map_2d.put(name, as) catch @panic("OOM");
    as_ptr = @intCast(@intFromPtr(as));
    return null;
}

fn animation_system_signal(animation_name: []const u8) void {
    _ = animation_name;
    const app = get_app();
    // FIXME: how to distinguish difference AnimationSystem and signal functions
    app.guest.emit() catch |err| {
        std.log.err("call guest.lunar_init error: {}", .{err});
    };
}

// [moonbit]
// fn connect_signal_ffi(as_ptr: UInt64) -> Bool = "lunar" "connect_signal"
pub fn connectSignal(args: []const Value, results: []Value) ?Ptr {
    var success: bool = false;
    defer results[0] = newi32(@intFromBool(success));
    const as: *j2d.AnimationSystem = @ptrFromInt(@as(usize, @intCast(args[0].of.i64)));
    const app = get_app();
    var it = app.as_map_2d.iterator();
    var name: ?[]const u8 = null;
    while (it.next()) |entry| {
        if (entry.value_ptr.* == as) {
            name = entry.key_ptr.*;
        }
    }
    if (name == null) {
        std.log.err("No AnimationSystem found for ptr={}", .{args[0].of.i64});
        return null;
    }
    // FIXME: name actually unused
    as.sig.connect(animation_system_signal) catch @panic("OOM");
    success = true;
    return null;
}

// [moonbit]
// fn add_simple_animation_ffi(
//   as_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   sp_start_ptr: Int, sp_count: Int,
//   fps: Float,
// ) -> Bool = "lunar" "add_simple_animation"
pub fn addSimpleAnimation(args: []const Value, results: []Value) ?Ptr {
    var success: bool = false;
    defer results[0] = newi32(@intFromBool(success));

    const as: *j2d.AnimationSystem = @alignCast(@ptrCast(args[0].to_host_ptr()));
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const sp_count: usize = @intCast(args[4].of.i32);
    const app = get_app();
    const sp_items: []Sprite = app.ctx.allocator().alloc(Sprite, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(sp_items);
    const frames: []Frame.Data = app.ctx.allocator().alloc(Frame.Data, sp_count) catch @panic("OOM");
    defer app.ctx.allocator().free(frames);
    c.readSprites(&args[3], sp_items);
    for (0..sp_count) |idx| {
        var frame = &frames[idx];
        frame.sp = sp_items[idx];
    }
    const fps: f32 = @bitCast(args[5].of.i32);
    as.addSimple(name, frames, fps, .{}) catch |err| {
        std.log.err("AnimationSystem.addSimple({s}) error: {}", .{name, err});
        return null;
    };
    success = true;
    return null;
}

// [moonbit]
// fn sprite_sheet_from_pictures_in_dir_ffi(
//   dir_ptr: Int, dir_len: Int,
//   width: Int, height: Int,
// ) -> UInt64 = "lunar" "sprite_sheet_from_pictures_in_dir"
pub fn spriteSheetFromPicturesInDir(args: []const Value, results: []Value) ?Ptr {
    var sheet_ptr: i64 = 0;
    defer results[0] = newi64(sheet_ptr);
    const dir = c.readFromUtf16StrWithApp(args[0..2]) orelse return null;
    const width: u32 = @intCast(args[2].of.i32);
    const height: u32 = @intCast(args[2].of.i32);
    const app = get_app();
    const sheet = j2d.SpriteSheet.fromPicturesInDir(app.ctx, @ptrCast(dir), width, height, .{}) catch |err| {
        std.log.err(
            "Call j2d.SpriteSheet.fromPicturesInDir({s}, {}, {}) error: {}",
            .{ dir, width, height, err },
        );
        return null;
    };
    sheet_ptr = @intCast(@intFromPtr(sheet));
    return null;
}

// [moonbit]
// fn get_sprite_by_name_ffi(
//   sheet_ptr: UInt64,
//   name_ptr: Int, name_len: Int,
//   sp_bytes_ptr: Int,
// ) -> Bool = "lunar" "get_sprite_by_name"
pub fn getSpriteByName(args: []const Value, results: []Value) ?Ptr {
    var success: bool = false;
    defer results[0] = newi32(@intFromBool(success));
    const sheet: *j2d.SpriteSheet = @alignCast(@ptrCast(args[0].to_host_ptr()));
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const sp = sheet.getSpriteByName(name) orelse return null;
    c.writeSprite(&args[3], sp);
    success = true;
    return null;
}
