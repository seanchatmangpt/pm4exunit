# Enforce a latency SLA

Give both events explicit timestamps and bound the gap:

```elixir
emit_event(session, "e1", :request_received, timestamp: t0)
emit_event(session, "e2", :response_dispatched, timestamp: t1)

assert_sla(session, :request_received, :response_dispatched, max_seconds: 5.0)
```

`max_duration:` is accepted as an alias for `max_seconds:`.

Cautions:

- Always pass `timestamp:`. A missing or unparsable timestamp falls back to the current time, which
  makes the result nondeterministic.
- Only the first occurrence of each activity is used.
- If either activity is absent, the assertion fails with a "was not observed" violation.
