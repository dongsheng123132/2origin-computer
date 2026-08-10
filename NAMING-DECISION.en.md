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

> **Revised in v0.2:** `Benqi` is retired, `Benli` takes the state layer, and `Benjing` returns to
> the environment layer. Rationale in §1.1.

| Role | Chinese | English | Home repo | What it actually is |
|---|---|---|---|---|
| The machine | **本源 AI 计算机** | 2Origin AI Computer | — | The whole machine. **The machine's name takes no component's name** — a part standing in for the whole is, in this system's own vocabulary, a projection impersonating the origin |
| Representation | **本象** Benxiang | **Origin IR** | `本象协议` | Persistent representation of the world: objects / relations / payloads / states / constraints / provenance / **limits** |
| Sensing | **取象** Quxiang | **Sensor** | `ShadowOS` | The single implementation of "look at the world". Iron rule: `observe()` **never** receives an expectation |
| Learned state | **本历** Benli | **State Layer** | `ShadowOS` | Durable task state: optimistic lock / recheckable sources / actor provenance |
| Environment | **本境** Benjing | **Machine Profile** | `本境协议` (uenv) | What this machine has and can run: tools / versions / proxy / can-it-build-this-project |

### 1.1 Why v0.1's "Benjing = learned state" was overturned

v0.1 assigned Benjing to the state layer and, in the same section, recorded the evidence against
itself:

> "Etymologically 境 leans slightly toward *environment*. **This point argues against the
> decision** and is recorded as such — it loses to (1)."

That recorded counter-evidence was later cited to overturn the decision. This is what writing
down the inconvenient point is *for*. 历 means *record, history, what one has been through* —
literally a curriculum vitae; 境 means *environment* — literally what uenv manages. Once each word
sits where it belongs:

- `本历` shares the character 历 with 学历 ("academic record"); Chinese readers need no gloss.
- **`本器` retires with it.** That name existed only to work around Benjing being occupied.
  **A patch disappearing is a signal the solution is right**: if a proposal needs a name whose sole
  purpose is dodging a collision, the collision probably wasn't solved.

### 1.2 Why the machine is not called "Benxiang AI Computer"

Seriously considered, with a replacement ready for the representation layer (**立象** *Lixiang* —
forming the *Xici*'s own verb pair: 观物取象 → 立象以尽意). Rejected, for two reasons:

1. **`本象协议` is the only component in this system pinned down by an external contract** —
   87 language-neutral conformance vectors, a second implementation in Python, 13 mutation checks.
   It is the only thing where a stranger can write their own implementation and prove conformance
   on the spot. The real cost of renaming it is not 945 text substitutions; it is **the semantic
   continuity of those 87 vectors**, whose value comes precisely from not moving.
2. **A machine name occupying a component name is a part impersonating the whole** — in this
   system's vocabulary, the same shape as a projection impersonating the origin. `2Origin` is a
   neutral name for the whole and competes with no component.

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
  2Origin / Benxiang / **Quxiang** / **Benli** / Benjing / ActionParity / Northbridge /
  Southbridge / Academy.

---

## 5. Names must also go candidate → verified

### 5.1 The disease

Count the names already in play: Benxiang, Benjing, Benli, Quxiang, ActionParity, Southbridge,
Northbridge, Academy, task state, learning, conformance judgment, out-of-band, anchoring, Origin IR,
bugscope, ShadowBench…

Now count, by this system's own standard ("one implementation passing its own tests does not
prove a protocol exists" — `本象协议/spec/conformance/README.md`), how many are **externally
verifiable**: **one**. Every other is a house implementation running house tests.

> **Naming has outrun verification. Names are free; judgments are expensive.**
> Every additional name adds one more component that *appears* to exist.

This is the same disease the Academy audit found — **58 learnings, 49 self-declared `verified`,
0 reproducible by anyone** — recurring at the naming layer, which has had no exam at all.

### 5.2 The rule (isomorphic to the Academy's learning lifecycle)

> **To define a name is to make an unverified existence claim.**
> "We have an X layer" has the same shape as bugscope A1, *presence ≠ verification*: naming it
> declares it exists.

| State | Condition |
|---|---|
| `candidate` | Proposed, but **no judgment turns red if the component is absent** |
| `verified` | A judgment in some `verify-*.mjs` pins it; remove the component and that judgment fails |

Symmetric with the Academy: **`verified` is granted by a judgment, never by the author.**

### 5.3 Current gaps stay `candidate` — no official names issued

After walking the motherboard, these slots are empty. Per §5.2 they **do not get names**:

| Gap | Observed failure it maps to | State |
|---|---|---|
| Memory protection / ownership | **Concurrent sessions eating task state (observed in practice)** | `candidate` — the only one backed by a real failure |
| Watchdog | Hung task / infinite loop, no auto-recovery | `candidate` — no observed case |
| Budget management | Token budget only half-handled, inside the Northbridge | `candidate` — no observed case |
| ~~DMA~~ | — | **withdrawn** |

### 5.4 One gap withdrawn, and why

The first draft listed **DMA** ("bulk data transfer bypassing the model"), copied from the
motherboard checklist. **Withdrawn.**

DMA's value is bypassing the CPU. In an LLM system, moving data without the model *is just a
function call* — it needs no component name. It appeared on the list only because a motherboard has one.

> **A metaphor that generates questions also conceals them.** The motherboard is the physical
> realization of the von Neumann architecture, whose premises are that instructions and data are
> separable, control flow is predictable, and state is exactly copyable. **Large models satisfy
> none of the three.** Filling in a motherboard checklist yields components that mean nothing here.

**So the test is not "does a motherboard have one", but "does it map to a failure actually
observed".** Memory protection passes; DMA does not.

This section is the first time the system turns its method on its own names. It has audited facts,
learnings, actions and time — never its vocabulary.
