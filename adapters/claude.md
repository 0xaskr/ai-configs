# Claude Code 适配器

## 加载机制

Claude Code 启动时自动读取项目根目录的 `CLAUDE.md`。在每个项目中创建一个 shim，将控制权交给本仓库的 `AGENTS.md`：

```markdown
# 全局指令

本文件是 Claude Code 的自动加载入口。完整指令见 `AGENTS.md`。
```

全局配置同理，`~/.claude/CLAUDE.md` 也可以是一个 shim：

```markdown
# 全局指令

本文件是 Claude Code 的全局入口。完整指令见 ~/dotfiles/ai-configs/AGENTS.md。
```

## 推荐 settings.json

位于 `~/.claude/settings.json`：

```json
{
  "model": "claude-opus-4-5-20251101",
  "contextWindow": "1m",
  "language": "zh-CN",
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  },
  "permissions": {
    "allow": [
      "Bash(notify-send:*)"
    ]
  }
}
```

## 项目级权限

在各项目的 `.claude/settings.local.json` 中按需放开：

```json
{
  "permissions": {
    "allow": [
      "Bash(uv run:*)",
      "Bash(git:*)",
      "Bash(gh:*)"
    ]
  }
}
```

## Skills

Claude Code 通过 superpowers 插件支持从 `skills/` 目录加载技能文件。技能在 `AGENTS.md` 的技能注册表中登记，触发条件匹配时由 AI 主动读取对应的 `skills/*.md`。

新增技能步骤：
1. 在 `skills/` 下创建 `skill-name.md`
2. 在 `AGENTS.md` 的技能注册表中添加一行触发条件映射
