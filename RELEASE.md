# Release guide

The current release line is `1.2.0.pre.1`. It is a prerelease, not a stable `1.2.0` release. The repository has no configured Git remote or repository metadata in this workspace, so release preparation stops before commit, tag, push, or RubyGems publication.

## Local release checklist

1. Update `lib/later/version.rb` and move the matching section in `CHANGELOG.md` from `Unreleased` to the release version.
2. Run `bundle install` in a clean environment.
3. Run the full test suite, including SQLite restart, consumer-group, lease, replay, and migration tests.
4. Run Ruby syntax checks, RuboCop, and `bundle audit`.
5. Build the gem with `gem build later.gemspec`.
6. Inspect the artifact and run `ruby scripts/verify_gem later-*.gem`.
7. Install the artifact into a clean Ruby environment and run a smoke test using `require "later"`.
8. Verify the version, changelog, README, gemspec, and generated artifact agree.
9. Only after CI passes: create a signed release commit and tag `v1.2.0.pre.1`.
10. Publish through RubyGems trusted publishing when configured; never store long-lived credentials in the repository.

## Current blockers

- The local Windows Ruby installation has a broken `sqlite3` 2.7.4 native extension, so SQLite-backed tests cannot run in this workspace.
- The project has no Git repository or remote configured here, so no commit or tag can be created.
- PostgreSQL, Rails, dashboard, network transport, and hosted documentation integrations are not stable release requirements for this prerelease.

Do not add credentials, sponsor accounts, download counts, or compatibility claims that the project owner has not supplied.
