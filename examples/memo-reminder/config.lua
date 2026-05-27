-- 备忘录自动化示例 — 全局配置
-- 文档: https://jonathanbasta7029.github.io/docs/

return {
  -- YKEngine 本机地址；也可通过环境变量 BASE_URL 覆盖
  baseUrl = os.getenv("BASE_URL") or "http://127.0.0.1:65322",

  -- 目标 App：iOS 自带「备忘录」
  bundleId = "com.apple.mobilenotes",

  -- prefs 命名空间，避免与其他脚本冲突（见模块 19）
  prefsNamespace = "memo_reminder.demo",

  -- 运行日志文件（设备本地绝对路径，见模块 13）
  logPath = "/var/mobile/Library/YKApp/Script/memo-reminder/run.log",

  -- 元素查找默认深度（见模块 08）
  elementMaxDepth = 10,

  -- 各步骤超时（毫秒）
  timeouts = {
    appLaunch = 8000,
    elementWait = 5000,
    betweenSteps = 600,
  },

  -- UI 文案匹配；不同 iOS 语言/版本可能需要调整
  selectors = {
    composeButton = { labelContains = "新建" },
    composeButtonEn = { labelContains = "New" },
    titleField = { type = "TextField" },
    bodyField = { type = "TextField", focused = true },
  },
}
