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

**Evidence (2026-08-08):** fresh `claude -p` session auto-received `task.origin.json` summary and reported the title. **Extended to a simulated second machine:** copying the environment (CLAUDE.md, schemas, hooks, a task.origin) to a new directory and opening a fresh session there still auto-loads the state and reports the title — the credentials "transferred" with the environment (environment-is-image / AI can transfer schools).

---

## C2 — Cross-Harness ✅

> Switching harness keeps the state usable — no re-asking.

**Test:**
1. Harness A does half the task, updates `task.origin.json`.
2. Harness B (`codex exec`, etc.) continues from only that state + facts.
3. Confirm B never asks "what is the task?"

**Pass =** B continues without re-asking, and can also **persist** via the Southbridge write path.

**Evidence (2026-08-08):** Claude Code → Codex handoff, zero re-asking (session logs). **Full loop:** Codex persisted its output itself via the Southbridge MCP tool (`southbridge_write` → `demo/southbridge-e2e.md`, 25 bytes), closing the cross-harness handoff end-to-end without a host harness writing on its behalf.

---

## C3 — Cross-Model ✅

> Switching models keeps the state usable — credentials do not reset.

**Test:** same `task.origin.json`, two *different* model endpoints (via `ANTHROPIC_BASE_URL` + `--settings` override), each fresh session asked "what is the task?" Compare answers.

**Pass =** both models report the same goal / state / next-steps without drift.

**Evidence (2026-08-08, truthful):**
- **Model A:** `deepseek-v4-flash` (official DeepSeek endpoint)
- **Model B:** `deepseek-v4-pro` (Xiapan Cloud endpoint `api.u-claw.org.cn`, a genuinely different model — returns `reasoning_content`/`thinking`, proving it's a distinct inference engine)

Both auto-loaded the same `task.origin.json` via SessionStart hook and reported **identical goal, identical current state (including the C5 bug-catch detail), identical first next-step** — zero drift across a genuine model swap.

> Honesty trail: an earlier draft claimed ✅ with a same-endpoint rename — corrected to ⚠️, then re-verified with a real second endpoint (Xiapan Cloud `deepseek-v4-pro`). Final status ✅ is backed by two genuinely different models.

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

**Evidence (2026-08-08):** Southbridge MCP logs every `southbridge_write` (done / denied) to `audit.log`. End-to-end: Codex's `southbridge_write` of `demo/southbridge-e2e.md` is recorded (`done`, 25 bytes); a path-traversal attempt (`evil/../shadow.txt`) is recorded as `denied`. Every write leaves an auditable trail.

---

## Summary

| # | Check | Status |
|---|---|---|
| C1 | Cross-Session | ✅ |
| C2 | Cross-Harness | ✅ |
| C3 | Cross-Model | ✅ 真实第二端点 |
| C4 | Portable actions | ✅ |
| C5 | Verifiable results | ✅ |
| C6 | No auto-permanent learning | ✅ |
| C7 | Auditable | ✅ |
| C8 | Cross-Session Retention | ✅ 100% |

**8/8 通过。** C3 经历了诚实链条：初标 ✅（误：同端点改名）→ 纠正为 ⚠️（只有一个端点）→ 用虾盘云 `deepseek-v4-pro` 真实第二端点复测 → 最终 ✅（真跨模型，零漂移）。C8（学历保留率）是 2Origin 独有指标（传统 harness=0%），证明"多年不遗忘"的机制能力。首测证据必须诚实，但证据补足后可以如实标绿。

## C8 — Cross-Session Retention (ShadowWork Bench) ✅

> The credential-survival claim, quantified. Traditional harness = 0%; 2Origin = ~100%.

**Test:** `bash conformance/run-tests.sh` → C8 runs `2origin-harness/bench/shadowwork-bench.mjs`.

**Pass =** retention ≥ 80%.

**Evidence (2026-08-08):** 50 facts across 20 simulated session closes/reopens → **100.0%** retention. New session auto-loads all credentials via benjing bundle. Traditional harness (no 本境) = 0%.

> Honest scope: this measures the *mechanism* (the 本境 preserves credentials across sessions), not the *semantic quality* of what's preserved (that's gated by promotion + auto-forgetting).
