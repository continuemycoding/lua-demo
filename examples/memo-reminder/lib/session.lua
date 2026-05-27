-- Session 生命周期（模块 01）

local Session = {}

function Session.create(client, name)
  local res, err = client:post("/session/create", {
    name = name or "memo-reminder",
    debugRequestLog = true,
    localControl = { enabled = true },
  })
  if not res then
    return nil, err
  end
  local sessionId = res.value and res.value.sessionId
  if not sessionId then
    return nil, "创建 Session 失败：未返回 sessionId"
  end
  client:setSession(sessionId)
  return sessionId, nil
end

function Session.close(client, sessionId)
  client:setSession(sessionId)
  client:delete("/session", { sessionId = sessionId })
  client:setSession(nil)
end

return Session
