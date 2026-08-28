# Roadmap

## 1.1 foundation

- durable SQLite runtime
- leases, recovery, priorities, idempotency, and history
- recurrence IR and virtual-clock testing
- event bus, DAG validation, futures, resilience helpers
- operational CLI and repository tooling

## 1.2 integrations

- PostgreSQL adapter with `FOR UPDATE SKIP LOCKED` integration tests
- Rails transaction hooks and Active Job adapter
- authenticated dashboard API
- optional OpenTelemetry exporter

## 1.3 temporal workflows

- durable workflow instances
- signals, cancellation propagation, compensation, and migration
- calendar rules with full DST ambiguity policies

Roadmap items are not shipped features. Each item requires implementation, tests, documentation, and a clean-environment validation gate.
