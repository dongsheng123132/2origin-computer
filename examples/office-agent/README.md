# Example: Office Agent — cross-harness task handoff

> The minimum reproducible demo of the 2Origin architecture: two different harnesses (Claude Code and Codex) take turns on the **same** task, and the handoff lives entirely in one `task.origin.json` — no chat transcripts copied.

## What it proves

| Conformance item | Demonstrated |
|---|---|
| Cross-Session | A fresh `claude -p` session auto-loads the state via a SessionStart hook and reports the task title — no re-explanation |
| Cross-Harness | Claude Code does STEP-A; Codex (`codex exec`) continues STEP-B from only `task.origin.json` + facts, zero re-asking |
| Verified Facts | `facts[]` carry `verified: true` + `source`; unverified claims are hypotheses, not facts |
| Learning pipeline | `learnings[]` start as `candidate`, only promoted to `verified` after confirmation |

## The task

> Distill 12 global harness best-practices (from a research note) into a structured, actionable checklist; then classify each as "done / in-progress / to-do."

- **STEP-A (Claude Code):** read source → write `extracted-facts.md` → update state
- **STEP-B (Codex):** read `task.origin.json` + facts → write `actionable-notes.md` → update state
- **STEP-C:** diff the two outputs, confirm no drift and no re-asking

## Files

```text
office-agent/
├── task.origin.json        # the only handoff medium
├── extracted-facts.md      # STEP-A artifact (produced by Claude Code)
└── actionable-notes.md     # STEP-B artifact (produced by Codex)
```

## `task.origin.json` (the state, abbreviated)

```json
{
  "spec": "2origin/0.1",
  "kind": "task.origin",
  "id": "demo.task2",
  "goal": "verify AI credentials survive a cross-harness handoff",
  "current_state": "STEP-A done. Awaiting STEP-B (Codex reads this state and continues).",
  "facts": [
    { "claim": "...", "verified": true, "source": "..." }
  ],
  "decisions": [
    { "what": "the only handoff medium is task.origin.json", "why": "harness is a shell; credentials live in state" }
  ],
  "actions": [
    { "verb": "file.write", "target": "extracted-facts.md", "status": "done" }
  ],
  "verification": "STEP-A artifact produced.",
  "next_steps": [
    "STEP-B (Codex): read this file, write actionable-notes.md",
    "STEP-C: diff outputs, confirm no drift"
  ],
  "learnings": [
    { "lesson": "harness is a shell; the state file is the asset", "confidence": 0.9, "status": "candidate" }
  ]
}
```

## How to reproduce

1. Install Claude Code **and** Codex on one machine.
2. Point both at the same working directory (both can use the same provider — e.g. DeepSeek).
3. Have Claude Code do STEP-A and update `task.origin.json`.
4. Run `codex exec --skip-git-repo-check "read task.origin.json and continue STEP-B"` (a Southbridge write tool lets Codex persist; see RFC-0000 §8-C).
5. Confirm Codex never asks "what is the task?"

## Note on the Southbridge (write access)

Headless harnesses are read-only by default. A Southbridge MCP server (`southbridge_write`, whitelist + audit log) gives a headless harness an audited write path. See RFC-0000 §8-C and the `southbridge/` prototype.
