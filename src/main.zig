//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("lunar_lib");
const std = @import("std");

pub fn main() !void {
    const result = try lib.run();
    std.log.info("Run result = {}", .{result});
}
