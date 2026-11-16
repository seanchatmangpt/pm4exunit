# API reference

## `use Pm4ExUnit`

Imports `Pm4ExUnit.Assertions`, aliases `Pm4ExUnit.Session`, and adds a `setup` that calls
`Session.start_link(test_name: to_string(context.test))` and puts the pid in the context as
`:pm4_session`. `use Pm4ExUnit` takes no options. Defines two helpers in the test module:

| Function | Description |
|---|---|
| `emit_event(session, event_id, activity, opts \\ [])` | Append an event. Returns `:ok`. |
| `register_object(session, obj_id, obj_type, attrs \\ %{})` | Record an object. Returns `:ok`. |

`emit_event` options (keyword list or map): `:timestamp` (`DateTime`, default now), `:attributes`
(map, default `%{}`), `:relationships` (list; falls back to `:objects`, default `[]`). `event_id`
and `activity` are stored as strings. Events are appended in call order.

## `Pm4ExUnit.Assertions`

`source` is a session pid, a `%Pm4ExUnit.TraceCollector{}`, or a list of events.

| Function | Description |
|---|---|
| `assert_conformance(source, valid_paths, opts \\ [])` | Fails unless `fitness >= min_fitness` and `missing_tokens == 0`. Remaining tokens matter only through fitness. |
| `refute_conformance(source, valid_paths, opts \\ [])` | Fails if the trace would pass `assert_conformance` with the same options. |
| `assert_sla(source, from, to, opts \\ [])` | Uses the first event for `from` and the first for `to`. Fails if either is absent or `to - from` exceeds the limit. A negative gap passes. |

Options: `min_fitness:` (default `1.0`) for conformance; `max_seconds:` or `max_duration:`
(both in seconds; one is required, omitting both raises `KeyError`) for SLA. All return the result
map on success.

## Result maps

Conformance: `%{success, fitness, violations, diagnostics}`. `diagnostics` holds `trace`,
`target_path`, `best_path`, `produced`, `consumed`, `missing_tokens`, `remaining_tokens`,
`missing_transitions`, `remaining_tokens_map`.

SLA: `%{success, actual_seconds, max_seconds, violations, diagnostics}`. `actual_seconds` is `nil`
and `diagnostics` is `%{}` when an activity is absent; otherwise `diagnostics` has `from`, `to`,
`duration_ms`, `start_time`, `end_time`.

## Other modules

| Module | Purpose |
|---|---|
| `Pm4ExUnit.Session` | GenServer holding one test's collector. `start_link/1` (opt `:test_name`), `emit_event/4`, `register_object/4`, `get_events/1`, `get_collector/1`. |
| `Pm4ExUnit.TraceCollector` | Pure struct `%{objects: %{}, events: []}`. `new/0`, `register_object/4` (default `attributes: %{}`), `emit_event/4` (default `opts: []`). |
| `Pm4ExUnit.Conformance` | `evaluate(events, valid_paths, opts \\ [])`; the replay engine (`:min_fitness` default `1.0`). Events may be `%{activity:}`, `%{"concept:name"}`, `%{name:}`, or bare strings/atoms. |
| `Pm4ExUnit.Temporal` | `evaluate_sla(events, from, to, max_seconds)`. Reads `:timestamp` (`DateTime`) or `"time:timestamp"` (ISO8601 string). |
| `Pm4ExUnit.Reporter` | `format_tap(test_name, success, violations, diagnostics)`; `format_junit(test_name, success, violations, diagnostics, duration_seconds \\ 0.001)`. Both return a string. No JSON formatter exists. |

Activity names are compared as strings, so `:a` and `"a"` are the same activity.
