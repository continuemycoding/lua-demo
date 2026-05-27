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

return root
