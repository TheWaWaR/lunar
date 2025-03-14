
fn debug_print_ffi(
  // utf16 string
  text_ptr: Int, text_len: Int, 
  pos_x: Float, pos_y: Float, 
  r: Byte, g: Byte, b: Byte, a: Byte,
) = "lunar" "debug_print"

pub fn debug_print(
  text: String, 
  pos~: Point = {x: 0, y: 0}, 
  color~: Color = Color::white(),
) -> Unit {
  let text_ptr = str2ptr(text)
  let text_len = text.length()
  debug_print_ffi(text_ptr, text_len, pos.x, pos.y, color.r, color.g, color.b, color.a)
}