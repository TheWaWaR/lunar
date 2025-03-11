

/// Write content to stdout with a new line
pub fn log(content: String) -> Unit {
  let new_line = "\n"
  for output in [content, new_line] {
   let _ = @wasi.stdout.fd_write?([output.to_bytes().to_fixedarray()]).unwrap() 
  }
}

pub fn get_global_buf_ptr() -> Int {
  malloc(16)
}