# Changelog

## 1.2.0.pre.1 - 2026-08-27 (Prerelease)

This prerelease begins the `1.2.0` development line. It expands `later` from a durable local scheduler into a broader SQLite-backed temporal runtime while keeping the support boundary explicit: this release is local-first and does not claim unfinished external integrations.

### Added

- Configuration helpers and structured error boundaries for runtime operations.
- SQLite WAL persistence, migrations, busy timeouts, durable leases, heartbeats, crash recovery, priorities, queues, tags, idempotency keys, retries, deadlines, and immutable execution history.
- Journal reader, writer, and replay abstractions for inspecting persisted runtime activity.
- Recurrence rules for intervals and weekday schedules, including timezone metadata and simulation helpers.
- Durable events with persisted payloads, filtered subscriptions, and local subscriber dispatch.
- Validated workflow DAG definitions with dependency-aware execution and cycle detection.
- Futures, worker supervision, circuit breakers, rate limiting, failure-isolated instrumentation hooks, and telemetry boundaries.
- `Later::Stream`, an append-only SQLite event log with stable per-stream offsets, consumer groups, leased claims, acknowledgements, replay, rewind, delayed visibility, retention, wildcard subscriptions, and JSON schema validation.
- CLI commands for job inspection, history, dead-letter handling, retry, JSON output, recurrence simulation, linting, diagnostics, database checks, and stream operations.
- Runnable examples, focused documentation, security guidance, contributor guidance, and a minimal documentation website foundation.

### Changed

- Organized the runtime around explicit persistence, scheduling, stream, workflow, event, worker, resilience, and observability boundaries instead of placeholder integrations.
- Made at-least-once delivery and repeat-safe handlers the documented reliability model for jobs and streams.
- Kept the core package focused on plain Ruby and local SQLite so the shipped behavior can be exercised without requiring a hosted service.

### Fixed

- Release metadata now consistently identifies this line as `1.2.0.pre.1`, including the gem version, README, changelog, and release documentation.
- Release packaging and verification are constrained to the intended runtime library, executable, license, and README files.
- Public documentation no longer implies that PostgreSQL, Rails, dashboard, network transport, hosted documentation, or OpenTelemetry exporter support is already available.

### CLI

The prerelease includes operational commands such as `jobs`, `inspect`, `history`, `dead`, `retry`, `simulate`, `lint`, `doctor`, and `db check`, with JSON output where supported. Stream commands cover publishing, consuming, replay, acknowledgement, inspection, and retention workflows.

### Streams

Streams provide durable append-only storage on SQLite. Each stream has stable offsets; consumer groups track committed positions and leased in-flight events; replay and rewind are scoped to consumers; delayed events become visible at their scheduled time; and schema registration can validate event payloads. Delivery remains at least once, so consumers must be idempotent.

### Runtime and reliability

Jobs persist before dispatch and can be recovered after lease expiry or process failure. Event payloads persist before local subscribers run. Workflow dependencies are validated as a directed acyclic graph before execution. These guarantees support durable local coordination, but they do not make external side effects exactly once.

### Documentation and tooling

The repository now includes architecture, compatibility, migration, security, release, roadmap, stream, CLI, and contribution documentation, plus examples and CI/security/dependency automation. The gem build and package audit scripts are included in the release workflow.

### Known limitations

- The core gem targets local SQLite; PostgreSQL coordination is not implemented.
- Rails/Active Job integration, authenticated dashboard control, network transports, hosted documentation, and OpenTelemetry exporters are planned extensions rather than shipped features.
- Full calendar and DST-aware recurrence parsing is not complete.
- Jobs and stream consumers receive at-least-once delivery. Handlers and consumers must tolerate retries and use idempotency keys around external APIs.
- This is a prerelease and may change before a stable `1.2.0` release.

### Validation

- Ruby syntax checks passed for the release sources.
- The gem was built as `later-1.2.0.pre.1.gem` and passed the package verification script.
- The unpacked artifact contained only the intended `lib/`, `exe/`, `LICENSE`, and `README.md` content; an isolated gem installation succeeded with dependencies ignored.
- Source-only recurrence, stream, and schema loading smoke checks passed.
- The full SQLite-backed test suite could not run in the local Windows environment because the installed `sqlite3-2.7.4-x64-mingw-ucrt` native extension fails to load with `sqlite3_native.so: The specified procedure could not be found`. This prerelease does not claim that blocked suite as passing.
