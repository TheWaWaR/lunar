//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

const Engine = @import("wasmtime.zig").Engine;

pub fn run() !void {
    var store_data: usize = 0;
    const engine = try Engine.new();
    const store = try engine.newStore(@ptrCast(&store_data));
    std.log.info("engine: {*}", .{store.ptr});
}
