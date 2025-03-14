const std = @import("std");
const jok = @import("jok");

const w = @import("wasmtime.zig");
const host_funcs = @import("host_funcs.zig");
const guest_funcs = @import("guest_funcs.zig");

// max wasm file size: 256MB
const MAX_WASM_SIZE: usize = 256 * 1024 * 1024;

var global_ctx: jok.Context = undefined;
var store_data: usize = 0;

var wasmtime_init_success: bool = false;
var engine: w.Engine = undefined;
var memory: w.Memory = undefined;
var store: w.Store = undefined;
var store_context: w.StoreContext = undefined;

var max_call_update_us: i64 = 0;

// Wasm function call time cost:
//   * call empty function: 1us ~ 5us
//   * call function with one log: 30us ~ 150us
var guest: guest_funcs.GuestFuncs = undefined;

pub fn get_init_ctx() jok.Context {
    return global_ctx;
}
pub fn get_memory_data() [*]u8 {
    return memory.data(store_context);
}

pub fn init(ctx: jok.Context) !void {
    global_ctx = ctx;

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
    try setupWasmtime(&global_ctx, wasm_data);

    try guest.init();

    std.log.info("init success", .{});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
    const event_type = 0;
    try guest.event(event_type);
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
    try guest.update();
}

pub fn draw(ctx: jok.Context) !void {
    // your drawing code
    _ = ctx;
    const t1 = std.time.microTimestamp();
    try guest.draw();
    const dt = std.time.microTimestamp() - t1;
    if (dt > max_call_update_us) {
        max_call_update_us = dt;
        // cost: less than 100us
        std.log.info("New max update() cost: {}us", .{max_call_update_us});
    }
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
    if (wasmtime_init_success) {
        guest.quit() catch {
            std.log.err("call lunar_quit error", .{});
        };
        store.destroy();
        engine.destroy();
    }
    std.log.info("quit success", .{});
}

fn setupWasmtime(ctx: *jok.Context, wasm_data: []const u8) !void {
    _ = ctx;

    engine = try w.Engine.new();
    store = try w.Store.new(engine, @ptrCast(&store_data));
    store_context = store.context();

    const wasi_config = w.WasiConfig.new();
    wasi_config.inheritStdout();
    wasi_config.inheritStderr();
    try store_context.setWasi(wasi_config);

    const linker = w.Linker.new(engine);
    defer linker.destroy();

    try linker.defineWasi();
    const memorytype = w.MemoryType.new(1, false, 0, false, false);
    memory = try w.Memory.new(store_context, memorytype);
    const mem_extern = w.Extern{ .kind = .extern_memory, .of = .{ .memory = memory.inner } };
    try linker.define(store_context, "env", "memory", &mem_extern);

    try host_funcs.defineHostFuncs(linker);
    std.log.info("define host functions success", .{});

    const module = try w.Module.new(engine, wasm_data);
    defer module.destroy();

    const instance = try linker.instantiate(store_context, module);
    guest = try guest_funcs.exportGetGuestFuncs(instance, store_context);
    wasmtime_init_success = true;
}
