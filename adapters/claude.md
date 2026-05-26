# 全局指令

完整指令见 `AGENTS.md`。

## Claude 特有配置

### Skills

Claude Code 通过 superpowers 插件加载技能。可用技能见 `AGENTS.md` 的技能注册表。

新增技能：在 `skills/` 下创建 `.md` 文件，并在 `AGENTS.md` 技能注册表中添加触发条件映射。

---

<!-- 以下为部署说明，供人类参考，Claude Code 可忽略 -->

## 部署说明

本文件由 sync 脚本复制到 `~/.claude/CLAUDE.md`。

### 推荐 settings.json

位于 `~/.claude/settings.json`：

```json
{
  "permissions": {
    "allow": [
      "Bash(notify-send:*)"
    ]
  },
  "model": "opus[1m]",
  "language": "中文",
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  }
}
```

### 项目级权限

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
