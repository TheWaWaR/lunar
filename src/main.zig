const std = @import("std");
const jok = @import("jok");

const w = @import("wasmtime.zig");
const host_funcs = @import("host_funcs.zig");
const guest_funcs = @import("guest_funcs.zig");

pub const jok_window_title: [:0]const u8 = "lunar";
pub const jok_window_size: jok.config.WindowSize = .{ .custom = .{ .width = 960, .height = 640 } };
pub const jok_window_resizable: bool = true;

// max wasm file size: 256MB
const MAX_WASM_SIZE: usize = 256 * 1024 * 1024;

const AppData = struct {
    ctx: jok.Context = undefined,
    engine: w.Engine = undefined,
    memory: w.Memory = undefined,
    store: w.Store = undefined,
    context: w.StoreContext = undefined,
    guest: guest_funcs.GuestFuncs = undefined,
    wasmtime_init_success: bool = false,

    const Self = @This();

    pub fn guest_mem_data(self: *Self) [*]u8 {
        return self.memory.data(self.context);
    }
};

var app: AppData = .{};
pub fn get_app() *AppData {
    return &app;
}

var store_data: usize = 0;
var max_call_update_us: i64 = 0;

pub fn init(ctx: jok.Context) !void {
    app.ctx = ctx;

    const args = try std.process.argsAlloc(ctx.allocator());
    defer std.process.argsFree(ctx.allocator(), args);
    if (args.len < 2) {
        std.log.err("Wasm path is missing! (Usage: lunar /path/to/game.wasm)", .{});
        ctx.kill();
        return;
    }

    const wasm_path = args[1];
    std.log.info("wasm path: {s}", .{wasm_path});
    const file = try std.fs.cwd().openFile(wasm_path, .{});
    defer file.close();
    const wasm_data = try file.readToEndAlloc(ctx.allocator(), MAX_WASM_SIZE);
    defer ctx.allocator().free(wasm_data);
    try setupWasmtime(&app.ctx, wasm_data);

    try app.guest.init();

    std.log.info("init success", .{});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
    const event_type = 0;
    try app.guest.event(event_type);
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
    try app.guest.update();
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);
    ctx.displayStats(.{});
    // your drawing code
    const t1 = std.time.microTimestamp();
    try app.guest.draw();
    const dt = std.time.microTimestamp() - t1;
    if (dt > 1000 and dt > max_call_update_us) {
        max_call_update_us = dt;
        // cost: less than 100us
        std.log.info(
            "New max draw() cost: {}us, fps={d:.1}",
            .{ max_call_update_us, ctx.fps() },
        );
    }
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
    if (app.wasmtime_init_success) {
        app.guest.quit() catch {
            std.log.err("call lunar_quit error", .{});
        };
        app.store.destroy();
        app.engine.destroy();
    }
    std.log.info("quit success", .{});
}

fn setupWasmtime(ctx: *jok.Context, wasm_data: []const u8) !void {
    _ = ctx;

    app.engine = try w.Engine.new();
    app.store = try w.Store.new(app.engine, @ptrCast(&store_data));
    app.context = app.store.context();

    const wasi_config = w.WasiConfig.new();
    wasi_config.inheritStdout();
    wasi_config.inheritStderr();
    try app.context.setWasi(wasi_config);

    const linker = w.Linker.new(app.engine);
    defer linker.destroy();

    try linker.defineWasi();
    const memorytype = w.MemoryType.new(1, false, 0, false, false);
    app.memory = try w.Memory.new(app.context, memorytype);
    const mem_extern = w.Extern{ .kind = .extern_memory, .of = .{ .memory = app.memory.inner } };
    try linker.define(app.context, "env", "memory", &mem_extern);

    try host_funcs.defineHostFuncs(linker);
    std.log.info("define host functions success", .{});

    const module = try w.Module.new(app.engine, wasm_data);
    defer module.destroy();

    const instance = try linker.instantiate(app.context, module);
    app.guest = try guest_funcs.exportGetGuestFuncs(instance, app.context);
    std.log.info("export guest functions success", .{});
    std.log.info("init wasmtime success", .{});
    app.wasmtime_init_success = true;
}
