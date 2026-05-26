# OpenAI Codex 适配器

## 加载机制

Codex 直接读取项目根目录的 `AGENTS.md`，无需 shim。本仓库的 `AGENTS.md` 即为 Codex 的入口文件，开箱即用。

## codex/instructions.md

Codex 也支持 `codex/instructions.md` 作为补充指令，可用于引用 `AGENTS.md` 或添加项目特定说明：

```markdown
# 项目补充指令

全局行为规范见 AGENTS.md。

本项目额外要求：
- 所有 Python 文件使用 uv 运行
- 测试命令：uv run pytest
```

## 沙箱权限

Codex 的网络和文件系统权限通过启动参数控制，而非配置文件：

```bash
# 允许网络访问
codex --full-auto --network

# 限制文件系统访问范围
codex --full-auto --sandbox /path/to/project
```

## 说明

Codex 是三个适配器中配置最简的：`AGENTS.md` 直接生效，无需任何 shim 或额外配置文件。权限模型通过命令行参数而非持久化配置管理。
