pub fn lunar_init() -> Unit {
  @lib.log("moon.init")
}

pub fn lunar_event(_: UInt) -> Unit { }

pub fn lunar_update() -> Unit {
  @lib.log("> moon.update")
}

pub fn lunar_draw() -> Unit {
  @lib.log("> moon.draw")
}

pub fn lunar_quit() -> Unit {
  @lib.log("> moon.init")
}