-- 用户配置数据封装（模块 19）

local Prefs = {}

function Prefs.get(client, namespace, key, defaultValue)
  local res = client:post("/prefs/get", {
    namespace = namespace,
    key = key,
    defaultValue = defaultValue,
  })
  return res and res.value
end

function Prefs.set(client, namespace, key, value)
  client:post("/prefs/set", {
    namespace = namespace,
    key = key,
    value = value,
  })
end

function Prefs.incrementRunCount(client, namespace)
  local count = Prefs.get(client, namespace, "runCount", 0) or 0
  Prefs.set(client, namespace, "runCount", count + 1)
  Prefs.set(client, namespace, "lastRunAt", os.date("%Y-%m-%d %H:%M:%S"))
  return count + 1
end

return Prefs
