# Buyer evaluation â€” Gemfile

## Goal

In 15â€“45 minutes, verify the Product builds or runs as documented and that proprietary notices are present.

## Steps

1. Confirm root `LICENSE` is proprietary and `ACQUISITION.md` exists.
2. Skim `README.md` install/run claims.
3. Execute:

```
```sh
gem install later
```
```ruby
# Gemfile
gem "later"
```
```sh
bundle install
```
```sh
bin/setup
```
```ruby
require "later"

Later.configure(path: "tmp/later.sqlite3")

Later.in("10m") { Cleanup.run }
Later.every("weekday at 09:00", timezone: "UTC") { Digest.send }
```
```sh
later run --db tmp/later.sqlite3
```
```ruby
class Reports
  def self.generate_monthly(month:)
    # Build the report for the supplied month.
  end
end

Later.configure(path: "tmp/later.sqlite3")
Later.call(Reports, :generate_monthly, at: "2026-09-01 09:00", month: "2026-08")
```
```ruby
Later.configure(path: "tmp/later.sqlite3")

Later.in("30s") { Cache.refresh }
Later.every("15m") { Metrics.flush }
Later.every("weekday at 09:00", timezone: "America/New_York") do
```

4. Run tests if present (`npm test`, `pytest`, `cargo test`, `go test ./...`, etc.).
5. Record README vs observed behavior gaps in workpapers.

## Pass criteria

- [ ] Clone succeeds
- [ ] Documented happy path works **or** failure is explained
- [ ] Minimal path needs no surprise secrets
- [ ] License notices intact

*Updated: 2026-09-22*
