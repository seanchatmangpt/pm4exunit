# TODO-FIX-AND-FINISH (pm4exunit)

Standing: UNVERIFIED

Source: `ash_surface/docs/jira/v26.11.11/PROJECT-REVIEWS.md` R9, re-read where marked confirmed.

## Fix

- HIGH `lib/pm4exunit/temporal.ex:96-104` bad/missing timestamps fall back to
  `DateTime.utc_now()` (confirmed lines 101, 104; review cited 92-99). `assert_sla` becomes
  nondeterministic. Check: event with bad timestamp returns typed error, repeatable.
- MED `lib/pm4exunit/temporal.ex:28-38` first occurrence of each activity used; `to` before
  `from` gives negative diff: UNVERIFIED (first-match `Enum.find` confirmed; negative case not
  tested). Check: test with reversed order fails with a violation.
- LOW `lib/pm4exunit/reporter.ex` XML is escaped via `escape_xml` (confirmed); TAP/YAML block
  injection UNVERIFIED. Check: test with newline/quote in violation yields valid TAP.
- LOW README stale OCPQ claim; dead code/stale comment in `lib/pm4exunit/conformance.ex`;
  empty-range `lcs_length`: UNVERIFIED.

## Finish

- Add temporal court for missing-timestamp refusal and reversed `from`/`to`.
- Decide handling of repeated activities (first, last, or all pairs) and document it.

## Commit hygiene

- `lib/pm4exunit/conformance.ex` modified, uncommitted (confirmed ` M`).
- `test/pm4exunit_cross_engine_vector_test.exs` untracked (confirmed `??`). Check: clean
  `git status --short`.

## Decide

- Is wall-clock fallback ever lawful? Default proposal: no, refuse.

## Reuse

- Static AST mock scanner `chicago/collaborators/mock_scan.ex:65,104` (UNVERIFIED lines) is
  reusable by ash_surface.

## See Also

- `/Users/sac/ash_surface/docs/jira/v26.11.11/PROJECT-REVIEWS.md`
- `/Users/sac/beam4pm/docs/jira/v26.11.12/TODO-FIX-AND-FINISH.md`
