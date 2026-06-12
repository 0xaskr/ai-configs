# AI 工具配置速查

本文件是仓库中所有 AI 编码工具的配置格式速查，供 agent 修改或理解配置时使用。避免幻觉出不存在配置项。

## 工具总览

| 工具 | 配置文件路径 | 格式 | 模型 | 指令入口 |
|------|-------------|------|------|---------|
| Claude Code | `~/.claude/settings.json` | JSON | Claude 系列 | `~/.claude/CLAUDE.md` → `~/.agents/AGENTS.md` |
| Codex | `~/.codex/config.toml` | TOML | GPT-5.5 | 内建 AGENTS.md 读取 |
| OpenCode | `~/.config/opencode/opencode.jsonc` | JSONC | claude-sonnet-4-5 | 内建 AGENTS.md 读取 |
| Gemini CLI | `~/.gemini/settings.json` | JSON | Gemini 系列 | `~/.gemini/GEMINI.md` → `~/.agents/AGENTS.md` |

---

## Claude Code (`settings.json`)

```json
{
  "permissions": {
    "allow": ["Bash(git:*)", "Bash(rg:*)", "WebFetch(domain:github.com)"],
    "deny":  ["Bash(rm -rf:*)", "Read(~/.ssh/**)", "Read(.env)"]
  },
  "enabledPlugins": ["superpowers@claude-plugins-official"],
  "language": "中文",
  "autoDreamEnabled": true,
  "skipDangerousModePermissionPrompt": true,
  "alwaysThinkingEnabled": true,
  "autoMemoryEnabled": true
}
```

| 键 | 类型 | 说明 |
|----|------|------|
| `permissions.allow` | string[] | 允许的工具调用，格式 `ToolName(subcommand:pattern)` |
| `permissions.deny` | string[] | 禁止的工具调用 |
| `enabledPlugins` | string[] | 启用的插件 |
| `language` | string | 界面语言 |
| `autoDreamEnabled` | bool | 自动后台思考 |
| `skipDangerousModePermissionPrompt` | bool | 跳过危险模式确认 |
| `alwaysThinkingEnabled` | bool | 始终启用深度思考 |
| `autoMemoryEnabled` | bool | 自动记忆功能 |

**权限格式**：`ToolName(pattern)` — 如 `Bash(git:*)` 表示允许所有 git 子命令，`Read(~/.ssh/**)` 表示禁止读 SSH 目录。

**本地覆写**：`~/.claude/settings.local.json`，与 `settings.json` 合并且不被 sync。

**Claude 插件缓存**：`~/.claude/plugins/cache/`

---

## Codex (`config.toml`)

```toml
model = "gpt-5.5"
model_reasoning_effort = "xhigh"
plan_mode_reasoning_effort = "medium"
approval_policy = "on-request"
approvals_reviewer = "guardian_subagent"
sandbox_mode = "workspace-write"
web_search = "cached"
personality = "pragmatic"

[features]
memories = true
multi_agent = true
hooks = true
shell_snapshot = true
undo = true
codex_git_commit = false
```

| 键 | 值/选项 | 说明 |
|----|---------|------|
| `model` | 模型 ID | 主模型，当前 `gpt-5.5` |
| `model_reasoning_effort` | `low`/`medium`/`high`/`xhigh` | 推理深度，`xhigh` 最强也最贵 |
| `plan_mode_reasoning_effort` | 同上 | Plan 模式下的推理深度，`medium` 较快 |
| `approval_policy` | `on-request`/`always`/`never` | 工具调用审批策略 |
| `approvals_reviewer` | subagent 名 | 用于审批的 subagent，如 `guardian_subagent` |
| `sandbox_mode` | `workspace-write` | 沙箱模式 |
| `web_search` | `cached`/`enabled`/`disabled` | 网络搜索策略 |
| `personality` | `pragmatic` | 对话风格 |

**规则文件**：`~/.codex/rules/default.rules`，自定义 DSL：

```
prefix_rule("rm -rf", "forbidden", "破坏性操作", parent)
prefix_rule("git push --force", "forbidden", "禁止 force push", parent)
prefix_rule("uv run", "allow", "Python 包运行器", parent)
```

每条规则：`prefix_rule(pattern, decision, justification, owner)`，其中 `decision` 为 `allow`/`forbid`/`ask`。

**不参与 sync 的文件**：`projects.*`、`auth.json`、`history.jsonl`、`*.sqlite`

---

## OpenCode (`opencode.jsonc`)

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"],
  "snapshot": false,
  "autoupdate": false,
  "compaction": {
    "aggressive": false
  },
  "share": false,
  "permission": {
    "bash": "ask",
    "write": "ask"
  }
}
```

| 键 | 说明 |
|----|------|
| `$schema` | JSON Schema URL |
| `model` | 主模型，格式 `provider/model-name` |
| `small_model` | 轻量模型，用于简单任务 |
| `plugin` | 插件列表，格式 `name@git+url` |
| `snapshot` | 启用截图功能 |
| `autoupdate` | 自动更新 |
| `compaction.aggressive` | 激进上下文压缩 |
| `share` | 分享功能 |
| `permission.bash` | bash 权限：`ask`/`allow`/`deny` |
| `permission.write` | 文件写入权限 |

---

## Gemini CLI (`settings.json`)

```json
{
  "mcpServers": {}
}
```

| 键 | 说明 |
|----|------|
| `mcpServers` | MCP 服务器配置 |

**自定义命令**：`~/.gemini/commands/*.toml`

```toml
[command]
description = "命令描述"

[prompt]
content = "提示词内容"
```

**技能目录**：`~/.gemini/skills/`

---

## 常见权限/规则语法对照

| 操作 | Claude (`settings.json`) | Codex (`default.rules`) | OpenCode (`opencode.jsonc`) |
|------|--------------------------|------------------------|----------------------------|
| 允许 git | `Bash(git:*)` | `prefix_rule("git", "allow", ...)` | `"bash": "ask"` |
| 禁止 rm -rf | `deny: ["Bash(rm -rf:*)"]` | `prefix_rule("rm -rf", "forbidden", ...)` | `"bash": "ask"` |
| 读文件 | `Read(allow)` / `Read(deny)` | 无（沙箱控制） | `"write": "ask"` |
| 网络访问 | `WebFetch(domain:xxx)` | `web_search = "cached"` | 无（工具控制） |

---

## 仓库源文件映射

所有工具的配置文件源头都在 `.agents/adapters/` 下，由 `scripts/install.sh` 部署到各工具的全局位置：

| 源文件 | → | 部署目标 |
|--------|---|---------|
| `.agents/AGENTS.md` | → | `~/.agents/AGENTS.md` |
| `.agents/adapters/claude/CLAUDE.md` | → | `~/.claude/CLAUDE.md` |
| `.agents/adapters/claude/settings.json` | → | `~/.claude/settings.json` |
| `.agents/adapters/codex/config.toml` | → | `~/.codex/config.toml` (合并) |
| `.agents/adapters/codex/rules/default.rules` | → | `~/.codex/rules/default.rules` |
| `.agents/adapters/opencode/opencode.jsonc` | → | `~/.config/opencode/opencode.jsonc` |
| `.agents/adapters/gemini.md` | → | `~/.gemini/GEMINI.md` |
