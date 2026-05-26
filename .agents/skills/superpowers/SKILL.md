# Skills 系统

确保当前 AI 工具的 skills 系统已激活，使 `skills/` 目录中的技能文件可被自动扫描加载。

## 阶段一：按工具检查并安装

```bash
# Claude Code — 需要 superpowers 插件
(claude plugins list 2>/dev/null | grep -q superpowers) || \
  { echo "请安装: claude plugins install superpowers@claude-plugins-official"; exit 1; }

# Codex — skills 原生支持，`~/.codex/skills/` 或项目 `.codex/skills/` 自动加载
codex --version >/dev/null 2>&1 || true

# OpenCode — skills 原生支持，`~/.config/opencode/skills/` 自动加载
opencode --version >/dev/null 2>&1 || true

# Gemini CLI — skills 原生支持，`~/.gemini/skills/` 自动加载
gemini --version >/dev/null 2>&1 || true
```

## 阶段二：使用

Skills 系统激活后，各工具自动扫描对应 `skills/` 目录的技能文件。AI 按 AGENTS.md 技能注册表中的触发条件匹配加载，无需手动干预。
