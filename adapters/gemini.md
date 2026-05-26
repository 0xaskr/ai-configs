# Gemini CLI 适配器

## 加载机制

Gemini CLI 启动时读取项目根目录的 `GEMINI.md`。在每个项目中创建 shim：

```markdown
请阅读 AGENTS.md 获取完整指令。
```

Gemini CLI 也会读取 `~/.gemini/GEMINI.md` 作为全局配置，同样可以设为 shim 指向本仓库的 `AGENTS.md`。

## MCP 服务器配置

在 `~/.gemini/settings.json` 中配置 MCP：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user"]
    }
  }
}
```

## 自定义命令

在项目的 `.gemini/commands/` 目录下创建 TOML 文件定义自定义命令：

```toml
# .gemini/commands/review.toml
name = "review"
description = "按照 AGENTS.md 规范做代码审查"
prompt = """
请按照 AGENTS.md 中的工作风格规范审查当前改动：
1. 变更范围是否超出被要求的层和领域
2. 是否引入了不必要的抽象
3. 是否有可复用的已有模式被忽略
"""
```

## 适用场景

Gemini CLI 适合 CI 自动化和标准化的审查工作流：命令通过 TOML 文件固化，易于在 CI 脚本中直接调用，输出格式一致。
