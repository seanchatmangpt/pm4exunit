# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [26.11.12] - 2026-11-12

### Changed

- Version scheme changed from `0.1.0` to calendar versioning (`26.11.12`).
- Package description no longer claims OCPQ support; it now reads "Process Intelligence and
  Conformance Checking for ExUnit".
- Hex package `files` now include `docs` alongside `lib`, `mix.exs`, `README.md` and `LICENSE`.
- README rewritten and documentation reorganized per the Diataxis framework: tutorial,
  how-to guides, reference and explanation.
- ExDoc extras list updated to include the new how-to guides.

### Added

- MIT `LICENSE` file.
- `ex_doc` as a dev dependency for Hex docs.
- Diataxis docs: first conformance test tutorial; how-to guides for refuting a trace,
  emitting TAP and JUnit, and asserting on plain lists; API reference; explanations of
  token-based replay and session-per-test.
- TS-parity conformance semantics with a cross-engine vector test
  (`test/pm4exunit_cross_engine_vector_test.exs`).

### Fixed

- Docs: removed the stale OCPQ claim and documented known SLA limitations.
- Docs: `Pm4ExUnit.Reporter` moduledoc no longer lists JSON output; the reporter emits
  TAP v13 and JUnit XML.
- Empty-trace LCS range bug in conformance (`1..0` stepped by -1).

### Removed

- Dead `pick_best/1` from `Pm4ExUnit.Conformance`.
- Generated ExDoc output is now git-ignored.

## [0.1.0] - 2026-11-06

### Added

- Initial commit of the pm4exunit process intelligence engine for ExUnit: `Pm4ExUnit`,
  `Assertions` (`assert_conformance`, `refute_conformance`, `assert_sla`), `Conformance`,
  `Temporal`, `Session`, `TraceCollector` and `Reporter` (TAP and JUnit).
- `TraceCollector` options aligned with wasm4pm-compat, with an integration test
  (`test/pm4exunit_compat_verification_test.exs`).
