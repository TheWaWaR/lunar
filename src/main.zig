const std = @import("std");
const jok = @import("jok");

const w = @import("wasmtime.zig");

var engine: w.Engine = undefined;

pub fn init(ctx: jok.Context) !void {
    // your init code
    engine = try w.Engine.new();
    var store_data: usize = 0;
    const store = try w.Store.new(engine, @ptrCast(&store_data));
    const context = store.context();
    std.log.info("context: {*}", .{context.ptr});

    const file = try std.fs.cwd().openFile("moonbit/examples/animation-2d/target/wasm/release/build/lunar.wasm", .{});
    defer file.close();
    const wasm_data = try file.readToEndAlloc(ctx.allocator(), 1024 * 1024);
    defer ctx.allocator().free(wasm_data);
    const module = try w.Module.new(engine, wasm_data);
    defer module.destroy();

    var params: [1]w.ValType = .{w.ValType.newI32()};
    var results: [0]w.ValType = .{};
    const functype = w.FuncType.new(params[0..], results[0..]);
    const linker = w.Linker.new(engine);
    var callback_env_data: i32 = 33;
    try linker.defineFunc("spectest", "print_char", functype, spectest_print_char, &callback_env_data);
    try linker.defineWasi();

    const instance = try linker.instantiate(context, module);
    const lunar_init: w.Extern = instance.exportGet(context, "lunar_init").?;
    std.log.info("lunar_init.kind: {}", .{lunar_init.kind});

    const arg0 = w.Value{ .kind = .i64, .of = .{ .i64 = 0 } };
    var args: [1]w.Value = .{arg0};
    var results_guest: [0]w.Value = .{};
    const lunar_init_func = w.Func{ .inner = lunar_init.of.func };
    try lunar_init_func.call(context, args[0..], results_guest[0..]);
}

fn spectest_print_char(
    env: *anyopaque,
    caller: *anyopaque,
    args: [*]const w.Value,
    nargs: usize,
    results: [*]w.Value,
    nresults: usize,
) callconv(.C) ?*anyopaque {
    _ = env;
    _ = caller;
    _ = results;
    _ = nresults;

    std.log.info("spectest_print_char(): args({})={}", .{ nargs, args[0].of.i32 });
    return null;
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
