
pub struct KeyboardState {
  slice: ZigSlice
}

fn is_key_pressed_ffi(states_ptr: UInt64, states_len: UInt64, scancode: Int) -> Bool = "lunar" "is_key_pressed"

pub fn is_pressed(self: KeyboardState, scancode: Int) -> Bool {
  is_key_pressed_ffi(self.slice.ptr, self.slice.len, scancode)
}

pub typealias KeyModifierSet = UInt16;

pub struct MouseState {
  buttons: Byte
  pos: Point
}

pub enum MouseButton {
  Left = 1;
  Middle = 2;
  Right = 3;
  Extra1 = 4;
  Extra2 = 5;
}

fn get_keyborad_state_ffi(len_ptr: Int) -> UInt64  = "lunar" "get_keyborad_state"

pub fn get_keyborad_state() -> KeyboardState {
  let len_ptr = get_global_buf_ptr()
  let ptr = get_keyborad_state_ffi(len_ptr)
  let len = load64_u(len_ptr)
  {slice: {ptr: ptr, len: len}}
}

fn get_keyboard_modifier_state_ffi() -> UInt16 = "lunar" "get_keyboard_modifier_state"

pub fn get_keyboard_modifier_state() -> KeyModifierSet {
  get_keyboard_modifier_state_ffi()
}

fn get_mouse_state_ffi(pos_x_ptr: Int, pos_y_ptr: Int) -> Byte = "lunar" "get_mouse_state"

pub fn get_mouse_state() -> MouseState {
  let pos_x_ptr = get_global_buf_ptr()
  let pos_y_ptr = pos_x_ptr + 4
  let buttons = get_mouse_state_ffi(pos_x_ptr, pos_y_ptr)
  let x = loadf32(pos_x_ptr)
  let y = loadf32(pos_y_ptr)
  {buttons, pos: {x, y}}
}
