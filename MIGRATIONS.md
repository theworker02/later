# Migrations

SQLite schema setup is idempotent and adds new job columns without deleting existing records. Existing legacy jobs receive stable `lat_legacy_*` identifiers.

Back up the database before upgrades. The current bootstrap migration is forward-only; rollback is not supported because removing durable metadata can destroy recovery information.

Future releases will move schema changes into numbered migration objects and expose `later db status` and `later db migrate`.
