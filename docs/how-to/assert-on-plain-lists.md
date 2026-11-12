# Assert on a plain list of activities

The first argument to every assertion may be a session pid, a `%Pm4ExUnit.TraceCollector{}`, or a
list of events. A list may hold atoms, strings, or maps with `:activity`, `:name`, or
`"concept:name"`:

```elixir
assert_conformance([:a, :b, :c], [[:a, :b, :c]])
```

This needs no session, so it also works in tests that do not `use Pm4ExUnit`.
