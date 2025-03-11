const std = @import("std");
const jok = @import("jok");

const w = @import("wasmtime.zig");
const host_funcs = @import("host_funcs.zig");

// max wasm file size: 256MB
const MAX_WASM_SIZE: usize = 256 * 1024 * 1024;

var init_ctx: jok.Context = undefined;
var engine: w.Engine = undefined;
var store_context: w.StoreContext = undefined;

// Function call time cost:
//   * call empty function: 1us ~ 5us
//   * call function with one log: 30us ~ 150us
var lunar_event: w.Func = undefined;
var lunar_update: w.Func = undefined;
var lunar_draw: w.Func = undefined;
var lunar_quit: w.Func = undefined;

pub fn get_init_ctx() jok.Context {
    return init_ctx;
}

pub fn init(ctx: jok.Context) !void {
    init_ctx = ctx;
    // your init code
    engine = try w.Engine.new();
    var store_data: usize = 0;
    const store = try w.Store.new(engine, @ptrCast(&store_data));
    store_context = store.context();
    const wasi_config = w.WasiConfig.new();
    wasi_config.inheritStdout();
    wasi_config.inheritStderr();
    try store_context.setWasi(wasi_config);

    const linker = w.Linker.new(engine);
    defer linker.destroy();

    const file = try std.fs.cwd().openFile("moonbit/examples/animation-2d/target/wasm/release/build/lunar.wasm", .{});
    defer file.close();
    const wasm_data = try file.readToEndAlloc(ctx.allocator(), MAX_WASM_SIZE);
    defer ctx.allocator().free(wasm_data);
    const module = try w.Module.new(engine, wasm_data);
    defer module.destroy();

    const memorytype = w.MemoryType.new(1, false, 0, false, false);
    const memory = try w.Memory.new(store_context, memorytype);
    const mem_extern = w.Extern{ .kind = .extern_memory, .of = .{ .memory = memory.inner } };
    var params: [1]w.ValType = .{w.ValType.newI32()};
    const functype = w.FuncType.new(params[0..], &.{});
    defer functype.destroy();
    var env_data: usize = 0;
    try linker.define(store_context, "env", "memory", &mem_extern);
    try linker.defineFunc("spectest", "print_char", functype, host_funcs.spectest_print_char, &env_data);
    try linker.defineWasi();

    const instance = try linker.instantiate(store_context, module);
    const lunar_init_extern: w.Extern = instance.exportGet(store_context, "lunar_init").?;
    const lunar_init = w.Func{ .inner = lunar_init_extern.of.func };
    const lunar_event_extern: w.Extern = instance.exportGet(store_context, "lunar_event").?;
    lunar_event = w.Func{ .inner = lunar_event_extern.of.func };
    const lunar_update_extern: w.Extern = instance.exportGet(store_context, "lunar_update").?;
    lunar_update = w.Func{ .inner = lunar_update_extern.of.func };
    const lunar_draw_extern: w.Extern = instance.exportGet(store_context, "lunar_draw").?;
    lunar_draw = w.Func{ .inner = lunar_draw_extern.of.func };
    const lunar_quit_extern: w.Extern = instance.exportGet(store_context, "lunar_quit").?;
    lunar_quit = w.Func{ .inner = lunar_quit_extern.of.func };

    try lunar_init.call(store_context, &.{}, &.{});

    std.log.info("init success", .{});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
    const event_type = 0;
    const args: [1]w.Value = .{w.Value.newI32(event_type)};
    try lunar_event.call(store_context, args[0..], &.{});
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
    try lunar_update.call(store_context, &.{}, &.{});
}

pub fn draw(ctx: jok.Context) !void {
    // your drawing code
    _ = ctx;
    try lunar_draw.call(store_context, &.{}, &.{});
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
    lunar_quit.call(store_context, &.{}, &.{}) catch {
        std.log.err("call lunar_quit error", .{});
    };
    engine.destroy();
    std.log.info("quit success", .{});
}
