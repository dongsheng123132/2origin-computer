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
| C8 | Cross-Session Retention | ✅ 100%（机制） |
| C9 | Continuation Cost | ⚠️ 降级为机制自测，原结论已撤回 |
| C10 | State vs Transcript | ✅ 97.5% vs 60.0%（对最强对照 rag，区间不重叠） |

**10 项：9 ✅ / 1 ⚠️。** 两条诚实链条：

- **C3**：初标 ✅（误：同端点改名）→ 纠正为 ⚠️（只有一个端点）→ 用虾盘云 `deepseek-v4-pro`
  真实第二端点复测 → 最终 ✅（真跨模型，零漂移）。
- **C9**：初标 ✅「传统 transcript 无法无追问续作」→ 复核发现该结论由对照组的**生成方式**
  保证恒真（判分器测的是自己写下的话）→ 降级为机制自测，"更有效"的证据改由 **C10**
  用真实语料 + 真实模型重新取得。真实答案比原结论更锋利：传统 transcript **能**续，
  **但会自信地续错任务**。

首测证据必须诚实；证据补足后可以如实标绿，证据被推翻时必须如实降级。

## C8 — Cross-Session Retention (ShadowWork Bench) ✅

> The credential-survival claim, quantified. Traditional harness = 0%; 2Origin = ~100%.

**Test:** `bash conformance/run-tests.sh` → C8 runs `2origin-harness/bench/shadowwork-bench.mjs`.

**Pass =** retention ≥ 80%.

**Evidence (2026-08-08):** 50 facts across 20 simulated session closes/reopens → **100.0%** retention. New session auto-loads all credentials via benjing bundle. Traditional harness (no 本境) = 0%.

> Honest scope: this measures the *mechanism* (the 本境 preserves credentials across sessions), not the *semantic quality* of what's preserved (that's gated by promotion + auto-forgetting).

---

## C9 — Continuation Cost (simulated self-test) ⚠️ 已降级

> 原标题 "Continuation Efficiency (2Origin vs traditional)"，原结论
> "传统 transcript 无法无追问续作"。**该结论已撤回**——它是构造出来的，不是观察到的。

**Test:** `bash conformance/run-tests.sh` → C9 runs `2origin-harness/bench/compare-bench.mjs`.

**为什么降级：** `compare-bench.mjs` 的对照组 transcript 由脚本自己的 `genTranscript` 生成，
而它**从没把 `goal` / `next_steps[0]` 原文写进 transcript**，于是 `tradCanResume` 恒为 `false`，
而 `success` 的判定条件正是 `!tradCanResume`。**判分器测的是自己写下的话，不是世界。**

实测复核：
```
transcript 是否含 goal 原文 : false
transcript 是否含 step 原文 : false
→ compare-bench 的 success 条件恒为 true
```

**现在的身份：** 机制自测（bundle 侧确实含 goal/next-steps，这部分成立）。
**"更有效"的真实证据改由 C10 承担。**

> 诚实链条：C9 初标 ✅「传统无法续作」→ 用真实语料 + 真实模型复测（C10）→ 发现传统
> transcript **能**无追问续作，只是**续错任务**。原结论方向对、机制说错了，故撤回重述。
> 这是 C3 那条"初标✅ → 纠正 → 真实复测"的同一条纪律。

---

## C10 — State vs Transcript (ShadowWork Bench spec 0.3) ✅

> "状态优于对话流"的**真实**对照实验：真实语料 + 真实模型 + 真值取自磁盘。

**Test:** `bash conformance/run-tests.sh` → C10 跑 `shadowwork-bench-live.mjs --dry-run`
（免费、离线：验证对照组是真实会话记录、两臂 payload 等长）。
真打模型需 `SHADOWWORK_LIVE=1 bash conformance/run-tests.sh`——一次 474 调用、约 600 万输入 token，
要花钱，所以做成显式开关：**会悄悄花钱的 conformance 项本身就是缺陷。**

**Pass =** 对照组必须是**真实会话记录**（不是脚本生成的），且两臂 payload 等长（预算对齐）。

**Evidence (2026-08-09, spec 0.3):** 9 份真实 `task.origin.json`（131 条已验证事实）+ 2 份真实
Claude Code 会话记录（3.0MB + 2.5MB，按字节钉死）。`deepseek-v4-flash`，temperature 0，
79 题/臂 × 6 臂 = 474 次调用，**0 错误 0 截断**。六个臂只差"开场喂什么"，除 10x 外**同预算 9,635 字符**：

| arm | 输入token | 四选一（瞎猜25%） | 事实均衡准确率（瞎猜50%） | 反问 |
|---|---|---|---|---|
| **2origin**（本境 bundle） | 5,191 | **100.0%** [79.6,100] | **97.5%** [87.1,99.6] | 否 |
| summary（模型摘要 /compact） | 5,611 | 60.0% [35.7,80.2] | 45.0% [30.7,60.2] | 否 |
| rag（按题 BM25 检索） | 4,586 | 46.7% [24.8,69.9] | 60.0% [44.6,73.7] | 否 |
| transcript（尾部截断） | 4,083 | 46.7% [24.8,69.9] | 47.5% [32.9,62.5] | 否 |
| transcript-10x | 40,397 | 53.3% [30.1,75.2] | 35.0% [22.1,50.5] | 否 |
| none（空上下文） | 231 | 33.3% [15.2,58.3] | 47.5% [32.9,62.5] | **是** |

---

## C11 — Delegated authority reference loop ✅

> 工作可以跨模型交接，权限不能凭空交接。一个 carrier 只有在主体的 active lease、明确的
> capability、绑定本次 effect 的人工确认同时成立时，才可执行高风险动作。

**Test:** `node conformance/tools/verify-delegation-lease.mjs` 验证 lease 对象的正反样本；
`node ../ShadowOS\ =\ Harness\ OS/southbridge/verify-delegated-email.mjs` 跑本地 mock carrier。

**Pass =** 无确认零投递；确认后产生 receipt；幂等重放不双发；撤销后两个不同 carrier 都被拒绝，
且既有 receipt 不变、准许与拒绝均留审计。

**范围声明：** 这是无网络、无真实凭据的参考闭环。`approval.human` 明确标为 `test_only`，不声称
完成生产身份认证、电子签名、密钥托管或 SMTP 对接。协议语义见 `RFC-0007`。

四条结论：

1. **补上最强对照后差距仍显著**：事实召回 2origin 97.5% vs 最强对照 rag 60.0%，
   **Wilson 区间不重叠**。v0.2 只跟"尾部截断"比是挑软柿子，0.3 把 summary / rag 补上了。
2. **摘要（/compact）把"哪条事实已验证"压没了**：45.0%，低于瞎猜线，也低于什么都不喂。
   它保住了"在干什么"的梗概，丢掉了续作最需要的那一半。
3. **给对话流 10 倍预算反而更差**：35.0%，显著低于瞎猜。更多历史 = 更多过时的、
   被推翻的、属于别的任务的断言。**比"信息不足"更糟，因为它有自信。**
4. **唯一说"我不知道"的仍是空上下文那一臂**，五个有上下文的臂全都没反问，直接答。

**地板线自查通过**：空上下文臂在所有 n≥8 的指标上贴着瞎猜线 → 题目没泄题。
（v0.2 时它曾在状态字段题上拿 100%——因为目标任务字段最长，"挑最长的"就能蒙对；
已改为干扰项按长度就近挑 + 正解位置轮流，并加了自动泄题检查。）

> Honest scope: 单模型 / 单任务 / 单次，未重采样；`2origin` 的 100% 是开卷（事实字面在 bundle 里），
> 本项测的是**「状态能不能无损送达」**，对照臂的低分才是信息量。`rag` 是词法检索不是向量检索。
> **一条如实作废的指标**：为突破开卷天花板新加的"两跳题"分不开任何一臂（六臂挤在 13.4pp 内，
> 空上下文臂还比 2origin 高 0.5pp）——它测的是主题相似度而非状态归属，不用于任何结论。
> 完整方法、置信区间、以及这轮抓出的**四个判分器自身的 bug** 见 `2origin-harness/bench/RESULTS-v3.md`。
