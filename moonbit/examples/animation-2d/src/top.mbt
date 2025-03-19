///|
typealias FrameData = @lunar.FrameData

///|
typealias DrawCmd = @lunar.DrawCmd

///|
typealias CircleCmd = @lunar.CircleCmd

///|
typealias AnimOption = @lunar.AnimOption

///|
typealias AffineTransform = @lunar.AffineTransform

///|
typealias Color = @lunar.Color

///|
typealias Point = @lunar.Point

///|
let sheet : Ref[@lunar.SpriteSheet] = { val: @lunar.SpriteSheet::new(0) }

///|
let anim_sys : Ref[@lunar.AnimationSystem] = {
  val: @lunar.AnimationSystem::new(0),
}

///|
let pos : Ref[Point] = { val: Point::new(200, 200) }

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
  let _success = anim_sys.val.connect_signal()
  sheet.val = @lunar.SpriteSheet::from_pictures_in_dir(
    "2d",
    "images",
    size.width,
    size.height,
  ).unwrap()
  let player = sheet.val.get_sprite_by_name("player").unwrap()
  let _success = anim_sys.val.add_simple(
    "player_left_right",
    [
      player.get_sub_sprite((4.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((5.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((3.0 * 16.0).to_float(), 0, 16, 16).to_data(),
    ][:],
    6,
  )
  let _success = anim_sys.val.add_simple(
    "player_up",
    [
      player.get_sub_sprite((7.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((8.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((6.0 * 16.0).to_float(), 0, 16, 16).to_data(),
    ][:],
    6,
  )
  let _success = anim_sys.val.add_simple(
    "player_down",
    [
      player.get_sub_sprite((1.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((2.0 * 16.0).to_float(), 0, 16, 16).to_data(),
      player.get_sub_sprite((0.0 * 16.0).to_float(), 0, 16, 16).to_data(),
    ][:],
    6,
  )
  let dcmds : UninitializedArray[FrameData] = UninitializedArray::make(20)
  for i in 0..<20 {
    dcmds[i] = DrawCmd(
      DrawCmd::new(
        Circle(
          CircleCmd::new(
            p = Point::new(0, 0),
            radius = (100.0 - i.to_double() * 10.0).abs().to_float(),
            color = Color::rgb((i * 50 % 255).to_byte(), (i * 50 % 255).to_byte(), 0),
            num_segments = 50,
            thickness = 6.0,
          ),
        ),
        0.5,
      ),
    )
  }
  let _success = anim_sys.val.add_simple(
    "player_circle_bg",
    dcmds[:],
    10,
    opt=AnimOption::new(is_loop=true),
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
    return
  }
  let mut force_replay = false
  let mut pos_x = pos.val.x
  let mut pos_y = pos.val.y
  if kbd.is_pressed(@lunar.SDL_SCANCODE_W) {
    pos_y -= velocity * @lunar.delta_seconds()
    animation.val = "player_up"
    flip_h.val = false
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_S) {
    pos_y += velocity * @lunar.delta_seconds()
    animation.val = "player_down"
    flip_h.val = false
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_D) {
    pos_x += velocity * @lunar.delta_seconds()
    animation.val = "player_left_right"
    flip_h.val = true
    force_replay = true
  } else if kbd.is_pressed(@lunar.SDL_SCANCODE_A) {
    pos_x -= velocity * @lunar.delta_seconds()
    animation.val = "player_left_right"
    flip_h.val = false
    force_replay = true
  }
  pos.val = Point::new(pos_x, pos_y)
  if force_replay && anim_sys.val.is_over(animation.val).unwrap() {
    let _success = anim_sys.val.reset(animation.val)
    let _success = anim_sys.val.set_stop("player_circle_bg", false)

  }
  anim_sys.val.update(@lunar.delta_seconds())
}

///|
pub fn lunar_draw() -> Unit {
  @lunar.get_renderer().clear(Color::rgb(77, 77, 77))
  @lunar.display_stats()
  let batch = @lunar.Batch2D::new()
  let _success = batch.sprite(
    sheet.val.get_sprite_by_name("player").unwrap(),
    @lunar.SpriteOption::new(
      pos=Point::new(0, 50),
      tint_color=Some(Color::rgb(100, 100, 100)),
      scale=Some(Point::new(4, 4)),
    ),
  )
  if anim_sys.val.is_stopped("player_circle_bg").unwrap() {
    @lunar.log("push dcmd")
    let _success = batch.push_transform()
    let trs = AffineTransform::init().translate(pos.val)
    batch.set_transform(trs)
    let cmd = anim_sys.val.get_current_frame("player_circle_bg").unwrap()
    let _success = batch.push_draw_cmd(cmd)
    batch.pop_transform()
  }
  let _success = batch.sprite(
    anim_sys.val.get_current_frame(animation.val).unwrap().get_sprite().unwrap(),
    @lunar.SpriteOption::new(
      pos=pos.val,
      flip_h=Some(flip_h.val),
      scale=Some(Point::new(5, 5)),
      anchor_point=Some(Point::new(0.5, 0.5)),
    ),
  )
  batch.submit()
  @lunar.debug_print(
    "Press W/S/A/D to move character around",
    pos=Point::new(200.0, 0.0),
    color=Color::blue(),
  )
}

///|
pub fn lunar_quit() -> Unit {
  @lunar.log("> moon.quit")
}

///| Receive AnimationSystem signal callback
pub fn lunar_signal() -> Unit {
  @lunar.log("signal, setStop(player_circle_bg, true)")
  let _success = anim_sys.val.set_stop("player_circle_bg", true)

}
