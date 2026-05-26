# AI Dotfiles 仓库设计

## 定位

**AI 的 dotfiles 仓库** — 一个用户下所有 AI 编码工具的配置中心。

就像 dotfiles 仓库是 shell/editor 的统一配置源一样，ai-configs 是 Claude Code、Gemini CLI、Codex、DeepSeek 等所有 AI 工具的统一配置源。内容是给 AI 读的，但服务于一个用户的全部 AI 会话。

### 核心原则

1. **工具无关** — 核心指令写在 AGENTS.md 中，不绑定任何特定 AI 工具
2. **单一真相源** — 每条规则只在一个地方定义，各工具通过 adapter 接入
3. **可分享** — 版本控制、可 fork、开源友好

### 不是什么

- 不是面向人类的教程或指南
- 不是项目级配置（那是各项目自己的 AGENTS.md）
- 不是模板生成器

## 架构

### 三层模型

```
┌──────────────────────────────────────────┐
│  Core Layer (工具无关)                     │
│  AGENTS.md — 全局 agent 指令              │
│  skills/   — 可复用技能                    │
│  references/ — AI 可查阅的参考知识          │
└────────────────┬─────────────────────────┘
                 │ import
┌────────────────┴─────────────────────────┐
│  Adapter Layer (工具适配)                   │
│  adapters/claude.md  — shim + 工具特有指令  │
│  adapters/gemini.md  — shim + 工具特有指令  │
│  adapters/codex.md   — 几乎不需要适配       │
└────────────────┬─────────────────────────┘
                 │
┌────────────────┴─────────────────────────┐
│  Settings Layer (工具机械配置)               │
│  各工具的 settings.json / config.toml      │
│  权限、hooks、插件、模型选择                  │
└──────────────────────────────────────────┘
```

### 层级职责

| 层 | 内容 | 谁维护 | 谁读 |
|----|------|--------|-----|
| Core | 通用规则、偏好、技能、参考资料 | 用户 | 所有 AI |
| Adapter | 工具特有指令（notify-send、MCP 配置等） | 用户 | 对应的 AI 工具 |
| Settings | 权限、hooks、插件 | 用户 | 对应的 AI 工具运行时 |

## 仓库结构

```
ai-configs/
├── README.md                  # 面向人类的仓库说明（开源时用）
│
├── AGENTS.md                  # 全局 agent 指令（核心）
│
├── skills/                    # Skill 库
│   ├── tpu-kernel-perf.md     # TPU Kernel 性能分析
│   └── ...                    # 更多 skill
│
├── references/                # AI 可查阅的参考知识
│   └── ...
│
├── adapters/                  # 各工具的适配文件
│   ├── claude.md              # → ~/.claude/CLAUDE.md
│   ├── gemini.md              # → GEMINI.md
│   └── codex.md               # → Codex 说明
│
└── docs/                      # 内部文档（设计决策等）
    └── ...
```

### 使用方式

- `~/.claude/CLAUDE.md` → symlink 或 include `adapters/claude.md`
- `~/.gemini/GEMINI.md` → symlink 或 include `adapters/gemini.md`
- Codex 直接读 AGENTS.md，几乎不需要适配
- 各项目可在自己的 AGENTS.md 中引用本仓库的 skills

## AGENTS.md 内容设计

全局指令的核心文件，所有 AI 工具通过各自的 adapter 加载它。

### 结构

```markdown
# 全局指令

## 身份和偏好
- 使用中文交流
- 回答简洁直接
- 不过度工程

## 工作流规则
- notify-send 协议
- commit / push 行为约束
- 不主动创建不必要的文件

## 技能注册表
- 列出所有可用 skill 及触发条件
- 指向 skills/ 目录

## 项目上下文协议
- 进入新项目时先读 AGENTS.md → ARCHITECTURE.md
- 渐进式披露：先看地图，再看细节
- 设计文档驱动：大改动先写 design doc
```

## Skill 规划

### 已有

| Skill | 用途 |
|-------|-----|
| tpu-kernel-perf | TPU Kernel 性能分析（三层时间模型） |

### 计划中

| Skill | 解决什么问题 | 优先级 |
|-------|------------|--------|
| kernel-design-review | 审查 kernel 设计文档是否符合标准 | 高 |
| pr-review | 标准化 PR review 流程（统一 Gemini 版） | 高 |
| project-bootstrap | 新项目初始化 AI 配置 | 中 |
| perf-regression | 性能回归检测和分析 | 中 |
| architecture-check | 检查代码变更是否符合分层架构约束 | 低 |

### Skill 编写原则

- 写在 `skills/` 目录下，使用 markdown 格式
- 前置 YAML frontmatter 定义 name、description、触发关键词
- 内容面向 AI：清晰的步骤、检查清单、验证方法
- 工具无关：不假设特定 AI 工具的能力

## 多工具策略

### 工具选择决策树

```
场景                          → 推荐工具
深度编码（新 kernel、重构）     → Claude Code（长上下文 + worktree）
CI / 自动化审查                → Gemini CLI（command 机制成熟）
快速问答 / 小修改              → DeepSeek / Copilot
代码补全                       → Copilot（IDE 内嵌）
```

### Adapter 职责

| Adapter | 内容 |
|---------|-----|
| claude.md | import AGENTS.md + notify-send 协议 + superpowers 插件指令 |
| gemini.md | import AGENTS.md + MCP 配置 + command 注册 |
| codex.md | 直接读 AGENTS.md，仅说明差异 |

## 演进计划

### 第一阶段：知识整理

1. 重构仓库结构为上述目录布局
2. 编写 AGENTS.md 全局指令
3. 将现有 SKILL.zh.md 移入 skills/
4. 创建 adapters/ 适配文件

### 第二阶段：Skill 扩展

5. 编写 kernel-design-review skill
6. 统一 PR review skill（合并 Gemini 版）
7. 编写 project-bootstrap skill

### 第三阶段：自动化和分享

8. 编写配置同步脚本
9. 完善 README.md
10. 开源发布
