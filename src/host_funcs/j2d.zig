const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");
const get_app = @import("../main.zig").get_app;

pub const animation_system = @import("j2d/animation_system.zig");
pub const affine_transform = @import("j2d/affine_transform.zig");
pub const sprite_sheet = @import("j2d/sprite_sheet.zig");
pub const sprite = @import("j2d/sprite.zig");

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
