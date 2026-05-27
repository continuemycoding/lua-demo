rockspec_format = "3.0"

package = "memo-reminder-dev"
version = "0.1.0-1"

description = {
  summary = "Local dev dependencies for memo-reminder",
  detailed = "Install LuaSocket for running the example on macOS/Linux.",
  homepage = "https://github.com/jonathanbasta7029/docs",
  license = "MIT",
}

source = {
  url = "file://.",
  dir = ".",
}

dependencies = {
  "luasocket >= 3.0",
}

build = {
  type = "none",
}
