---
name: reference-gap-profiling
description: Use when a confirmed performance gap against a reference implementation, library, competitor, prior version, or baseline needs root-cause attribution, especially when source, counters, profilers, traces, or logs are available and black-box wall time would invite guessing.
---

# Reference Gap Profiling

Explain a measured performance gap by instrumenting the reference path and the local path, normalizing to a shared unit of work, and reading both implementations before naming a cause.

Use `performance-comparison` first when the inputs, correctness gate, or headline ranking are not yet fair. Use this skill after the gap is real enough to explain.

## Checklist

Copy this into the work log and check it off:

- [ ] Reuse before rebuild: inventory existing benchmarks, flags, profilers, traces, and logs.
- [ ] Pin a clean baseline: measure the production path, not a diagnostic shortcut.
- [ ] Instrument the reference: enable its counters first; compile or patch it only when needed.
- [ ] Normalize to a per-unit invariant: use cost per request, iteration, token, item, frame, or operation.
- [ ] Decompose the gap: separate count differences from per-unit cost differences.
- [ ] Expose confounds: reproduce surprising numbers before trusting them.
- [ ] Read both sources: localize with data, then name the mechanism in code.
- [ ] Land durable artifacts: reusable harness, evidence report, and ranked follow-up targets.

## Method

1. State the gap and the decision it affects. Include the compared systems, workload, correctness gate, hardware, limits, and exact commands.
2. Start from existing harnesses. Prefer production entrypoints with flags over one-off diagnostic binaries. Add tooling only for a missing measurement.
3. Confirm cleanliness. If local changes can pollute timing, build from a clean branch or isolated worktree with separate build output.
4. Instrument the reference in this order:
   - documented runtime counters or analysis logs;
   - standard profilers or tracing;
   - source build with small targeted patches.
5. Record comparable units. Wall time alone is not enough; capture the work count and a per-unit metric.
6. Split total gap into:
   - work-count factor: how much more work one system did;
   - per-unit factor: how expensive the same kind of work was;
   - unmapped work: setup, cleanup, retries, fallback paths, IO, allocation, scheduling, or post-processing.
7. Treat slices as hypotheses. A tiny case, profiler capture, or flamegraph can explain a mechanism, but representative workloads rank priorities.
8. Read the reference and local source for load-bearing claims. Data can point at a region; code must explain why.
9. Write an evidence report under the repo's `performance/<topic>/` workspace unless the repo already has a stronger convention.

## Evidence Report

Use this shape for `performance/<topic>/report.md`:

```markdown
# <topic> Reference Gap Profile

## Question
What decision this analysis supports.

## Common Contract
Workload, correctness gate, config, machine, limits, and commands.

## Baseline
Table with system, status, wall time, work units, per-unit metric, resources, and notes.

## Decomposition
Count factor, per-unit factor, mapped regions, unmapped work, and confounds.

## Attribution
Profiler, counter, trace, log, and source evidence with file:line citations where possible.

## Caveats
Instrumentation overhead, noisy runs, excluded cases, non-production paths, and missing counters.

## Next Actions
Ranked changes, follow-up measurements, or stop condition.
```

## Traps

- Do not infer causes from black-box wall time when source or counters are available.
- Do not compare profiler output as the headline benchmark.
- Do not average over confounds; explain or exclude them.
- Do not trust a single surprising run until it reproduces through the production path.
- Do not let delegated code reads become proof. Re-read load-bearing source lines yourself.
- Do not tune one downstream knob while upstream phases are changing the work mix.
