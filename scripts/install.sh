#!/usr/bin/env bash
# ai-configs 一键安装脚本
#
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/0xaskr/ai-configs/main/scripts/install.sh | bash
#
#   也支持从仓库内直接运行：
#   ./scripts/install.sh
#
set -euo pipefail

# ── 默认值 ───────────────────────────────────────────────────────────
REPO_URL="${AI_CONFIGS_REPO:-https://github.com/0xaskr/ai-configs.git}"
BRANCH="${AI_CONFIGS_BRANCH:-main}"
INSTALL_DIR="${AI_CONFIGS_DIR:-$HOME/ai-configs}"
YES="${AI_CONFIGS_YES:-0}"

# ── 颜色 ─────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD="\033[1m"; DIM="\033[2m"
  GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"
  CYAN="\033[36m"; MAGENTA="\033[35m"
  RESET="\033[0m"
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; CYAN=""; MAGENTA=""; RESET=""
fi

info()  { printf "  ${CYAN}▸${RESET} %b\n" "$*"; }
ok()    { printf "  ${GREEN}✓${RESET} %b\n" "$*"; }
warn()  { printf "  ${YELLOW}!${RESET} %b\n" "$*"; }
fail()  { printf "  ${RED}✗${RESET} %b\n" "$*" >&2; exit 1; }

# ── 参数解析 ─────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)   REPO_URL="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --dir)    INSTALL_DIR="$2"; shift 2 ;;
    -y|--yes) YES=1; shift ;;
    --uninstall)
      # 路由到卸载
      if [ -f "$INSTALL_DIR/scripts/uninstall.sh" ]; then
        bash "$INSTALL_DIR/scripts/uninstall.sh"
        exit $?
      fi
      exec bash <(curl -fsSL "https://raw.githubusercontent.com/0xaskr/ai-configs/${BRANCH}/scripts/uninstall.sh")
      ;;
    *) shift ;;
  esac
done

# ── 检测是否已在仓库内 ───────────────────────────────────────────────
in_repo() {
  local d="${1:-$(pwd)}"
  [ -f "$d/.agents/AGENTS.md" ] && [ -d "$d/.agents/adapters" ]
}

# ── 第一阶段：获取仓库 ───────────────────────────────────────────────
acquire_repo() {
  if in_repo "$(pwd)"; then
    REPO_DIR="$(pwd)"
    return
  fi

  if in_repo "$(dirname "$0")/.."; then
    REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    return
  fi

  # curl pipe 模式 —— 克隆仓库
  if [ ! -d "$INSTALL_DIR" ]; then
    info "克隆到 ${BOLD}${INSTALL_DIR}${RESET} …"
    git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" 2>&1 | while IFS= read -r line; do
      echo "        $line"
    done
    ok "仓库已克隆"
  else
    info "目录已存在: ${BOLD}${INSTALL_DIR}${RESET}"
    if [ "$YES" -ne 1 ]; then
      read -r -p "  ${CYAN}?${RESET} 重新拉取? (git pull) [Y/n] " yn
      case "${yn:-y}" in
        [Nn]*) info "跳过更新" ;;
        *)      info "git pull …"
                git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" ;;
      esac
    else
      info "git pull …"
      git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" || true
    fi
  fi
  REPO_DIR="$INSTALL_DIR"
}

# ── 第二阶段：部署配置 ───────────────────────────────────────────────
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    cp "$file" "${file}${BACKUP_SUFFIX}"
    info "备份: ${file} → ${file}${BACKUP_SUFFIX}"
  fi
}

extract_adapter_content() {
  local file="$1"
  if grep -q '<!-- 以下为部署说明' "$file" 2>/dev/null; then
    sed '/<!-- 以下为部署说明/,$d' "$file"
  else
    cat "$file"
  fi
}

install_config() {
  local label="$1"
  local adapter="$2"
  local target="$3"

  if [ ! -f "$adapter" ]; then
    warn "跳过 ${label}: 适配器文件不存在"
    return
  fi

  mkdir -p "$(dirname "$target")"
  backup_if_exists "$target"

  {
    cat "$REPO_DIR/.agents/AGENTS.md"
    echo ""
    echo "---"
    echo ""
    extract_adapter_content "$adapter" | tail -n +2
  } > "$target"

  ok "${label}  → ${target}"
}

deploy() {
  echo ""
  info "部署配置 …"
  echo ""

  install_config "Claude Code" \
    "$REPO_DIR/.agents/adapters/claude.md" \
    "$HOME/.claude/CLAUDE.md"

  install_config "Gemini CLI" \
    "$REPO_DIR/.agents/adapters/gemini.md" \
    "$HOME/.gemini/GEMINI.md"

  info "Codex （直接读取项目内 AGENTS.md，无需全局安装）"
}

# ── 主流程 ───────────────────────────────────────────────────────────
main() {
  printf "\n  ${BOLD}${MAGENTA}▊ ai-configs${RESET}\n\n"

  acquire_repo
  deploy

  echo ""
  ok "安装完成"
  echo ""
  echo "  仓库: ${DIM}${REPO_DIR}${RESET}"
  echo ""
  echo "  下一步:"
  echo "    - 检查 ~/.claude/CLAUDE.md 确认内容正确"
  echo "    - 修改 ${BOLD}.agents/AGENTS.md${RESET} 后重新运行安装即可更新"
  echo "    - 运行 ${DIM}${INSTALL_DIR}/scripts/uninstall.sh${RESET} 可恢复原始配置"
  echo ""
}

main "$@"
