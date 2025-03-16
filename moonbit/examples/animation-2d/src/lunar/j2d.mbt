pub struct Batch2D {
  inner: UInt64
}

pub struct SpriteOption {
  pos: Option[Point]
  tint_color: Option[Color]
  scale: Option[Point]
  rotate_degree: Option[Float]
  anchor_point: Option[Point]
  flip_h: Option[Bool]
  flip_v: Option[Bool]
  depth: Option[Float]
}

pub fn SpriteOption::default() -> SpriteOption {
  SpriteOption::{
    pos: None, 
    tint_color: None,
    scale: None,
    rotate_degree: None,
    anchor_point: None,
    flip_h: None,
    flip_v: None,
    depth: None,
  }
}
pub fn SpriteOption::writeTo(self: SpriteOption, ptr: Int) -> Int {
  let mut flags = 0;
  let mut size = 0;
  if self.pos is Some(v) {
    flags = flags.lor(1)
    size += v.writeTo(ptr + size)
  }
  if self.tint_color is Some(v) {
    flags = flags.lor(2)
    size += v.writeTo(ptr + size)
  }
  if self.scale is Some(v) {
    flags = flags.lor(4)
    size += v.writeTo(ptr + size)
  }
  if self.rotate_degree is Some(v) {
    flags = flags.lor(8)
    storef32(ptr + size, v)
    size += 4;
  }
  if self.anchor_point is Some(v) {
    flags = flags.lor(16)
    size += v.writeTo(ptr + size)
  }
  if self.flip_h is Some(v) {
    flags = flags.lor(32)
    store8(ptr + size, v.to_int())
    size += 1;
  }
  if self.flip_v is Some(v) {
    flags = flags.lor(64)
    store8(ptr + size, v.to_int())
    size += 1;
  }
  if self.rotate_degree is Some(v) {
    flags = flags.lor(128)
    storef32(ptr + size, v)
    size += 4;
  }
  size
}

fn batch_new_2d_ffi() -> UInt64 = "lunar" "batch_new_2d"
fn batch_submit_2d_ffi(batch_ptr: UInt64) = "lunar" "batch_submit_2d"
fn batch_push_transform_2d_ffi(batch_ptr: UInt64) -> Bool  = "lunar" "batch_push_transform_2d"
fn batch_pop_transform_2d_ffi(batch_ptr: UInt64) = "lunar" "batch_pop_transform_2d"
fn batch_sprite_2d_ffi( 
  batch_ptr: UInt64, sp_ptr: Int, opt_ptr: Int,
) -> Bool = "lunar" "batch_sprite_2d"

pub fn Batch2D::new() -> Batch2D {
  Batch2D::{ inner: batch_new_2d_ffi() }
}
pub fn Batch2D::submit(self: Batch2D) -> Unit {
  batch_submit_2d_ffi(self.inner)
}
pub fn Batch2D::push_transform(self: Batch2D) -> Bool {
  batch_push_transform_2d_ffi(self.inner)
}
pub fn Batch2D::pop_transform(self: Batch2D) -> Unit {
  batch_pop_transform_2d_ffi(self.inner)
}
pub fn Batch2D::sprite(self: Batch2D, sp: Sprite, opt: SpriteOption) -> Bool {
    let ptr = get_global_buf_ptr()
    let opt_offset = sp.writeTo(ptr)
    let _ = opt.writeTo(ptr + opt_offset)
    batch_sprite_2d_ffi(self.inner, ptr, ptr + opt_offset)
}
