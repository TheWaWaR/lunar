///|
fn debug_print_ffi(
  // utf16 string
  text_ptr : Int,
  text_len : Int,
  pos_ptr : Int,
  color_ptr : Int
) = "lunar" "debug_print"

///|
pub fn debug_print(
  text : String,
  pos~ : Point = { x: 0, y: 0 },
  color~ : Color = Color::white()
) -> Unit {
  let text_ptr = str2ptr(text)
  let text_len = text.length()
  let wasm_ptr = get_global_buf_ptr()
  let pos_len = pos.writeTo(wasm_ptr)
  let color_ptr = wasm_ptr + pos_len
  let _ = color.writeTo(wasm_ptr + pos_len)
  debug_print_ffi(text_ptr, text_len, wasm_ptr, color_ptr)
}

///|
pub fn kill() = "lunar" "kill"

///|
pub fn delta_seconds() -> Float = "lunar" "delta_seconds"

///|
fn get_canvas_size_ffi(width_ptr : Int, height_ptr : Int) = "lunar" "get_canvas_size"

///|
pub fn get_canvas_size() -> Size {
  let ptr = get_global_buf_ptr()
  get_canvas_size_ffi(ptr + 0, ptr + 4)
  let width = load32_u(ptr + 0)
  let height = load32_u(ptr + 4)
  Size::new(width, height)
}

///|
fn get_renderer_ffi() -> UInt64 = "lunar" "get_renderer"

///|
pub fn get_renderer() -> Renderer {
  { inner: get_renderer_ffi() }
}

///|
pub fn display_stats() = "lunar" "display_stats"