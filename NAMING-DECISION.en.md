# Naming Decision · One Name, Two Things (naming/decision-0.1)

> This file is the **single source of truth for cross-repository naming**. Where an implementation
> repo's `TERMINOLOGY.md` disagrees with this file, this file wins.
> [中文版](NAMING-DECISION.md)

---

## 0. Not a matter of taste — one name is pointing at two different components

`NAMING-REVIEW.md` sorts naming problems into three classes: A concept names (taste — don't
change), B name/content mismatch (a real defect — fix, but not casually), C external mapping
(just publish a table). **This document handles a fourth class that taxonomy missed: one name,
two things.**

The test involves no aesthetics at all:

> **The same word denotes two different components in two repositories, and the two
> glossaries contradict each other.**

The contradiction, as measured (not conjectured):

| Source | What "Benxiang 本象" is defined as |
|---|---|
| `本象协议/README.md` | A persistent, AI-native **object representation layer**; the Origin IR |
| `2origin-computer/README.md` architecture table | Benxiang → **GPU** → *world representation* |
| `ShadowOS/TERMINOLOGY.md` line 18 | **the observer** — the one and only implementation of "look at the world" |
| `ShadowOS/TERMINOLOGY.md` line 77 | "**Do not** translate Benxiang as *world model*. It does not model; it only observes." |

The translation that last line **explicitly forbids** is exactly the meaning the first two lines
rely on. This is not a translation disagreement — it is two components competing for one name,
and it has already hardened into both specs.

### Root cause: one name used for both the *specified ideal* and the *thing actually built*

`RFC-0006 §0` and `2origin-harness/README.md` both state that **"the one component never built
is Benxiang."** But that sentence is about the **observer**. The Benxiang in the architecture
table — *world representation* — **was** built; it just lives in a **different repository**:
`本象协议/compiler/` (87 language-neutral conformance vectors + an independent Python
implementation).

> **So the truth is: there have always been two components here, sharing one name.**
> This decision does not rename the observer. It **names, separately, two things that already existed.**

---

## 1. The decision

| Role | Chinese | English | Home repo | What it actually is |
|---|---|---|---|---|
| Representation | **本象** Benxiang | **Origin IR** | `本象协议` | Persistent representation of the world: objects / relations / payloads / states / constraints / provenance / **limits** |
| Sensing | **取象** Quxiang | **Sensor** | `ShadowOS` | The single implementation of "look at the world". Iron rule: `observe()` **never** receives an expectation |
| Learned state | **本境** Benjing | **State Layer** | `ShadowOS` | Durable task state: optimistic lock / recheckable sources / actor provenance |
| Environment | **本器** Benqi | **Machine Profile** | `本境协议` (uenv) | What this machine has and can run: tools / versions / proxy / can-it-build-this-project |

### The Chinese names are a matched set, not a coincidence

The first three come from the same chapter of the *Xici* commentary on the *I Ching*, where they
already stand in sequence:

```
观物取象   "observe things, take the image"     → Quxiang (sensing)      ← input
立象以尽意 "establish the image to exhaust meaning" → Benxiang (representation) ← the IR
形而下者谓之器 "what has form is called a vessel"   → Benqi (the machine itself)
```

**Take the image first, then establish it** — precisely the first two steps of
`Observe → Think`. The names encode the data flow.

### The four English names don't collide

`Origin IR` / `Sensor` / `State Layer` / `Machine Profile`. An English reader needs no Chinese
and no *I Ching* to place them. That is a hard requirement of this decision:
**the Chinese names carry the conceptual symmetry; the English names carry comprehensibility;
they need not be translations of each other.** Precedent exists — 影核 is `ActionParity`,
a rendering of sense, not sound.

### Why `Sensor` and not `Observer`

1. `Observer` collides head-on with the GoF Observer pattern (event subscription). An English
   reader's first association is pub/sub, which this is emphatically not.
2. The whole machine is a PC analogy (CPU / RAM / SSD / GPU / Northbridge / Southbridge).
   **Sensor fills the slot that was always empty there: the input device.**
3. Most important: **a sensor does not read 25°C because you were hoping for 25°C.** That is
   this component's one iron rule — `observe()` throws if handed a third argument.
   The name *is* the judgment.

### Why "Benxiang" goes to the representation layer, not the observer

Three reasons, by weight:

1. **Etymology.** "Establish the image to exhaust the meaning" is about *carrying* meaning —
   representation, not observation. Observation has its own word in the same text: *take* the image.
2. **The spec already says so.** `2origin-computer`'s table: Benxiang → GPU → world representation.
   Changing the spec costs far more than renaming one directory.
3. **Cost differs by an order of magnitude.** `本象协议` ships 87 conformance vectors, four
   dialects (CAD / law / xlsx / memory), a second implementation in Python, an English README
   and MANIFESTO, and **is already published**. The ShadowOS observer is one directory of five
   `.mjs` files.

### Why "Benjing" goes to the state layer, not the environment layer

1. **The spec already says so**: Benjing → SSD → *everything the AI learned*; `TERMINOLOGY.md`
   says `state layer`; the papers use it that way.
2. Etymologically 境 leans slightly toward *environment*. **This point argues against the
   decision** and is recorded as such — it loses to (1) because the spec and papers have the
   larger blast radius.
3. `Benqi` is in fact the better fit for uenv: it answers "what is this machine configured with",
   and `Machine Profile` is more precise than `Environment` (which is overloaded in English and
   collides with env vars).

---

## 2. The price tag (measured, not estimated)

`NAMING-REVIEW.md §2` set the rule: **quantify the blast radius before renaming, especially
`facts[].source` — those are evidence pointers, and a bulk find-and-replace downgrades
"recheckable" to "looks recheckable".** Done:

### Benxiang → Quxiang (ShadowOS)

| Location | Count | Nature |
|---|---|---|
| Code imports / paths | 19 | mechanical |
| Docs / RFC command lines | 29 | mechanical |
| **Task-state `facts[].source`** | **35** | **evidence pointers — must be rechecked one by one** |
| Anchor snapshots `governance/anchors/` | **16 files** | 🛑 **must never change** |
| State backups `demo/.benjing-backups/` | **67 files** | 🛑 **must never change** |
| Append-only ledger `observations.jsonl` | all | 🛑 **must never change** |

### Benjing → Benqi (本境协议 / uenv)

121 occurrences across 30 files (Rust / docs / config).

### A constraint you won't find elsewhere: **history is immutable, so the migration is bilingual forever**

The `benxiang` strings inside anchor snapshots and state backups are **what was true at the
time**. Change one byte and the `.ots` is void — that batch of Bitcoin time anchors dies with it.
Therefore:

> **Old and new names do not "coexist during a transition". They coexist permanently.**
> In historical evidence the name is forever `benxiang`; `quxiang` applies only to code and docs
> written from here on.

This is not a compromise. It follows from what an evidence chain *is*.
**The alias table is therefore not a migration tool — it is a permanent component.**

---

## 3. What happens now, and what does not

### ✅ This round (zero risk to the evidence chain)

- [x] Publish this decision, in both languages
- [ ] Fix the self-contradiction at `ShadowOS/TERMINOLOGY.md` lines 18 / 77 and point it here
- [ ] Add 取象 to the naming freeze in `ShadowOS/CLAUDE.md`
- [ ] Add the Sensor row to the `2origin-computer/README.md` architecture table — the input-device
      slot has been empty this whole time

### 🛑 Not this round (per `NAMING-REVIEW.md §2` preconditions)

**`git mv benxiang/ quxiang/` will not be executed.** Not one precondition is in place:

1. `dereferenceSource` needs a **path alias table** first (`benxiang/x.mjs` → `quxiang/x.mjs`)
   so that 35 verified facts still dereference after the move — **keep the evidence chain intact
   before touching any file**;
2. that table must be **bidirectional and permanent** (see end of §2), because 16 anchor
   snapshots will point at the old name forever;
3. run the full judgment suite after each batch and clear all 35 sources **individually** via the
   B12 dangling report — no global `sed`.

> Acting before the alias table exists would invalidate 35 verified facts' evidence pointers at
> once — which is exactly the conclusion `NAMING-REVIEW.md` reached for the `southbridge/` debt
> and has not yet paid off.
> **A naming decision should not, in the act of landing, commit the very error it cites.**

---

## 4. For translators and paper authors

- In papers, "Benxiang" always means **Origin IR (the representation layer)**. If the context is
  observation, write **Sensor**.
- **Do not** translate Quxiang as `Observer` (GoF collision) or `Watcher` (implies continuous
  listening; this is a one-shot call).
- **Do not** translate Benjing as `Environment` — that is Benqi. Benjing is the `State Layer`.
- The naming freeze (no changes within one quarter) now covers:
  2Origin / Benxiang / **Quxiang** / Benjing / **Benqi** / ActionParity / Northbridge /
  Southbridge / Academy.
