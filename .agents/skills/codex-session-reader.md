---
name: codex-session-reader
description: 仅在用户要求阅读/查找/回顾 Codex CLI 的历史对话记录时使用。触发关键词：codex 对话、codex 记录、codex 会话、codex session、上一个 codex、查找 codex、阅读 codex。
---

# Codex CLI 对话记录 — 查找和阅读历史会话

## 使用场景

用户想了解之前 Codex CLI（OpenAI 的编码助手）在这个仓库做了什么，需要查找和阅读 Codex 的本地历史会话记录。

---

## 第一步：了解 Codex 存储结构

Codex 将所有会话以 JSONL 格式存储在 `~/.codex/` 下。关键目录结构：

```
~/.codex/
├── config.toml              # Codex 配置
├── auth.json                # 认证信息
├── history.jsonl            # 用户输入历史（简要）
├── sessions/                # 会话 rollout 文件（完整对话）
│   └── YYYY/
│       └── MM/
│           └── DD/
│               └── rollout-YYYY-MM-DDTHH-MM-SS-<session-id>.jsonl
├── state_*.sqlite           # 会话状态数据库
├── logs_*.sqlite            # 日志数据库
├── memories/                # Codex 记忆
├── skills/                  # 技能文件
├── plugins/                 # 插件
└── rules/                   # 规则文件
```

**核心文件**：`sessions/` 下的 `rollout-*.jsonl` 文件包含完整对话历史（系统指令、用户消息、助手响应、工具调用）。

---

## 第二步：列出可用会话

```bash
# 列出所有 rollout 文件，按时间倒序
find ~/.codex/sessions/ -name "rollout-*.jsonl" | sort -r
```

根据时间戳筛选用户关心的会话。文件名格式：`rollout-YYYY-MM-DDTHH-MM-SS-<session-id>.jsonl`，时间戳即为会话开始时间。

---

## 第三步：获取会话概况

```bash
# 查看行数（每行是一个 event）
wc -l ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl

# 提取 session_meta 获取会话基本信息
head -1 ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl | python3 -c "
import json, sys
meta = json.loads(sys.stdin.readline())
p = meta['payload']
print(f'Session: {p[\"session_id\"]}')
print(f'CWD: {p[\"cwd\"]}')
print(f'Model: {p.get(\"model_provider\", \"?\")}')
print(f'CLI version: {p[\"cli_version\"]}')
print(f'Git branch: {p.get(\"git\", {}).get(\"branch\", \"?\")}')
print(f'Git commit: {p.get(\"git\", {}).get(\"commit_hash\", \"?\")}')
"
```

---

## 第四步：提取对话摘要

### 4a. 提取用户消息（不含系统指令中注入的 AGENTS.md）

```bash
rg '"role":"user"' ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    obj = json.loads(line)
    if obj.get('type') == 'response_item':
        msg = obj.get('payload', {})
        if msg.get('role') == 'user':
            for c in msg.get('content', []):
                if c.get('type') == 'input_text' and 'AGENTS.md' not in c.get('text',''):
                    print(c['text'][:200])
                    print('---')
"
```

### 4b. 提取助手消息

```bash
rg '"role":"assistant"' ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    obj = json.loads(line)
    if obj.get('type') == 'response_item':
        msg = obj.get('payload', {})
        if msg.get('role') == 'assistant':
            for c in msg.get('content', []):
                if c.get('type') == 'output_text':
                    print(c['text'][:300])
                    print('---')
"
```

### 4c. 提取工具调用

```bash
rg '"tool_use"' ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    obj = json.loads(line)
    if obj.get('type') == 'response_item':
        msg = obj.get('payload', {})
        if msg.get('role') == 'assistant':
            for c in msg.get('content', []):
                if c.get('type') == 'tool_use':
                    print(f'{c[\"name\"]}: {str(c.get(\"input\",{}))[:150]}')
"
```

---

## 第五步：理解 JSONL 事件类型

| type | 含义 |
|------|------|
| `session_meta` | 会话元数据（第 1 行）：模型、CWD、git 信息、CLI 版本 |
| `turn_context` | Turn 上下文：沙箱策略、审批策略、模型参数 |
| `event_msg` | 事件通知：task_started、task_completed 等 |
| `response_item` | 对话消息：user/assistant/system 的 role 消息 |
| `tool_call` | 工具调用和结果 |

`response_item` 中的 role 字段决定消息来源：
- `role: "user"` → 用户输入（`input_text` 类型）
- `role: "assistant"` → 助手输出（`output_text` 类型）或工具调用（`tool_use` 类型）

---

## 注意事项

- rollout 文件可能非常大（数百行 JSONL），每行 JSON 可能包含大量嵌套的系统指令。**不要直接用 cat 或 Read 读取整个文件**——使用 `head`、`tail`、`rg`、`python3` 做定向提取。
- 多个 rollout 文件对应多次 Codex 会话，文件名中的时间戳即为会话开始时间。
- `~/.codex/history.jsonl` 仅包含用户输入历史（简要），完整对话需查看 `sessions/` 目录。
- 若用户未指定具体会话，先列出所有会话（第二步），然后让其选择，或默认选择最近的一个。
