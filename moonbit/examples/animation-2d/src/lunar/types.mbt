
pub struct ZigSlice {
  ptr: UInt64
  len: UInt64
}

pub struct Point {
  x: Float
  y: Float
}

pub fn Point::new(x: Float, y: Float) -> Point {
  { x, y }
}

pub struct Color {
  r: Byte
  g: Byte
  b: Byte
  a: Byte
}
pub fn Color::rgb(r: Byte, g: Byte, b: Byte) -> Color {
  { r, g, b, a: 255 }
}
pub fn Color::rgba(r: Byte, g: Byte, b: Byte, a: Byte) -> Color {
  { r, g, b, a }
}
pub fn Color::none() -> Color { Color::rgba(0x00, 0x00, 0x00, 0x00) }
pub fn Color::black() -> Color { Color::rgb(0x00, 0x00, 0x00) }
pub fn Color::white() -> Color { Color::rgb(0xFF, 0xFF, 0xFF) }
pub fn Color::red() -> Color { Color::rgb(0xFF, 0x00, 0x00) }
pub fn Color::green() -> Color { Color::rgb(0x00, 0xFF, 0x00) }
pub fn Color::blue() -> Color { Color::rgb(0x00, 0x00, 0xFF) }
pub fn Color::magenta() -> Color { Color::rgb(0xFF, 0x00, 0xFF) }
pub fn Color::cyan() -> Color { Color::rgb(0x00, 0xFF, 0xFF) }
pub fn Color::yellow() -> Color { Color::rgb(0xFF, 0xFF, 0x00) }
pub fn Color::purple() -> Color { Color::rgb(255, 128, 255) }