# later

**Durable time and workflows for Ruby.**

`later` is a local-first temporal runtime for plain Ruby. It persists scheduled operations in SQLite, recovers leased work after crashes, records execution history, and provides an expressive path from one delayed call to recurring jobs, events, futures, and validated workflow graphs.

> Current release line: `1.2.0.pre.1`. This is a development release; the project does not claim PostgreSQL, Rails, dashboard, network transport, hosted-docs, full calendar/DST, or OpenTelemetry exporter support until those extensions have their own implementations and CI.

## Install

```text
gem install later
```

Or from a checkout:

```text
bundle install
```

## Five-minute start

```ruby
require "later"

Later.configure(path: "tmp/later.sqlite3")

Later.in("10m") { Cleanup.run }
Later.every("weekday at 09:00", timezone: "UTC") { Digest.send }
```

Start the embedded worker in the application environment:

```text
later run
```

For restart-safe jobs, use a named constant and JSON-compatible arguments:

```ruby
Later.call(Reports, :generate_monthly, at: "2026-09-01 09:00")
```

## Workflows and events

```ruby
Later.workflow(:release) do
  step(:test) { TestSuite.run }
  step(:build, after: :test) { Build.run }
  step(:publish, after: :build) { Publish.run }
end

Later.start_workflow(:release)
```

```ruby
Later.on("invoice.paid", where: ->(event) { event[:total].to_f > 1_000 }) do |event|
  FraudReview.run(event)
end

Later.emit("invoice.paid", invoice_id: 42, total: 2_000)
```

Workflow definitions are validated as DAGs before scheduling. Event payloads are persisted before local subscribers run.

## Runtime capabilities

- SQLite WAL persistence with migrations and busy timeouts;
- stable `lat_...` IDs, priorities, queues, tags, idempotency keys, retries, deadlines through timeouts, leases, heartbeats, and recovery;
- interval and weekday recurrence represented as an intermediate rule;
- immutable job history and a journal reader/writer/replay boundary;
- futures, event filters, DAG workflows, worker supervision, circuit breakers, rate limiting, and failure-isolated instrumentation;
- CLI inspection, JSON output, schedule simulation, linting, and diagnostics;
- virtual-clock helpers for tests and simulations.

## CLI

```text
later jobs --json
later inspect lat_...
later history
later dead
later retry lat_...
later simulate "weekday at 09:00" --next 10 --timezone UTC
later lint "15m"
later doctor
later db check
```

## Guarantees and limitations

`later` provides durable dispatch and lease recovery, not magical exactly-once external side effects. Handlers must be safe to repeat and should use idempotency keys around external APIs.

The core gem currently targets local SQLite. PostgreSQL coordination, Rails/Active Job, authenticated dashboard control, full calendar/DST parsing, and OpenTelemetry exporters are extension work tracked in `ROADMAP.md`; no placeholder implementation is presented as production support.

## Streams

The prerelease `Later::Stream` subsystem adds a durable append-only log with stable offsets and consumer groups:

```ruby
orders = Later::Stream.open("orders")
orders.publish(type: "order.created", data: { order_id: 842 })

consumer = orders["analytics"]
while (event = consumer.next)
  Analytics.apply(event)
  consumer.ack(event)
end
```

Events can be replayed or rewound without affecting another consumer group. Delayed visibility, retention, wildcard subscriptions, and JSON schema validation are available on SQLite. Delivery is at-least-once and stream consumers must be idempotent.

## Project map

- `lib/later/` — runtime, persistence, scheduling, workflows, events, workers, resilience, telemetry;
- `test/` — unit and integration behavior;
- `examples/` — runnable application-shaped examples;
- `docs/` — focused user and security documentation;
- `website/` — minimal Astro documentation foundation;
- `.github/` — CI, security, dependency, issue, and contribution automation.

See `ARCHITECTURE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `RELEASE.md`, and `ROADMAP.md` before making changes.

## Development

```text
bin/setup
bundle exec rake test
gem build later.gemspec
```

The test suite requires a working `sqlite3` native extension for the current Ruby and operating system.

## License

MIT. See `LICENSE`.
