const std = @import("std");
const jok = @import("jok");
const w = @import("wasmtime.zig");

const io = @import("host_funcs/io.zig");
const ctx = @import("host_funcs/context.zig");

const newI32 = w.ValType.newI32;
const newI64 = w.ValType.newI64;
const newF32 = w.ValType.newF32;
const newF64 = w.ValType.newF64;

const MODULE: []const u8 = "lunar";

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(w.Value) != 24) {
        @compileError("The size of Value MUST be 24 bytes!");
    }

    inline for (.{
        .{ "get_keyborad_state", io.getKeyboardState, &.{newI32()}, &.{newI64()} },
        .{ "is_key_pressed", io.isKeyPressed, &.{ newI64(), newI64(), newI32() }, &.{newI32()} },
        .{ "get_keyboard_modifier_state", io.getKeyboardModifierState, &.{}, &.{newI32()} },
        .{ "get_mouse_state", io.getMouseState, &.{ newI32(), newI32() }, &.{newI32()} },
        .{
            "debug_print",
            ctx.debugPrint,
            &.{ newI32(), newI32(), newF32(), newF32(), newI32(), newI32(), newI32(), newI32() },
            &.{},
        },
    }) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define host func: {s}", .{func_name});
        try linker.defineFunc(MODULE, func_name, w.wrapFn(callback), params, results, &env_data);
    }
}
