///|
pub struct Sprite {
  width : Float
  height : Float
  uv0 : Point
  uv1 : Point
  tex : UInt64
} derive(Show)

///|
fn sprite_get_sub_sprite_ffi(
  sp_in_ptr : Int,
  offset_x : Float,
  offset_y : Float,
  width : Float,
  height : Float,
  sp_out_ptr : Int
) = "lunar" "sprite_get_sub_sprite"

///|
pub fn Sprite::writeTo(self : Sprite, ptr : Int) -> Int {
  let mut size = 0
  storef32(ptr + size, self.width)
  size += 4
  storef32(ptr + size, self.height)
  size += 4
  size += self.uv0.writeTo(ptr + size)
  size += self.uv1.writeTo(ptr + size)
  store64_u(ptr + size, self.tex)
  size += 8
  size
}

///|
pub fn Sprite::readFrom(ptr : Int) -> Sprite {
  let mut offset = 0
  let width = loadf32(ptr + offset)
  offset += 4
  let height = loadf32(ptr + offset)
  offset += 4
  let uv0 = Point::readFrom(ptr + offset)
  offset += 8
  let uv1 = Point::readFrom(ptr + offset)
  offset += 8
  let tex = load64_u(ptr + offset)
  Sprite::{ width, height, uv0, uv1, tex }
}

pub fn Sprite::to_data(self: Sprite) -> FrameData {
  FrameData::Sprite(self)
}

///|
pub fn Sprite::get_sub_sprite(
  self : Sprite,
  offset_x : Float,
  offset_y : Float,
  width : Float,
  height : Float
) -> Sprite {
  let ptr = get_global_buf_ptr()
  let ptr_out = ptr + self.writeTo(ptr)
  sprite_get_sub_sprite_ffi(ptr, offset_x, offset_y, width, height, ptr_out)
  Sprite::readFrom(ptr_out)
}
