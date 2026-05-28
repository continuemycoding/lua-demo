-- 设置模块搜索路径
local function scriptRoot()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return src:match("^(.*)/[^/]+$") or "."
end

local root = scriptRoot()
local lua_version = _VERSION:match("%d+%.%d+") or "5.5"
local luarocks_root = root .. "/lua_modules"

-- luarocks 本地依赖（luasocket 等），见 memo-reminder-dev-0.1.0-1.rockspec
local luarocks_path = table.concat({
  luarocks_root .. "/share/lua/" .. lua_version .. "/?.lua",
  luarocks_root .. "/share/lua/" .. lua_version .. "/?/init.lua",
}, ";")
local luarocks_cpath = luarocks_root .. "/lib/lua/" .. lua_version .. "/?.so"

package.path = table.concat({
  root .. "/?.lua",
  root .. "/lib/?.lua",
  root .. "/tasks/?.lua",
  root .. "/data/?.lua",
  luarocks_path,
  package.path,
}, ";")
package.cpath = luarocks_cpath .. ";" .. package.cpath

local function ensure_deps()
  local marker = luarocks_root .. "/share/lua/" .. lua_version .. "/socket/http.lua"
  local f = io.open(marker, "r")
  if f then
    f:close()
    return
  end

  io.stderr:write(table.concat({
    "[memo-reminder] 缺少依赖 LuaSocket（未找到 " .. marker .. "）。",
    "",
    "首次运行请先安装依赖：",
    "  cd examples/memo-reminder",
    "  make deps",
    "",
    "或直接：",
    "  make run",
    "",
  }, "\n"))
  os.exit(1)
end

ensure_deps()

return root
