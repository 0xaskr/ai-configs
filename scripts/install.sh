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
    -y|--yes) YES=1; shift ;;
    --uninstall)
      exec bash <(curl -fsSL "https://raw.githubusercontent.com/0xaskr/ai-configs/${BRANCH}/scripts/uninstall.sh")
      ;;
    *) shift ;;
  esac
done

# ── 清理函数 ─────────────────────────────────────────────────────────
CLEANUP_DIR=""

cleanup() {
  if [ -n "$CLEANUP_DIR" ] && [ -d "$CLEANUP_DIR" ]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

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

  if ! command -v git >/dev/null 2>&1; then
    fail "未找到 git，请先安装 git"
  fi

  CLEANUP_DIR="$(mktemp -d /tmp/ai-configs.XXXXXX)"
  info "克隆到 ${BOLD}${CLEANUP_DIR}${RESET} …"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$CLEANUP_DIR" 2>&1 | while IFS= read -r line; do
    echo "        $line"
  done
  ok "仓库已克隆"
  REPO_DIR="$CLEANUP_DIR"
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

backup_dir_if_exists() {
  local dir="$1"
  if [ -d "$dir" ] && [ ! -L "$dir" ]; then
    mv "$dir" "${dir}${BACKUP_SUFFIX}"
    info "备份: ${dir} → ${dir}${BACKUP_SUFFIX}"
  elif [ -L "$dir" ]; then
    rm -f "$dir"
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

# ── .agents 部署 ──────────────────────────────────────────────────────
deploy_agents() {
  local agents_src="$REPO_DIR/.agents"
  local agents_dst="$HOME/.agents"

  if [ ! -d "$agents_src" ]; then
    return
  fi

  echo ""
  info "部署 .agents …"
  echo ""

  backup_dir_if_exists "$agents_dst"

  cp -r "$agents_src" "$agents_dst"

  ok ".agents 已部署到 ${agents_dst}"
}

# ── Skill 部署 ─────────────────────────────────────────────────────────
deploy_skills() {
  local skills_src="$REPO_DIR/.agents/skills"
  if [ ! -d "$skills_src" ]; then
    return
  fi

  local -A tool_skills_dirs=(
    ["Claude Code"]="$HOME/.claude/skills"
    ["Gemini CLI"]="$HOME/.gemini/skills"
    ["OpenCode"]="$HOME/.config/opencode/skills"
  )

  echo ""
  info "部署 Skills …"
  echo ""

  for tool in "${!tool_skills_dirs[@]}"; do
    local dest="${tool_skills_dirs[$tool]}"
    mkdir -p "$(dirname "$dest")"

    backup_dir_if_exists "$dest"

    cp -r "$skills_src" "$dest"

    ok "${tool} 技能已部署"
  done

  info "Codex — 项目级 skills，需在项目 .codex/skills/ 下手动部署"
}

# ── 主流程 ───────────────────────────────────────────────────────────
main() {
  printf "\n  ${BOLD}${MAGENTA}▊ ai-configs${RESET}\n\n"

  acquire_repo
  deploy
  deploy_agents
  deploy_skills

  echo ""
  ok "安装完成"
  echo ""
  echo "  下一步:"
  echo "    - 检查 ~/.claude/CLAUDE.md 确认内容正确"
  echo "    - 检查 ~/.agents/ 确认内容完整"
  echo "    - 运行 curl -fsSL ${REPO_URL%.git}/raw/${BRANCH}/scripts/uninstall.sh | bash 可恢复原始配置"
  echo ""
}

main "$@"
