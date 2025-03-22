///|
pub struct AnimationSystem {
  inner : UInt64
}

///|
pub fn AnimationSystem::new(inner : UInt64) -> AnimationSystem {
  { inner, }
}

///|
fn animation_system_create_ffi(name_ptr : UInt64, name_len : Int) -> UInt64 = "lunar" "animation_system_create"

///|
pub fn AnimationSystem::create(name : String) -> AnimationSystem? {
  let name_ptr = str2ptr(name)
  let inner = animation_system_create_ffi(name_ptr.to_uint64(), name.length())
  if inner > 0 {
    Some({ inner, })
  } else {
    None
  }
}

///|
fn add_simple_animation_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int,
  sp_start_ptr : UInt64,
  sp_count : Int,
  fps : Float,
  wait_time : Float,
  is_loop : Bool,
  reverse : Bool
) -> Bool = "lunar" "add_simple_animation"

///|
pub fn AnimationSystem::add_simple(
  self : AnimationSystem,
  name : String,
  frame_datas : ArrayView[FrameData],
  fps : Float,
  opt~ : AnimOption = AnimOption::new()
) -> Bool {
  let ptr = get_global_buf_ptr()
  let mut offset = 0
  for data in frame_datas {
    offset += data.writeTo(ptr + offset)
  }
  let name_ptr = str2ptr(name)
  add_simple_animation_ffi(
    self.inner,
    name_ptr.to_uint64(),
    name.length(),
    ptr.to_uint64(),
    frame_datas.length(),
    fps,
    opt.wait_time,
    opt.is_loop,
    opt.reverse,
  )
}

///|
fn animation_system_is_over_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int,
  is_over_ptr : UInt64
) -> Bool = "lunar" "animation_system_is_over"

///|
pub fn AnimationSystem::is_over(self : AnimationSystem, name : String) -> Bool? {
  let name_ptr = str2ptr(name)
  let bool_ptr = get_global_buf_ptr()
  if animation_system_is_over_ffi(
      self.inner,
      name_ptr.to_uint64(),
      name.length(),
      bool_ptr.to_uint64(),
    ) {
    Some(load8_u(bool_ptr) > 0)
  } else {
    None
  }
}

///|
fn animation_system_is_stopped_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int,
  is_stopped_ptr : UInt64
) -> Bool = "lunar" "animation_system_is_stopped"

///|
pub fn AnimationSystem::is_stopped(
  self : AnimationSystem,
  name : String
) -> Bool? {
  let name_ptr = str2ptr(name)
  let bool_ptr = get_global_buf_ptr()
  if animation_system_is_stopped_ffi(
      self.inner,
      name_ptr.to_uint64(),
      name.length(),
      bool_ptr.to_uint64(),
    ) {
    Some(load8_u(bool_ptr) > 0)
  } else {
    None
  }
}

///|
fn animation_system_reset_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int
) -> Bool = "lunar" "animation_system_reset"

///|
pub fn AnimationSystem::reset(self : AnimationSystem, name : String) -> Bool {
  animation_system_reset_ffi(
    self.inner,
    str2ptr(name).to_uint64(),
    name.length(),
  )
}

///|
fn animation_system_set_stop_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int,
  stop : Bool
) -> Bool = "lunar" "animation_system_set_stop"

///|
pub fn AnimationSystem::set_stop(
  self : AnimationSystem,
  name : String,
  stop : Bool
) -> Bool {
  animation_system_set_stop_ffi(
    self.inner,
    str2ptr(name).to_uint64(),
    name.length(),
    stop,
  )
}

///|
fn animation_system_get_current_frame_ffi(
  as_ptr : UInt64,
  name_ptr : UInt64,
  name_len : Int,
  frame_data_ptr : UInt64
) -> Bool = "lunar" "animation_system_get_current_frame"

///|
pub fn AnimationSystem::get_current_frame(
  self : AnimationSystem,
  name : String
) -> FrameData? {
  let frame_data_ptr = get_global_buf_ptr()
  if animation_system_get_current_frame_ffi(
      self.inner,
      str2ptr(name).to_uint64(),
      name.length(),
      frame_data_ptr.to_uint64(),
    ) {
    Some(FrameData::readFrom(frame_data_ptr))
  } else {
    None
  }
}

///|
fn animation_system_update_ffi(as_ptr : UInt64, delta_tick : Float) = "lunar" "animation_system_update"

///|
pub fn AnimationSystem::update(
  self : AnimationSystem,
  delta_tick : Float
) -> Unit {
  animation_system_update_ffi(self.inner, delta_tick)
}

///|
fn connect_signal_ffi(as_ptr : UInt64) -> Bool = "lunar" "connect_signal"

///|
pub fn AnimationSystem::connect_signal(self : AnimationSystem) -> Bool {
  connect_signal_ffi(self.inner)
}

///|
pub(all) enum FrameData {
  Sprite(Sprite)
  DrawCmd(DrawCmd)
}

///|
pub fn FrameData::get_sprite(self : FrameData) -> Sprite? {
  match self {
    Sprite(sp) => Some(sp)
    DrawCmd(_) => None
  }
}

///|
pub fn FrameData::get_cmd(self : FrameData) -> DrawCmd? {
  match self {
    Sprite(_) => None
    DrawCmd(cmd) => Some(cmd)
  }
}

///|
pub fn FrameData::writeTo(self : FrameData, init_ptr : Int) -> Int {
  let mut ptr = init_ptr
  ptr += 1
  let mut enum_tag : Int = 0
  match self {
    Sprite(sp) => {
      enum_tag = 1
      ptr += sp.writeTo(ptr)
    }
    DrawCmd(dcmd) => {
      enum_tag = 2
      ptr += dcmd.writeTo(ptr)
    }
  }
  store8(init_ptr, enum_tag)
  ptr - init_ptr
}

///|
pub fn FrameData::readFrom(init_ptr : Int) -> FrameData {
  let mut ptr = init_ptr
  let enum_tag = load8_u(ptr)
  ptr += 1
  match enum_tag {
    1 => Sprite(Sprite::readFrom(ptr))
    2 => DrawCmd(DrawCmd::readFrom(ptr))
    _ => {
      log("Error FrameData tag: \{enum_tag}")
      panic()
    }
  }
}

///|
pub(all) struct DrawCmd {
  cmd : Cmd
  depth : Float
}

///|
pub fn DrawCmd::new(cmd : Cmd, depth : Float) -> DrawCmd {
  { cmd, depth }
}

///|
pub fn DrawCmd::to_data(self : DrawCmd) -> FrameData {
  FrameData::DrawCmd(self)
}

///|
pub fn DrawCmd::writeTo(self : DrawCmd, init_ptr : Int) -> Int {
  let mut ptr = init_ptr
  ptr += self.cmd.writeTo(ptr)
  storef32(ptr, self.depth)
  ptr += 4
  ptr - init_ptr
}

///|
pub fn DrawCmd::readFrom(init_ptr : Int) -> DrawCmd {
  let (cmd, cmd_size) = Cmd::readFrom(init_ptr)
  let depth = loadf32(init_ptr + cmd_size)
  { cmd, depth }
}

///|
pub(all) enum Cmd {
  Circle(CircleCmd)
  // FIXME: add more commands
}

///|
pub fn Cmd::writeTo(self : Cmd, init_ptr : Int) -> Int {
  let mut ptr = init_ptr
  ptr += 1
  let mut enum_tag : Int = 0
  match self {
    Circle(cmd) => {
      enum_tag = 10
      ptr += cmd.writeTo(ptr)
    }
  }
  store8(init_ptr, enum_tag)
  ptr - init_ptr
}

///|
pub fn Cmd::readFrom(init_ptr : Int) -> (Cmd, Int) {
  let mut ptr = init_ptr
  let enum_tag = load8_u(ptr)
  ptr += 1
  match enum_tag {
    10 => {
      let (circle, size) = CircleCmd::readFrom(ptr)
      (Circle(circle), size + 1)
    }
    _ => ...
  }
}

///|
pub(all) struct CircleCmd {
  p : Point
  radius : Float
  color : UInt
  thickness : Float
  num_segments : UInt
}

///|
pub fn CircleCmd::new(
  p~ : Point,
  radius~ : Float,
  color~ : Color,
  thickness~ : Float,
  num_segments~ : UInt
) -> CircleCmd {
  let color = color.to_internal()
  { p, radius, color, thickness, num_segments }
}

///|
pub fn CircleCmd::writeTo(self : CircleCmd, init_ptr : Int) -> Int {
  let mut ptr = init_ptr
  ptr += self.p.writeTo(ptr)
  storef32(ptr, self.radius)
  ptr += 4
  store32_u(ptr, self.color)
  ptr += 4
  storef32(ptr, self.thickness)
  ptr += 4
  store32_u(ptr, self.num_segments)
  ptr += 4
  ptr - init_ptr
}

///|
pub fn CircleCmd::readFrom(init_ptr : Int) -> (CircleCmd, Int) {
  let mut ptr = init_ptr
  let p = Point::readFrom(ptr)
  ptr += 8
  let radius = loadf32(ptr)
  ptr += 4
  let color = load32_u(ptr)
  ptr += 4
  let thickness = loadf32(ptr)
  ptr += 4
  let num_segments = load32_u(ptr)
  ptr += 4
  ({ p, radius, color, thickness, num_segments }, ptr - init_ptr)
}

///|
pub struct AnimOption {
  wait_time : Float
  is_loop : Bool
  reverse : Bool
}

///|
pub fn AnimOption::new(
  wait_time~ : Float = 0.0,
  is_loop~ : Bool = false,
  reverse~ : Bool = false
) -> AnimOption {
  { wait_time, is_loop, reverse }
}
