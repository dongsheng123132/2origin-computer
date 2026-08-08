# RFC-0000 — 2Origin Computer Architecture

**Status:** Draft · Request for Comments
**Version:** 0.1
**Date:** 2026-08-08
**Author:** U-King

> We don't build models. We want to build an AI computer.
> The model is the CPU — but a CPU is never a computer.

**Principle:** Model is replaceable. State survives. Actions are portable. Learning compounds.

---

## 1. Goal

This architecture defines a **persistent computer architecture for AI agents**.

It does not define models. It does not replace MCP, A2A, or any specific Harness (agent runtime). It defines the layer above all of them:

> **How does an AI computer obtain world state, persist long-term state, execute real-world actions, and learn from every job — independent of model and independent of Harness?**

A conforming machine must allow DeepSeek, GPT, Claude, Kimi, or any future model to run as a swappable compute unit — without losing the environment, projects, skills, and experience the machine has accumulated.

---

## 2. Why an "AI computer" and not "another agent"

Today's agent stack already has good parts:

- **Model** (DeepSeek / GPT / Claude) — CPU
- **Context Window** — RAM
- **MCP / A2A** — device bus / inter-process communication
- **Harness** (Claude Code / Codex / OpenHands) — kernel / scheduler

But they don't assemble into *one computer*, because the **motherboard, disk, drivers, and operating system** are missing.

The universal pain point:

> **Taught today, forgotten tomorrow. Learned on this task, restarting from grade one on the next Session.**

The reason: agents persist **chat transcripts** (shadows) instead of **object state** (origin). State is "what the world is right now"; a transcript is "who said what." An AI always sees the shadow, never the object itself.

---

## 3. Terminology & Layers

### 3.1 Architecture

| Layer | PC analogue | In this system | Responsibility |
|---|---|---|---|
| Intelligence | CPU | **Model** (swappable) | reasoning, planning |
| Working memory | RAM | **Context Window** | current thinking |
| Long-term storage | SSD + FS | **Benjing 本境** | everything this AI learned |
| World representation | GPU / scene graph | **Benxiang 本象** | world → AI-computable objects |
| Action I/O | Southbridge + drivers | **ActionParity 影核** | changing the world (GUI/CLI/API/device) |
| High-speed bus | Northbridge | **OriginBus** | compiling relevant state into Context |
| Kernel / boot | BIOS + Kernel | **Harness** (swappable) | scheduling, context, tools |
| Self-learning | system service | **Academy 学堂** | distilling experience into credentials |
| The machine | PC | **U-King** | first reference implementation |

### 3.2 One-liners

> **Benxiang saves the world. Benjing saves growth. ActionParity changes the world.**
> **The Northbridge knows (Know What). The Southbridge acts (Do What).**

---

## 4. The full task loop

A completed task must traverse the full loop:

```text
Observe → Think → Act → Verify → Learn
```

```
① BOOT        Harness starts → mount Benjing → load project/environment
② OBSERVE     Benxiang reads world state → Northbridge filters → into Context
③ THINK       Model reasons → produces a plan
④ ACT         Harness schedules → Southbridge → ActionParity → the world
⑤ VERIFY      Observe the world again → confirm it truly succeeded (not exit code = 0)
⑥ LEARN       Academy analyzes the trace → experience/SOP/skill → back to Benjing
⑦ NEXT BOOT   The AI understands this machine better than last time
```

### Constraints

- **Verify is not "tool returned success."** Success must be confirmed by re-observing real state (State Diff).
- **Learning must be candidate → verified.** One success is not a permanent truth.

```text
candidate → reviewed → verified → deprecated / superseded
```

---

## 5. State format (minimal Benxiang)

All significant objects use one Envelope:

```json
{
  "spec": "2origin/0.1",
  "kind": "task.origin",
  "id": "2o:task:001",
  "version": 1,
  "scope": "project:demo",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "goal": "...",
  "current_state": "...",
  "facts": [{ "claim": "...", "verified": true, "source": "..." }],
  "decisions": [{ "what": "...", "why": "..." }],
  "actions": [{ "verb": "...", "status": "done" }],
  "artifacts": ["..."],
  "verification": "...",
  "next_steps": ["..."],
  "learnings": [{ "lesson": "...", "confidence": 0.9, "status": "candidate" }]
}
```

Iron rules:
- **facts must be verified.** Unverified is a hypothesis, not a fact.
- **Persist State + Facts, not chat transcripts.** Transcripts are shadows; Benxiang is the object itself.
- **Learning starts as candidate, becomes verified.** One success is not a permanent truth.

---

## 6. Learning loop (Academy)

```text
complete task → record trajectory → verify result → distill success/failure
→ abstract SOP → decide if long-term → write to Benjing → generate/update Skill → auto-invoke next time
```

The Academy produces a portable **AI Transcript**. Models may be swapped; the transcript persists.

---

## 7. Conformance

An implementation is **2Origin Compatible** only when it satisfies all of:

1. **Cross-Session state**: closing and reopening a session resumes via State, not transcript replay.
2. **Cross-Harness**: switching harness (Claude Code ↔ Codex ↔ OpenHands) keeps the state usable — no re-asking.
3. **Cross-Model**: switching models keeps the state usable — credentials do not reset.
4. **Portable actions**: the same action can be executed by different drivers (API/CLI/GUI/device).
5. **Verifiable results**: outcomes confirmed by observing real state, not just exit codes.
6. **No auto-permanent learning**: experience must pass candidate → verified.
7. **Auditable**: all critical actions, promotions, and policy changes are recorded.

---

## 8. Verified evidence (2026-08-08, first run)

> First-run pass = signal the architecture is right (not a benchmark-tuned result).

### A — Cross-Session ✅
A fresh, independent Claude Code session (`claude -p`, zero prior conversation) received the `task.origin.json` summary automatically via a SessionStart hook and **correctly reported the task title and goal** — no user re-explanation needed.

### B — Cross-Harness ✅
Claude Code did STEP-A (distilled 12 facts into `extracted-facts.md`, updated state). Codex (`codex exec`) continued STEP-B from only `task.origin.json` + facts with **zero re-asking**. Session logs confirm Codex never asked "what is the task?"

### C — Southbridge write access: SOLVED ✅ (was a known limitation)
What cross-harness really lacked was not the state format (Benxiang solves that) but a **unified write authorization in the OriginBus Trust layer** — the Southbridge's job. A **Southbridge MCP server** (`southbridge_write`) provides exactly that: a whitelisted, audited write path for headless harnesses.

**End-to-end verified (2026-08-08):** Codex (`codex exec --approve-for-me`) called `southbridge_write` to persist `demo/southbridge-e2e.md` → `OK: wrote 25 bytes`. The audit log records the action (actor, action, target, bytes, timestamp). Whitelist check denied a path-traversal attempt (`evil/../shadow.txt`) earlier — the Trust layer blocks what it should.

**Why other approaches failed:** Codex's read-only sandbox blocks shell writes; `-s workspace-write` doesn't expose apply_patch; plain `codex exec` cancels MCP calls for lack of an approval channel. The Southbridge's MCP tool + `--approve-for-me` closes the loop. The earlier blocker (expired Codex login token) was an environment issue, now resolved.

---

## 9. Relation to existing standards

- Does **not** replace **MCP** (tool/data connection), **A2A** (agent interop), or **Harness** (runtime).
- This architecture is one level higher: **how to assemble them into a computer that works long-term and gets better with use.**
- Implementations may use MCP / A2A / any harness as transport — no conflict.

---

## 10. Open questions (Request for Comments)

1. Benjing layering: SQLite fact source + file snapshots + optional vector index — sufficient?
2. What standard interface should the Northbridge Context compiler (relevance + token budget) expose?
3. Minimal safe model for Southbridge write authorization (Trust/Approval)?
4. Which Academy promotions should be automatic vs. human-reviewed?

---

**License:** Apache-2.0
**Trademark:** U-King and 2Origin are trademarks. See TRADEMARKS.
