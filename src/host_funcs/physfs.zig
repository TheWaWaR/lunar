const std = @import("std");
const jok = @import("jok");
const w = @import("../wasmtime.zig");
const c = @import("common.zig");

const get_app = @import("../main.zig").get_app;
const physfs = jok.physfs;

pub const FUNCS = [_]w.FuncInfo{
    w.wrapHostFn("physfs_mount", mount),
};

pub fn mount(dir_ptr: usize, dir_len: u32, mount_point_ptr: usize, mount_point_len: u32, append: bool) bool {
    const dir, const mount_point = c.readFromUtf16StrWithApp2(
        dir_ptr,
        dir_len,
        mount_point_ptr,
        mount_point_len,
    ) orelse return false;
    physfs.mount(@ptrCast(dir), @ptrCast(mount_point), append) catch |err| {
        std.log.err("physfs.mount({s}, {s}, {}) error: {}", .{ dir, mount_point, append, err });
        return false;
    };
    return true;
}
