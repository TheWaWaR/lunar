///|
let sheet : Ref[@lunar.SpriteSheet] = { val: @lunar.SpriteSheet::new(0) }

///|
let anim_sys : Ref[@lunar.AnimationSystem] = {
  val: @lunar.AnimationSystem::new(0),
}

///|
let pos : Ref[@lunar.Point] = { val: @lunar.Point::new(200, 200) }

///|
let flip_h : Ref[Bool] = { val: false }

///|
let animation : Ref[String] = { val: "player_down" }

///|
let velocity : Float = 100.0

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
  let mut force_replay = false
  let mut pos_x = pos.val.x
  let mut pos_y = pos.val.y
  let kbd = @lunar.get_keyboard_state()
  if kbd.is_pressed(@lunar.SDL_SCANCODE_Q) {
    @lunar.log("Quit game")
    @lunar.kill()
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_W) {
    @lunar.log("pressed: W/up")
    pos_y -= velocity * @lunar.delta_seconds()
    animation.val = "player_up"
    flip_h.val = false
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_S) {
    @lunar.log("pressed: S/down")
    pos_y += velocity * @lunar.delta_seconds()
    animation.val = "player_down"
    flip_h.val = false
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_D) {
    @lunar.log("pressed: D/right")
    pos_x += velocity * @lunar.delta_seconds()
    animation.val = "player_left_right"
    flip_h.val = true
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_A) {
    @lunar.log("pressed: A/left")
    pos_x -= velocity * @lunar.delta_seconds()
    animation.val = "player_left_right"
    flip_h.val = false
    force_replay = true
  }
  pos.val = @lunar.Point::new(pos_x, pos_y)
  if force_replay && anim_sys.val.is_over(animation.val).unwrap() {
    let _success = anim_sys.val.reset(animation.val)
    // anim_sys.val.set_stop("player_circle_bg", false)
  }
  anim_sys.val.update(@lunar.delta_seconds())
}

///|
pub fn lunar_draw() -> Unit {
  @lunar.get_renderer().clear(@lunar.Color::rgb(77, 77, 77))
  let batch = @lunar.Batch2D::new()
  let _success = batch.sprite(
    sheet.val.get_sprite_by_name("player").unwrap(),
    @lunar.SpriteOption::new(
      pos=@lunar.Point::new(0, 50),
      tint_color=Some(@lunar.Color::rgb(100, 100, 100)),
      scale=Some(@lunar.Point::new(4, 4)),
    ),
  )
  let _success = batch.sprite(
    anim_sys.val.get_current_frame(animation.val).unwrap(),
    @lunar.SpriteOption::new(
      pos=pos.val,
      flip_h=Some(flip_h.val),
      scale=Some(@lunar.Point::new(5, 5)),
      anchor_point=Some(@lunar.Point::new(0.5, 0.5)),
    ),
  )
  batch.submit()
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
  // let _success = anim_sys.val.set_stop("player_circle_bg", true)
}
