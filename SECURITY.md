# Security Policy

## Supported Versions

pm4exunit uses CalVer (`YY.M.D`). Only the latest CalVer release receives security fixes.
Please upgrade to the newest release before reporting an issue.

| Version        | Supported |
| -------------- | --------- |
| Latest release | Yes       |
| Older releases | No        |

## Reporting a Vulnerability

Report vulnerabilities privately through GitHub security advisories:

<https://github.com/seanchatmangpt/pm4exunit/security/advisories/new>

Please do not open a public issue for a suspected vulnerability. Include:

- the affected version and environment (Elixir/OTP versions),
- a description of the issue and its impact,
- steps or a minimal test case to reproduce it.

The maintainer will acknowledge the report, investigate, and coordinate a fix and
disclosure through the advisory.

## Scope

pm4exunit is test-only tooling: process-conformance assertions for ExUnit. It is intended
to run in development and CI, not in production runtime paths. Reports are in scope when
the library mishandles untrusted input (for example, crafted event logs or trace files) or
its reporters produce unsafe output. Issues arising only from running untrusted test code
are out of scope.
