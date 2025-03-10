
pub fn log(content: String) -> Unit {
  let _ = @wasi.stdout.fd_write?([content.to_bytes().to_fixedarray()]).unwrap()
}
