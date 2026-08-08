# 2Origin Computer Architecture

**本源计算架构 · An open architecture for persistent AI computers.**

> We don't build models. We want to build an AI computer.
> The model is the CPU — but a CPU is never a computer.
>
> 我们不造模型，我们想造一台 AI 计算机。模型是 CPU，但 CPU 从来不等于一台计算机。

**Status:** Draft · Request for Comments · v0.1
**License:** Apache-2.0
**Principle:** Model is replaceable. State survives. Actions are portable. Learning compounds.

---

## The Problem

Today's agent stack has good parts: models (CPU), Context Windows (RAM), MCP (buses), and harnesses (kernels). But they don't assemble into **one computer** — the motherboard, disk, drivers, and OS are missing.

The universal pain point:

> **Taught today, forgotten tomorrow. Learned on this task, restarting from grade one on the next Session.**

Because agents persist **chat transcripts** (shadows), not **object state** (origin).

## The Architecture: An AI Computer

| Layer | PC analogue | This system | Responsibility |
|---|---|---|---|
| Intelligence | CPU | **Model** (swappable) | reasoning |
| Working memory | RAM | **Context Window** | current thinking |
| Long-term storage | SSD | **Benjing 本境** | everything the AI learned |
| World representation | GPU | **Benxiang 本象** | world → AI-computable objects |
| Action I/O | Southbridge | **ActionParity 影核** | changing the world |
| High-speed bus | Northbridge | **OriginBus** | state → Context |
| Kernel | BIOS + Kernel | **Harness** (swappable) | scheduling |
| Self-learning | system service | **Academy 学堂** | experience → credentials |
| The machine | PC | **U-King** | first reference implementation |

> **Benxiang saves the world. Benjing saves growth. ActionParity changes the world.**
> **The Northbridge knows. The Southbridge acts.**

Full loop: `Observe → Think → Act → Verify → Learn`

Read the full spec: **[RFC-0000 — 2Origin Computer Architecture](rfcs/RFC-0000-2origin-computer.en.md)** · [中文版](rfcs/RFC-0000-2origin-computer.md)

---

## Verified by first-run evidence (2026-08-08)

> First-run pass = signal the architecture is right (not a benchmark-tuned result).

### ✅ Cross-Session — close the window, resume the task
A fresh, independent Claude Code session (`claude -p`, zero prior conversation) received the `task.origin.json` summary automatically via a SessionStart hook and **reported the task title and goal correctly**.

### ✅ Cross-Harness — swap the engine, keep the credentials
Claude Code did half the task (distilled 12 facts). Codex (`codex exec`) continued from only `task.origin.json` + facts with **zero re-asking**. Session logs confirm Codex never asked "what is the task?"

### ⏳ Known limitation: write access for headless harnesses
Codex's sandbox is read-only. The fix is a **Southbridge write action** — an audited MCP tool (`southbridge_write`, whitelist + audit log) injected into the harness. Prototype self-tests pass (write / path-traversal denial / audit log); injection into Codex confirmed. Final end-to-end test is blocked by an expired Codex login token (environment issue, not architecture). This is the Southbridge/Trust layer's job.

---

## Repository layout

```text
2origin-computer/
├── README.md                      ← you are here
├── rfcs/
│   ├── RFC-0000-2origin-computer.en.md    ← full spec (EN)
│   └── RFC-0000-2origin-computer.md       ← full spec (中文)
├── schemas/                       ← state format JSON Schemas (task.origin, ...)
├── examples/                      ← reference implementation examples
├── conformance/                   ← conformance checklist
├── LICENSE                        ← Apache-2.0
└── TRADEMARKS.md                  ← trademark boundaries
```

## How to contribute

- Read [RFC-0000](rfcs/RFC-0000-2origin-computer.en.md)
- Pick an open question from §10: Benjing layering / Northbridge Context compiler / Southbridge write authorization / Academy promotion thresholds
- Open an Issue or PR

## Trademarks

U-King, 2Origin, Benxiang, Benjing, ActionParity, Academy, and OriginBus are trademarks — see [TRADEMARKS.md](TRADEMARKS.md). Code is Apache-2.0; the trademark license is separate.

---

## 中文速览

我们不造模型，我们想造一台 **AI 计算机**。模型是 CPU，但 CPU 从来不等于一台计算机。

本架构定义持久 AI 计算机的一层：**模型可换，状态不丢，动作可迁移，经验会复利。** 模型/Context/Harness/MCP 都已是现成零件，缺的是把它们装成一整台机器的**主板、硬盘、驱动和操作系统**。

- **本象**保存世界，**本境**保存成长，**影核**改变世界
- **北桥**负责知，**南桥**负责行
- 闭环：`Observe → Think → Act → Verify → Learn`
- **U-King** 是第一台参考整机
