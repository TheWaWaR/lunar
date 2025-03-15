const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;
// [moonbit]
// fn sprite_sheet_from_pictures_in_dir_ffi(
//   dir_ptr: Int, dir_len: Int,
//   width: Int, height: Int,
// ) -> UInt64 = "lunar" "sprite_sheet_from_pictures_in_dir"
pub fn fromPicturesInDir(args: []const Value, results: []Value) ?Ptr {
    var sheet_ptr: i64 = 0;
    defer results[0] = newi64(sheet_ptr);
    const dir = c.readFromUtf16StrWithApp(args[0..2]) orelse return null;
    const width: u32 = args[2].to_u32();
    const height: u32 = args[3].to_u32();
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
