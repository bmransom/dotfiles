---
name: performance-comparison
description: Use when comparing two systems, implementations, algorithms, models, tools, or versions for speed, throughput, cost, scaling, or resource performance.
---

# Performance Comparison

Compare systems by making the work identical first, then measure, explain, and rank with evidence.

## Workflow

1. Define the question: what decision will this comparison change?
2. Establish a common input interface:
   - same workload or request set;
   - same correctness or quality gate;
   - same configuration class unless the difference is the experiment;
   - same machine, limits, warmup, concurrency, and data version where possible.
3. Use production-faithful paths for ranking. If a diagnostic path bypasses production setup, label it as diagnostic and do not use it for headline results.
4. Separate run types:
   - **Ranking runs** compare outcomes across representative workloads.
   - **Explanation runs** use profiling, tracing, logs, counters, or source builds to explain a confirmed gap.
5. Normalize metrics:
   - wall time or latency;
   - work units completed;
   - time per work unit;
   - throughput;
   - success/failure and correctness/quality gate;
   - CPU, memory, IO, network, or accelerator usage when relevant.
6. Attribute the gap with evidence. Use profilers, trace points, logging, or instrumented builds only after a fair comparison shows a real gap.
7. Write the conclusion with caveats and next actions.

## Repo Workspace

When invoked in a repo, create or use `performance/` for local evidence:

```text
performance/
  README.md
  <topic-or-date>/
    plan.md
    runs/
    metrics.csv
    report.md
```

Keep raw logs, profiler captures, and generated metrics in `performance/<topic>/runs/`. Keep the reusable skill free of repo-specific artifacts.

## Report Template

```markdown
# <topic> Performance Comparison

## Question
Decision this measurement supports.

## Common Input Contract
Workload, configuration, environment, correctness gate.

## Results
Table with system, status, wall time, work units, normalized metric, resources, notes.

## Attribution
Evidence from profiling, logs, counters, traces, or source inspection.

## Caveats
Instrumentation overhead, noisy cases, skipped workloads, non-production paths.

## Next Actions
Ranked changes, follow-up measurements, or stop condition.
```

## Traps

- Do not compare different inputs, hidden defaults, or different production paths.
- Do not rank work from a tiny slice; use slices for hypotheses and representative corpora for decisions.
- Do not treat profiler output as a headline benchmark.
- Do not ignore correctness, quality, or status differences.
- Do not assume a faster reference implementation proves why it is faster; measure the gap.
