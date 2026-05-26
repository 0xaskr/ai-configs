# AI Dotfiles 第一阶段实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 ai-configs 仓库重构为 AI dotfiles 架构，建立 AGENTS.md 为核心的三层配置体系。

**Architecture:** AGENTS.md 作为工具无关的全局指令入口，skills/ 存放可复用技能，adapters/ 存放各 AI 工具的适配文件。现有 CLAUDE.md 变为 shim 指向 AGENTS.md。

**Tech Stack:** Markdown, YAML frontmatter, shell

---

### Task 1: 创建目录结构

**Files:**
- Create: `skills/`
- Create: `adapters/`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p skills adapters
```

- [ ] **Step 2: 确认结构**

```bash
ls -la
```

Expected: 看到 `skills/` 和 `adapters/` 目录

---

### Task 2: 编写 AGENTS.md 全局指令

**Files:**
- Create: `AGENTS.md`

这是整个仓库的核心文件。内容基于用户现有的 `~/.claude/CLAUDE.md` 和 `pallas-kernel/AGENTS.md` 的模式提炼。

- [ ] **Step 1: 创建 AGENTS.md**

```markdown
# 全局指令

这是所有 AI 编码工具的通用指令。各工具通过各自的适配文件（adapters/）加载本文件。

## 偏好

- 使用中文交流
- 回答简洁直接，不废话
- 不过度工程，YAGNI
- 不主动创建不必要的文件

## 通知协议

整个回答过程中 `notify-send` 命令只允许调用**一次**，且必须是**最后一个工具调用**。中间步骤绝对不要调用 `notify-send`。

- **Sub-agent 禁止通知**：被 Agent 工具派发的子代理，绝对不要调用 `notify-send`。通知只由最外层主对话负责。
- **完成通知**：完成所有工作、准备停止响应时，最后调用一次 `notify-send '简短总结'`。总结 20 个中文字以内。
- **等待确认通知**：调用 AskUserQuestion 等需要用户输入的工具时，紧接着调用一次 `notify-send '需要你确认'`，然后停止。

## 版本控制规则

- 不主动 commit / push，除非用户明确要求
- 不 revert 用户的修改，除非用户明确要求
- 不使用 --force 或 --no-verify

## 项目上下文协议

进入一个新项目时，按以下顺序了解上下文：

1. 读 AGENTS.md（或 CLAUDE.md / GEMINI.md，它们会指向 AGENTS.md）
2. 读 ARCHITECTURE.md（如果存在）
3. 读 README.md
4. 按需深入 docs/

先看地图，再看细节。不要在不了解项目结构的情况下直接改代码。

## 技能注册表

可用的自定义技能在 `skills/` 目录下。当前可用：

| 技能 | 触发场景 |
|------|---------|
| [tpu-kernel-perf](skills/tpu-kernel-perf.md) | 分析 TPU kernel 性能、计算 Gold Time / Hardware Theoretical Time、分析 LLO dump |

## 设计文档驱动

对于较大的改动（新功能、架构变更、新 kernel），先写设计文档，获得认可后再实现。不要直接开始写代码。
```

- [ ] **Step 2: 确认文件创建成功**

```bash
wc -l AGENTS.md
```

Expected: 约 50 行

---

### Task 3: 迁移 Skill 到 skills/ 目录

**Files:**
- Move: `SKILL.zh.md` → `skills/tpu-kernel-perf.md`

- [ ] **Step 1: 移动文件**

```bash
mv SKILL.zh.md skills/tpu-kernel-perf.md
```

- [ ] **Step 2: 确认**

```bash
ls skills/
```

Expected: `tpu-kernel-perf.md`

---

### Task 4: 创建 Claude 适配器

**Files:**
- Create: `adapters/claude.md`

从现有的 CLAUDE.md 内容提炼。Claude 特有的内容：superpowers 插件、Claude Code 特定的工具调用方式。

- [ ] **Step 1: 创建 adapters/claude.md**

```markdown
# Claude Code 适配

本文件是 Claude Code 的适配层。核心指令见项目根目录的 `AGENTS.md`。

## 加载方式

Claude Code 自动读取项目根目录的 `CLAUDE.md`。`CLAUDE.md` 应作为 shim 指向 `AGENTS.md`：

```
# 全局指令

本文件是 Claude Code 的自动加载入口。完整指令见 `AGENTS.md`。
```

## Claude 特有配置

### superpowers 插件

启用 superpowers 插件以获得 brainstorming、TDD、plan 等工作流技能。

在 `~/.claude/settings.json` 中配置：

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  }
}
```

### 推荐 settings.json

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

### 项目级权限示例

在项目的 `.claude/settings.local.json` 中按需添加：

```json
{
  "permissions": {
    "allow": [
      "Bash(uv run:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(gh:*)"
    ]
  }
}
```
```

---

### Task 5: 创建 Gemini 适配器

**Files:**
- Create: `adapters/gemini.md`

- [ ] **Step 1: 创建 adapters/gemini.md**

```markdown
# Gemini CLI 适配

本文件是 Gemini CLI 的适配层。核心指令见项目根目录的 `AGENTS.md`。

## 加载方式

Gemini CLI 读取 `GEMINI.md`。在项目根目录创建 `GEMINI.md` 作为 shim：

```
请阅读 `AGENTS.md` 获取完整的项目指令和工作规则。
```

## Gemini 特有配置

### 自定义 Commands

Gemini CLI 支持 `.gemini/commands/` 下的 TOML 命令文件。适合用于 CI 自动化和标准化审查流程。

示例 command 结构：

```toml
[command]
description = "Review a pull request"

[prompt]
content = """
你是一个代码审查助手。请阅读 AGENTS.md 了解项目规则，然后审查当前的 PR 变更。
"""
```

### MCP Server 配置

在 `.gemini/settings.json` 中配置 MCP server：

```json
{
  "mcpServers": {
    "docs": {
      "url": "https://example.com/mcp"
    }
  }
}
```
```

---

### Task 6: 创建 Codex 适配器

**Files:**
- Create: `adapters/codex.md`

- [ ] **Step 1: 创建 adapters/codex.md**

```markdown
# OpenAI Codex 适配

本文件是 OpenAI Codex CLI 的适配层。核心指令见项目根目录的 `AGENTS.md`。

## 加载方式

Codex CLI 直接读取项目根目录的 `AGENTS.md`，无需额外 shim 文件。

## Codex 特有配置

### instructions.md

Codex 支持项目级的 `codex/instructions.md`。如果项目同时使用 Codex 和其他工具，可在此文件中引用 AGENTS.md：

```
请阅读 `AGENTS.md` 获取完整的项目指令。
```

### 沙箱模式

Codex 默认在沙箱中运行。网络访问和文件系统权限需要在启动时通过参数配置，不同于 Claude Code 的 settings.json 方式。
```

---

### Task 7: 更新 CLAUDE.md 为 shim

**Files:**
- Modify: `CLAUDE.md`

将现有的 CLAUDE.md（包含完整 notify-send 规则）改为 shim，因为这些规则已移入 AGENTS.md。

- [ ] **Step 1: 更新 CLAUDE.md**

```markdown
# 全局指令

本文件是 Claude Code 的自动加载入口。完整指令见 `AGENTS.md`。
```

---

### Task 8: 编写 README.md

**Files:**
- Create: `README.md`

面向人类的仓库说明，用于开源分享。

- [ ] **Step 1: 创建 README.md**

```markdown
# ai-configs

AI 编码工具的 dotfiles 仓库 — 一个用户下所有 AI 的统一配置中心。

## 理念

就像 dotfiles 管理 shell 和编辑器的配置，ai-configs 管理 Claude Code、Gemini CLI、Codex、DeepSeek 等 AI 编码工具的配置。

核心原则：

- **工具无关** — 指令写在 `AGENTS.md` 中，不绑定特定 AI 工具
- **单一真相源** — 每条规则只在一个地方定义，各工具通过适配器接入
- **可分享** — fork 后修改 `AGENTS.md` 即可适配你自己的偏好

## 结构

```
AGENTS.md          # 全局 agent 指令（所有 AI 通用）
skills/            # 可复用的自定义技能
adapters/          # 各 AI 工具的适配文件
  claude.md        # Claude Code 适配
  gemini.md        # Gemini CLI 适配
  codex.md         # OpenAI Codex 适配
```

## 使用方式

1. Fork 本仓库
2. 修改 `AGENTS.md` 为你自己的偏好和规则
3. 在 `skills/` 中添加你的自定义技能
4. 在各项目中创建 shim 文件指向 `AGENTS.md`

## 各工具接入

| 工具 | 接入方式 |
|------|---------|
| Claude Code | `CLAUDE.md` 作为 shim → `AGENTS.md` |
| Gemini CLI | `GEMINI.md` 作为 shim → `AGENTS.md` |
| Codex | 直接读取 `AGENTS.md` |

详见 `adapters/` 目录下各工具的适配说明。
```

---

### Task 9: 清理和提交

**Files:**
- Delete: `settings.local.json`（根目录的，已不需要）

- [ ] **Step 1: 删除根目录的 settings.local.json**

这个文件包含 Claude 权限配置，属于 Settings Layer，不应在仓库根目录。已有 `.claude/settings.local.json` 提供项目级权限。

```bash
rm settings.local.json
```

- [ ] **Step 2: 确认最终结构**

```bash
find . -not -path './.git/*' -not -path './.claude/*' -type f | sort
```

Expected:
```
./AGENTS.md
./CLAUDE.md
./README.md
./adapters/claude.md
./adapters/codex.md
./adapters/gemini.md
./docs/superpowers/specs/2026-05-26-ai-dotfiles-design.md
./skills/tpu-kernel-perf.md
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "refactor: restructure as AI dotfiles repository

- Add AGENTS.md as tool-agnostic global agent instructions
- Move SKILL.zh.md to skills/tpu-kernel-perf.md
- Add adapters for Claude, Gemini, and Codex
- Convert CLAUDE.md to shim pointing to AGENTS.md
- Add README.md for open-source sharing"
```
