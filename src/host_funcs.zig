const std = @import("std");
const jok = @import("jok");
const w = @import("wasmtime.zig");
const app = @import("main.zig");

const Value = w.Value;
const Ptr = w.Ptr;

const newI32 = w.ValType.newI32;
const newI64 = w.ValType.newI64;
const newF32 = w.ValType.newF32;
const newF64 = w.ValType.newF64;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

const MODULE: []const u8 = "lunar";

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(Value) != 24) {
        @compileError("The size of Value must be 24 bytes!");
    }

    inline for (.{
        .{ "get_keyborad_state", getKeyboardState, &.{newI32()}, &.{newI64()} },
        .{ "is_key_pressed", isKeyPressed, &.{ newI64(), newI64(), newI32() }, &.{newI32()} },
        .{ "get_keyboard_modifier_state", getKeyboardModifierState, &.{}, &.{newI32()} },
        .{ "get_mouse_state", getMouseState, &.{ newI32(), newI32() }, &.{newI32()} },
    }) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define func: {s}", .{func_name});
        try linker.defineFunc(MODULE, func_name, w.wrapFn(callback), params, results, &env_data);
    }
}

// [moonbit]: fn get_keyborad_state_ffi(len_ptr: Int) -> UInt64  = "lunar" "get_keyborad_state"
pub fn getKeyboardState(args: [*]const Value, results: [*]Value) ?Ptr {
    const states = jok.io.getKeyboardState().states;
    const mem_data = app.get_memory_data();
    const len_ptr = args[0].to_guest_ptr();
    std.mem.writeInt(usize, @ptrCast(mem_data[len_ptr..]), states.len, .little);
    results[0] = newi64(@intCast(@intFromPtr(states.ptr)));
    return null;
}

// [moonbit] fn is_key_pressed_ffi(states_ptr: UInt64, states_len: UInt64, scancode: Int) -> Bool = "lunar" "is_key_pressed"
pub fn isKeyPressed(args: [*]const Value, results: [*]Value) ?Ptr {
    const states = to_host_byte_slice(&args[0], &args[1]);
    const scancode: c_uint = @intCast(args[2].of.i32);
    const kbd = jok.io.KeyboardState{ .states = states };
    const is_pressed = kbd.isPressed(@enumFromInt(scancode));
    results[0] = newi32(@intFromBool(is_pressed));
    return null;
}

// [moonbit] fn get_keyboard_modifier_state_ffi() -> UInt16 = "lunar" "get_keyboard_modifier_state"
pub fn getKeyboardModifierState(_: [*]const Value, results: [*]Value) ?Ptr {
    results[0] = newi32(@intCast(jok.io.getKeyboardModifierState().storage));
    return null;
}

// [moonbit] fn get_mouse_state_ffi(pos_x_ptr: Int, pos_y_ptr: Int) -> Byte = "lunar" "get_mouse_state"
pub fn getMouseState(args: [*]const Value, results: [*]Value) ?Ptr {
    const pos_x_ptr = args[0].to_guest_ptr();
    const pos_y_ptr = args[1].to_guest_ptr();
    const mem_data = app.get_memory_data();
    const state = jok.io.getMouseState();
    std.mem.writeInt(u32, @ptrCast(mem_data[pos_x_ptr..]), @bitCast(state.pos.x), .little);
    std.mem.writeInt(u32, @ptrCast(mem_data[pos_y_ptr..]), @bitCast(state.pos.y), .little);
    results[0] = newi32(@intCast(state.buttons.storage));
    return null;
}
