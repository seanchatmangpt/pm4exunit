# Emit TAP or JUnit output

`assert_conformance/3` returns the result map. Pass its fields to the reporter:

```elixir
result = assert_conformance(session, paths)

tap = Pm4ExUnit.Reporter.format_tap("order saga", result.success, result.violations, result.diagnostics)
xml = Pm4ExUnit.Reporter.format_junit("order saga", result.success, result.violations, result.diagnostics, 0.02)
```

Both return strings; write them wherever your CI reads reports.
