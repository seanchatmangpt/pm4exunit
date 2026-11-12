# Allow several valid paths

Pass one inner list per allowed path. A trace conforms if it fully follows any one of them.

```elixir
paths = [
  [:draft, :submitted, :approved, :dispatched],
  [:draft, :submitted, :rejected, :closed]
]

assert_conformance(session, paths, min_fitness: 1.0)
```

Paths share a start and end place, so they behave as alternative branches. A trace that mixes
steps from two branches does not conform.
