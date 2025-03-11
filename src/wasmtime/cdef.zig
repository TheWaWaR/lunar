pub const Ptr = *anyopaque;
pub const ConstPtr = *const anyopaque;
pub const TrapPtr = *?Ptr;

// ==== Configuration ====
pub extern "c" fn wasm_config_new() Ptr;

// ==== Engine ====

// fn() -> engine
pub extern "c" fn wasm_engine_new() ?Ptr;
// fn(engine)
pub extern "c" fn wasm_engine_delete(Ptr) void;
// fn(config) -> engine
pub extern "c" fn wasm_engine_new_with_config(Ptr) Ptr;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/error.h

pub const ByteVec = extern struct {
    size: usize,
    data: [*]u8,
};
// fn(error, message)
pub extern "c" fn wasmtime_error_message(ConstPtr, Ptr) void;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/linker.h

// fn(engine) -> linker
pub extern "c" fn wasmtime_linker_new(Ptr) Ptr;
// fn(linker)
pub extern "c" fn wasmtime_linker_delete(Ptr) void;
// fn(linker, store_context, module, module_len, name, name_len, extern) -> error
pub extern "c" fn wasmtime_linker_define(Ptr, Ptr, ConstPtr, usize, ConstPtr, usize, ConstPtr) ?Ptr;
// fn(linker) -> error
pub extern "c" fn wasmtime_linker_define_wasi(Ptr) ?Ptr;
// fn(linker, store_context, module, instance, trap) -> error
pub extern "c" fn wasmtime_linker_instantiate(ConstPtr, Ptr, ConstPtr, Ptr, TrapPtr) ?Ptr;
// fn(linker, store_context, name, name_len, instance) -> error
pub extern "c" fn wasmtime_linker_define_instance(Ptr, Ptr, ConstPtr, usize, ConstPtr) ?Ptr;
// fn(linker, module, module_len, name, name_len, ty, cb, data, finalizer) -> error
pub extern "c" fn wasmtime_linker_define_func(Ptr, ConstPtr, usize, ConstPtr, usize, ConstPtr, ConstPtr, Ptr, ?Ptr) ?Ptr;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/memory.h
// fn (min, max_present, max, is_64, shared) -> memorytype
pub extern "c" fn wasmtime_memorytype_new(u64, bool, u64, bool, bool) Ptr;
// fn (store_context, memorytype, memory) -> error
pub extern "c" fn wasmtime_memory_new(Ptr, ConstPtr, Ptr) ?Ptr;
// fn (store_context, memory) -> data_ptr
pub extern "c" fn wasmtime_memory_data(ConstPtr, ConstPtr) [*c]u8;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/func.h

// fn wasmtime_func_callback_t(env, caller, args, nargs, results, nresults) -> trap

// fn(store_context, func, args, nargs, results, nresults, trap) -> error
pub extern "c" fn wasmtime_func_call(Ptr, ConstPtr, ConstPtr, usize, Ptr, usize, TrapPtr) ?Ptr;
// fn(store_context, type, callback, env, finalizer, ret)
pub extern "c" fn wasmtime_func_new(Ptr, ConstPtr, ConstPtr, ?Ptr, ?Ptr, Ptr) void;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/instance.h

// fn(store_context, module, imports, nimports, instance, trap) -> error
pub extern "c" fn wasmtime_instance_new(Ptr, ConstPtr, ConstPtr, usize, Ptr, TrapPtr) ?Ptr;
// fn(store_context, instance, name, name_len, item) -> bool
pub extern "c" fn wasmtime_instance_export_get(Ptr, ConstPtr, ConstPtr, usize, Ptr) bool;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/store.h

// fn(engine, data, finalizer) -> store
pub extern "c" fn wasmtime_store_new(Ptr, Ptr, ?Ptr) ?Ptr;
// fn(store) -> store_context
pub extern "c" fn wasmtime_store_context(Ptr) Ptr;
// fn(store)
pub extern "c" fn wasmtime_store_delete(Ptr) void;
// fn(store_context) -> data
pub extern "c" fn wasmtime_context_get_data(Ptr) Ptr;
// fn(store_context, data)
pub extern "c" fn wasmtime_context_set_data(Ptr, Ptr) void;
// fn(store_context, wasi_config) -> error
pub extern "c" fn wasmtime_context_set_wasi(Ptr, Ptr) ?Ptr;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/module.h

// fn(engine, wasm, wasm_len, ret) -> error
pub extern "c" fn wasmtime_module_new(Ptr, ConstPtr, usize, *Ptr) ?Ptr;
// fn(module)
pub extern "c" fn wasmtime_module_delete(Ptr) void;
// fn(engine, wasm, wasm_len) -> error
pub extern "c" fn wasmtime_module_validate(Ptr, ConstPtr, usize) ?Ptr;

// func.h : wasmtime_func_callback_t
// fn(env, caller, args, nargs, results, nresults) -> trap
pub const CallbackFn = *const fn (
    env: Ptr,
    caller: Ptr,
    // no alignment
    args: [*c]const Value,
    nargs: usize,
    // no alignment
    results: [*c]Value,
    nresults: usize,
) callconv(.C) ?Ptr;

pub const ValueUnion = extern union {
    i32: i32,
    i64: i64,
    f32: f32,
    f64: f64,
    anyref: u128,
    externref: u128,
    funcref: u128,
    wasmtime_v128: [16]u8,
};

pub const ValueKind = enum(u8) {
    i32 = 0,
    i64 = 1,
    f32 = 2,
    f64 = 3,
    v128 = 4,
    funcref = 5,
    externref = 6,
    anyref = 7,
};

// val.h : wasmtime_val_t
pub const Value = extern struct {
    kind: ValueKind,
    of: ValueUnion,

    pub fn newI32(value: i32) Value {
        return Value{ .kind = .i32, .of = .{ .i32 = value } };
    }
    pub fn newI64(value: i64) Value {
        return Value{ .kind = .i64, .of = .{ .i64 = value } };
    }
    pub fn newF32(value: f32) Value {
        return Value{ .kind = .f32, .of = .{ .f32 = value } };
    }
    pub fn newF64(value: f32) Value {
        return Value{ .kind = .f64, .of = .{ .f64 = value } };
    }
};

pub const ExternUnion = extern union {
    func: Func,
    global: Global,
    table: Table,
    memory: Memory,
    sharedmemory: Ptr,
};
pub const ExternKind = enum(u8) {
    extern_func = 0,
    extern_global = 1,
    extern_table = 2,
    extern_memory = 3,
    extern_sharedmemory = 4,
};
pub const Extern = extern struct {
    kind: ExternKind,
    of: ExternUnion,
};

// extern.h : wasmtime_func_t
pub const Func = extern struct {
    store_id: u64,
    __private: usize,
};
pub const Table = extern struct {
    store_id: u64,
    __private: usize,
};
// wasmtime_memory_t
pub const Memory = extern struct {
    store_id: u64,
    __private: usize,
};
pub const Global = extern struct {
    store_id: u64,
    __private: usize,
};

pub const Instance = extern struct {
    store_id: u64,
    index: usize,
};

///////////////////////////////////////////////////////////////////////////////
// wasm.h

// fn wasm_functype_t* wasm_functype_new(wasm_valtype_vec_t *params, wasm_valtype_vec_t *results);
pub extern "c" fn wasm_functype_new(Ptr, Ptr) Ptr;
// fn void wasm_functype_delete(wasm_functype_t *)
pub extern "c" fn wasm_functype_delete(Ptr) void;

const WasmValKind = enum(u8) {
    i32,
    i64,
    f32,
    f64,
    externref = 128,
    funcref,
};
pub extern "c" fn wasm_valtype_new(u8) Ptr;
pub fn wasm_valtype_new_i32() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.i32));
}
pub fn wasm_valtype_new_i64() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.i64));
}
pub fn wasm_valtype_new_f32() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.f32));
}
pub fn wasm_valtype_new_f64() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.f64));
}
pub fn wasm_valtype_new_externref() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.externref));
}
pub fn wasm_valtype_new_funcref() Ptr {
    return wasm_valtype_new(@intFromEnum(WasmValKind.funcref));
}

// fn void wasm_valtype_vec_new(wasm_valtype_vec_t *out, size_t, wasm_valtype_t *const[])
pub extern "c" fn wasm_valtype_vec_new(Ptr, usize, ConstPtr) void;
// fn void wasm_valtype_vec_new_empty(wasm_valtype_vec_t *out)
pub extern "c" fn wasm_valtype_vec_new_empty(Ptr) void;

pub const ValTypeVec = extern struct {
    size: usize,
    data: ?*Ptr,
};

///////////////////////////////////////////////////////////////////////////////
// fn() -> wasi_config
pub extern "c" fn wasi_config_new() Ptr;
pub extern "c" fn wasi_config_delete(Ptr) void;
pub extern "c" fn wasi_config_inherit_argv(Ptr) void;
pub extern "c" fn wasi_config_inherit_env(Ptr) void;
pub extern "c" fn wasi_config_inherit_stdin(Ptr) void;
pub extern "c" fn wasi_config_inherit_stdout(Ptr) void;
pub extern "c" fn wasi_config_inherit_stderr(Ptr) void;
