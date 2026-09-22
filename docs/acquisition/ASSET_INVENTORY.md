# Asset inventory â€” Gemfile

## Repository surfaces

| Asset | Location / notes |
|-------|------------------|
| Source tree | Repository root / language packages |
| Tests | `test/`, `tests/`, CI workflows if present |
| Docs | `README.md`, `docs/` |
| Diligence room | `docs/acquisition/` |
| License / notices | `LICENSE`, transition notices if present |
| Funding | `.github/FUNDING.yml` |
| CI | `.github/workflows/` if present |
| Branding | logos/assets folders if present |

## Capability highlights

- **At-least-once delivery:** a job or stream event can be retried or redelivered after a failure or expired lease.
- **Repeat-safe handlers:** use idempotency keys and make external side effects safe to repeat.
- **Durable state:** jobs, event payloads, leases, stream offsets, and execution history are persisted in SQLite.
- **Trusted application boundary:** job handlers are application code; the SQLite database and any unauthenticated control surface must not be exposed to untrusted users.
- **Restricted arguments:** durable callable arguments are limited to JSON-compatible strings, numbers, booleans, arrays, hashes, and null. Procs, open files, arbitrary Ruby objects, and arbitrary deserialization are rejected.
- `test/` Ã¢â‚¬â€ unit and integration behavior;
- `examples/` Ã¢â‚¬â€ runnable, application-shaped examples;
- `docs/` Ã¢â‚¬â€ focused scheduling, stream, CLI, migration, and security documentation;
- `website/` Ã¢â‚¬â€ Astro documentation site using the same visual identity;
- `.github/` Ã¢â‚¬â€ CI, security, dependency, Pages, and release automation.

## Usually excluded

Seller personal accounts, unrelated repos, and unreissued registry tokens â€” unless listed in the definitive agreement.

*Updated: 2026-09-22*
