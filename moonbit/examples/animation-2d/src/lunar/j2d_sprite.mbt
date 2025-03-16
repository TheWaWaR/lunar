pub struct Sprite {
  width: Float
  height: Float
  uv0: Point
  uv1: Point
  tex: UInt64
}

pub fn Sprite::writeTo(self: Sprite, ptr: Int) -> Int {
  let mut size = 0;
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