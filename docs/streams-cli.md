# Stream CLI

```text
later stream create orders
later stream publish orders --type order.created --data '{"order_id":842}'
later stream history orders
later stream replay orders --from 10
later stream consume orders --group analytics
later stream rewind orders --group analytics --from 0
later stream lag orders --group analytics
later stream compact orders
```

The CLI operates on the configured SQLite database. Consumer delivery is at-least-once and `consume` acknowledges after printing; use application consumers for transactional processing.
