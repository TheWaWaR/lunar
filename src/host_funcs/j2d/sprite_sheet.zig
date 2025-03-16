const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{ "sprite_sheet_from_pictures_in_dir", fromPicturesInDir, &.{ I32, I32, I32, I32 }, &.{I64} },
    .{ "get_sprite_by_name", getSpriteByName, &.{ I64, I32, I32, I32 }, &.{I32} },
};

// [moonbit]
// fn sprite_sheet_from_pictures_in_dir_ffi(
//   dir_ptr: Int, dir_len: Int,
//   width: Int, height: Int,
// ) -> UInt64 = "lunar" "sprite_sheet_from_pictures_in_dir"
pub fn fromPicturesInDir(args: []const Value, results: []Value) ?Ptr {
    var sheet_ptr: i64 = 0;
    defer results[0] = newi64(sheet_ptr);
    const dir = c.readFromUtf16StrWithApp(args[0..2]) orelse return null;
    const width = args[2].to_number(u32);
    const height = args[3].to_number(u32);
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
    const sheet = args[0].to_host_ptr(j2d.SpriteSheet);
    const name = c.readFromUtf16StrWithApp(args[1..3]) orelse return null;
    const sp = sheet.getSpriteByName(name) orelse return null;
    c.writeSprite(&args[3], sp);
    success = true;
    return null;
}
