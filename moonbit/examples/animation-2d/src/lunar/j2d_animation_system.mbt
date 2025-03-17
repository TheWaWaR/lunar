///|
pub struct AnimationSystem {
  inner : UInt64
}

///|
pub fn AnimationSystem::new(inner : UInt64) -> AnimationSystem {
  { inner, }
}

///|
fn animation_system_create_ffi(name_ptr : Int, name_len : Int) -> UInt64 = "lunar" "animation_system_create"

///|
pub fn AnimationSystem::create(name : String) -> AnimationSystem? {
  let name_ptr = str2ptr(name)
  let inner = animation_system_create_ffi(name_ptr, name.length())
  if inner > 0 {
    Some({ inner, })
  } else {
    None
  }
}

///|
fn add_simple_animation_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  sp_start_ptr : Int,
  sp_count : Int,
  fps : Float
) -> Bool = "lunar" "add_simple_animation"

///|
pub fn AnimationSystem::add_simple_animation(
  self : AnimationSystem,
  name : String,
  sprites : ArrayView[Sprite],
  fps : Float
) -> Bool {
  let sp_ptr = get_global_buf_ptr()
  let mut offset = 0
  for sp in sprites {
    offset += sp.writeTo(sp_ptr + offset)
  }
  let name_ptr = str2ptr(name)
  add_simple_animation_ffi(
    self.inner,
    name_ptr,
    name.length(),
    sp_ptr,
    sprites.length(),
    fps,
  )
}

///|
fn animation_system_is_over_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  is_over_ptr : Int
) -> Bool = "lunar" "animation_system_is_over"

///|
pub fn AnimationSystem::is_over(self : AnimationSystem, name : String) -> Bool? {
  let name_ptr = str2ptr(name)
  let bool_ptr = get_global_buf_ptr()
  if animation_system_is_over_ffi(self.inner, name_ptr, name.length(), bool_ptr) {
    Some(load8_u(bool_ptr) > 0)
  } else {
    None
  }
}

///|
fn animation_system_is_stopped_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  is_stopped_ptr : Int
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
      name_ptr,
      name.length(),
      bool_ptr,
    ) {
    Some(load8_u(bool_ptr) > 0)
  } else {
    None
  }
}

///|
fn animation_system_reset_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int
) -> Bool = "lunar" "animation_system_reset"

///|
pub fn AnimationSystem::reset(self : AnimationSystem, name : String) -> Bool {
  animation_system_reset_ffi(self.inner, str2ptr(name), name.length())
}

///|
fn animation_system_set_stop_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  stop : Bool
) -> Bool = "lunar" "animation_system_set_stop"

///|
pub fn AnimationSystem::set_stop(
  self : AnimationSystem,
  name : String,
  stop : Bool
) -> Bool {
  animation_system_set_stop_ffi(self.inner, str2ptr(name), name.length(), stop)
}

///|
fn animation_system_get_current_frame_ffi(
  as_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  sprite_ptr : Int
) -> Bool = "lunar" "animation_system_get_current_frame"

///|
pub fn AnimationSystem::get_current_frame(
  self : AnimationSystem,
  name : String
) -> Sprite? {
  let sprite_ptr = get_global_buf_ptr()
  if animation_system_get_current_frame_ffi(
      self.inner,
      str2ptr(name),
      name.length(),
      sprite_ptr,
    ) {
    Some(Sprite::readFrom(sprite_ptr))
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
