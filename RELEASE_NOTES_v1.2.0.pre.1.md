# later v1.2.0.pre.1

`v1.2.0.pre.1` begins the `1.2.0` development line. It expands `later` from a durable local scheduler into a SQLite-backed temporal runtime with events, workflow graphs, futures, observability boundaries, and durable streams.

> **Prerelease:** This release targets plain Ruby with local SQLite. It does not claim PostgreSQL, Rails/Active Job, dashboard, network transport, hosted documentation, full calendar/DST parsing, or OpenTelemetry exporter support.

## Highlights

- Durable SQLite jobs with WAL mode, migrations, busy timeouts, leases, heartbeats, crash recovery, retries, deadlines, priorities, queues, tags, idempotency keys, and immutable history.
- Interval and weekday recurrence rules with timezone metadata and simulation helpers.
- Persisted events with filtered local subscriptions.
- Validated workflow DAGs with dependency-aware execution and cycle detection.
- Futures, worker supervision, circuit breakers, rate limiting, and failure-isolated instrumentation hooks.
- `Later::Stream`, a durable append-only SQLite log with stable offsets, consumer groups, leased claims, acknowledgements, replay, rewind, delayed visibility, retention, wildcard subscriptions, and JSON schema validation.
- Operational CLI commands, JSON output, diagnostics, examples, architecture/security documentation, and release tooling.

## CLI and streams

The CLI supports job inspection, history, dead-letter handling, retry, recurrence simulation, linting, diagnostics, database checks, and stream operations. Stream consumers use stable offsets and consumer-group leases; replay and rewind are consumer-scoped, and delayed events become visible at their scheduled time.

Jobs and streams intentionally use at-least-once delivery. Handlers and consumers must tolerate retries and protect external side effects with idempotency keys.

## Validation

The gem was built and passed the package verification script. The unpacked artifact contains only the intended `lib/`, `exe/`, `LICENSE`, and `README.md` content. Source-only recurrence, stream, and schema smoke checks passed.

The full SQLite-backed test suite could not run in the local Windows environment because the installed `sqlite3-2.7.4-x64-mingw-ucrt` native extension fails to load with `sqlite3_native.so: The specified procedure could not be found`. This prerelease does not claim that blocked suite as passing.

See [`CHANGELOG.md`](CHANGELOG.md) for the complete release record and [`RELEASE.md`](RELEASE.md) for the release checklist and support boundary.
