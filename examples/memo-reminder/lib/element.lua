-- 元素查找与操作封装（模块 08）

local Element = {}

local function mergeOptions(config, extra)
  local options = { maxDepth = config.elementMaxDepth }
  if extra then
    for k, v in pairs(extra) do
      options[k] = v
    end
  end
  return options
end

function Element.waitFor(client, config, query, timeoutMs, expectPresent)
  local res, err = client:post("/element/waitFor", {
    query = query,
    options = mergeOptions(config),
    timeoutMs = timeoutMs or config.timeouts.elementWait,
    expectPresent = expectPresent ~= false,
  })
  if not res or not res.value or not res.value.found then
    return nil, err or "元素未出现"
  end
  return res.value.element, nil
end

function Element.click(client, config, query)
  local res, err = client:post("/element/click", {
    query = query,
    options = mergeOptions(config),
  })
  if not res or not res.value then
    return false, err or "点击失败"
  end
  return true, nil
end

function Element.input(client, config, query, text, opts)
  opts = opts or {}
  local res, err = client:post("/element/input", {
    query = query,
    text = text,
    options = mergeOptions(config, opts.options),
    clearBeforeInput = opts.clearBeforeInput ~= false,
    append = opts.append or false,
    submit = opts.submit or false,
  })
  if not res or not res.value then
    return false, err or "输入失败"
  end
  return true, nil
end

function Element.clickFirstMatching(client, config, queries)
  for _, query in ipairs(queries) do
    local ok = Element.click(client, config, query)
    if ok then
      return true, query
    end
  end
  return false, "未找到可点击元素"
end

return Element
