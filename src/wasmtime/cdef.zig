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

///////////////////////////////////////////////////////////////////////////////
// wasmtime/linker.h

// fn(engine) -> linker
pub extern "c" fn wasmtime_linker_new(Ptr) Ptr;
// fn(linker)
pub extern "c" fn wasmtime_linker_delete(Ptr) void;
// fn(linker) -> error
pub extern "c" fn wasmtime_linker_define_wasi(Ptr) ?Ptr;
// fn(linker, store_context, module, instance, trap) -> error
pub extern "c" fn wasmtime_linker_instantiate(ConstPtr, Ptr, ConstPtr, Ptr, TrapPtr) ?Ptr;
// fn(linker, store_context, name, name_len, instance) -> error
pub extern "c" fn wasmtime_linker_define_instance(Ptr, Ptr, ConstPtr, usize, ConstPtr) ?Ptr;
// fn(linker, module, module_len, name, name_len, ty, cb, data, finalizer) -> error
pub extern "c" fn wasmtime_linker_define_func(Ptr, ConstPtr, usize, ConstPtr, usize, ConstPtr, ConstPtr, Ptr, ?Ptr) ?Ptr;

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
// fn(store) -> context
pub extern "c" fn wasmtime_store_context(Ptr) Ptr;
// fn(store)
pub extern "c" fn wasmtime_store_delete(Ptr) void;
// fn(context) -> data
pub extern "c" fn wasmtime_context_get_data(Ptr) Ptr;
// fn(context, data)
pub extern "c" fn wasmtime_context_set_data(Ptr, Ptr) void;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/module.h

// fn(engine, wasm, wasm_len, ret) -> error
pub extern "c" fn wasmtime_module_new(Ptr, ConstPtr, usize, *Ptr) ?Ptr;
// fn(module)
pub extern "c" fn wasmtime_module_delete(Ptr) void;
// fn(engine, wasm, wasm_len) -> error
pub extern "c" fn wasmtime_module_validate(Ptr, ConstPtr, usize) ?Ptr;

// fn(env, caller, args, nargs, results, nresults) -> trap
pub const CallbackFn = *const fn (
    env: Ptr,
    caller: Ptr,
    args: ConstPtr,
    nargs: usize,
    results: Ptr,
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

pub const Value = extern struct {
    kind: u8,
    of: ValueUnion,
};

pub const ExternUnion = extern union {
    func: Func,
    global: Global,
    table: Table,
    memory: Memory,
    sharedmemory: Ptr,
};
pub const Extern = extern struct {
    kind: u8,
    of: ExternUnion,
};

pub const Func = extern struct {
    store_id: u64,
    __private: usize,
};
pub const Table = extern struct {
    store_id: u64,
    __private: usize,
};
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

pub extern "c" fn wasm_valtype_new_i32() Ptr;
pub extern "c" fn wasm_valtype_new_i64() Ptr;
pub extern "c" fn wasm_valtype_new_f32() Ptr;
pub extern "c" fn wasm_valtype_new_f64() Ptr;
pub extern "c" fn wasm_valtype_new_externref() Ptr;
pub extern "c" fn wasm_valtype_new_funcref() Ptr;

// fn void wasm_valtype_vec_new(wasm_valtype_vec_t *out, size_t, wasm_valtype_t *const[])
pub extern "c" fn wasm_valtype_vec_new(Ptr, usize, Ptr) void;
// fn void wasm_valtype_vec_new_empty(wasm_valtype_vec_t *out)
pub extern "c" fn wasm_valtype_vec_new_empty(Ptr) void;

pub const ValTypeVec = extern struct {
    size: usize,
    data: ?*Ptr,
};
