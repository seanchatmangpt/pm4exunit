# Contributing

Thanks for improving pm4exunit, an Elixir library for process-conformance testing inside ExUnit.

## Setup

```sh
mix deps.get
mix test
```

`mix test` runs the whole suite (15 tests, 0 failures at v26.11.12).

The repo has no `.formatter.exs`, so `mix format --check-formatted` exits with an error and is not
a gate yet. If you add a `.formatter.exs`, run `mix format --check-formatted` before sending a
change.

## Project layout

All library code lives in `lib/`:

```text
lib/pm4exunit.ex                 public entry point
lib/pm4exunit/assertions.ex      assertion macros and functions
lib/pm4exunit/conformance.ex     conformance checking (token-based replay)
lib/pm4exunit/reporter.ex        TAP and JUnit output
lib/pm4exunit/session.ex         per-test session
lib/pm4exunit/temporal.ex        temporal and latency checks
lib/pm4exunit/trace_collector.ex trace collection
```

## Testing style

- Use real collaborators. Mocks, stubs, and `Mox`-style patching of code we own are not accepted.
- Assert on final state: the resulting trace, verdict, or output, not on call counts.
- If a real collaborator is infeasible, use a simple hand-written fake and say why in the test.
- Do not use `Process.sleep` to coordinate. Poll an observable with a deadline instead.

## Docs conventions

Docs under `docs/` follow Diataxis:

| Directory | Purpose |
|---|---|
| `docs/tutorials/` | Learning-oriented walkthroughs |
| `docs/how-to/` | Task-oriented recipes |
| `docs/reference/` | Accurate API description |
| `docs/explanation/` | Background and design rationale |

Markdown rules: the H1 matches the file's topic, filenames are kebab-case, lines are at most 100
characters, and code blocks carry a language tag. End each page with a See Also section.

## Versioning

Releases use CalVer `vYY.M.D`, for example `v26.11.12`. The version is set once in `mix.exs`:

```elixir
@version "26.11.12"
```

Bump `@version` there and nowhere else.

## See Also

- [README](README.md)
- [API reference](docs/reference/api.md)
- [Docs index](docs/README.md)
