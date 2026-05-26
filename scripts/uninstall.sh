#!/bin/bash
# uninstall.sh — 移除 ai-configs 部署，恢复备份
#
# 用法: ./scripts/uninstall.sh

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

# 清理 skill 符号链接
echo ""
echo "[Skills]"
for skills_dir in "${SKILL_DIRS[@]}"; do
    if [ -d "$skills_dir" ]; then
        for link in "$skills_dir"/*/; do
            if [ -L "$link" ]; then
                rm -f "$link"
                echo "  删除链接: $link"
            fi
        done
    fi
done

echo ""
echo "================================"
echo "卸载完成"
