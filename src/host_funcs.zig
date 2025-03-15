const std = @import("std");
const w = @import("wasmtime.zig");

const io = @import("host_funcs/io.zig");
const ctx = @import("host_funcs/context.zig");
const physfs = @import("host_funcs/physfs.zig");
const j2d = @import("host_funcs/j2d.zig");

const I32 = w.WasmValKind.i32;
const I64 = w.WasmValKind.i64;
const F32 = w.WasmValKind.f32;
const F64 = w.WasmValKind.f64;

const MODULE: []const u8 = "lunar";

const FUNCS: []const struct {
    []const u8,
    w.HostFn,
    []const w.WasmValKind,
    []const w.WasmValKind,
} = &.{
    // ==== io.zig =====
    .{ "get_keyborad_state", io.getKeyboardState, &.{I32}, &.{I64} },
    .{ "is_key_pressed", io.isKeyPressed, &.{ I64, I64, I32 }, &.{I32} },
    .{ "get_keyboard_modifier_state", io.getKeyboardModifierState, &.{}, &.{I32} },
    .{ "get_mouse_state", io.getMouseState, &.{ I32, I32 }, &.{I32} },
    // ==== physfs.zig ====
    .{ "physfs_mount", physfs.mount, &.{ I32, I32, I32, I32, I32 }, &.{I32} },
    // ==== context.zig ====
    .{ "debug_print", ctx.debugPrint, &.{ I32, I32, F32, F32, I32, I32, I32, I32 }, &.{} },
    .{ "get_canvas_size", ctx.getCanvasSize, &.{ I32, I32 }, &.{} },
    // ==== j2d.zig ====
    .{ "create_animation_system", j2d.createAnimationSystem, &.{ I32, I32 }, &.{I64} },
    .{ "connect_signal", j2d.connectSignal, &.{I64}, &.{I32} },
    .{ "add_simple_animation", j2d.addSimpleAnimation, &.{ I64, I32, I32, I32, I32, I32 }, &.{I32} },
    .{ "sprite_sheet_from_pictures_in_dir", j2d.spriteSheetFromPicturesInDir, &.{ I32, I32, I32, I32 }, &.{I64} },
    .{ "get_sprite_by_name", j2d.getSpriteByName, &.{ I64, I32, I32, I32 }, &.{I32} },
};

var env_data: usize = 0;

pub fn defineHostFuncs(linker: w.Linker) !void {
    // Ensure align with C type: wasmtime_val_t
    if (@sizeOf(w.Value) != 24) {
        @compileError("The size of Value MUST be 24 bytes!");
    }

    var params_buf: [16]w.ValType = undefined;
    var results_buf: [1]w.ValType = undefined;
    inline for (FUNCS) |item| {
        const func_name, const callback, const params, const results = item;
        std.log.info("define host func: {s}", .{func_name});
        inline for (params, 0..) |param, idx| {
            params_buf[idx] = w.ValType.new(param);
        }
        inline for (results, 0..) |result, idx| {
            results_buf[idx] = w.ValType.new(result);
        }
        try linker.defineFunc(
            MODULE,
            func_name,
            w.wrapHostFn(callback),
            params_buf[0..params.len],
            results_buf[0..results.len],
            &env_data,
        );
    }
}
