#!/bin/bash
# install.sh — 将 ai-configs 部署到当前机器
#
# 做两件事：
# 1. 拼接 AGENTS.md + 适配器特有内容 → 目标配置文件
# 2. 备份已有配置
#
# 用法: ./scripts/install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# --- 工具函数 ---

backup_if_exists() {
    local file="$1"
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        cp "$file" "${file}${BACKUP_SUFFIX}"
        echo "  备份: ${file} → ${file}${BACKUP_SUFFIX}"
    fi
}

extract_adapter_content() {
    # 提取适配器中 AI 读取的部分（<!-- 以下为部署说明 --> 之前的内容）
    # 如果没有分隔线，取全部内容
    local file="$1"
    if grep -q '<!-- 以下为部署说明' "$file" 2>/dev/null; then
        sed '/<!-- 以下为部署说明/,$d' "$file"
    else
        cat "$file"
    fi
}

install_config() {
    local tool_name="$1"
    local adapter_file="$2"
    local target_file="$3"

    echo ""
    echo "[$tool_name]"

    if [ ! -f "$adapter_file" ]; then
        echo "  跳过: 适配器文件不存在 ($adapter_file)"
        return
    fi

    mkdir -p "$(dirname "$target_file")"
    backup_if_exists "$target_file"

    # 拼接: AGENTS.md 内容 + 适配器特有内容（去掉适配器中重复的标题）
    {
        cat "$REPO_DIR/AGENTS.md"
        echo ""
        echo "---"
        echo ""
        # 适配器内容，跳过第一行标题（避免与 AGENTS.md 标题重复）
        extract_adapter_content "$adapter_file" | tail -n +2
    } > "$target_file"

    echo "  安装: $target_file"
}

# --- 主流程 ---

echo "ai-configs 安装脚本"
echo "仓库: $REPO_DIR"
echo "================================"

# Claude Code
install_config "Claude Code" \
    "$REPO_DIR/adapters/claude.md" \
    "$HOME/.claude/CLAUDE.md"

# Gemini CLI
install_config "Gemini CLI" \
    "$REPO_DIR/adapters/gemini.md" \
    "$HOME/.gemini/GEMINI.md"

# Codex — 不需要全局安装，AGENTS.md 直接在项目中生效
echo ""
echo "[Codex]"
echo "  跳过: Codex 直接读取项目中的 AGENTS.md，无需全局安装"

echo ""
echo "================================"
echo "安装完成"
echo ""
echo "下一步:"
echo "  - 检查 ~/.claude/CLAUDE.md 确认内容正确"
echo "  - 修改 AGENTS.md 后重新运行此脚本以更新部署"
echo "  - 运行 ./scripts/uninstall.sh 可恢复原始配置"
