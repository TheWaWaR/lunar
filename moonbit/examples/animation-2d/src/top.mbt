pub fn lunar_init() -> Unit {
  @lunar.log("> moon.init")
}

pub fn lunar_event(_: UInt) -> Unit { }

pub fn lunar_update() -> Unit { }

pub fn lunar_draw() -> Unit { }

pub fn lunar_quit() -> Unit {
  @lunar.log("> moon.quit")
}