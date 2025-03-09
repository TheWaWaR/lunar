pub fn lunar_init(ctx: UInt64) -> Unit {
  println("> moon.init: \{ctx}")
}

pub fn lunar_event(ctx: UInt64, e: UInt64) -> Unit {
  println("> moon.event: \{ctx}, \{e}")
}

pub fn lunar_update(ctx: UInt64) -> Unit {
  println("> moon.update: \{ctx}")
}

pub fn lunar_draw(ctx: UInt64) -> Unit {
  println("> moon.draw: \{ctx}")
}

pub fn lunar_quit(ctx: UInt64) -> Unit {
  println("> moon.init: \{ctx}")
}