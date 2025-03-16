pub fn lunar_init() -> Unit {
  @lunar.log("> moon.init")
  let size = @lunar.get_canvas_size()
  @lunar.log("size: \{size}")
  if @lunar.physfs_mount("zig-out/assets", "", false) {
    @lunar.log("mount to zig-out/assets success")
  }
}

pub fn lunar_event(_: UInt) -> Unit { }

pub fn lunar_update() -> Unit { 
  let kbd = @lunar.get_keyboard_state()
  if kbd.is_pressed(@lunar.SDL_SCANCODE_Q) {
    @lunar.log("Quit game")
    @lunar.kill()
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_A) {
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
    "Press W/S/A/D to move character around", 
    pos= @lunar.Point::new(300.0, 0.0), 
    color=@lunar.Color::blue(),
  )
}

pub fn lunar_quit() -> Unit {
  @lunar.log("> moon.quit")
}

/// Receive AnimationSystem signal callback
pub fn lunar_signal() -> Unit { }
