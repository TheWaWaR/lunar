const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const common = @import("common.zig");
const get_app = @import("../main.zig").get_app;

const Value = w.Value;
const Ptr = w.Ptr;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

const readBytes = common.readBytes;
const readFromUtf16StrWithApp = common.readFromUtf16StrWithApp;
const readPoint = common.readPoint;
const readColor = common.readColor;

// [moonbit]
// fn debug_print_ffi(
//   text_ptr: Int, text_len: Int,
//   pos_x: Float, pos_y: Float,
//   r: Byte, g: Byte, b: Byte, a: Byte,
// ) = "lunar" "debug_print"
pub fn debugPrint(args: [*]const Value, _: [*]Value) ?Ptr {
    const text = readFromUtf16StrWithApp(args[0..2]);
    const pos = readPoint(args[2..4]);
    const color = readColor(args[4..8]);

    get_app().ctx.debugPrint(text, .{ .pos = pos, .color = color });
    return null;
}
