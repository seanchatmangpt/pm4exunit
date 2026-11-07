# pm4exunit

**pm4exunit** is the native Elixir / ExUnit equivalent of [`pm4pytest`](../pm4pytest), providing autonomous Process Mining, Token-Based Replay (TBR) Conformance Checking, Temporal SLA latency enforcement, and Object-Centric Process Querying (OCPQ) for BEAM/Elixir test suites.

---

## Capabilities

1. **Native ExUnit Integration (`use Pm4ExUnit`)**:
   - Zero-overhead test instrumentation via process-bound `Session`.
   - Built-in `emit_event/4` and `register_object/4`.
2. **Formal Conformance Assertions**:
   - `assert_conformance(session, valid_paths, min_fitness: 1.0)`: Token-Based Replay (TBR) conformance checking against finite state machine DAGs or multi-path sagas.
   - Computes formal token fitness:
     $$\text{fitness} = \frac{1}{2}\left(1 - \frac{\text{missing}}{\text{consumed}}\right) + \frac{1}{2}\left(1 - \frac{\text{remaining}}{\text{produced}}\right)$$
   - Diagnoses missing mandatory transitions and unexpected/unconsumed tokens.
3. **Temporal SLA Gates**:
   - `assert_sla(session, :from_activity, :to_activity, max_seconds: float)`: Enforces upper bounds on execution latency between transitions.
4. **Universal Test Protocol Reporters**:
   - **TAP v13 (Test Anything Protocol)** with structured YAML diagnostic blocks.
   - **JUnit XML** for CI/CD pipeline integration.

---

## Usage in ExUnit

```elixir
defmodule MyDomainSagaTest do
  use ExUnit.Case
  use Pm4ExUnit

  test "work order state machine satisfies FSM conformance", %{pm4_session: session} do
    emit_event(session, "e1", :draft)
    emit_event(session, "e2", :ingested)
    emit_event(session, "e3", :dispatched)
    emit_event(session, "e4", :completed)

    assert_conformance(
      session,
      [
        [:draft, :ingested, :dispatched, :completed],
        [:draft, :ingested, :cancelled]
      ],
      min_fitness: 1.0
    )
  end

  test "dispatch-to-fulfillment temporal SLA", %{pm4_session: session} do
    t0 = DateTime.utc_now()
    t1 = DateTime.add(t0, 3, :second)

    emit_event(session, "e1", :dispatched, timestamp: t0)
    emit_event(session, "e2", :completed, timestamp: t1)

    assert_sla(session, :dispatched, :completed, max_seconds: 5.0)
  end
end
```
