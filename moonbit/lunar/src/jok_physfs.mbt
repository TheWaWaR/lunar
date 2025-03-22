///|
fn physfs_mount_ffi(
  dir_ptr : UInt64,
  dir_len : Int,
  mount_point_ptr : UInt64,
  mount_point_len : Int,
  append : Bool
) -> Bool = "lunar" "physfs_mount"

///|
pub fn physfs_mount(dir : String, mount_point : String, append : Bool) -> Bool {
  let dir_ptr = str2ptr(dir)
  let mount_point_ptr = str2ptr(mount_point)
  physfs_mount_ffi(
    dir_ptr.to_uint64(),
    dir.length(),
    mount_point_ptr.to_uint64(),
    mount_point.length(),
    append,
  )
}
