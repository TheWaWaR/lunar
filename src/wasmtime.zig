const std = @import("std");
const cdef = @import("wasmtime/cdef.zig");

pub const WasmtimeError = error{
    NewEngineError,
    NewStoreError,
    NewModuleError,
    DefineError,
    DefineWasiError,
    DefineFuncError,
    InstantiateError,
    DefineInstanceError,
    NewInstanceError,
    FuncCallError,
    NewMemoryError,
    SetWasiError,
};

const Ptr = cdef.Ptr;
const ConstPtr = cdef.ConstPtr;
const ValTypeVec = cdef.ValTypeVec;
pub const Extern = cdef.Extern;
pub const Value = cdef.Value;
pub const CallbackFn = cdef.CallbackFn;

var err_msg_buf: [1024]u8 = undefined;
var err_msg: cdef.ByteVec = .{
    .size = 0,
    .data = err_msg_buf[0..],
};
fn print_err(err_ptr: Ptr) void {
    cdef.wasmtime_error_message(err_ptr, &err_msg);
    std.log.err("error msg: {s}", .{err_msg.data[0..err_msg.size]});
}

pub const Engine = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new() !Engine {
        const ptr = cdef.wasm_engine_new() orelse return error.NewEngineError;
        return Engine{ .ptr = ptr };
    }

    pub fn destroy(self: Self) void {
        cdef.wasm_engine_delete(self.ptr);
    }
};

pub const Linker = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new(engine: Engine) Linker {
        const ptr = cdef.wasmtime_linker_new(engine.ptr);
        return Linker{ .ptr = ptr };
    }

    pub fn destroy(self: Self) void {
        cdef.wasmtime_linker_delete(self.ptr);
    }

    pub fn instantiate(self: Self, context: StoreContext, module: Module) !Instance {
        var trap: ?*anyopaque = null;
        var instance: Instance = undefined;
        const err_ptr_opt = cdef.wasmtime_linker_instantiate(self.ptr, context.ptr, module.ptr, &instance.inner, &trap);
        if (trap != null) {
            return error.InstantiateError;
        }
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.InstantiateError;
        }
        return instance;
    }

    pub fn define(
        self: Self,
        context: StoreContext,
        module_name: []const u8,
        extern_name: []const u8,
        extern_value: *const Extern,
    ) !void {
        const err_ptr_opt = cdef.wasmtime_linker_define(
            self.ptr,
            context.ptr,
            module_name.ptr,
            module_name.len,
            extern_name.ptr,
            extern_name.len,
            extern_value,
        );
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.DefineError;
        }
    }

    pub fn defineWasi(self: Self) !void {
        if (cdef.wasmtime_linker_define_wasi(self.ptr)) |_| {
            return error.DefineWasiError;
        }
    }

    pub fn defineInstance(self: Self, context: StoreContext, name: []const u8, instance: Instance) !void {
        if (cdef.wasmtime_linker_define_instance(self.ptr, context.ptr, name.ptr, name.len, instance.ptr)) |_| {
            return error.DefineInstanceError;
        }
    }

    pub fn defineFunc(
        self: Self,
        module_name: []const u8,
        func_name: []const u8,
        cb: CallbackFn,
        params: []const ValType,
        results: []const ValType,
        data: *anyopaque,
    ) !void {
        const ty = FuncType.new(params, results);
        const err_ptr_opt = cdef.wasmtime_linker_define_func(
            self.ptr,
            module_name.ptr,
            module_name.len,
            func_name.ptr,
            func_name.len,
            ty.ptr,
            cb,
            data,
            null,
        );
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.DefineFuncError;
        }
    }
};

pub const MemoryType = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new(min: u64, max_present: bool, max: u64, is_64: bool, shared: bool) MemoryType {
        const ptr = cdef.wasmtime_memorytype_new(min, max_present, max, is_64, shared);
        return MemoryType{ .ptr = ptr };
    }
};

pub const Memory = struct {
    inner: cdef.Memory,

    const Self = @This();

    pub fn new(context: StoreContext, ty: MemoryType) !Memory {
        var memory: Memory = undefined;
        const err_ptr_opt = cdef.wasmtime_memory_new(context.ptr, ty.ptr, &memory.inner);
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.NewMemoryError;
        }
        return memory;
    }

    pub fn data(self: Self, context: StoreContext) [*c]u8 {
        return cdef.wasmtime_memory_data(context.ptr, &self.inner);
    }
};

pub const Func = struct {
    inner: cdef.Func,

    const Self = @This();

    pub fn new(context: StoreContext, ty: FuncType, callback: CallbackFn) Func {
        var func: Func = undefined;
        cdef.wasmtime_func_new(context.ptr, ty.ptr, callback, null, null, &func.inner);
        return func;
    }

    pub fn call(self: Self, context: StoreContext, args: []const Value, results: []Value) !void {
        var trap: ?*anyopaque = null;
        const err_ptr_opt = cdef.wasmtime_func_call(
            context.ptr,
            &self.inner,
            args.ptr,
            args.len,
            results.ptr,
            results.len,
            &trap,
        );
        if (trap != null) {
            return error.FuncCallError;
        }
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.FuncCallError;
        }
    }
};

pub const FuncType = struct {
    ptr: *anyopaque,

    const Self = @This();

    fn vec_new(items: []const ValType) ValTypeVec {
        var wrapper: ValTypeVec = undefined;
        if (items.len == 0) {
            cdef.wasm_valtype_vec_new_empty(&wrapper);
        } else {
            cdef.wasm_valtype_vec_new(&wrapper, items.len, items.ptr);
        }
        return wrapper;
    }

    pub fn new(params: []const ValType, results: []const ValType) FuncType {
        var params_wrapper = Self.vec_new(params);
        var results_wrapper = Self.vec_new(results);
        const ptr = cdef.wasm_functype_new(&params_wrapper, &results_wrapper);
        return FuncType{ .ptr = ptr };
    }

    pub fn destroy(self: Self) void {
        cdef.wasm_functype_delete(self.ptr);
    }
};

pub const ValType = struct {
    ptr: Ptr,

    pub fn newI32() ValType {
        return ValType{ .ptr = cdef.wasm_valtype_new_i32() };
    }
    pub fn newI64() ValType {
        return ValType{ .ptr = cdef.wasm_valtype_new_i64() };
    }
    pub fn newF32() ValType {
        return ValType{ .ptr = cdef.wasm_valtype_new_f32() };
    }
    pub fn newF64() ValType {
        return ValType{ .ptr = cdef.wasm_valtype_new_f64() };
    }
};

pub const Instance = struct {
    inner: cdef.Instance,

    const Self = @This();

    pub fn new(context: StoreContext, module: Module, imports: []Extern) !Instance {
        var trap: ?*anyopaque = null;
        var instance: Instance = undefined;
        const err_ptr_opt = cdef.wasmtime_instance_new(
            context.ptr,
            module.ptr,
            imports.ptr,
            imports.len,
            &instance.inner,
            &trap,
        );
        if (trap != null) {
            return error.NewInstanceError;
        }
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.NewInstanceError;
        } else {
            return instance;
        }
    }

    pub fn exportGet(self: Self, context: StoreContext, name: []const u8) ?Extern {
        var run: Extern = undefined;
        if (cdef.wasmtime_instance_export_get(context.ptr, &self.inner, name.ptr, name.len, &run)) {
            return run;
        } else {
            return null;
        }
    }
};

pub const Store = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new(engine: Engine, data: *anyopaque) !Store {
        const finalizer: ?*anyopaque = null;
        const ptr = cdef.wasmtime_store_new(engine.ptr, data, finalizer) orelse return error.NewStoreError;
        return Store{ .ptr = ptr };
    }

    pub fn context(self: Store) StoreContext {
        const ptr = cdef.wasmtime_store_context(self.ptr);
        return StoreContext{ .ptr = ptr };
    }

    pub fn destroy(self: Store) void {
        cdef.wasmtime_store_delete(self.ptr);
    }
};

pub const StoreContext = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn getData(self: StoreContext) *anyopaque {
        return cdef.wasmtime_context_get_data(self.ptr);
    }

    pub fn setData(self: StoreContext, data: *anyopaque) void {
        cdef.wasmtime_context_set_data(self.ptr, data);
    }

    pub fn setWasi(self: StoreContext, config: WasiConfig) !void {
        const err_ptr_opt = cdef.wasmtime_context_set_wasi(self.ptr, config.ptr);
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.SetWasiError;
        }
    }
};

pub const Module = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new(engine: Engine, binary: []const u8) !Module {
        var ptr: *anyopaque = undefined;
        const err_ptr_opt = cdef.wasmtime_module_new(engine.ptr, binary.ptr, binary.len, &ptr);
        if (err_ptr_opt) |err_ptr| {
            print_err(err_ptr);
            return error.NewModuleError;
        } else {
            return Module{ .ptr = ptr };
        }
    }

    pub fn destroy(self: Module) void {
        cdef.wasmtime_module_delete(self.ptr);
    }
};

pub const WasiConfig = struct {
    ptr: *anyopaque,

    const Self = @This();

    pub fn new() WasiConfig {
        const ptr = cdef.wasi_config_new();
        return WasiConfig{ .ptr = ptr };
    }

    pub fn inheritArgv(self: WasiConfig) void {
        cdef.wasi_config_inherit_argv(self.ptr);
    }
    pub fn inheritEnv(self: WasiConfig) void {
        cdef.wasi_config_inherit_env(self.ptr);
    }
    pub fn inheritStdin(self: WasiConfig) void {
        cdef.wasi_config_inherit_stdin(self.ptr);
    }
    pub fn inheritStdout(self: WasiConfig) void {
        cdef.wasi_config_inherit_stdout(self.ptr);
    }
    pub fn inheritStderr(self: WasiConfig) void {
        cdef.wasi_config_inherit_stderr(self.ptr);
    }
};
