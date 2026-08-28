# Contributing

1. Run `bin/setup`.
2. Run `bundle exec rake test` and `ruby -c` on changed Ruby files.
3. Add focused tests for behavior changes.
4. Update documentation and `CHANGELOG.md` for public API changes.
5. Do not add placeholder integrations or claim unsupported delivery guarantees.

Keep cohesive implementation together; add a subsystem boundary when it owns a real policy, persistence contract, lifecycle, or test surface. Avoid changing persisted formats without a migration and compatibility note.
