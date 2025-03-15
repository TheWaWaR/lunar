const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");

const get_app = @import("../main.zig").get_app;
const physfs = jok.physfs;

const Value = w.Value;
const Ptr = w.Ptr;

const newi32 = Value.newI32;
const newi64 = Value.newI64;
const newf32 = Value.newF32;
const newf64 = Value.newF64;
const to_host_byte_slice = Value.to_host_byte_slice;

// [moonbit]
// fn physfs_mount(
//   dir_ptr: Int, dir_len: Int,
//   mount_point_ptr: Int, mount_point_len: Int,
//   append: Bool,
// ) -> Bool = "lunar" "physfs_mount"
pub fn mount(args: []const Value, results: []Value) ?Ptr {
    const dir, const mount_point = c.readFromUtf16StrWithApp2(args[0..2], args[2..4]) orelse return null;
    const append: bool = args[4].of.i32 > 0;

    physfs.mount(@ptrCast(dir), @ptrCast(mount_point), append) catch |err| {
        std.log.err("physfs.mount({s}, {s}, {}) error: {}", .{ dir, mount_point, append, err });
        results[0] = newi32(0);
        return null;
    };
    results[0] = newi32(1);
    return null;
}
