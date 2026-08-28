# Durable streams

`Later::Stream` is a SQLite-backed append-only event log. Events have a stable per-stream offset, JSON payload, metadata, timestamp, correlation and causation IDs, and producer identity.

```ruby
orders = Later::Stream.open("orders")
event = orders.publish(type: "order.created", data: { order_id: 842 })

orders.each { |event| puts event.data }
```

## Consumer groups

Each group has an independent committed offset:

```ruby
consumer = orders["analytics"]
while (event = consumer.next)
  Analytics.apply(event)
  consumer.ack(event)
end
```

An unacknowledged event remains available after its lease expires and can be redelivered. Delivery is at-least-once; handlers must be idempotent.

```ruby
orders.rewind("analytics", to: 0)
orders.lag("analytics")
orders.replay(from: 100) { |event| puts event.type }
```

## Schemas

```ruby
Later::Schema.define("orders.created", version: 1) do
  integer :order_id, required: true
  decimal :total, required: true
end

Later.publish("orders.created", order_id: 842, total: 129.99)
```

Invalid payloads are rejected before append. Full PostgreSQL consumer coordination, network transports, projections, and pipelines are not part of the SQLite stream release yet.
