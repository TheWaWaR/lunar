
fn debug_print_ffi(
  // utf16 string
  text_ptr: Int, text_len: Int, 
  pos_ptr: Int, color_ptr: Int,
) = "lunar" "debug_print"

pub fn debug_print(
  text: String, 
  pos~: Point = {x: 0, y: 0}, 
  color~: Color = Color::white(),
) -> Unit {
  let text_ptr = str2ptr(text)
  let text_len = text.length()
  let wasm_ptr = get_global_buf_ptr()
  let color_ptr = wasm_ptr + pos.writeTo(wasm_ptr)
  let _ = color.writeTo(color_ptr)
  debug_print_ffi(text_ptr, text_len, wasm_ptr, color_ptr)
}