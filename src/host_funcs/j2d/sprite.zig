const std = @import("std");
const jok = @import("jok");
const w = @import("../../wasmtime.zig");
const c = @import("../common.zig");
const get_app = @import("../../main.zig").get_app;

const j2d = jok.j2d;
const Value = w.Value;
const Ptr = w.Ptr;
const Sprite = j2d.Sprite;
const Frame = j2d.AnimationSystem.Frame;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;

pub const FUNCS = [_]c.FuncDef{
    .{"sprite_get_sub_sprite", getSubSprite, &.{I64, F32, F32, F32, F32, I64}, &.{}},
};

// [moonbit]
// fn sprite_get_sub_sprite_ffi(
//   sp_in_ptr: Int,
//   offset_x: f32, offset_y: f32,
//   width: f32, height: f32,
//   sp_out_ptr: Int,
// ) = "lunar" "sprite_get_sub_sprite"
fn getSubSprite(args: []const Value, _: []Value) ?Ptr {
    const sp = c.readSpriteArg(&args[0]);
    const offset_x = args[1].toNumber(f32);
    const offset_y = args[2].toNumber(f32);
    const width = args[3].toNumber(f32);
    const height = args[4].toNumber(f32);
    const sub_sp = sp.getSubSprite(offset_x, offset_y, width, height);
    _ = c.writeSpriteArg(&args[5], &sub_sp);
    return null;
}
