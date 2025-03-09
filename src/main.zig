const std = @import("std");
const jok = @import("jok");

const Engine = @import("wasmtime.zig").Engine;

pub fn init(ctx: jok.Context) !void {
    // your init code
    _ = ctx;
    var store_data: usize = 0;
    const engine = try Engine.new();
    const store = try engine.newStore(@ptrCast(&store_data));
    std.log.info("engine: {*}", .{store.ptr});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    // your drawing code
    _ = ctx;
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
}
