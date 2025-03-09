const Ptr = *anyopaque;
const ConstPtr = *const anyopaque;

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
// fn(linker, store, module, instance, trap) -> error
pub extern "c" fn wasmtime_linker_instantiate(ConstPtr, Ptr, ConstPtr, Ptr, *Ptr) ?Ptr;
// fn(linker, store, name, name_len, instance) -> error
pub extern "c" fn wasmtime_linker_define_instance(Ptr, Ptr, ConstPtr, usize, ConstPtr) ?Ptr;


///////////////////////////////////////////////////////////////////////////////
// wasmtime/func.h

// fn(store, func, args, nargs, results, nresults, trap) -> error
pub extern "c" fn wasmtime_func_call(Ptr, ConstPtr, ConstPtr, usize, Ptr, usize, *Ptr) ?Ptr;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/instance.h

// fn(store, module, imports, nimports, instance, trap) -> error
pub extern "c" fn wasmtime_instance_new(Ptr, ConstPtr, ConstPtr, usize, Ptr, *Ptr) ?Ptr;
// fn(store, instance, name, name_len, item) -> bool
pub extern "c" fn wasmtime_instance_export_get(Ptr, ConstPtr, ConstPtr, usize, Ptr) bool;

///////////////////////////////////////////////////////////////////////////////
// wasmtime/store.h

// fn(engine, data, finalizer) -> store
pub extern "c" fn wasmtime_store_new(Ptr, Ptr, ?Ptr) ?Ptr;
// fn(store) -> context
pub extern "c" fn wasmtime_store_context(Ptr) ?Ptr;
// fn(store)
pub extern "c" fn wasmtime_store_delete(Ptr) void;
// fn(context) -> data
pub extern "c" fn wasmtime_context_get_data(Ptr) ?Ptr;
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
