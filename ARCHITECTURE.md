# Architecture

`later` is organized around a durable scheduler core with replaceable boundaries.

```text
Public DSL
   |
Scheduler ---- Events::Bus
   |                 |
Storage adapter   durable event log
   |
SQLite Persistence
   |
Journal / leases / recovery
```

## Runtime boundaries

- `Configuration` validates deployment settings.
- `Scheduler` owns enqueue, claim, execution, retry, recurrence, and worker leases.
- `Persistence` is the default SQLite adapter and implements the storage contract.
- `Journal` appends and reads immutable aggregate events.
- `Workflows::Graph` validates DAGs before `Workflows::Runtime` schedules steps.
- `Events::Bus` handles process-local subscriptions; emitted events are persisted before dispatch.
- `Workers::Supervisor` runs polling workers and stops them cooperatively.
- `Telemetry::Instrumentation` isolates observer failures from job execution.

## Delivery model

Claims are transactional and lease-backed. A process crash makes an expired lease eligible for recovery. External side effects are at-least-once and must be idempotent; the system does not claim impossible exactly-once behavior.

## Extension boundaries

`Later::Storage::Adapter` is the minimum adapter contract. SQLite is complete for the local runtime. PostgreSQL, Rails, dashboard, and OpenTelemetry integrations belong in separately tested extensions and are not silently enabled by the core gem.
