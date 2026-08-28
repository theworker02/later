# Changelog

## 1.2.0.pre.1 - Unreleased

### Added

- configuration and structured error boundaries;
- SQLite journal reader/writer/replay abstractions;
- recurrence rules with weekday schedules and timezone metadata;
- durable events, workflow DAG validation/runtime, futures, worker supervisor, resilience helpers, and telemetry hooks;
- `Later::Stream` append-only SQLite logs with stable offsets, consumer groups, replay, rewind, delayed visibility, retention, wildcard subscriptions, and schema validation;
- simulation, lint, doctor, JSON CLI output, examples, and contributor documentation.

### Changed

- expanded the repository around real runtime boundaries instead of placeholder files.

### Known limitations

- PostgreSQL, Rails, dashboard, and hosted documentation integrations are planned extensions, not shipped core features.
