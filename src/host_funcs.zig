const std = @import("std");
const jok = @import("jok");
const w = @import("wasmtime.zig");
const app = @import("main.zig");

const newI32 = w.ValType.newI32;
const newI64 = w.ValType.newI64;
const newF32 = w.ValType.newf32;
const newF64 = w.ValType.newf64;
const to_zig_byte_slice = w.Value.to_zig_byte_slice;

const MODULE: []const u8 = "lunar";

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(w.Value) != 24) {
        @compileError("The size of Value must be 24 bytes!");
    }

    inline for (.{
        .{ "get_keyborad_state", getKeyboardState, &.{newI32()}, &.{newI64()} },
        .{ "is_key_pressed", isKeyPressed, &.{ newI64(), newI64(), newI32() }, &.{newI32()} },
    }) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define func: {s}", .{func_name});
        try linker.defineFunc(MODULE, func_name, callback, params, results, &env_data);
    }
}

// [moonbit]: fn get_keyborad_state_ffi(len_ptr: Int) -> UInt64  = "lunar" "get_keyborad_state"
pub fn getKeyboardState(
    env: *anyopaque,
    caller: *anyopaque,
    args: [*]const w.Value,
    nargs: usize,
    results: [*]w.Value,
    nresults: usize,
) callconv(.C) ?*anyopaque {
    _ = env;
    _ = caller;
    _ = nargs;
    _ = nresults;
    const states = jok.io.getKeyboardState().states;
    const mem_data = app.get_memory_data();
    const len_ptr = args[0].to_byte_ptr();
    std.mem.writeInt(usize, @ptrCast(mem_data[len_ptr..]), states.len, .little);
    results[0] = w.Value.newI64(@intCast(@intFromPtr(states.ptr)));
    return null;
}

// [moonbit] fn is_key_pressed_ffi(states_ptr: UInt64, states_len: UInt64, scancode: Int) -> Bool = "lunar" "is_key_pressed"
pub fn isKeyPressed(
    env: *anyopaque,
    caller: *anyopaque,
    args: [*]const w.Value,
    nargs: usize,
    results: [*]w.Value,
    nresults: usize,
) callconv(.C) ?*anyopaque {
    _ = env;
    _ = caller;
    _ = nargs;
    _ = nresults;
    const states = to_zig_byte_slice(&args[0], &args[1]);
    const scancode: c_uint = @intCast(args[2].of.i32);
    const kbd = jok.io.KeyboardState{ .states = states };
    const is_pressed = kbd.isPressed(@enumFromInt(scancode));
    results[0] = w.Value.newI32(@intFromBool(is_pressed));
    return null;
}
