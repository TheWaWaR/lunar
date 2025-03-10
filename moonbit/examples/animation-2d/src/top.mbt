pub fn lunar_init() -> Unit {
  println("moon.init")
}

pub fn lunar_event(event_type: UInt) -> Unit {
  println("> moon.event: \{event_type}")
}

pub fn lunar_update() -> Unit {
  println("> moon.update")
}

pub fn lunar_draw() -> Unit {
  println("> moon.draw")
}

pub fn lunar_quit() -> Unit {
  println("> moon.init")
}
