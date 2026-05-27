-- 应用管理封装（模块 03）

local App = {}

function App.ensureFront(client, bundleId, timeoutMs)
  local deadline = os.time() + math.ceil(timeoutMs / 1000)
  while os.time() <= deadline do
    local res = client:get("/app/frontBid")
    if res and res.value == bundleId then
      return true
    end
    require("socket").sleep(0.3)
  end
  return false
end

function App.launch(client, bundleId, timeoutMs)
  local res, err = client:post("/app/run", { bundleId = bundleId })
  if not res or not res.value then
    return false, err or "启动 App 失败"
  end
  if not App.ensureFront(client, bundleId, timeoutMs) then
    return false, "App 未进入前台: " .. bundleId
  end
  return true, nil
end

return App
