# RFC-0005 — 本境协议 v0.2（Benjing Persistent State v0.2）

**Status:** Draft · Request for Comments
**Version:** 0.2
**Date:** 2026-08-08

> 本境保存成长。这份 RFC 把「本境跨会话积累」的可复现机制标准化——让任何机器都能复刻「越用越懂」。
> v0.1 的四个缺陷全部来自实测（见 §4），不是纸上设计。

---

## 1. 目标

定义 **Benjing 本境** 的持久状态协议 v0.2：一台 AI 计算机如何跨会话、跨 harness、跨模型保存"学到的东西"——且**可验证、可迁移、可审计**。

v0.1 只做到了"保存状态文件"。v0.2 让它**可信**：内容有指纹、写入有乐观锁、source 必须可复核、写入者可追溯。

---

## 2. 核心对象：task.origin（任务状态）

每个任务的状态存一份 `task.origin.json`：

```json
{
  "spec": "2origin/0.2",
  "kind": "task.origin",
  "id": "demo.task1",
  "title": "...",
  "goal": "...",
  "version": 3,
  "content_hash": "sha256(canonical(state - {version,updated_at,content_hash,actor}))",
  "actor": { "harness": "claude-code", "model": "deepseek-v4-flash", "session_id": "...", "at": "ISO8601" },
  "scope": "project:x",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "current_state": "...",
  "facts": [{ "claim": "...", "verified": true, "source": "...", "source_kind": "file|command|testcase" }],
  "decisions": [{ "what": "...", "why": "..." }],
  "actions": [{ "verb": "...", "status": "done", "evidence": "..." }],
  "artifacts": ["..."],
  "verification": "...",
  "next_steps": ["..."],
  "learnings": [{ "lesson": "...", "confidence": 0.9, "status": "candidate" }]
}
```

### 必选字段
- `spec` / `kind` / `id` / `goal` / `version` / `updated_at` / `current_state` / `next_steps`
- **`facts` 的每条必须有 `verified` 和 `source`**；`verified: true` 的必须有 `source_kind`（或 source 启发式可判）

### 铁律
1. **不存聊天记录，存 State + Facts**：聊天记录是影，本象是对象本身。
2. **facts 必须 verified**：没验证的不叫事实，叫假设。
3. **learning 先 candidate 后 verified**：一次成功不是永久真理。

---

## 3. v0.2 机制（对应实测缺陷）

### 3.1 content_hash — 内容指纹乐观锁

**缺陷①（实测）**：v0.1 每次 SessionEnd 无脑 `version += 1`，内容一字未变时 version 从 1 涨到 4。版本号既判断不了状态是否变化，也不能当乐观锁。

**v0.2**：
```text
content_hash = sha256(canonical(state - {version, updated_at, content_hash, actor}))
```
- **version 由 content_hash 变化驱动**，不由会话次数驱动。内容没变，一个字节都不写。
- 写入学历时必须带 `--expect <content_hash>`（乐观锁）：证明"你读过当前内容"才准写。语义同影核 v0.2 的 `expect_sha256`。
- 好处：跨 harness 并发写入不会被静默覆盖（先读后写的人必须持最新 hash）。

### 3.2 source 必须可复核

**缺陷②（实测）**：v0.1 的验证器只判 `source` 非空——实测把 9 条 source 全换成"我说的，不信拉倒"，判决依然 VERIFIED。那不是验证，是存在性检查。

**v0.2**：`source` 必须引用**可复核物**：
- **文件路径**（`*.md / *.json / *.log / *.mjs` …）
- **可重跑的命令**（`git log -S x` / `cargo test y` / `node z.mjs`）
- **验证用例编号**（`T3.2`）

纯自然语言断言（"实测过"/"我说的"）判 `unverifiable`，**不配叫 verified fact**。
判据是"引没引可复核物"，不是"可复核物现在还在不在"——很多 fact 描述的正 是"文件被删了/命令报错了"，要求路径存在会把真事实判成假。

### 3.3 actor — 写入者 provenance

**缺陷③（实测）**：跨模型/跨 harness 继承学历是本架构的核心主张，但 v0.1 状态文件里 0 个 provenance 字段，主张无从举证。

**v0.2**：每条状态带 `actor`：
- `harness`：由环境变量观测得出（claude-code / codex）
- `model`：**观测不到就写 `unobserved`，不许编**（本机 Claude Code 与 codex 均无可靠模型名环境变量）
- `session_id` / `at`

### 3.4 本境 bundle 编译（SessionStart 加载）

**缺陷④（实测）**：v0.1 按 mtime 抓最新一份状态注入——磁盘上 4 份学历共 19 条事实，开会只进 9 条，另外 10 条在会话里完全不可见，且没人知道丢了。本境号称硬盘，实际是"只有最后一个扇区可读"的硬盘。

**v0.2**：SessionStart 编译 **bundle**：
```text
当前任务全量 + 其余任务的已验证事实结转，受字符预算约束。
丢了什么必须写在开头：宁可说"丢了 2 条"，也不能让人以为全装上了。
```
输出示例：
```
[本境 bundle · benjing/0.2]
装载 5/5 份学历 · 已验证事实 27/27 条
✔ 无丢弃
── 当前任务 · demo/uking-triage/task.origin.json ──
...
```

---

## 4. 已验证证据（2026-08-08 实测）

| 机制 | 实测 |
|---|---|
| content_hash 版本驱动 | SessionEnd 连跑内容不变 → 版本不涨（修复前从 1 涨到 4） |
| source 可复核 | recheckSource 抓出"散文式 source"标 `⚠source不可复核`；改指向文件/命令后消失 |
| actor provenance | 状态文件带 harness/model/session_id |
| bundle 编译 | 5 份学历 27 条事实全部注入，无丢弃 |

---

## 5. Conformance 关联

本 RFC 支撑 Conformance：
- **C1 Cross-Session**：bundle 编译让新会话带上全部学历
- **C6 No auto-permanent learning**：learning 先 candidate
- **C7 Auditable**：actor + content_hash 让写入可追溯、可防覆盖

---

## 6. 职责分界：本境的任务层 vs 环境层

**本境分两层，别混成一个协议：**

| 层 | 对象 | 管什么 | 实现 |
|---|---|---|---|
| **任务层** | `task.origin`（本 RFC） | 任务到哪了：目标/事实/下一步/学历 | benjing/0.2（本 RFC） |
| **环境层** | `environment.origin` | 机器能跑什么：OS/工具链/路径 | uenv（spec `origin-environment/v0.1`） |

**为什么分开**：环境快照（这台机器什么样）和任务学历（这个任务到哪了）正交——像 Linux 的 `/etc`（环境配置）和 `/var`（运行状态）。硬合并会造成"一个协议既描述机器又描述任务"的混乱。

**规则**：
- 环境层变化（装了 Python、改路径）→ 更新 `environment.origin`，不影响 `task.origin`
- 任务层变化（进度推进、新事实）→ 更新 `task.origin`，不写环境
- 两者可关联（任务学历引用环境快照的版本），但各自独立演进

---

## 7. 讨论点

1. content_hash 的 canonical 序列化规则要不要出正式规范（字段顺序/转义）？
2. source_kind 的启发式判定要不要支持自定义？
3. bundle 的字符预算（当前 9000）是否该可配置、按任务类型分档？

**License:** Apache-2.0
