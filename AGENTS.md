# AGENTS

Agent-facing guide for `pm4exunit` (Elixir, CalVer 26.11.12): process mining, conformance
checking, and temporal SLA assertions for ExUnit. Counterpart of `pm4pytest`.

## Commands

Verified by running them in this checkout:

- `mix compile` - builds the library.
- `mix test` - runs all tests (15 tests, 0 failures at time of writing).

## Module map

- `lib/pm4exunit.ex` - `Pm4ExUnit`: entry point, `__using__` macro for test modules.
- `lib/pm4exunit/assertions.ex` - `assert_conformance`, `refute_conformance`, `assert_sla`.
- `lib/pm4exunit/conformance.ex` - token-based replay and FSM conformance (`evaluate/3`).
- `lib/pm4exunit/temporal.ex` - latency SLA between two activities (`evaluate_sla/4`).
- `lib/pm4exunit/session.ex` - per-test GenServer holding events and objects.
- `lib/pm4exunit/trace_collector.ex` - in-memory OCEL 2.0 object and event recording.
- `lib/pm4exunit/reporter.ex` - TAP v13 and JUnit XML output.

Tests live in `test/` (compat verification, cross-engine vectors, main suite).

## Conventions

- Tests are Chicago-style: real collaborators (real Session, real Conformance), assert on
  final state. No mocks, no `Mock`/`patch` style doubles.
- Docs are Diataxis under `docs/`: `tutorials/`, `how-to/`, `reference/`, `explanation/`.
- Never edit generated `doc/` (ex_doc output) or `_build/`; both are gitignored.
- Version is CalVer, set via `@version` in `mix.exs`.
- Git: never rebase, never force-push; merge only.
