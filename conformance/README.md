# Conformance — 2Origin Compatible checklist

A machine is **2Origin Compatible** only when it satisfies **all** checks below. Each check is executable, so "conformance" is testable, not aspirational.

**Status legend:** ✅ passed (with evidence) · ⏳ in progress · ❌ not yet

---

## C1 — Cross-Session state ✅

> Close the session, reopen, and the task resumes via State — not transcript replay.

**Test:**
1. Start a task, create a `task.origin.json`.
2. Open a **fresh** harness session in the same directory (zero prior conversation).
3. Check it receives the state (e.g. via SessionStart hook) and can state the task title/goal without re-asking.

**Pass =** the fresh session reports the correct task without user explanation.

**Evidence (2026-08-08):** fresh `claude -p` session auto-received `task.origin.json` summary and reported the title.

---

## C2 — Cross-Harness ✅

> Switching harness keeps the state usable — no re-asking.

**Test:**
1. Harness A does half the task, updates `task.origin.json`.
2. Harness B (`codex exec`, etc.) continues from only that state + facts.
3. Confirm B never asks "what is the task?"

**Pass =** B continues without re-asking.

**Evidence (2026-08-08):** Claude Code → Codex handoff, zero re-asking (session logs).

---

## C3 — Cross-Model ⚠️

> Switching models keeps the state usable — credentials do not reset.

**Test:** same `task.origin.json`, two *different* model endpoints, each fresh session asked "what is the task?" Compare answers.

**Pass =** both models report the same goal / state / next-steps without drift.

**Honest status:** ⚠️ **Not yet truly verified.** The test machine has **only one real model endpoint** (`deepseek-v4-flash` via `api.deepseek.com`). Running `claude -p --model deepseek-v4-pro` only renamed the same endpoint — it was **not a real model swap**. The identical outputs proved the state loads consistently, but did **not** prove cross-model independence. True C3 requires a second real endpoint (e.g. GPT or Claude API). Do not count this as passed until a genuine second model reproduces the state.

> Honesty note: initial draft claimed ✅. Correction: same-endpoint rename ≠ cross-model. Fixed per "first-run evidence must be truthful, not tuned."

---

## C4 — Portable actions ✅

> The same action can be executed by different drivers (API / CLI / GUI / device).

**Test:** `node examples/portable-action/document-save.js --driver cli` and `--driver api`; compare output hashes.

**Pass =** identical sha256 from both drivers.

**Evidence (2026-08-08):** both drivers produced byte-identical `document.save` output (`21e01778…`, 41 bytes). See `examples/portable-action/`.

---

## C5 — Verifiable results ✅

> Outcomes are confirmed by observing real state, not exit codes.

**Test:** `node conformance/tools/verify-state.mjs <task.origin.json>` — checks artifacts exist on disk, verified facts carry sources, and state is self-consistent.

**Pass =** verdict `✅ VERIFIED` from real observation.

**Evidence (2026-08-08):** verified task1 + task2. On first run it **caught a real bug** — task2 declared `actionable-notes.md` in artifacts but the file didn't exist on disk; verdict was `❌ NOT VERIFIED`. Rebuilding the file flipped it to `✅ VERIFIED` (9 checks pass). The validator's job: architecture proves itself by observing reality, not by trusting claims.

---

## C6 — No auto-permanent learning ✅

> Experience must pass candidate → verified. One success is not a permanent truth.

**Test:** inspect the `learnings[]` lifecycle: new items are `candidate`, only promoted after confirmation.

**Evidence (2026-08-08):** task.origin files carry `candidate` items; promotion is a manual/review step, not automatic.

---

## C7 — Auditable ✅

> All critical actions, promotions, and policy changes are recorded.

**Test:** confirm a write action leaves an audit trail (actor, action, target, timestamp).

**Evidence (2026-08-08):** Southbridge MCP logs every `southbridge_write` (done / denied) to `audit.log`.

---

## Summary

| # | Check | Status |
|---|---|---|
| C1 | Cross-Session | ✅ |
| C2 | Cross-Harness | ✅ |
| C3 | Cross-Model | ⚠️ 待真实第二端点 |
| C4 | Portable actions | ✅ |
| C5 | Verifiable results | ✅ |
| C6 | No auto-permanent learning | ✅ |
| C7 | Auditable | ✅ |

**6/7 通过，1 条诚实降级。** C3 初始标 ✅ 被纠正为 ⚠️：本机只有一个真实模型端点，`--model` 改名≠换模型。首测证据必须诚实，不为好看调状态。
