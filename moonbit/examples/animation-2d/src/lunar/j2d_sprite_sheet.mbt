///|
pub struct SpriteSheet {
  inner : UInt64
}

///|
pub fn SpriteSheet::new(inner : UInt64) -> SpriteSheet {
  { inner, }
}

///|
fn sprite_sheet_from_pictures_in_dir_ffi(
  name_ptr: Int,
  name_len: Int,
  dir_ptr : Int,
  dir_len : Int,
  width : UInt,
  height : UInt
) -> UInt64 = "lunar" "sprite_sheet_from_pictures_in_dir"

///|
fn get_sprite_by_name_ffi(
  sheet_ptr : UInt64,
  name_ptr : Int,
  name_len : Int,
  sp_ptr : Int
) -> Bool = "lunar" "get_sprite_by_name"

///|
pub fn SpriteSheet::from_pictures_in_dir(
  name: String,
  dir : String,
  width : UInt,
  height : UInt
) -> SpriteSheet? {
  let inner = sprite_sheet_from_pictures_in_dir_ffi(
    str2ptr(name),
    name.length(),
    str2ptr(dir),
    dir.length(),
    width,
    height,
  )
  if inner > 0 {
    Some({ inner, })
  } else {
    None
  }
}

///|
pub fn SpriteSheet::get_sprite_by_name(
  self : SpriteSheet,
  name : String
) -> Sprite? {
  let name_ptr = str2ptr(name)
  let sp_ptr = get_global_buf_ptr()
  if get_sprite_by_name_ffi(self.inner, name_ptr, name.length(), sp_ptr) {
    Some(Sprite::readFrom(sp_ptr))
  } else {
    None
  }
}
