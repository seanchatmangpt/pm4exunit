# Assert that a trace is rejected

Use `refute_conformance/3` to prove that a trace is rejected: it fails the model, or its fitness
is below `:min_fitness` (default `1.0`). Requires `use Pm4ExUnit`, which imports the assertions
and defines `emit_event/4`:

```elixir
emit_event(session, "e1", :order_created)
emit_event(session, "e3", :order_fulfilled)

refute_conformance(session, [[:order_created, :payment_processed, :order_fulfilled]])
```

It raises `ExUnit.AssertionError` if the trace conforms. It returns the evaluation result
(`%{success: false, violations: [...], diagnostics: %{...}}`), so you can assert on `violations`.
