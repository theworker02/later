# Compatibility

The current development line targets Ruby 3.2 and newer. SQLite support depends on the pinned `sqlite3` gem and the host platform's native extension.

The public API is pre-1.0 and may change. Persisted job rows are migrated forward by the SQLite bootstrap migration. PostgreSQL and Rails compatibility are not claimed until their extension packages and CI matrices exist.
