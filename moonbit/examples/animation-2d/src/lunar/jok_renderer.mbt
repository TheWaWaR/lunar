///|
pub struct Renderer {
  inner : UInt64
}

///|
fn renderer_clear_ffi(ptr : UInt64, color_ptr : Int) -> Bool = "lunar" "renderer_clear"

///|
pub fn Renderer::clear(self : Renderer, color : Color) -> Unit {
  let ptr = get_global_buf_ptr()
  let _len = color.writeTo(ptr)
  let _success = renderer_clear_ffi(self.inner, ptr)

}
