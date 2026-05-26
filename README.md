# ai-configs

AI 编码工具的 dotfiles 仓库。

## 理念

就像 dotfiles 统一管理 shell 和编辑器配置，本仓库统一管理所有 AI 编码工具的行为规范。所有配置集中在 `.agents/` 目录，作为唯一源头。各工具通过安装脚本部署到对应的全局入口文件，无需重复维护多份指令。Fork 后修改 `.agents/AGENTS.md` 即可完成定制。

## 仓库结构

```
ai-configs/
├── .agents/                    # 配置源头（唯一真相来源）
│   ├── AGENTS.md               # 全局指令（核心，给 AI 读）
│   ├── adapters/               # 各工具适配说明
│   │   ├── claude.md
│   │   ├── gemini.md
│   │   └── codex.md
│   ├── skills/                 # 技能文件
│   │   ├── tpu-kernel-perf.md
│   │   ├── kernel-design-review.md
│   │   └── pr-review.md
│   └── commands/               # 自定义命令（待扩展）
├── scripts/
│   ├── install.sh              # 安装脚本
│   └── uninstall.sh            # 卸载脚本
└── docs/                       # 设计文档
```

## 安装

一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/0xaskr/ai-configs/main/scripts/install.sh | bash
```

也可 Fork 后安装自己的仓库：

```bash
curl -fsSL https://raw.githubusercontent.com/<你>/ai-configs/main/scripts/install.sh | bash
```

选项：

| 参数 | 说明 | 默认值 |
|---|---|---|
| `--repo <url>` | 仓库地址 | `https://github.com/0xaskr/ai-configs.git` |
| `--branch <name>` | 分支 | `main` |
| `--dir <path>` | 本地存放路径 | `~/ai-configs` |
| `-y` / `--yes` | 跳过交互确认 | 关闭 |
| `--uninstall` | 卸载并恢复备份 | — |

从仓库内直接运行：

```bash
./scripts/install.sh
```

## 定制

Fork 本仓库后，修改 `.agents/AGENTS.md` 写入自己的偏好，重新运行安装脚本即可生效。

## 各工具接入方式

| 工具 | 全局入口文件 | 接入方式 |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | 重定向到 `.agents/AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` | 重定向到 `.agents/AGENTS.md` |
| OpenAI Codex | 项目内 `AGENTS.md` | 直接读取项目内的 `AGENTS.md`，无需全局安装 |

`.agents/AGENTS.md` 是唯一源头，各工具的全局入口文件是轻量重定向 shim。

各工具的详细配置（settings、权限、自定义命令）见 `.agents/adapters/` 目录。
