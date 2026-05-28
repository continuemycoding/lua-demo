#!/usr/bin/env lua
-- 将项目与 LuaSocket 纯 Lua 部分打包为单文件（C 扩展需单独复制 .so）

local function script_root()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return src:match("^(.*)/[^/]+$") or "."
end

local ROOT = script_root() .. "/.."
local OUT = arg[1] or (ROOT .. "/dist/memo-reminder.lua")
local LUA_VERSION = _VERSION:match("%d+%.%d+") or "5.5"
local LUAROCKS_ROOT = ROOT .. "/lua_modules"

local C_MODULES = {
  ["socket.core"] = true,
  ["mime.core"] = true,
  ["socket.serial"] = true,
  ["socket.unix"] = true,
}

local STDLIB = {
  ["string"] = true,
  ["table"] = true,
  ["math"] = true,
  ["io"] = true,
  ["os"] = true,
  ["debug"] = true,
  ["coroutine"] = true,
  ["package"] = true,
  ["utf8"] = true,
  ["ssl.https"] = true,
}

local bundled = {}
local order = {}

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    return nil, err
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function search_paths(name)
  local paths = {}
  local dotted = name:gsub("%.", "/")

  if not name:find(".", 1, true) then
    paths[#paths + 1] = ROOT .. "/lib/" .. name .. ".lua"
    paths[#paths + 1] = ROOT .. "/tasks/" .. name .. ".lua"
    paths[#paths + 1] = ROOT .. "/data/" .. name .. ".lua"
    paths[#paths + 1] = ROOT .. "/" .. name .. ".lua"
  end

  paths[#paths + 1] = ROOT .. "/lib/" .. dotted .. ".lua"
  paths[#paths + 1] = ROOT .. "/tasks/" .. dotted .. ".lua"
  paths[#paths + 1] = ROOT .. "/data/" .. dotted .. ".lua"
  paths[#paths + 1] = ROOT .. "/" .. dotted .. ".lua"
  paths[#paths + 1] = LUAROCKS_ROOT .. "/share/lua/" .. LUA_VERSION .. "/" .. dotted .. ".lua"
  paths[#paths + 1] = LUAROCKS_ROOT .. "/share/lua/" .. LUA_VERSION .. "/" .. dotted .. "/init.lua"

  return paths
end

local function resolve_module(name)
  for _, path in ipairs(search_paths(name)) do
    if exists(path) then
      return path
    end
  end
  return nil
end

local function extract_requires(source)
  local names = {}
  for req in source:gmatch('require%(%s*["\']([^"\']+)["\']%s*%)') do
    names[#names + 1] = req
  end
  return names
end

local function bundle_module(name)
  if C_MODULES[name] or STDLIB[name] or bundled[name] then
    return
  end

  local path = resolve_module(name)
  if not path then
    if name == "bootstrap" then
      bundled[name] = "-- bootstrap inlined by bundler"
      order[#order + 1] = name
      return
    end
    io.stderr:write("warning: module not found, leave as runtime require: " .. name .. "\n")
    return
  end

  local source, err = read_file(path)
  if not source then
    error("read " .. path .. ": " .. tostring(err))
  end

  bundled[name] = source
  order[#order + 1] = name

  for _, dep in ipairs(extract_requires(source)) do
    bundle_module(dep)
  end
end

local function escape_lua_string(s)
  return string.format("%q", s)
end

local function emit_modules()
  local parts = { "local __modules = {}\n" }
  for _, name in ipairs(order) do
    local source = bundled[name]
    parts[#parts + 1] = string.format(
      "__modules[%s] = function()\n%s\nend\n\n",
      escape_lua_string(name),
      source
    )
  end
  return table.concat(parts)
end

local function emit_loader()
  return [[
local __orig_require = require
local function __bundle_require(name)
  local loader = __modules[name]
  if loader then
    local mod = package.loaded[name]
    if mod ~= nil then
      return mod
    end
    mod = loader() or true
    package.loaded[name] = mod
    return mod
  end
  return __orig_require(name)
end
require = __bundle_require

local function __bundle_root()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return src:match("^(.*)/[^/]+$") or "."
end

local __root = __bundle_root()
package.path = table.concat({
  __root .. "/?.lua",
  __root .. "/?/init.lua",
  package.path,
}, ";")
package.cpath = table.concat({
  __root .. "/lib/lua/]] .. LUA_VERSION .. [[/?.so",
  __root .. "/lib/lua/]] .. LUA_VERSION .. [[/socket/?.so",
  __root .. "/lib/lua/]] .. LUA_VERSION .. [[/mime/?.so",
  package.cpath,
}, ";")

]]
end

local function emit_main()
  local main_path = ROOT .. "/main.lua"
  local main, err = read_file(main_path)
  if not main then
    error("read main.lua: " .. tostring(err))
  end
  main = main:gsub('require%(%s*["\']bootstrap["\']%s*%)', "-- bootstrap inlined")
  main = main:gsub("^#![^\n]*\n", "")
  return main
end

local marker = LUAROCKS_ROOT .. "/share/lua/" .. LUA_VERSION .. "/socket/http.lua"
if not exists(marker) then
  io.stderr:write(table.concat({
    "缺少 LuaSocket，请先运行：",
    "  make deps",
    "",
  }, "\n"))
  os.exit(1)
end

local main_path = ROOT .. "/main.lua"
local main_source, main_err = read_file(main_path)
if not main_source then
  error("read main.lua: " .. tostring(main_err))
end

for _, dep in ipairs(extract_requires(main_source)) do
  if dep ~= "bootstrap" then
    bundle_module(dep)
  end
end

local out_dir = OUT:match("^(.*)/[^/]+$")
if out_dir then
  os.execute("mkdir -p " .. out_dir)
end

local output = table.concat({
  "-- generated by tools/bundle.lua; do not edit\n",
  emit_modules(),
  emit_loader(),
  emit_main(),
  "\n",
})

local f, err = io.open(OUT, "wb")
if not f then
  error("write " .. OUT .. ": " .. tostring(err))
end
f:write(output)
f:close()

print("wrote " .. OUT)
print("modules: " .. table.concat(order, ", "))
