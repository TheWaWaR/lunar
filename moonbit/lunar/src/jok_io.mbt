///|
pub struct KeyboardState {
  slice : ZigSlice
}

///|
fn is_key_pressed_ffi(
  states_ptr : UInt64,
  states_len : UInt64,
  scancode : Int
) -> Bool = "lunar" "is_key_pressed"

///|
pub fn is_pressed(self : KeyboardState, scancode : Int) -> Bool {
  is_key_pressed_ffi(self.slice.ptr, self.slice.len, scancode)
}

///|
pub struct KeyModifierSet {
  inner : UInt16
}

///|
pub struct MouseState {
  buttons : Byte
  pos : Point
}

///| FIXME: TODO
// pub enum MouseButton {
//   Left = 1
//   Middle = 2
//   Right = 3
//   Extra1 = 4
//   Extra2 = 5
// }

///|
fn get_keyboard_state_ffi(len_ptr : UInt64) -> UInt64 = "lunar" "get_keyboard_state"

///|
pub fn get_keyboard_state() -> KeyboardState {
  let len_ptr = get_global_buf_ptr()
  let ptr = get_keyboard_state_ffi(len_ptr.to_uint64())
  let len = load64_u(len_ptr)
  { slice: { ptr, len } }
}

///|
fn get_keyboard_modifier_state_ffi() -> UInt16 = "lunar" "get_keyboard_modifier_state"

///|
pub fn get_keyboard_modifier_state() -> KeyModifierSet {
  { inner: get_keyboard_modifier_state_ffi() }
}

///|
fn get_mouse_state_ffi(pos_ptr : UInt64) -> Byte = "lunar" "get_mouse_state"

///|
pub fn get_mouse_state() -> MouseState {
  let pos_ptr = get_global_buf_ptr()
  let buttons = get_mouse_state_ffi(pos_ptr.to_uint64())
  let pos = Point::readFrom(pos_ptr)
  { buttons, pos }
}
