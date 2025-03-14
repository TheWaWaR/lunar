pub fn lunar_init() -> Unit {
  @lunar.log("> moon.init")
}

pub fn lunar_event(_: UInt) -> Unit { }

pub fn lunar_update() -> Unit { 
  let kbd = @lunar.get_keyborad_state()
  if kbd.is_pressed(@lunar.SDL_SCANCODE_A) {
    @lunar.log("pressed: A")
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_S) {
    @lunar.log("pressed: S")
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_D) {
    @lunar.log("pressed: D")
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_W) {
    @lunar.log("pressed: W")
  }
}

pub fn lunar_draw() -> Unit {
  @lunar.debug_print(
    "Press up/down/left/right to move character around", 
    pos= @lunar.Point::new(300.0, 0.0), 
    color=@lunar.Color::white(),
  )
}

pub fn lunar_quit() -> Unit {
  @lunar.log("> moon.quit")
}