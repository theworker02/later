# Release guide

The current release is `1.2.0.pre.1`, published as the prerelease tag `v1.2.0.pre.1`. It is a development release, not a stable `1.2.0` release. The repository is configured with the `origin` remote at `https://github.com/theworker02/later.git`; RubyGems publication is intentionally not part of this release task.

## v1.2.0.pre.1 release state

- Version source: `lib/later/version.rb`.
- Changelog: `CHANGELOG.md`.
- GitHub release body: `RELEASE_NOTES_v1.2.0.pre.1.md`.
- Release target: `main` and annotated tag `v1.2.0.pre.1`.
- Support boundary: local SQLite and plain Ruby only. PostgreSQL, Rails/Active Job, dashboard, network transports, hosted documentation, full calendar/DST parsing, and OpenTelemetry exporters remain extension work.

## Local release checklist

1. Confirm `lib/later/version.rb`, `CHANGELOG.md`, `README.md`, and this guide agree on the release version and support boundary.
2. Run `bundle install` in a clean environment.
3. Run the full test suite, including SQLite restart, consumer-group, lease, replay, and migration tests.
4. Run Ruby syntax checks, RuboCop, and `bundle audit`.
5. Build the gem with `gem build later.gemspec`.
6. Inspect the artifact and run `ruby scripts/verify_gem later-*.gem`.
7. Install the artifact into a clean Ruby environment and run a smoke test using `require "later"`.
8. Verify the version, changelog, README, gemspec, and generated artifact agree.
9. Commit release metadata, create the annotated tag `v1.2.0.pre.1`, and push the commit and tag normally.
10. Publish the GitHub prerelease with the detailed notes file. Do not publish to RubyGems without an explicit release decision and configured trusted publishing.

## Validation record for v1.2.0.pre.1

- Ruby syntax checks passed for the release sources.
- `later-1.2.0.pre.1.gem` built successfully and passed `scripts/verify_gem`.
- The unpacked artifact contained only the intended runtime `lib/`, `exe/`, `LICENSE`, and `README.md` content.
- An isolated gem installation succeeded with dependencies ignored.
- Source-only recurrence, stream, and schema smoke checks passed.
- The full SQLite-backed test suite and `require "later"` runtime smoke test are blocked locally by the Windows `sqlite3-2.7.4-x64-mingw-ucrt` native extension error: `sqlite3_native.so: The specified procedure could not be found`.

Do not add credentials, sponsor accounts, download counts, or compatibility claims that the project owner has not supplied.
