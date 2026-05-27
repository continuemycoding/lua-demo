-- 核心自动化流程：打开备忘录 → 新建 → 写入 → 保存进度

local App = require("app")
local Element = require("element")
local Prefs = require("prefs")
local Ui = require("ui")
local Utils = require("utils")

local Task = {}

local function pickTemplate(templates, lastIndex)
  if #templates == 0 then
    return nil, "没有可用模板"
  end
  local nextIndex = ((lastIndex or 0) % #templates) + 1
  return templates[nextIndex], nextIndex
end

function Task.run(client, config, templates)
  Utils.ensureLogDir(client, config.logPath)
  Utils.log(client, config.logPath, "任务开始")

  local lastIndex = Prefs.get(client, config.prefsNamespace, "lastTemplateIndex", 0) or 0
  local template, templateIndex = pickTemplate(templates, lastIndex)
  if not template then
    return false, templateIndex
  end

  Ui.toast(client, "准备打开备忘录…")
  Utils.log(client, config.logPath, "启动 App: " .. config.bundleId)

  local ok, err = App.launch(client, config.bundleId, config.timeouts.appLaunch)
  if not ok then
    Ui.toast(client, "启动失败: " .. tostring(err))
    return false, err
  end
  Utils.sleep(config.timeouts.betweenSteps)

  -- 解锁屏幕后若仍在列表页，点「新建」
  Ui.toast(client, "查找新建按钮…")
  local clicked, clickErr = Element.clickFirstMatching(client, config, {
    config.selectors.composeButton,
    config.selectors.composeButtonEn,
    { labelContains = "撰写" },
    { labelContains = "Compose" },
  })
  if not clicked then
    Utils.log(client, config.logPath, "新建按钮未找到: " .. tostring(clickErr))
    Ui.toast(client, "未找到新建按钮，请检查 selectors")
    return false, clickErr
  end
  Utils.sleep(config.timeouts.betweenSteps)

  -- 输入标题
  Ui.toast(client, "写入标题…")
  local titleOk = Element.input(client, config, config.selectors.titleField, template.title, {
    clearBeforeInput = true,
  })
  if not titleOk then
    -- 部分版本标题与正文在同一 TextField，退化为直接输入全文
    Utils.log(client, config.logPath, "标题输入框未命中，尝试写入正文区")
  else
    Utils.sleep(300)
    Element.input(client, config, config.selectors.bodyField, template.body, {
      append = false,
    })
  end

  if not titleOk then
    local fullText = template.title .. "\n\n" .. template.body
    Element.input(client, config, { type = "TextField" }, fullText, {
      clearBeforeInput = true,
    })
  end

  Utils.sleep(config.timeouts.betweenSteps)

  -- 保存运行进度
  local runCount = Prefs.incrementRunCount(client, config.prefsNamespace)
  Prefs.set(client, config.prefsNamespace, "lastTemplateIndex", templateIndex)
  Prefs.set(client, config.prefsNamespace, "lastMemoId", template.id)

  Utils.log(client, config.logPath, string.format(
    "完成 template=%s index=%d runCount=%d",
    template.id,
    templateIndex,
    runCount
  ))

  Ui.toast(client, string.format("已创建「%s」(#%d)", template.title, runCount), 2500)
  return true, nil
end

return Task
