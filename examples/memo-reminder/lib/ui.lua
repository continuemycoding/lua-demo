-- 悬浮 UI 封装（模块 16）

local Ui = {}

function Ui.toast(client, message, durationMs)
  client:post("/ui/toast", {
    message = message,
    durationMs = durationMs or 2000,
  })
end

return Ui
