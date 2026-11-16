# Why a session process per test

Events are recorded in a GenServer started in each test's `setup` (`use Pm4ExUnit`), not in a
module attribute or ETS. The session holds a `Pm4ExUnit.TraceCollector` struct with the registered
objects and an ordered list of events.

- **Isolation.** Each test gets its own session pid, passed in the test context as
  `:pm4_session`. Traces from different tests (including `async: true` tests) never interleave.
- **Cleanup.** `Session.start_link/1` is called from `setup`, so the session is linked to the test
  process and exits with it. There is no explicit teardown.
- **Cross-process emission.** Code under test running in other processes can call
  `Pm4ExUnit.Session.emit_event/4` and `register_object/4` with the session pid. These are
  synchronous `GenServer.call`s, so events are stored in arrival order. Order is arrival, not
  `timestamp`: a caller-supplied `:timestamp` is stored as-is and does not reorder events.

The cost is that you pass the session explicitly (`%{pm4_session: session}`). For one-off checks,
assertions also accept a plain list, which avoids the session entirely.
