# Long-Term AI Computer Open Challenge

## What belongs here

The challenge is for tasks that test whether state survives time, interruption, model changes, and
real-world actions. A suitable task normally has at least two of these properties:

- it cannot be completed in one ordinary chat session;
- it spans many files, tools, models, or people;
- facts, constraints, and decisions change over time;
- it must resume correctly after interruption;
- completion can be verified from real artifacts rather than model self-report;
- failures are useful enough to publish and learn from.

Typical directions include million-word content engineering, large tenders and reports,
multi-session software projects, multimodal archive analysis, and long-running research.

## Submission and acceptance

1. Submit an Issue with the goal, scale, materials, and disclosure boundary.
2. We screen for fit, safety, legality, and available resources.
3. Before accepting, both sides write down success criteria, failure criteria, tool permissions,
   privacy boundaries, and a cost ceiling.
4. An accepted task receives an independent durable state and a public or redacted progress record.
5. The final report includes artifacts, verification results, human intervention, limitations, and
   any retracted claims.

Submitting an Issue does not mean the task has been accepted.

## Tasks we do not accept

- illegal, deceptive, infringing, or unsafe work;
- data, accounts, or confidential material the submitter cannot authorize;
- tasks whose success cannot be observed;
- requests to generate volume without testing consistency, recovery, or verification;
- requests to guarantee results or invent customers, awards, endorsements, or benchmarks.

## Disclosure levels

- **Public:** prompt, data, process, and results may be published.
- **Redacted process:** method and aggregate results may be published; source materials stay private.
- **Approved conclusions only:** nothing is published without explicit agreement on the exact text.

Personal information, trade secrets, and copyrighted source material are private by default.

## Minimum final audit

Every accepted challenge must answer:

1. Does the final artifact exist in the real world?
2. Can important facts be traced to sources?
3. Can the task resume after interruption or a model swap?
4. Are failures, retries, and human interventions recorded?
5. Can a third party reproduce every conclusion we claim is public and reproducible?

