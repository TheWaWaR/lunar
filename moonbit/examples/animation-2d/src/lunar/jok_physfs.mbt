///|
fn physfs_mount_ffi(
  dir_ptr : Int,
  dir_len : Int,
  mount_point_ptr : Int,
  mount_point_len : Int,
  append : Bool
) -> Bool = "lunar" "physfs_mount"

///|
pub fn physfs_mount(dir : String, mount_point : String, append : Bool) -> Bool {
  let dir_ptr = str2ptr(dir)
  let mount_point_ptr = str2ptr(mount_point)
  physfs_mount_ffi(
    dir_ptr,
    dir.length(),
    mount_point_ptr,
    mount_point.length(),
    append,
  )
}
