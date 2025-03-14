
fn debug_print_ffi(
  text_ptr: Int, text_len: Int, 
  pos_x: Float, pos_y: Float, 
  r: Byte, g: Byte, b: Byte, a: Byte,
) = "lunar" "debug_print"

pub fn debug_print(
  text: String, 
  pos~: Point = {x: 0, y: 0}, 
  color~: Color = Color::white(),
) -> Unit {
  let bytes = text |> @wasi.encode_utf8
  let bytes_len = bytes.length()
  let bytes_ptr = byte_array2ptr(bytes)
  debug_print_ffi(bytes_ptr, bytes_len, pos.x, pos.y, color.r, color.g, color.b, color.a)
}