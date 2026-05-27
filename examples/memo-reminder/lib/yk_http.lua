-- YKEngine HTTP 客户端（LuaSocket，见模块 20）

local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

local YkHttp = {}
YkHttp.__index = YkHttp

function YkHttp.new(baseUrl)
  return setmetatable({ baseUrl = baseUrl, sessionId = nil }, YkHttp)
end

function YkHttp:setSession(sessionId)
  self.sessionId = sessionId
end

local function urlEncode(str)
  return (tostring(str):gsub("([^%w%-%.%_%~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function buildUrl(base, path, query)
  local url = base .. path
  if query and next(query) then
    local parts = {}
    for k, v in pairs(query) do
      parts[#parts + 1] = urlEncode(k) .. "=" .. urlEncode(v)
    end
    url = url .. "?" .. table.concat(parts, "&")
  end
  return url
end

function YkHttp:request(method, path, opts)
  opts = opts or {}
  local url = buildUrl(self.baseUrl, path, opts.query)
  local headers = {
    ["Accept"] = "application/json",
    ["Content-Type"] = "application/json",
  }
  if self.sessionId then
    headers["X-YK-Session-Id"] = self.sessionId
  end
  if opts.headers then
    for k, v in pairs(opts.headers) do
      headers[k] = v
    end
  end

  local body = opts.body and json.encode(opts.body) or nil
  if body then
    headers["Content-Length"] = tostring(#body)
  end

  local response_chunks = {}
  local status_code
  local ok, err = pcall(function()
    local res_body, code = http.request({
      url = url,
      method = method,
      headers = headers,
      source = body and ltn12.source.string(body) or nil,
      sink = ltn12.sink.table(response_chunks),
    })
    status_code = code
    return res_body
  end)

  if not ok then
    return nil, "HTTP 请求失败: " .. tostring(err)
  end

  local raw = table.concat(response_chunks)
  if status_code ~= 200 then
    return nil, string.format("HTTP %s: %s", tostring(status_code), raw)
  end

  local decoded = json.decode(raw)
  if not decoded then
    return nil, "响应不是合法 JSON: " .. raw
  end

  if decoded.value and type(decoded.value) == "table" and decoded.value.error then
    local msg = decoded.value.message or decoded.value.error
    return nil, msg
  end

  return decoded, nil
end

function YkHttp:get(path, query)
  return self:request("GET", path, { query = query })
end

function YkHttp:post(path, body)
  return self:request("POST", path, { body = body })
end

function YkHttp:delete(path, query)
  return self:request("DELETE", path, { query = query })
end

return YkHttp
