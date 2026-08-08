# RFC-0006 — Northbridge Standard Interface & Southbridge Trust Model

**Status:** Draft · Request for Comments
**Version:** 0.1
**Date:** 2026-08-08

> This RFC fixes the **verified** Northbridge and Southbridge implementations as standard interfaces. Reference implementation: 2origin-harness (34 tests passing).
> Principle: spec = verified design, not paper imagination.

---

## 1. Northbridge: standard interface `context.request → context.bundle`

### 1.1 Request

```json
{
  "kind": "context.request",
  "goal": "write a release doc",
  "scope": ["project:x"],
  "budget": { "tokens": 30000, "facts": 10 },
  "freshness": "latest"
}
```

### 1.2 Response

```json
{
  "kind": "context.bundle",
  "goal": "write a release doc",
  "scope": ["project:x"],
  "state": [
    { "id": "task.1", "file": ".../task.origin.json",
      "current_state": "half written", "next_steps": ["finish intro"] }
  ],
  "memory": [ { "claim": "...", "verified": true, "source": "..." } ],
  "skills": ["skills/xxx"],
  "evidence": ["reports/Q2.json"],
  "token_estimate": 18320,
  "budget": 30000,
  "over_budget": false,
  "note": "only the relevant part of 本境 entered context, not the whole disk"
}
```

### 1.3 Rules

1. **Northbridge knows**: don't stuff the whole disk into RAM. `state[]` filtered by `scope`, `memory[]` by `goal` relevance.
2. **Relevance is a hint**: `memory[]` carries only "relevant right now" verified facts.
3. **Evidence verifiable**: `evidence[]` lists only recheckable sources (file/command/testcase, see RFC-0005 §3.2).
4. **Honest degradation**: when estimate exceeds `budget.tokens`, set `over_budget: true` and say what was cut — never drop silently.

---

## 2. Southbridge: Trust model (risk tiers + approval)

### 2.1 Risk tiers

Judged by three **objective inputs** only (never the model's claim): in-whitelist, exists, protected path.

| Risk | Case | Note |
|---|---|---|
| `denied` | target outside whitelist | path traversal rejected |
| `low` | new file (in whitelist, not exists) | append also low |
| `medium` | overwrite existing file | destructive write |
| `high` | protected path (`task.origin` / code / schemas / `.claude`) and exists | overwriting credentials/code/spec |

### 2.2 Approval

| Risk | Approval |
|---|---|
| `low` | **auto** |
| `medium` | `expect_sha256` (optimistic lock: prove you read the current content) or `approval:"confirm"` |
| `high` | `approval:"confirm"` (human in the loop) |

### 2.3 Action result

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

### 2.4 Rules

1. **Status from observation**: re-observe (stat + sha256) after write; not "writeFileSync didn't throw."
2. **Backup before overwrite**: `reversible` has evidence (`backup_path`), not an adjective.
3. **`expect_sha256` is the headless harness's approval**: it's the only proof a headless agent can produce that it read the current content.
4. **Audit**: every action (including denied / requires_approval) logged.

---

## 3. Verified evidence (2026-08-08, 2origin-harness)

| Interface | Tested |
|---|---|
| Northbridge scope filter | `buildContext(root, {scope:['project:a']})` returns only project:a ✅ |
| Northbridge over_budget | tiny budget → `over_budget: true` + honest note ✅ |
| Southbridge medium risk | overwrite existing → `requires_approval` ✅ |
| Southbridge expect_sha256 | correct hash passes, wrong hash rejected ✅ |
| Southbridge path traversal | `../evil.sh` → `denied`, not written ✅ |

---

## 4. Conformance links

- **C4 Portable actions**: unified action.result across drivers (API/CLI/GUI)
- **C5 Verifiable results**: status from post-write observation
- **C7 Auditable**: every action (incl. denials) leaves a trail

---

## 5. Open questions

1. `token_estimate` uses `chars/4` — should a proper tokenizer standard be defined?
2. Should the `high` protected-path list be configurable?
3. `expect_sha256` verifies content only, not path — add path binding to prevent rename-replay?

**License:** Apache-2.0
