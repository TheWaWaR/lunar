const std = @import("std");
const jok = @import("jok");
const c = @import("common.zig");
const w = @import("../wasmtime.zig");
const get_app = @import("../main.zig").get_app;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("get_keyboard_state", getKeyboardState),
    w.wrapHostFn("is_key_pressed", isKeyPressed),
    w.wrapHostFn("get_keyboard_modifier_state", getKeyboardModifierState),
    w.wrapHostFn("get_mouse_state", getMouseState),
};

pub fn getKeyboardState(len_ptr: usize) u64 {
    const mem = get_app().guest_mem_data();
    const states = jok.io.getKeyboardState().states;
    _ = c.writeNumber(mem, len_ptr, states.len);
    return @intCast(@intFromPtr(states.ptr));
}

pub fn isKeyPressed(states_ptr: *u8, states_len: usize, scancode: c_uint) bool {
    const ptr: [*]u8 = @alignCast(@ptrCast(states_ptr));
    const states = ptr[0..states_len];
    const kbd = jok.io.KeyboardState{ .states = states };
    return kbd.isPressed(@enumFromInt(scancode));
}

pub fn getKeyboardModifierState() u16 {
    return jok.io.getKeyboardModifierState().storage;
}

pub fn getMouseState(pos_ptr: usize) u8 {
    const mem = get_app().guest_mem_data();
    const state = jok.io.getMouseState();
    _ = c.writePointPtr(mem, pos_ptr, &state.pos);
    return @intCast(state.buttons.storage);
}
