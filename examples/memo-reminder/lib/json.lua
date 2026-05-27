-- 轻量 JSON 编解码（Lua 5.1 + LuaSocket 环境无 cjson 时使用）

local json = {}

local escape_map = {
  ["\\"] = "\\\\",
  ["\""] = "\\\"",
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t",
}

local function escape_str(s)
  return (s:gsub('[\\"\b\f\n\r\t]', escape_map))
end

local function encode_value(v, stack)
  local t = type(v)
  if t == "nil" then
    return "null"
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "number" then
    return tostring(v)
  elseif t == "string" then
    return '"' .. escape_str(v) .. '"'
  elseif t == "table" then
    if stack[v] then
      error("json.encode: circular reference")
    end
    stack[v] = true

    local is_array = #v > 0
    local parts = {}
    if is_array then
      for i = 1, #v do
        parts[#parts + 1] = encode_value(v[i], stack)
      end
      stack[v] = nil
      return "[" .. table.concat(parts, ",") .. "]"
    end

    for k, val in pairs(v) do
      if type(k) == "string" then
        parts[#parts + 1] = '"' .. escape_str(k) .. '":' .. encode_value(val, stack)
      end
    end
    stack[v] = nil
    return "{" .. table.concat(parts, ",") .. "}"
  end
  error("json.encode: unsupported type " .. t)
end

function json.encode(v)
  return encode_value(v, {})
end

-- 简易解码，覆盖 API 常见响应结构即可
local function skip_ws(s, i)
  while true do
    local c = s:sub(i, i)
    if c == "" or not c:match("%s") then
      return i
    end
    i = i + 1
  end
end

local function parse_value(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == "{" then
    local obj = {}
    i = i + 1
    while true do
      i = skip_ws(s, i)
      if s:sub(i, i) == "}" then
        return obj, i + 1
      end
      if s:sub(i, i) ~= '"' then
        error("json.decode: expected string key at " .. i)
      end
      local k
      k, i = parse_value(s, i)
      i = skip_ws(s, i)
      if s:sub(i, i) ~= ":" then
        error("json.decode: expected ':' at " .. i)
      end
      local val
      val, i = parse_value(s, i + 1)
      obj[k] = val
      i = skip_ws(s, i)
      local sep = s:sub(i, i)
      if sep == "}" then
        return obj, i + 1
      elseif sep ~= "," then
        error("json.decode: expected ',' at " .. i)
      end
      i = i + 1
    end
  elseif c == "[" then
    local arr = {}
    i = i + 1
    if s:sub(i, i) == "]" then
      return arr, i + 1
    end
    while true do
      local val
      val, i = parse_value(s, i)
      arr[#arr + 1] = val
      i = skip_ws(s, i)
      local sep = s:sub(i, i)
      if sep == "]" then
        return arr, i + 1
      elseif sep ~= "," then
        error("json.decode: expected ',' at " .. i)
      end
      i = i + 1
    end
  elseif c == '"' then
    local j = i + 1
    local buf = {}
    while j <= #s do
      local ch = s:sub(j, j)
      if ch == '"' then
        return table.concat(buf), j + 1
      elseif ch == "\\" then
        local esc = s:sub(j + 1, j + 1)
        local map = { n = "\n", r = "\r", t = "\t", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\" }
        buf[#buf + 1] = map[esc] or esc
        j = j + 2
      else
        buf[#buf + 1] = ch
        j = j + 1
      end
    end
    error("json.decode: unterminated string")
  elseif c == "t" and s:sub(i, i + 3) == "true" then
    return true, i + 4
  elseif c == "f" and s:sub(i, i + 4) == "false" then
    return false, i + 5
  elseif c == "n" and s:sub(i, i + 3) == "null" then
    return nil, i + 4
  else
    local num = s:match("^%-?%d+%.?%d*[eE%-%+]?%d*", i)
    if num and #num > 0 then
      return tonumber(num), i + #num
    end
    error("json.decode: unexpected token at " .. i)
  end
end

function json.decode(s)
  if not s or s == "" then
    return nil
  end
  local value, rest = parse_value(s, 1)
  rest = skip_ws(s, rest or 1)
  if rest <= #s then
    error("json.decode: trailing characters at " .. rest)
  end
  return value
end

return json
