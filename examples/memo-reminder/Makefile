.PHONY: deps setup path run bundle run-dist

LUA ?= $(shell command -v lua5.5 2>/dev/null || command -v lua 2>/dev/null)
LUAROCKS ?= $(shell command -v luarocks 2>/dev/null)
DEPS_MARKER = lua_modules/share/lua/5.5/socket/http.lua
BUNDLE_OUT = dist/memo-reminder.lua
BUNDLE_LIB = dist/lib/lua/5.5

# 安装本地开发依赖（LuaSocket）
deps: $(DEPS_MARKER)

$(DEPS_MARKER): memo-reminder-dev-0.1.0-1.rockspec
	@if [ -z "$(LUAROCKS)" ]; then \
		echo "未找到 luarocks。请先安装 Lua 5.5 与 Luarocks，例如：brew install lua luarocks"; \
		exit 1; \
	fi
	$(LUAROCKS) install --local --tree lua_modules --only-deps --force memo-reminder-dev-0.1.0-1.rockspec

# 首次 clone 后的快捷入口（安装依赖）
setup: deps

# 打印当前项目的 LUA_PATH / LUA_CPATH
path:
	@luarocks path

# 本地运行（缺依赖时会自动 make deps；需 YKEngine 服务已启动）
run: deps
	@if [ -x ./lua ]; then ./lua main.lua; elif [ -n "$(LUA)" ]; then $(LUA) main.lua; else \
		echo "未找到 lua 解释器。请安装 Lua 5.5，例如：brew install lua"; \
		exit 1; \
	fi

# 打包：业务代码 + LuaSocket 纯 Lua → 单文件；C 扩展复制到 dist/lib/
bundle: deps $(BUNDLE_OUT)

$(BUNDLE_OUT): main.lua tools/bundle.lua
	@mkdir -p dist
	$(LUA) tools/bundle.lua $(BUNDLE_OUT)
	@mkdir -p $(BUNDLE_LIB)/socket $(BUNDLE_LIB)/mime
	cp lua_modules/lib/lua/5.5/socket/core.so $(BUNDLE_LIB)/socket/
	cp lua_modules/lib/lua/5.5/mime/core.so $(BUNDLE_LIB)/mime/
	@chmod +x dist/run.sh
	@echo "bundle ready: dist/run.sh"

# 运行打包产物（clone 后只需 make bundle && make run-dist）
run-dist: bundle
	@./dist/run.sh
