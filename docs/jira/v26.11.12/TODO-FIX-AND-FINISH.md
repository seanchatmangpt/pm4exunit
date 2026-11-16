# TODO-FIX-AND-FINISH (pm4exunit)

Standing: PARTIAL (audited against 7ca9dd3 plus dirty tree, 2026-11-12; code read, not run)

Source: `ash_surface/docs/jira/v26.11.11/PROJECT-REVIEWS.md` R9, re-read where marked confirmed.

## Fix

- HIGH (confirmed, open) `lib/pm4exunit/temporal.ex:97-104`: a bad ISO timestamp (:101) or a
  missing timestamp (:104) falls back to `DateTime.utc_now()`, so `assert_sla` is
  nondeterministic. Check: bad or missing timestamp returns a typed error, repeatably.
- MED (confirmed, open) `temporal.ex:22-30,55-57`: first occurrence of each activity is used and
  no ordering check exists. Reversed `to`/`from` gives a negative diff that satisfies
  `<= max_seconds`, so the SLA falsely passes. Check: reversed-order test fails with a violation.
- LOW (confirmed, open) `reporter.ex:10-36`: `format_tap` interpolates `test_name` and
  violations unescaped into its YAML block. JUnit is safe (`escape_xml`). Check: newline or
  quote in a violation yields valid TAP.
- LOW `lcs_length` (`conformance.ex:340`) on empty trace/pattern looks safe but is untested.
  Add a test. Dead-code/stale-comment claim in `conformance.ex` is unconfirmed.
- DONE 2026-11-12: stale OCPQ claim removed from `mix.exs` description; reporter moduledoc no
  longer claims JSON; docs audited and corrected.

## Finish

- Add temporal tests for missing-timestamp refusal and reversed `from`/`to`.
- Decide handling of repeated activities (first, last, or all pairs) and document it.

## Commit hygiene

- Uncommitted: version bump 26.11.12 and the doc/mix.exs corrections. Check: clean
  `git status --short`.
- Cross-engine vector test is already committed (67c06ae).

## Decide

- Is wall-clock fallback ever lawful? Default proposal: no, refuse.

## Reuse

- Moved: `chicago/collaborators/mock_scan.ex` is not in this repo; track it in its owning repo.

## See Also

- `/Users/sac/ash_surface/docs/jira/v26.11.11/PROJECT-REVIEWS.md`
- `/Users/sac/beam4pm/docs/jira/v26.11.12/TODO-FIX-AND-FINISH.md`
