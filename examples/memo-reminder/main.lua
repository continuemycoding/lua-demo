#!/usr/bin/env lua
-- 备忘录自动化示例 — 入口
-- 部署: 将整个 memo-reminder 目录复制到 /var/mobile/Library/YKApp/Script/
-- 启动: POST /executor/v1/scripts/run { "scriptName": "memo-reminder/main.lua" }
-- 文档: https://jonathanbasta7029.github.io/docs/

require("bootstrap")

local config = require("config")
local YkHttp = require("yk_http")
local Session = require("session")
local Task = require("run_memo_task")
local templates = require("templates")
local Utils = require("utils")

local function main()
  local client = YkHttp.new(config.baseUrl)

  print("[memo-reminder] 检查服务…")
  local health, err = client:get("/health")
  if not health or not health.value or not health.value.ready then
    print("[memo-reminder] 服务不可用: " .. tostring(err))
    os.exit(1)
  end

  local sessionId, sessionErr = Session.create(client, "memo-reminder")
  if not sessionId then
    print("[memo-reminder] Session 创建失败: " .. tostring(sessionErr))
    os.exit(1)
  end
  print("[memo-reminder] Session: " .. sessionId)

  local ok, taskErr = Task.run(client, config, templates)

  Session.close(client, sessionId)

  if not ok then
    print("[memo-reminder] 任务失败: " .. tostring(taskErr))
    os.exit(1)
  end

  print("[memo-reminder] 任务成功 @" .. Utils.now())
  os.exit(0)
end

main()
