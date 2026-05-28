#!/bin/sh
set -e
cd "$(dirname "$0")"
LUA="${LUA:-$(command -v lua5.5 2>/dev/null || command -v lua 2>/dev/null)}"
if [ -z "$LUA" ]; then
  echo "未找到 lua 解释器。请安装 Lua 5.5，例如：brew install lua"
  exit 1
fi
exec "$LUA" memo-reminder.lua "$@"
