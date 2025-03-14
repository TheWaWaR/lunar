const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const common = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

const readBytes = common.readBytes;
const readFromUtf16StrWithApp = common.readFromUtf16StrWithApp;
const readFromUtf16StrAlloc = common.readFromUtf16StrAlloc;
const readPoint = common.readPoint;
const readColor = common.readColor;

// [moonbit]
// fn create_animation_system_ffi(
//   name_ptr: Int, name_len: Int,
// ) -> UInt64 = "lunar" "create_animation_system"
pub fn createAnimationSystem(args: []const Value, results: []Value) ?Ptr {
    var as_ptr: i64 = 0;
    defer results[0] = newi64(as_ptr);
    const app = get_app();
    const name = readFromUtf16StrAlloc(args[0..2]) orelse return null;
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
    var success: i32 = 0;
    defer results[0] = newi32(success);
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
    success = 1;
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
    const dir = readFromUtf16StrWithApp(args[0..2]) orelse return null;
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
