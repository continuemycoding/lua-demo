-- 设置模块搜索路径
local function scriptRoot()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return src:match("^(.*)/[^/]+$") or "."
end

local root = scriptRoot()
package.path = table.concat({
  root .. "/?.lua",
  root .. "/lib/?.lua",
  root .. "/tasks/?.lua",
  root .. "/data/?.lua",
  package.path,
}, ";")

return root
