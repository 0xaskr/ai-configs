# Codex 适配器

Codex 的配置文件存放在 `.agents/adapters/codex/` 目录下，由 `install.sh` 部署到 `~/.codex/`。

Codex 读取 `~/.agents/AGENTS.md` 作为全局指令。

## Settings 同步

| 文件 | 仓库位置 | 部署策略 |
|------|---------|---------|
| `config.toml` | `.agents/adapters/codex/config.toml` | 合并部署（保留项目信任列表） |
| `rules/default.rules` | `.agents/adapters/codex/rules/default.rules` |

## 不同步的文件

| 文件 | 原因 |
|------|------|
| `[projects.*]` | config.toml 中的项目信任配置包含本地路径 |
| `auth.json` | 认证凭据 |
| `history.jsonl` | 会话历史 |
| `*.sqlite` | 运行时数据库 |
