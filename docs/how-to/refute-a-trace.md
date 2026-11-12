# Assert that a trace is rejected

Use `refute_conformance/3` to prove that a bad trace is caught:

```elixir
emit_event(session, "e1", :order_created)
emit_event(session, "e3", :order_fulfilled)

refute_conformance(session, [[:order_created, :payment_processed, :order_fulfilled]])
```

It raises `ExUnit.AssertionError` if the trace conforms.
