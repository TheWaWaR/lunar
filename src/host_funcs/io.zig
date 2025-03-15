const std = @import("std");
const jok = @import("jok");
const c = @import("common.zig");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

const Value = w.Value;
const Ptr = w.Ptr;

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

pub const FUNCS = [_]c.FuncDef{
    .{ "get_keyborad_state", getKeyboardState, &.{I32}, &.{I64} },
    .{ "is_key_pressed", isKeyPressed, &.{ I64, I64, I32 }, &.{I32} },
    .{ "get_keyboard_modifier_state", getKeyboardModifierState, &.{}, &.{I32} },
    .{ "get_mouse_state", getMouseState, &.{ I32, I32 }, &.{I32} },
};

// [moonbit]: fn get_keyborad_state_ffi(len_ptr: Int) -> UInt64  = "lunar" "get_keyborad_state"
pub fn getKeyboardState(args: []const Value, results: []Value) ?Ptr {
    const states = jok.io.getKeyboardState().states;
    _ = c.writeNumberArg(&args[0], states.len);
    results[0] = newi64(@intCast(@intFromPtr(states.ptr)));
    return null;
}

// [moonbit] fn is_key_pressed_ffi(states_ptr: UInt64, states_len: UInt64, scancode: Int) -> Bool = "lunar" "is_key_pressed"
pub fn isKeyPressed(args: []const Value, results: []Value) ?Ptr {
    const states = to_host_byte_slice(&args[0], &args[1]);
    const scancode: c_uint = @intCast(args[2].of.i32);

    const kbd = jok.io.KeyboardState{ .states = states };
    const is_pressed = kbd.isPressed(@enumFromInt(scancode));
    results[0] = newi32(@intFromBool(is_pressed));
    return null;
}

// [moonbit] fn get_keyboard_modifier_state_ffi() -> UInt16 = "lunar" "get_keyboard_modifier_state"
pub fn getKeyboardModifierState(_: []const Value, results: []Value) ?Ptr {
    results[0] = newi32(@intCast(jok.io.getKeyboardModifierState().storage));
    return null;
}

// [moonbit] fn get_mouse_state_ffi(pos_x_ptr: Int, pos_y_ptr: Int) -> Byte = "lunar" "get_mouse_state"
pub fn getMouseState(args: []const Value, results: []Value) ?Ptr {
    const state = jok.io.getMouseState();
    _ = c.writeNumberArg(&args[0], state.pos.x);
    _ = c.writeNumberArg(&args[1], state.pos.y);
    results[0] = newi32(@intCast(state.buttons.storage));
    return null;
}
