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

## C3 — Cross-Model ⏳

> Switching models keeps the state usable — credentials do not reset.

**Test:** same as C2 but swap the model between steps (e.g. DeepSeek → GPT → Claude), keep the same `task.origin.json`.

**Status:** Same-machine dual-harness confirmed; true cross-model test pending (providers exist on this machine).

---

## C4 — Portable actions ⏳

> The same action can be executed by different drivers (API / CLI / GUI / device).

**Test:** define one action (e.g. `document.save`) and execute it via two different drivers; confirm identical result.

**Status:** ActionParity prototype exists (46 actions, GUI/CLI/MCP share core); formal cross-driver test pending.

---

## C5 — Verifiable results ⏳

> Outcomes are confirmed by observing real state, not exit codes.

**Test:** after an action, re-observe the world (State Diff) and confirm the intended change — not just "exit code 0."

**Status:** principle in RFC §4; automated state-diff verification not yet wired into the loop.

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
| C3 | Cross-Model | ⏳ |
| C4 | Portable actions | ⏳ |
| C5 | Verifiable results | ⏳ |
| C6 | No auto-permanent learning | ✅ |
| C7 | Auditable | ✅ |

4/7 可运行检查已通过（⏳ 是需要补实现、不是失败）。
