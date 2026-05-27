-- 备忘录内容模板

return {
  {
    id = "daily_checklist",
    title = "今日待办",
    body = table.concat({
      "□ 回复重要消息",
      "□ 整理截图与文件",
      "□ 备份脚本配置",
      "",
      "—— 由 memo-reminder 自动生成",
    }, "\n"),
  },
  {
    id = "automation_note",
    title = "自动化记录",
    body = table.concat({
      "脚本: memo-reminder",
      "引擎: YKEngine HTTP API",
      "说明: 演示按文件组织的 Lua 自动化示例",
    }, "\n"),
  },
}
