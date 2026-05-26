#!/bin/bash
# uninstall.sh — 移除 ai-configs 部署，恢复备份
#
# 用法: ./scripts/uninstall.sh

set -euo pipefail

TARGETS=(
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.gemini/GEMINI.md"
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

    # 查找最近的备份
    latest_backup=$(ls -t "${target}.bak."* 2>/dev/null | head -1 || true)

    rm "$target"
    echo "  删除: $target"

    if [ -n "$latest_backup" ]; then
        mv "$latest_backup" "$target"
        echo "  恢复: $latest_backup → $target"
    else
        echo "  无备份可恢复"
    fi
done

echo ""
echo "================================"
echo "卸载完成"
