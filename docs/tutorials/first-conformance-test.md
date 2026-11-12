# Write your first conformance test

In this tutorial you will add pm4exunit to a project, record events in a test, and watch a
conformance assertion pass and then fail. It takes about ten minutes.

## 1. Add the dependency

In `mix.exs`:

```elixir
{:pm4exunit, "~> 0.1", only: :test}
```

Run `mix deps.get`.

## 2. Write a passing test

Create `test/order_saga_test.exs`:

```elixir
defmodule OrderSagaTest do
  use ExUnit.Case
  use Pm4ExUnit

  test "order saga follows the model", %{pm4_session: session} do
    emit_event(session, "e1", :order_created)
    emit_event(session, "e2", :payment_processed)
    emit_event(session, "e3", :order_fulfilled)

    assert_conformance(session, [[:order_created, :payment_processed, :order_fulfilled]])
  end
end
```

`use Pm4ExUnit` starts a session for each test and passes it in the test context as
`:pm4_session`. The list of lists is the model: each inner list is one allowed path.

Run `mix test`. The test passes.

## 3. Break it

Delete the `:payment_processed` line and run `mix test` again. The assertion fails with a
message like:

```text
Process Conformance Assertion Failed!
Minimum Fitness Required: 1.0
Observed Fitness: 0.5
Violations:
  * Conformance fitness 0.5 is below required minimum 1.0.
  * Trace missed 1 mandatory transition(s) in path: ["order_created", "payment_processed", "order_fulfilled"].
  * Trace ended with 1 unconsumed token(s) (premature termination or superfluous transitions).
```

The skipped step is named in the violations.

## 4. Add a latency limit

Add a second test:

```elixir
test "fulfilment is fast enough", %{pm4_session: session} do
  t0 = ~U[2026-11-12 10:00:00Z]

  emit_event(session, "e1", :order_created, timestamp: t0)
  emit_event(session, "e2", :order_fulfilled, timestamp: DateTime.add(t0, 2, :second))

  assert_sla(session, :order_created, :order_fulfilled, max_seconds: 5.0)
end
```

Change `2` to `9` and it fails with `SLA violated`.

## Next

- Several valid paths: [model-multiple-paths](../how-to/model-multiple-paths.md)
- What the fitness number means: [token-based replay](../explanation/token-based-replay.md)
