# How token-based replay scores a trace

Each valid path becomes a branch of a Petri net. All branches share one source place and one sink
place; within a branch each activity is a transition between consecutive places. The source
holds one token at the start.

Replaying a trace tries, for each activity, to fire a transition with that label whose input place
holds a token. If none can fire, the event is a cannot-fire step: it counts as **missing** and as
one consumed token, and produces nothing. No token is manufactured. After the last event, every
token outside the sink place is counted as **remaining**. With several branches, replay
backtracks to choose the firing sequence that minimises `(missing, remaining)` in that order.

```text
fitness = 0.5 * (1 - missing / consumed) + 0.5 * (1 - remaining / produced)
```

A perfect trace has fitness `1.0`. `assert_conformance` additionally requires `missing == 0`, so
a trace cannot pass by being mostly right when it skipped a mandatory step. An empty trace leaves
the initial token stranded and scores `0.5`, matching the TypeScript engine.

Backtracking is capped at 100,000 search steps. If the cap is exceeded, replay gives up and treats
every event as cannot-fire, so the result is pessimistic (low fitness) rather than an error. A
zero denominator in either ratio counts as 0.

Why this model: it ports the token-based replay of pm4vitest (the TypeScript engine) and is
checked against it counter for counter by the cross-engine vector tests. It follows the usual
TBR idea of missing and remaining tokens, but it is not verified against pm4py. The reported
`best_path` and `missing_transitions` are chosen by longest common subsequence and are
diagnostics only.
