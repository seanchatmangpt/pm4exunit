# Why a session process per test

Events are recorded in a GenServer started in each test's `setup`, not in module state or ETS.

- **Isolation.** Tests run concurrently under `async: true`. A per-test process means traces
  never interleave.
- **Cleanup.** The session is linked to the test process and exits with it.
- **Cross-process emission.** Code under test running in other processes can emit events using the
  session pid; calls are serialized, preserving arrival order.

The cost is that you pass the session explicitly. For one-off checks, assertions also accept a
plain list, which avoids the session entirely.
