# API reference

## `use Pm4ExUnit`

Imports `Pm4ExUnit.Assertions`, aliases `Pm4ExUnit.Session`, and adds a `setup` that starts a
session and puts it in the context as `:pm4_session`. Defines two helpers in the test module:

| Function | Description |
|---|---|
| `emit_event(session, event_id, activity, opts \\ [])` | Append an event. Returns `:ok`. |
| `register_object(session, obj_id, obj_type, attrs \\ %{})` | Record an object. Returns `:ok`. |

`emit_event` options: `:timestamp` (`DateTime`, default now), `:attributes` (map),
`:relationships` or `:objects` (list).

## `Pm4ExUnit.Assertions`

`source` is a session pid, a `%Pm4ExUnit.TraceCollector{}`, or a list of events.

| Function | Description |
|---|---|
| `assert_conformance(source, valid_paths, opts \\ [])` | Fails unless `fitness >= min_fitness` and no tokens are missing. |
| `refute_conformance(source, valid_paths, opts \\ [])` | Fails if the trace conforms. |
| `assert_sla(source, from, to, opts \\ [])` | Fails if the gap exceeds the limit or an activity is absent. |

Options: `min_fitness:` (default `1.0`) for conformance; `max_seconds:` or `max_duration:`
(required) for SLA. All return the result map on success.

## Result maps

Conformance: `%{success, fitness, violations, diagnostics}`. `diagnostics` holds `trace`,
`target_path`, `best_path`, `produced`, `consumed`, `missing_tokens`, `remaining_tokens`,
`missing_transitions`, `remaining_tokens_map`.

SLA: `%{success, actual_seconds, max_seconds, violations, diagnostics}`.

## Other modules

| Module | Purpose |
|---|---|
| `Pm4ExUnit.Session` | GenServer holding one test's collector. `emit_event/4`, `register_object/4`, `get_events/1`, `get_collector/1`. |
| `Pm4ExUnit.TraceCollector` | Pure struct of `objects` and `events`. `new/0`, `emit_event/4`, `register_object/4`. |
| `Pm4ExUnit.Conformance` | `evaluate(events, valid_paths, opts)`; the replay engine. |
| `Pm4ExUnit.Temporal` | `evaluate_sla(events, from, to, max_seconds)`. |
| `Pm4ExUnit.Reporter` | `format_tap/4`, `format_junit/5`. |

Activity names are compared as strings, so `:a` and `"a"` are the same activity.
