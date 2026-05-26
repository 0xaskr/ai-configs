# ai-configs

AI 编码工具的 dotfiles 仓库。

## 理念

就像 dotfiles 统一管理 shell 和编辑器配置，本仓库统一管理所有 AI 编码工具的行为规范。核心是一份工具无关的 `AGENTS.md`，定义跨工具通用的偏好、工作风格和技能注册表。各工具通过各自的 adapter 接入，无需重复维护多份指令。Fork 后按自己的习惯修改 `AGENTS.md` 即可完成定制。

## 三层架构

| 层 | 内容 |
|---|---|
| **Core** | `AGENTS.md` — 工具无关的全局指令，所有工具共用 |
| **Adapter** | `adapters/` — 各工具的接入方式（shim、settings、命令） |
| **Settings** | `settings.local.json` 等 — 项目级权限与运行时配置 |

## 仓库结构

```
ai-configs/
├── AGENTS.md              # 全局指令（核心，给 AI 读）
├── CLAUDE.md              # Claude Code shim → AGENTS.md
├── adapters/
│   ├── claude.md          # Claude Code 适配说明
│   ├── gemini.md          # Gemini CLI 适配说明
│   └── codex.md           # OpenAI Codex 适配说明
├── skills/
│   └── tpu-kernel-perf.md # TPU kernel 性能分析技能
└── docs/                  # 设计文档
```

## 使用方式

1. Fork 本仓库到自己的账号
2. Clone 到本地，例如 `~/dotfiles/ai-configs`
3. 修改 `AGENTS.md`，写入自己的偏好和行为规范
4. 按下表配置各工具的 shim，指向本仓库的 `AGENTS.md`

## 各工具接入方式

| 工具 | 全局入口文件 | 接入方式 |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | shim 文件，内容指向本仓库 `AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` | shim 文件，内容指向本仓库 `AGENTS.md` |
| OpenAI Codex | `AGENTS.md` | 直接读取，无需 shim，开箱即用 |

各工具的详细配置（settings、权限、自定义命令）见 `adapters/` 目录。
