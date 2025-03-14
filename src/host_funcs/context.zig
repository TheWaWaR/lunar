const std = @import("std");
const jok = @import("jok");
const app = @import("../main.zig");
const w = @import("../wasmtime.zig");
const common = @import("common.zig");

const Value = w.Value;
const Ptr = w.Ptr;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

const readBytes = common.readBytes;
const readPoint = common.readPoint;
const readColor = common.readColor;

// [moonbit]
// fn debug_print_ffi(
//   text_ptr: Int, text_len: Int,
//   pos_x: Float, pos_y: Float,
//   r: Byte, g: Byte, b: Byte, a: Byte,
// ) = "lunar" "debug_print"
pub fn debugPrint(args: [*]const Value, _: [*]Value) ?Ptr {
    const text = readBytes(app.get_memory_data(), args[0..2]);
    const pos = readPoint(args[2..4]);
    const color = readColor(args[4..8]);

    app.get_init_ctx().debugPrint(text, .{ .pos = pos, .color = color });
    return null;
}
