///|
let sheet : Ref[@lunar.SpriteSheet] = { val: @lunar.SpriteSheet::new(0) }

///|
let anim_sys : Ref[@lunar.AnimationSystem] = {
  val: @lunar.AnimationSystem::new(0),
}

///|
pub fn lunar_init() -> Unit {
  @lunar.log("> moon.init")
  if @lunar.physfs_mount("zig-out/assets", "", true) {
    @lunar.log("mount to zig-out/assets success")
  }
  let size = @lunar.get_canvas_size()
  @lunar.log("size: \{size}")
  anim_sys.val = @lunar.AnimationSystem::create("2d").unwrap()
  sheet.val = @lunar.SpriteSheet::from_pictures_in_dir(
    "2d",
    "images",
    size.width,
    size.height,
  ).unwrap()
  let player = sheet.val.get_sprite_by_name("player").unwrap()
  let _success = anim_sys.val.add_simple_animation(
    "player_left_right",
    [
      player.get_sub_sprite((4.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((5.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((3.0 * 16.0).to_float(), 0, 16, 16),
    ][:],
    6,
  )
  let _success = anim_sys.val.add_simple_animation(
    "player_up",
    [
      player.get_sub_sprite((7.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((8.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((6.0 * 16.0).to_float(), 0, 16, 16),
    ][:],
    6,
  )
  let _success = anim_sys.val.add_simple_animation(
    "player_down",
    [
      player.get_sub_sprite((1.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((2.0 * 16.0).to_float(), 0, 16, 16),
      player.get_sub_sprite((0.0 * 16.0).to_float(), 0, 16, 16),
    ][:],
    6,
  )
}

///|
pub fn lunar_event(_ : UInt) -> Unit {

}

///|
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

///|
pub fn lunar_draw() -> Unit {
  @lunar.debug_print(
    "Press W/S/A/D to move character around",
    pos=@lunar.Point::new(200.0, 0.0),
    color=@lunar.Color::blue(),
  )
}

///|
pub fn lunar_quit() -> Unit {
  @lunar.log("> moon.quit")
}

///| Receive AnimationSystem signal callback
pub fn lunar_signal() -> Unit {

}
