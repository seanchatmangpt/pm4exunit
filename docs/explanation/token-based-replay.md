# How token-based replay scores a trace

Each valid path becomes a branch of a Petri net. All branches share one source place and one sink
place; within a branch each activity is a transition between consecutive places. The source
holds one token at the start.

Replaying a trace fires the transition matching each activity. If the needed input token is not
there, a token is created artificially and counted as **missing**. After the last event, any token
not in the sink is counted as **remaining**. With several branches, replay backtracks to choose
the firing sequence that minimises `(missing, remaining)` in that order.

```text
fitness = 0.5 * (1 - missing / consumed) + 0.5 * (1 - remaining / produced)
```

A perfect trace has fitness `1.0`. `assert_conformance` additionally requires `missing == 0`, so
a trace cannot pass by being mostly right when it skipped a mandatory step. An empty trace leaves
the initial token stranded and scores `0.5`, matching the TypeScript engine.

Backtracking is bounded by a budget of 100,000 search steps so pathological models terminate.

Why this model: it is the same standard TBR used in process mining, so a model written for pm4py
or pm4vitest means the same thing here. It tells you which step is missing, not only that
something is wrong.
