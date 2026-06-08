# Claude Code 适配器

Claude 的配置文件存放在 `.agents/adapters/claude/` 目录下，由 `install.sh` 直接部署到 `~/.claude/`。

## Settings 同步

| 文件 | 仓库位置 | 部署策略 |
|------|---------|---------|
| `CLAUDE.md` | `.agents/adapters/claude/CLAUDE.md` | 覆盖部署 |
| `settings.json` | `.agents/adapters/claude/settings.json` | 覆盖部署 |
| `settings.local.json` | `.agents/adapters/claude/settings.local.json.template` | 仅新机器首次部署（不覆盖已有） |

`settings.local.json` 是模板文件，包含通用的额外权限。各机器可在此基础上自行修改。
