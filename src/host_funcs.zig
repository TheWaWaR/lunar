const std = @import("std");
const jok = @import("jok");
const w = @import("wasmtime.zig");
const app = @import("main.zig");

const MODULE: []const u8 = "lunar";

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    inline for (.{
        .{
            "get_keyborad_state",
            getKeyboardState,
            &.{w.ValType.newI32()},
            &.{w.ValType.newI64()},
        },
        .{
            "is_key_pressed",
            isKeyPressed,
            &.{ w.ValType.newI64(), w.ValType.newI64(), w.ValType.newI32() },
            &.{w.ValType.newI32()},
        },
    }) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define func: {s}", .{func_name});
        try linker.defineFunc(MODULE, func_name, callback, params, results, &env_data);
    }
}

fn to_byte_ptr(val: w.Value) usize {
    return @intCast(val.of.i32);
}

fn to_zig_byte_ptr(val: w.Value) [*]u8 {
    const ptr_int: usize = @intCast(val.of.i64);
    const ptr: [*]u8 = @ptrFromInt(ptr_int);
    return ptr;
}

fn to_zig_byte_slice(val1: w.Value, val2: w.Value) []u8 {
    const ptr = to_zig_byte_ptr(val1);
    const len: usize = @intCast(val2.of.i64);
    return ptr[0..len];
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
    std.log.info("getKeyboardState, nargs: {}, nresults: {}", .{ nargs, nresults });
    const states = jok.io.getKeyboardState().states;
    const mem_data = app.get_memory_data();
    const arg0 = args[0];
    const len_ptr = to_byte_ptr(arg0);
    const bytes: [*]const u8 = @ptrCast(&args[0].of);
    std.log.info("len_ptr: {}, {}, bytes: {any}", .{ len_ptr, arg0.of.i32, bytes[0..16] });
    std.mem.writeInt(usize, @ptrCast(mem_data[13480..]), states.len, .little);
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
    std.log.info("isKeyPressed BEGIN, nargs={}, nresults={}", .{ nargs, nresults });
    const states = to_zig_byte_slice(args[0], args[1]);
    const scancode: c_uint = @intCast(args[2].of.i32);
    const kbd = jok.io.KeyboardState{ .states = states };
    const is_pressed = kbd.isPressed(@enumFromInt(scancode));
    results[0] = w.Value.newI32(@intFromBool(is_pressed));
    std.log.info("isKeyPressed END", .{});
    return null;
}
