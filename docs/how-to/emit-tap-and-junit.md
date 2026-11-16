# Emit TAP or JUnit output

`assert_conformance/3` raises on failure, so it only returns a successful result. To report both
pass and fail, call `evaluate/3` directly:

```elixir
events = Pm4ExUnit.Session.get_events(session)
result = Pm4ExUnit.Conformance.evaluate(events, [[:step_a, :step_b]])

tap = Pm4ExUnit.Reporter.format_tap("order saga", result.success, result.violations, result.diagnostics)
xml = Pm4ExUnit.Reporter.format_junit("order saga", result.success, result.violations, result.diagnostics, 0.02)
```

The fifth argument to `format_junit` is the duration in seconds (default `0.001`). `diagnostics`
is accepted but not written to the XML.

TAP output is `TAP version 13`, `1..1`, `ok 1 - name` (or `not ok`), then an indented `---` YAML
block listing violations, then `...`. JUnit output is a `<testsuites>` / `<testsuite>` /
`<testcase>` tree; a failure adds a `<failure message="...">` node.

Both return strings; write them wherever your CI reads reports.
