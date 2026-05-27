-- 通用工具

local socket = require("socket")

local Utils = {}

function Utils.sleep(ms)
  socket.sleep(ms / 1000)
end

function Utils.now()
  return os.date("%Y-%m-%d %H:%M:%S")
end

function Utils.log(client, path, line)
  local text = string.format("[%s] %s\n", Utils.now(), line)
  print(text:sub(1, -2))
  client:post("/file/append", {
    path = path,
    data = text,
    encoding = "utf8",
  })
end

function Utils.ensureLogDir(client, logPath)
  local dir = logPath:match("^(.*)/[^/]+$")
  if not dir then
    return
  end
  local exists = client:get("/file/exists", { path = dir })
  if exists and exists.value == false then
    client:post("/file/directory/create", { path = dir })
  end
end

return Utils
