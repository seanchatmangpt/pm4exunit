# Assert on a plain list of activities

The first argument to `assert_conformance/3` and `refute_conformance/3` (and `assert_sla/4`, which
needs timestamped event maps) may be a session pid, a `%Pm4ExUnit.TraceCollector{}`, or a
list of events. A list may hold atoms, strings, or maps with `:activity`, `:name`, or
`"concept:name"`:

```elixir
assert_conformance([:a, :b, :c], [[:a, :b, :c]])
```

This needs no session. In a test that does not `use Pm4ExUnit`, add
`import Pm4ExUnit.Assertions` first.
