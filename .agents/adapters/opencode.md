# OpenCode 适配器

OpenCode 读取项目根目录的 `opencode.md` 或 `.opencode/` 目录。

## 全局配置

`~/.config/opencode/opencode.jsonc` 中配置插件和权限：

```jsonc
{
  "plugins": [],
  "permissions": {
    "external_directory": "allow",
    "bash": "allow",
    "edit": "allow",
    "task": "allow",
    "skill": "allow",
    "webfetch": "allow"
  }
}
```

## Skills

在项目 `.opencode/skills/` 或用户 `~/.config/opencode/skills/` 下创建 `SKILL.md` 文件：

```
.opencode/skills/<skill-name>/SKILL.md
```

可用技能见 AGENTS.md 的技能注册表。OpenCode 会自动扫描并加载。

## 说明

OpenCode 支持多 agent 编排（oh-my-openagent 插件），适合需要并发子 agent 协调的复杂任务。
