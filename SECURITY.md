# Security Policy

Do not deserialize arbitrary Ruby objects from the database. Durable callable arguments are restricted to JSON-compatible values and constant/method dispatch is explicit.

The dashboard and worker protocol are not production network services in the core gem. Do not expose a SQLite file or an unauthenticated control panel to untrusted users.

Report vulnerabilities privately through the repository's configured security contact. Include the affected version, Ruby/runtime details, reproduction, and impact. Do not include credentials or production data in reports.

Job handlers are trusted application code. Plugins, storage adapters, and telemetry exporters execute with application privileges and must be reviewed accordingly.
