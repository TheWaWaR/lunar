///|
pub struct Batch2D {
  inner : UInt64
}

///|
pub struct SpriteOption {
  pos : Point
  tint_color : Color?
  scale : Point?
  rotate_degree : Float?
  anchor_point : Point?
  flip_h : Bool?
  flip_v : Bool?
  depth : Float?
} derive(Show)

///|
pub fn SpriteOption::new(
  pos~ : Point,
  tint_color~ : Color? = None,
  scale~ : Point? = None,
  rotate_degree~ : Float? = None,
  anchor_point~ : Point? = None,
  flip_h~ : Bool? = None,
  flip_v~ : Bool? = None,
  depth~ : Float? = None
) -> SpriteOption {
  { pos, tint_color, scale, rotate_degree, anchor_point, flip_h, flip_v, depth }
}

///|
pub fn SpriteOption::writeTo(self : SpriteOption, ptr : Int) -> Int {
  let mut flags = 1
  let mut size = 1
  size += self.pos.writeTo(ptr + size)
  if self.tint_color is Some(v) {
    flags = flags | 2
    size += v.writeTo(ptr + size)
  }
  if self.scale is Some(v) {
    flags = flags | 4
    size += v.writeTo(ptr + size)
  }
  if self.rotate_degree is Some(v) {
    flags = flags | 8
    storef32(ptr + size, v)
    size += 4
  }
  if self.anchor_point is Some(v) {
    flags = flags | 16
    size += v.writeTo(ptr + size)
  }
  if self.flip_h is Some(v) {
    flags = flags | 32
    store8(ptr + size, v.to_int())
    size += 1
  }
  if self.flip_v is Some(v) {
    flags = flags | 64
    store8(ptr + size, v.to_int())
    size += 1
  }
  if self.rotate_degree is Some(v) {
    flags = flags | 128
    storef32(ptr + size, v)
    size += 4
  }
  store8(ptr, flags)
  size
}

///|
fn batch_new_2d_ffi() -> UInt64 = "lunar" "batch_new_2d"

///|
fn batch_submit_2d_ffi(batch_ptr : UInt64) = "lunar" "batch_submit_2d"

///|
fn batch_push_transform_2d_ffi(batch_ptr : UInt64) -> Bool = "lunar" "batch_push_transform_2d"

///|
fn batch_pop_transform_2d_ffi(batch_ptr : UInt64) = "lunar" "batch_pop_transform_2d"

///|
fn batch_sprite_2d_ffi(
  batch_ptr : UInt64,
  sp_ptr : UInt64,
  opt_ptr : UInt64
) -> Bool = "lunar" "batch_sprite_2d"

///|
pub fn Batch2D::new() -> Batch2D {
  Batch2D::{ inner: batch_new_2d_ffi() }
}

///|
pub fn Batch2D::submit(self : Batch2D) -> Unit {
  batch_submit_2d_ffi(self.inner)
}

///|
pub fn Batch2D::push_transform(self : Batch2D) -> Bool {
  batch_push_transform_2d_ffi(self.inner)
}

///|
pub fn Batch2D::pop_transform(self : Batch2D) -> Unit {
  batch_pop_transform_2d_ffi(self.inner)
}

///|
pub fn Batch2D::sprite(self : Batch2D, sp : Sprite, opt : SpriteOption) -> Bool {
  let ptr = get_global_buf_ptr()
  let opt_offset = sp.writeTo(ptr)
  let _ = opt.writeTo(ptr + opt_offset)
  batch_sprite_2d_ffi(
    self.inner,
    ptr.to_uint64(),
    (ptr + opt_offset).to_uint64(),
  )
}

///|
fn batch_set_transform_2d_ffi(batch_ptr : UInt64, mat_ptr : UInt64) = "lunar" "batch_set_transform_2d"

///|
pub fn Batch2D::set_transform(self : Batch2D, trs : AffineTransform) -> Unit {
  let ptr = get_global_buf_ptr()
  let _ = trs.writeTo(ptr)
  batch_set_transform_2d_ffi(self.inner, ptr.to_uint64())
}

///|
fn batch_push_draw_cmd_2d_ffi(
  batch_ptr : UInt64,
  frame_data_ptr : UInt64
) -> Bool = "lunar" "batch_push_draw_cmd_2d"

///|
pub fn Batch2D::push_draw_cmd(self : Batch2D, frame_data : FrameData) -> Bool {
  let ptr = get_global_buf_ptr()
  let _ = frame_data.writeTo(ptr)
  batch_push_draw_cmd_2d_ffi(self.inner, ptr.to_uint64())
}
