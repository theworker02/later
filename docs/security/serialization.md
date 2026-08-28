# Serialization safety

Durable callable arguments are limited to strings, numbers, booleans, arrays, hashes, and null. Ruby objects, open files, Procs, and arbitrary deserialization are rejected. Treat job arguments and the SQLite database as trusted application data, and make external side effects idempotent.
