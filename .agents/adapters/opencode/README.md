# OpenCode 适配器

OpenCode 的配置文件存放在 `.agents/adapters/opencode/` 目录下，由 `install.sh` 部署到 `~/.config/opencode/`。

OpenCode 读取 `~/.agents/AGENTS.md` 作为全局指令（通过 `instructions` 字段或 `.opencode/` 目录）。

## Settings 同步

| 文件 | 仓库位置 | 部署策略 |
|------|---------|---------|
| `opencode.jsonc` | `.agents/adapters/opencode/opencode.jsonc` | 覆盖部署 |

## 不同步的文件

| 文件 | 原因 |
|------|------|
| `node_modules/` | 插件依赖，自动安装 |
| `package.json` / `package-lock.json` | 插件依赖管理，自动生成 |
| `ai.opencode.desktop/` | 桌面应用运行时数据 |
