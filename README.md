# pm4exunit

Process-conformance and latency assertions for ExUnit. Record the events your code emits during a
test, then assert that the trace follows an allowed process model and meets its time limits.

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

## Install

```elixir
def deps do
  [{:pm4exunit, "~> 0.1", only: :test}]
end
```

Requires Elixir 1.15 or later. No runtime dependencies.

## What it does

- **Conformance:** `assert_conformance/3` and `refute_conformance/3` replay a trace against one or
  more valid paths using token-based replay, and report a fitness score in `0.0..1.0`.
- **Latency:** `assert_sla/4` bounds the time between two activities.
- **Recording:** each test gets its own session process (`%{pm4_session: pid}`) that stores events
  and OCEL-style objects.
- **Reporting:** `Pm4ExUnit.Reporter` formats a result as TAP v13 or JUnit XML.

Replay semantics port the pm4vitest TBR engine, so the same model and trace score identically in
both. This is verified by `test/pm4exunit_cross_engine_vector_test.exs`.

## Documentation

The docs follow [Diátaxis](https://diataxis.fr). Start at [`docs/README.md`](docs/README.md).

| You want to | Read |
|---|---|
| Learn by doing | [Tutorials](docs/tutorials/first-conformance-test.md) |
| Solve a specific task | [How-to guides](docs/how-to/) |
| Look up an API | [Reference](docs/reference/api.md) |
| Understand the model | [Explanation](docs/explanation/token-based-replay.md) |

## Known limitations

- `assert_sla/4` uses the first occurrence of each activity. Repeated activities are not paired.
- An event with a missing or unparsable timestamp falls back to `DateTime.utc_now()` inside
  `Pm4ExUnit.Temporal`. Always pass explicit timestamps when asserting SLAs.
- Object-centric querying (OCPQ) is not implemented. Objects are recorded but not queryable.

## License

MIT. See [LICENSE](LICENSE).
