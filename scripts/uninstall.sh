#!/bin/bash
# uninstall.sh — 移除 ai-configs 部署，恢复备份
#
# 用法: curl -fsSL ... | bash  或直接在仓库内 ./scripts/uninstall.sh

set -euo pipefail

TARGETS=(
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.gemini/GEMINI.md"
)

SKILL_DIRS=(
    "$HOME/.claude/skills"
    "$HOME/.gemini/skills"
    "$HOME/.config/opencode/skills"
)

echo "ai-configs 卸载脚本"
echo "================================"

for target in "${TARGETS[@]}"; do
    echo ""
    echo "[$(basename "$target")]"

    if [ ! -f "$target" ]; then
        echo "  跳过: 文件不存在"
        continue
    fi

    latest_backup=$(ls -t "${target}.bak."* 2>/dev/null | head -1 || true)

    rm -f "$target"
    echo "  删除: $target"

    if [ -n "$latest_backup" ]; then
        mv "$latest_backup" "$target"
        echo "  恢复: $latest_backup → $target"
    else
        echo "  无备份可恢复"
    fi
done

echo ""
echo "[Skills]"
for skills_dir in "${SKILL_DIRS[@]}"; do
    latest_backup=$(ls -dt "${skills_dir}.bak."* 2>/dev/null | head -1 || true)

    if [ -d "$skills_dir" ]; then
        rm -rf "$skills_dir"
        echo "  删除: $skills_dir"
    fi

    if [ -n "$latest_backup" ]; then
        mv "$latest_backup" "$skills_dir"
        echo "  恢复: $latest_backup → $skills_dir"
    else
        echo "  无备份可恢复: $skills_dir"
    fi
done

echo ""
echo "[.agents]"
latest_backup=$(ls -dt "${HOME}/.agents.bak."* 2>/dev/null | head -1 || true)

if [ -d "$HOME/.agents" ]; then
    rm -rf "$HOME/.agents"
    echo "  删除: $HOME/.agents"
fi

if [ -n "$latest_backup" ]; then
    mv "$latest_backup" "$HOME/.agents"
    echo "  恢复: $latest_backup → $HOME/.agents"
else
    echo "  无备份可恢复: $HOME/.agents"
fi

echo ""
echo "================================"
echo "卸载完成"
