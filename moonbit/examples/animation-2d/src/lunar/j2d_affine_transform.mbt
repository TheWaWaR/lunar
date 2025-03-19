///|
pub struct AffineTransform {
  // f32 * 4 * 4
  mat : FixedArray[Float]
}

///|
fn affine_transform_init_2d_ffi(mat_ptr : Int) = "lunar" "affine_transform_init_2d"

///|
pub fn AffineTransform::init() -> AffineTransform {
  let ptr = get_global_buf_ptr()
  affine_transform_init_2d_ffi(ptr)
  AffineTransform::readFrom(ptr)
}

///|
fn affine_transform_translate_2d_ffi(
  mat_in_ptr : Int,
  pos_ptr : Int,
  mat_out_ptr : Int
) = "lunar" "affine_transform_translate_2d"

///|
pub fn AffineTransform::translate(
  self : AffineTransform,
  pos : Point
) -> AffineTransform {
  let mut ptr = get_global_buf_ptr()
  let mat_in_ptr = ptr
  ptr += self.writeTo(ptr)
  let pos_ptr = ptr
  ptr += pos.writeTo(ptr)
  let mat_out_ptr = ptr
  affine_transform_translate_2d_ffi(mat_in_ptr, pos_ptr, mat_out_ptr)
  AffineTransform::readFrom(mat_out_ptr)
}

///|
pub fn AffineTransform::writeTo(self : AffineTransform, init_ptr : Int) -> Int {
  let mut ptr = init_ptr
  for i in 0..<16 {
    storef32(ptr, self.mat[i])
    ptr += 4
  }
  ptr - init_ptr
}

///|
pub fn AffineTransform::readFrom(init_ptr : Int) -> AffineTransform {
  let mut ptr = init_ptr
  let mat = FixedArray::make(16, (0.0 : Float))
  for i in 0..<16 {
    mat[i] = loadf32(ptr)
    ptr += 4
  }
  { mat, }
}
