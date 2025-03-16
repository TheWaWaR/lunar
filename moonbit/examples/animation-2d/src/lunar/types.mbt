///|
pub struct ZigSlice {
  ptr : UInt64
  len : UInt64
}

///|
pub struct Point {
  x : Float
  y : Float
} derive(Show)

///|
pub fn Point::new(x : Float, y : Float) -> Point {
  { x, y }
}

///|
pub fn Point::readFrom(ptr : Int) -> Point {
  let x = loadf32(ptr + 0)
  let y = loadf32(ptr + 4)
  Point::new(x, y)
}

///|
pub fn Point::writeTo(self : Point, ptr : Int) -> Int {
  storef32(ptr + 0, self.x)
  storef32(ptr + 4, self.y)
  8
}

///|
pub struct Size {
  width : UInt
  height : UInt
} derive(Show)

///|
pub fn Size::new(width : UInt, height : UInt) -> Size {
  { width, height }
}

///|
pub fn Size::readFrom(ptr : Int) -> Size {
  let width = load32_u(ptr + 0)
  let height = load32_u(ptr + 4)
  Size::new(width, height)
}

///|
pub fn Size::writeTo(self : Size, ptr : Int) -> Int {
  store32_u(ptr + 0, self.width)
  store32_u(ptr + 4, self.height)
  8
}

///|
pub struct Color {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Show)

///|
pub fn Color::readFrom(ptr : Int) -> Color {
  let r = load8_u(ptr + 0).to_byte()
  let g = load8_u(ptr + 1).to_byte()
  let b = load8_u(ptr + 2).to_byte()
  let a = load8_u(ptr + 3).to_byte()
  Color::rgba(r, g, b, a)
}

///|
pub fn Color::writeTo(self : Color, ptr : Int) -> Int {
  store8(ptr + 0, self.r.to_int())
  store8(ptr + 1, self.g.to_int())
  store8(ptr + 2, self.b.to_int())
  store8(ptr + 3, self.a.to_int())
  4
}

///|
pub fn Color::rgb(r : Byte, g : Byte, b : Byte) -> Color {
  { r, g, b, a: 255 }
}

///|
pub fn Color::rgba(r : Byte, g : Byte, b : Byte, a : Byte) -> Color {
  { r, g, b, a }
}

///|
pub fn Color::none() -> Color {
  Color::rgba(0x00, 0x00, 0x00, 0x00)
}

///|
pub fn Color::black() -> Color {
  Color::rgb(0x00, 0x00, 0x00)
}

///|
pub fn Color::white() -> Color {
  Color::rgb(0xFF, 0xFF, 0xFF)
}

///|
pub fn Color::red() -> Color {
  Color::rgb(0xFF, 0x00, 0x00)
}

///|
pub fn Color::green() -> Color {
  Color::rgb(0x00, 0xFF, 0x00)
}

///|
pub fn Color::blue() -> Color {
  Color::rgb(0x00, 0x00, 0xFF)
}

///|
pub fn Color::magenta() -> Color {
  Color::rgb(0xFF, 0x00, 0xFF)
}

///|
pub fn Color::cyan() -> Color {
  Color::rgb(0x00, 0xFF, 0xFF)
}

///|
pub fn Color::yellow() -> Color {
  Color::rgb(0xFF, 0xFF, 0x00)
}

///|
pub fn Color::purple() -> Color {
  Color::rgb(255, 128, 255)
}
