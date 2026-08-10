# Evidence and Limits

This page is the citation boundary for the Long-Term AI Computer Open Challenge. Marketing copy
must not turn a narrower result into a broader claim.

## Current external-control result

Source: [`2origin-harness/bench/RESULTS-v4.md`](https://github.com/dongsheng123132/2origin-harness/blob/HEAD/bench/RESULTS-v4.md)

- Run: 2026-08-09, `deepseek-v4-flash`, temperature 0.
- 76 questions × 7 arms = 532 calls; 0 call errors and 0 residual truncations.
- The external comparison used mem0 2.0.17 plus self-built summary, lexical RAG, transcript,
  10× transcript, and empty-context arms.

The initial headline number was 97.5% balanced factual recall for 2Origin versus 55.0% for mem0.
That number **must not be quoted alone**. A publication-day audit found that the controls did not
contain the answers to 10 of the 20 true-fact questions because the durable state kept evolving while
the transcript corpus was frozen.

After splitting by answer availability:

| measurable distinction | 2Origin | lexical RAG | mem0 |
|---|---:|---:|---:|
| true facts whose answers were present in the corpus (TPR, n=10) | 90% | **90%** | 70% |
| reject facts belonging to other tasks (TNR, n=20) | **100%** | 55% | 60% |

The supportable claim is therefore narrower and more useful:

> There is no evidence here that structured state retrieves available facts better than lexical RAG.
> The measured advantage is task boundary and verification status: 2Origin was better at rejecting
> real facts that belonged to a different task.

## What this does not prove

- It does not prove stronger reasoning. The two-hop probe remains retracted; 2Origin tied the empty
  context floor in v4.
- It does not establish general superiority over memory systems. Only mem0 was connected; Letta,
  LangMem, Zep, and others were not tested.
- It is one model, one task, one run, without resampling.
- The mem0 arm used a local Hugging Face embedder rather than its default OpenAI embedding.
- The corpus is the project's own work history; external validity is untested.

## Evaluation apparatus

[`self-attesting-evaluation`](https://github.com/dongsheng123132/self-attesting-evaluation)
publishes evaluation failures, repairs, and retractions. Its machine-checked judgments are guardrails,
not customer cases or third-party benchmark wins. They do not imply zero hallucinations or absolute
reliability.

## “World-first” claim

“World-first long-term AI computer prototype” is the initiator's public, falsifiable description.
It is not a certification or industry standard.

A counterexample should provide an earlier public date, a runnable implementation or sufficiently
complete technical artifact, and comparable properties: replaceable model, durable state, auditable
action, and resumable tasks. Verified counterexamples will be recorded and the wording updated.

