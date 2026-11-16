# pm4exunit migration plan v26.11.16

Standing: UNVERIFIED

## Identity
- Path: /Users/sac/pm4exunit
- Remote: https://github.com/seanchatmangpt/pm4exunit.git (origin/main)
- Branch: main@7ca9dd3, last commit 2026-11-12, 7 commits
- Size: 1 MB
- Languages/build: Elixir (mix.exs, mix.lock), ex_doc; Diataxis docs/
- Nested repos: none

## Observed state
- Dirty 11 / untracked 6: docs/how-to (3), docs/explanation (2), docs/tutorials, docs/reference,
  README.md, SECURITY.md, mix.exs, lib/pm4exunit — a docs-and-packaging pass in flight.
- Ahead/behind 0/0. Stash 0. Unpushed branches 0.
- doc/ (generated ex_doc output) present, ignored. No _build/deps measured (tiny). No .env.

## What it is
pm4exunit: process-conformance and latency assertions for ExUnit — record emitted events in a
test, assert the trace follows an allowed process model and meets time limits. Consumed by
ash_a2a's multi-agent tests.

## Classification
ACTIVE (census agrees).

## Migration risk
MEDIUM. 11 modified + 6 new files uncommitted (docs rewrite, mix.exs change, lib edit); nothing
else local-only.

## Recommended action
COMMIT-PUSH
1. `cd /Users/sac/pm4exunit && git diff --stat` — confirm the docs/mix.exs edits are intended.
2. `git add -A && git commit -F <msg>` (repo rule: commit via -F, lines <= 100 chars).
3. `git push origin main`.
4. `rm -rf _build deps doc` before any copy (all regenerable).
5. Clone fresh.

## First commands on the new machine
`git clone https://github.com/seanchatmangpt/pm4exunit.git && cd pm4exunit && mix deps.get && mix compile && mix test`

## See Also
- ../v26.11.12/
- /Users/sac/docs/jira/v26.11.16/README.md
