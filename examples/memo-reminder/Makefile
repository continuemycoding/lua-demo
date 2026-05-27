.PHONY: deps path run

# 安装本地开发依赖（LuaSocket）
deps:
	luarocks install --local --tree lua_modules --only-deps --force memo-reminder-dev-0.1.0-1.rockspec

# 打印当前项目的 LUA_PATH / LUA_CPATH
path:
	@luarocks path

# 本地运行（需 YKEngine 服务已启动）
run:
	@if [ -x ./lua ]; then ./lua main.lua; else lua main.lua; fi
