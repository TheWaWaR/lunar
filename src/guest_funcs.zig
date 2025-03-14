const w = @import("wasmtime.zig");

pub const GuestFuncs = struct {
    context: w.StoreContext,

    // Wasm function call time cost:
    //   * call empty function: 1us ~ 5us
    //   * call function with one log: 30us ~ 150us
    lunar_init: w.Func = undefined,
    lunar_event: w.Func = undefined,
    lunar_update: w.Func = undefined,
    lunar_draw: w.Func = undefined,
    lunar_quit: w.Func = undefined,

    const Self = @This();

    pub fn init(self: *Self) !void {
        try self.lunar_init.call(self.context, &.{}, &.{});
    }
    pub fn event(self: *Self, event_type: i32) !void {
        try self.lunar_event.call(self.context, &.{w.Value.newI32(event_type)}, &.{});
    }
    pub fn update(self: *Self) !void {
        try self.lunar_update.call(self.context, &.{}, &.{});
    }
    pub fn draw(self: *Self) !void {
        try self.lunar_draw.call(self.context, &.{}, &.{});
    }
    pub fn quit(self: *Self) !void {
        try self.lunar_quit.call(self.context, &.{}, &.{});
    }
};

pub fn exportGetGuestFuncs(instance: w.Instance, context: w.StoreContext) !GuestFuncs {
    var funcs = GuestFuncs{ .context = context };
    inline for (.{
        .{ "lunar_init", &funcs.lunar_init },
        .{ "lunar_event", &funcs.lunar_event },
        .{ "lunar_update", &funcs.lunar_update },
        .{ "lunar_draw", &funcs.lunar_draw },
        .{ "lunar_quit", &funcs.lunar_quit },
    }) |item| {
        const name, const func = item;
        const extern_value: w.Extern = instance.exportGet(context, name).?;
        func.* = w.Func{ .inner = extern_value.of.func };
    }
    return funcs;
}
