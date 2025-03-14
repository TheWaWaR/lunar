
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
  let pos_y_ptr = pos_x_ptr + 8
  let buttons = get_mouse_state_ffi(pos_x_ptr, pos_y_ptr)
  let x = loadf64(pos_x_ptr)
  let y = loadf64(pos_y_ptr)
  {buttons, pos: {x, y}}
}
 
pub const SDL_SCANCODE_A = 4
pub const SDL_SCANCODE_B = 5
pub const SDL_SCANCODE_C = 6
pub const SDL_SCANCODE_D = 7
pub const SDL_SCANCODE_E = 8
pub const SDL_SCANCODE_F = 9
pub const SDL_SCANCODE_G = 10
pub const SDL_SCANCODE_H = 11
pub const SDL_SCANCODE_I = 12
pub const SDL_SCANCODE_J = 13
pub const SDL_SCANCODE_K = 14
pub const SDL_SCANCODE_L = 15
pub const SDL_SCANCODE_M = 16
pub const SDL_SCANCODE_N = 17
pub const SDL_SCANCODE_O = 18
pub const SDL_SCANCODE_P = 19
pub const SDL_SCANCODE_Q = 20
pub const SDL_SCANCODE_R = 21
pub const SDL_SCANCODE_S = 22
pub const SDL_SCANCODE_T = 23
pub const SDL_SCANCODE_U = 24
pub const SDL_SCANCODE_V = 25
pub const SDL_SCANCODE_W = 26
pub const SDL_SCANCODE_X = 27
pub const SDL_SCANCODE_Y = 28
pub const SDL_SCANCODE_Z = 29
pub const SDL_SCANCODE_1 = 30
pub const SDL_SCANCODE_2 = 31
pub const SDL_SCANCODE_3 = 32
pub const SDL_SCANCODE_4 = 33
pub const SDL_SCANCODE_5 = 34
pub const SDL_SCANCODE_6 = 35
pub const SDL_SCANCODE_7 = 36
pub const SDL_SCANCODE_8 = 37
pub const SDL_SCANCODE_9 = 38
pub const SDL_SCANCODE_0 = 39
pub const SDL_SCANCODE_RETURN = 40
pub const SDL_SCANCODE_ESCAPE = 41
pub const SDL_SCANCODE_BACKSPACE = 42
pub const SDL_SCANCODE_TAB = 43
pub const SDL_SCANCODE_SPACE = 44
pub const SDL_SCANCODE_MINUS = 45
pub const SDL_SCANCODE_EQUALS = 46
pub const SDL_SCANCODE_LEFTBRACKET = 47
pub const SDL_SCANCODE_RIGHTBRACKET = 48
pub const SDL_SCANCODE_BACKSLASH = 49
pub const SDL_SCANCODE_NONUSHASH = 50
pub const SDL_SCANCODE_SEMICOLON = 51
pub const SDL_SCANCODE_APOSTROPHE = 52
pub const SDL_SCANCODE_GRAVE = 53
pub const SDL_SCANCODE_COMMA = 54
pub const SDL_SCANCODE_PERIOD = 55
pub const SDL_SCANCODE_SLASH = 56
pub const SDL_SCANCODE_CAPSLOCK = 57
pub const SDL_SCANCODE_F1 = 58
pub const SDL_SCANCODE_F2 = 59
pub const SDL_SCANCODE_F3 = 60
pub const SDL_SCANCODE_F4 = 61
pub const SDL_SCANCODE_F5 = 62
pub const SDL_SCANCODE_F6 = 63
pub const SDL_SCANCODE_F7 = 64
pub const SDL_SCANCODE_F8 = 65
pub const SDL_SCANCODE_F9 = 66
pub const SDL_SCANCODE_F10 = 67
pub const SDL_SCANCODE_F11 = 68
pub const SDL_SCANCODE_F12 = 69
pub const SDL_SCANCODE_PRINTSCREEN = 70
pub const SDL_SCANCODE_SCROLLLOCK = 71
pub const SDL_SCANCODE_PAUSE = 72
pub const SDL_SCANCODE_INSERT = 73
pub const SDL_SCANCODE_HOME = 74
pub const SDL_SCANCODE_PAGEUP = 75
pub const SDL_SCANCODE_DELETE = 76
pub const SDL_SCANCODE_END = 77
pub const SDL_SCANCODE_PAGEDOWN = 78
pub const SDL_SCANCODE_RIGHT = 79
pub const SDL_SCANCODE_LEFT = 80
pub const SDL_SCANCODE_DOWN = 81
pub const SDL_SCANCODE_UP = 82
pub const SDL_SCANCODE_NUMLOCKCLEAR = 83
pub const SDL_SCANCODE_KP_DIVIDE = 84
pub const SDL_SCANCODE_KP_MULTIPLY = 85
pub const SDL_SCANCODE_KP_MINUS = 86
pub const SDL_SCANCODE_KP_PLUS = 87
pub const SDL_SCANCODE_KP_ENTER = 88
pub const SDL_SCANCODE_KP_1 = 89
pub const SDL_SCANCODE_KP_2 = 90
pub const SDL_SCANCODE_KP_3 = 91
pub const SDL_SCANCODE_KP_4 = 92
pub const SDL_SCANCODE_KP_5 = 93
pub const SDL_SCANCODE_KP_6 = 94
pub const SDL_SCANCODE_KP_7 = 95
pub const SDL_SCANCODE_KP_8 = 96
pub const SDL_SCANCODE_KP_9 = 97
pub const SDL_SCANCODE_KP_0 = 98
pub const SDL_SCANCODE_KP_PERIOD = 99
pub const SDL_SCANCODE_NONUSBACKSLASH = 100
pub const SDL_SCANCODE_APPLICATION = 101
pub const SDL_SCANCODE_POWER = 102
pub const SDL_SCANCODE_KP_EQUALS = 103
pub const SDL_SCANCODE_F13 = 104
pub const SDL_SCANCODE_F14 = 105
pub const SDL_SCANCODE_F15 = 106
pub const SDL_SCANCODE_F16 = 107
pub const SDL_SCANCODE_F17 = 108
pub const SDL_SCANCODE_F18 = 109
pub const SDL_SCANCODE_F19 = 110
pub const SDL_SCANCODE_F20 = 111
pub const SDL_SCANCODE_F21 = 112
pub const SDL_SCANCODE_F22 = 113
pub const SDL_SCANCODE_F23 = 114
pub const SDL_SCANCODE_F24 = 115
pub const SDL_SCANCODE_EXECUTE = 116
pub const SDL_SCANCODE_HELP = 117
pub const SDL_SCANCODE_MENU = 118
pub const SDL_SCANCODE_SELECT = 119
pub const SDL_SCANCODE_STOP = 120
pub const SDL_SCANCODE_AGAIN = 121
pub const SDL_SCANCODE_UNDO = 122
pub const SDL_SCANCODE_CUT = 123
pub const SDL_SCANCODE_COPY = 124
pub const SDL_SCANCODE_PASTE = 125
pub const SDL_SCANCODE_FIND = 126
pub const SDL_SCANCODE_MUTE = 127
pub const SDL_SCANCODE_VOLUMEUP = 128
pub const SDL_SCANCODE_VOLUMEDOWN = 129
pub const SDL_SCANCODE_KP_COMMA = 133
pub const SDL_SCANCODE_KP_EQUALSAS400 = 134
pub const SDL_SCANCODE_INTERNATIONAL1 = 135
pub const SDL_SCANCODE_INTERNATIONAL2 = 136
pub const SDL_SCANCODE_INTERNATIONAL3 = 137
pub const SDL_SCANCODE_INTERNATIONAL4 = 138
pub const SDL_SCANCODE_INTERNATIONAL5 = 139
pub const SDL_SCANCODE_INTERNATIONAL6 = 140
pub const SDL_SCANCODE_INTERNATIONAL7 = 141
pub const SDL_SCANCODE_INTERNATIONAL8 = 142
pub const SDL_SCANCODE_INTERNATIONAL9 = 143
pub const SDL_SCANCODE_LANG1 = 144
pub const SDL_SCANCODE_LANG2 = 145
pub const SDL_SCANCODE_LANG3 = 146
pub const SDL_SCANCODE_LANG4 = 147
pub const SDL_SCANCODE_LANG5 = 148
pub const SDL_SCANCODE_LANG6 = 149
pub const SDL_SCANCODE_LANG7 = 150
pub const SDL_SCANCODE_LANG8 = 151
pub const SDL_SCANCODE_LANG9 = 152
pub const SDL_SCANCODE_ALTERASE = 153
pub const SDL_SCANCODE_SYSREQ = 154
pub const SDL_SCANCODE_CANCEL = 155
pub const SDL_SCANCODE_CLEAR = 156
pub const SDL_SCANCODE_PRIOR = 157
pub const SDL_SCANCODE_RETURN2 = 158
pub const SDL_SCANCODE_SEPARATOR = 159
pub const SDL_SCANCODE_OUT = 160
pub const SDL_SCANCODE_OPER = 161
pub const SDL_SCANCODE_CLEARAGAIN = 162
pub const SDL_SCANCODE_CRSEL = 163
pub const SDL_SCANCODE_EXSEL = 164
pub const SDL_SCANCODE_KP_00 = 176
pub const SDL_SCANCODE_KP_000 = 177
pub const SDL_SCANCODE_THOUSANDSSEPARATOR = 178
pub const SDL_SCANCODE_DECIMALSEPARATOR = 179
pub const SDL_SCANCODE_CURRENCYUNIT = 180
pub const SDL_SCANCODE_CURRENCYSUBUNIT = 181
pub const SDL_SCANCODE_KP_LEFTPAREN = 182
pub const SDL_SCANCODE_KP_RIGHTPAREN = 183
pub const SDL_SCANCODE_KP_LEFTBRACE = 184
pub const SDL_SCANCODE_KP_RIGHTBRACE = 185
pub const SDL_SCANCODE_KP_TAB = 186
pub const SDL_SCANCODE_KP_BACKSPACE = 187
pub const SDL_SCANCODE_KP_A = 188
pub const SDL_SCANCODE_KP_B = 189
pub const SDL_SCANCODE_KP_C = 190
pub const SDL_SCANCODE_KP_D = 191
pub const SDL_SCANCODE_KP_E = 192
pub const SDL_SCANCODE_KP_F = 193
pub const SDL_SCANCODE_KP_XOR = 194
pub const SDL_SCANCODE_KP_POWER = 195
pub const SDL_SCANCODE_KP_PERCENT = 196
pub const SDL_SCANCODE_KP_LESS = 197
pub const SDL_SCANCODE_KP_GREATER = 198
pub const SDL_SCANCODE_KP_AMPERSAND = 199
pub const SDL_SCANCODE_KP_DBLAMPERSAND = 200
pub const SDL_SCANCODE_KP_VERTICALBAR = 201
pub const SDL_SCANCODE_KP_DBLVERTICALBAR = 202
pub const SDL_SCANCODE_KP_COLON = 203
pub const SDL_SCANCODE_KP_HASH = 204
pub const SDL_SCANCODE_KP_SPACE = 205
pub const SDL_SCANCODE_KP_AT = 206
pub const SDL_SCANCODE_KP_EXCLAM = 207
pub const SDL_SCANCODE_KP_MEMSTORE = 208
pub const SDL_SCANCODE_KP_MEMRECALL = 209
pub const SDL_SCANCODE_KP_MEMCLEAR = 210
pub const SDL_SCANCODE_KP_MEMADD = 211
pub const SDL_SCANCODE_KP_MEMSUBTRACT = 212
pub const SDL_SCANCODE_KP_MEMMULTIPLY = 213
pub const SDL_SCANCODE_KP_MEMDIVIDE = 214
pub const SDL_SCANCODE_KP_PLUSMINUS = 215
pub const SDL_SCANCODE_KP_CLEAR = 216
pub const SDL_SCANCODE_KP_CLEARENTRY = 217
pub const SDL_SCANCODE_KP_BINARY = 218
pub const SDL_SCANCODE_KP_OCTAL = 219
pub const SDL_SCANCODE_KP_DECIMAL = 220
pub const SDL_SCANCODE_KP_HEXADECIMAL = 221
pub const SDL_SCANCODE_LCTRL = 224
pub const SDL_SCANCODE_LSHIFT = 225
pub const SDL_SCANCODE_LALT = 226
pub const SDL_SCANCODE_LGUI = 227
pub const SDL_SCANCODE_RCTRL = 228
pub const SDL_SCANCODE_RSHIFT = 229
pub const SDL_SCANCODE_RALT = 230
pub const SDL_SCANCODE_RGUI = 231
pub const SDL_SCANCODE_MODE = 257
pub const SDL_SCANCODE_AUDIONEXT = 258
pub const SDL_SCANCODE_AUDIOPREV = 259
pub const SDL_SCANCODE_AUDIOSTOP = 260
pub const SDL_SCANCODE_AUDIOPLAY = 261
pub const SDL_SCANCODE_AUDIOMUTE = 262
pub const SDL_SCANCODE_MEDIASELECT = 263
pub const SDL_SCANCODE_WWW = 264
pub const SDL_SCANCODE_MAIL = 265
pub const SDL_SCANCODE_CALCULATOR = 266
pub const SDL_SCANCODE_COMPUTER = 267
pub const SDL_SCANCODE_AC_SEARCH = 268
pub const SDL_SCANCODE_AC_HOME = 269
pub const SDL_SCANCODE_AC_BACK = 270
pub const SDL_SCANCODE_AC_FORWARD = 271
pub const SDL_SCANCODE_AC_STOP = 272
pub const SDL_SCANCODE_AC_REFRESH = 273
pub const SDL_SCANCODE_AC_BOOKMARKS = 274
pub const SDL_SCANCODE_BRIGHTNESSDOWN = 275
pub const SDL_SCANCODE_BRIGHTNESSUP = 276
pub const SDL_SCANCODE_DISPLAYSWITCH = 277
pub const SDL_SCANCODE_KBDILLUMTOGGLE = 278
pub const SDL_SCANCODE_KBDILLUMDOWN = 279
pub const SDL_SCANCODE_KBDILLUMUP = 280
pub const SDL_SCANCODE_EJECT = 281
pub const SDL_SCANCODE_SLEEP = 282
pub const SDL_SCANCODE_APP1 = 283
pub const SDL_SCANCODE_APP2 = 284
pub const SDL_SCANCODE_AUDIOREWIND = 285
pub const SDL_SCANCODE_AUDIOFASTFORWARD = 286
