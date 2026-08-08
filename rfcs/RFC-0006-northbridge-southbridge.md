# RFC-0006 — 北桥标准接口 & 南桥 Trust 模型

**Status:** Draft · Request for Comments
**Version:** 0.1
**Date:** 2026-08-08

> 本 RFC 把北桥与南桥的**已验证实现**固化为标准接口。参考实现：2origin-harness（34 测试通过）。
> 原则：规范 = 已验证的设计，不是纸上想象。

---

## 1. 北桥：标准接口 `context.request → context.bundle`

### 1.1 请求（context.request）

```json
{
  "kind": "context.request",
  "goal": "写发布文档",
  "scope": ["project:x"],
  "budget": { "tokens": 30000, "facts": 10 },
  "freshness": "latest"
}
```

### 1.2 响应（context.bundle）

```json
{
  "kind": "context.bundle",
  "goal": "写发布文档",
  "scope": ["project:x"],
  "state": [
    { "id": "task.1", "file": ".../task.origin.json",
      "current_state": "写了一半", "next_steps": ["写完引言"] }
  ],
  "memory": [ { "claim": "...", "verified": true, "source": "..." } ],
  "skills": ["skills/xxx"],
  "evidence": ["reports/Q2.json"],
  "token_estimate": 18320,
  "budget": 30000,
  "over_budget": false,
  "note": "本境只进了'此刻相关'的部分，不是整个硬盘"
}
```

### 1.3 规则

1. **北桥负责知**：不把整个硬盘塞进 RAM。`state[]` 按 `scope` 过滤，`memory[]` 按 `goal` 相关性选。
2. **相关性是提示**：`memory[]` 只进"此刻相关"的已验证事实，不是全部。
3. **evidence 可复核**：`evidence[]` 只列可复核的 source（文件/命令/测试用例，见 RFC-0005 §3.2）。
4. **诚实降级**：估算超出 `budget.tokens` 时，`over_budget: true` + 标注已截断，不静默丢。

---

## 2. 南桥：Trust 模型（风险分级 + 批准）

### 2.1 风险分级

判据只有三个**客观输入**（不看模型怎么说）：目标在不在白名单、目标存不存在、目标是不是受保护路径。

| 风险 | 场景 | 说明 |
|---|---|---|
| `denied` | 目标不在白名单 | 路径穿越拒绝 |
| `low` | 新建文件（白名单内，不存在） | 追加写也算 low |
| `medium` | 覆盖已存在文件 | 破坏性写 |
| `high` | 受保护路径（`task.origin` / 代码 / schemas / `.claude`）且存在 | 覆盖学历/代码/协议 |

### 2.2 批准机制

| 风险 | 批准方式 |
|---|---|
| `low` | **自动**放行 |
| `medium` | `expect_sha256`（乐观锁：证明你读过当前内容）或 `approval:"confirm"` |
| `high` | `approval:"confirm"`（人在环） |

### 2.3 动作结果（action.result）

```json
{
  "spec": "2origin/0.1",
  "kind": "action.result",
  "action_id": "act:...",
  "status": "done | requires_approval | denied | failed",
  "risk": "low | medium | high",
  "approval": "auto | expect_sha256 | confirm",
  "evidence": { "exists": true, "size_bytes": 17, "sha256": "..." },
  "state_diff": { "before": {...}, "after": {...} },
  "reversible": true,
  "backup_path": "...",
  "undo_hint": "restore from backup_path | delete target"
}
```

### 2.4 规则

1. **status 由观察决定**：写后回头观察（stat + sha256），不是 writeFileSync 没抛错就 OK。
2. **覆盖前备份**：`reversible` 有物证（backup_path），不是形容词。
3. **expect_sha256 是无头 harness 的批准**：它唯一能出示的"证明你读过当前内容"。
4. **审计**：每次动作（含 denied / requires_approval）记 audit.log。

---

## 3. 已验证证据（2026-08-08，参考实现 2origin-harness）

| 接口 | 实测 |
|---|---|
| 北桥 scope 过滤 | `buildContext(root, {scope:['project:a']})` 只返回 project:a ✅ |
| 北桥 over_budget | 极低预算 → `over_budget: true` + 诚实 note ✅ |
| 南桥 medium risk | 覆盖已存在文件 → `requires_approval` ✅ |
| 南桥 expect_sha256 | 正确 hash 放行，错误 hash 拒绝 ✅ |
| 南桥路径穿越 | `../evil.sh` → `denied`，不落盘 ✅ |

---

## 4. Conformance 关联

- **C4 动作可迁移**：南桥 action.result 是统一格式，不同驱动（API/CLI/GUI）同一结果
- **C5 结果可验证**：status 由写后观察决定
- **C7 可审计**：所有动作（含拒绝）留审计

---

## 5. 讨论点

1. 北桥的 `token_estimate` 用 `字符数/4` 粗估——要不要出更准的 tokenizer 标准？
2. `high` 风险的受保护路径列表要不要可配置？
3. `expect_sha256` 只验内容不验路径——要不要加路径绑定（防改名重放）？

**License:** Apache-2.0
