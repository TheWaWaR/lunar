const cdef = @import("wasmtime/cdef.zig");

pub const WasmtimeError = error{
    NewEngineError,
    NewStoreError,
    NewModuleError,
};

pub const Engine = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new() !Engine {
        const ptr = cdef.wasm_engine_new() orelse return error.NewEngineError;
        return Engine{ .ptr = ptr };
    }

    pub fn newStore(self: Self, data: *anyopaque) !Store {
        const finalizer: ?*anyopaque = null;
        const ptr = cdef.wasmtime_store_new(self.ptr, data, finalizer) orelse return error.NewStoreError;
        return Store{ .ptr = ptr };
    }
};

pub const Linker = struct {
    ptr: *anyopaque,

    const Self = @This();
};


pub const Instance = struct {
    ptr: *anyopaque,

    const Self = @This();
};

pub const Store = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn newModule(self: Self, binary: []const u8) !Module {
        const ptr: *anyopaque = undefined;
        const err_ptr_opt = cdef.wasmtime_module_new(self.ptr, binary.ptr, binary.len, &ptr);
        if (err_ptr_opt) |_| {
            return error.NewModuleError;
        } else {
            return Module{ .ptr = ptr };
        }
    }
};

pub const StoreContext = struct {
    ptr: *anyopaque,

    const Self = @This();
};

pub const Module = struct {
    ptr: *anyopaque,

    const Self = @This();
};
