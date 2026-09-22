# Acquisition Brief â€” Gemfile

**Date:** 2026-09-22  
**Repository:** https://github.com/theworker02/later  
**Default branch:** `main`  
**Primary language:** Ruby  
**Status:** Diligence briefing only. **No acquisition has occurred** by virtue of this file.  
**License:** Proprietary â€” sale, written commercial license, or completed asset transfer required (see root `LICENSE`).  
**Valuation:** Not stated.  
**Contact:** GitHub [@theworker02](https://github.com/theworker02) Â· [thanks.dev/u/gh/theworker02](https://thanks.dev/u/gh/theworker02)

> Cloning or forking this repository does **not** grant production, redistribution, SaaS, OEM, or commercial rights.

---

## 1. Executive thesis

<img src="assets/brand/later-wordmark.svg" alt="later Ã¢â‚¬â€ Durable time and workflows for Ruby" width="420"> <strong>Durable time and workflows for Ruby.</strong><br> A local-first temporal runtime for plain Ruby, backed by SQLite.

**Why a buyer cares:** Gemfile packages transferable product IP â€” source, docs, in-repo brand assets, and a diligence room under `docs/acquisition/` â€” under a clear proprietary posture so diligence can proceed without mistaking the repo for open source.

---

## 2. Product snapshot

| Item | Detail |
|------|--------|
| Product | Gemfile |
| Repo | `theworker02/later` |
| Language | Ruby |
| Open source? | **No** â€” proprietary |
| Rightsholder | theworker02 |
| Diligence pack | `docs/acquisition/` |

### Capability highlights (from current materials)

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

---

## 3. Problem / opportunity

Teams evaluating Gemfile typically need either (a) a commercial right to run or embed it, or (b) outright ownership of the Product IP for strategic build-out. Public GitHub visibility without a proprietary license creates false assumptions about free production use. This brief and the linked data room make the commercial path explicit.

---

## 4. What ships today

Honest maturity: treat repository contents, README claims, tests, and release tags as the source of truth. Do not assume production customers, ARR, filed patents, or SLAs unless separately evidenced in diligence.

Typical transferable surfaces:

- Source tree and build/test scripts present in-repo
- Documentation and design notes
- Acquisition / diligence markdown under `docs/acquisition/`
- Branding assets committed to the repository (if any)

---

## 5. Demo / evaluation path (buyer)

Minimal path (no secrets required unless README says otherwise):

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

Extended evaluation: `docs/acquisition/BUYER_EVALUATION.md`. Written NDA / evaluation grants may be required for private materials.

---

## 6. What a transaction typically includes

Subject to definitive schedules:

| Included (typical) | Excluded (typical) |
|--------------------|--------------------|
| Repo materials + asserted original IP | Seller personal accounts / unrelated repos |
| Docs + diligence room at closing | Third-party dependency source under separate licenses |
| In-repo brand marks as assigned | Secrets without rotation plan |
| Know-how captured in docs | Fabricated revenue, user, or adoption metrics |

---

## 7. Suggested deal structures

| Structure | When it fits |
|-----------|--------------|
| Non-exclusive commercial license | Deploy/run under seat or environment terms |
| Exclusive field-of-use license | Buyer wants exclusivity; seller may retain entity |
| Asset / IP assignment | Buyer wants ownership of Materials outright |
| OEM / redistribution | Separate agreement â€” not implied here |

Commercial terms (price, earnouts, escrow) are negotiated under NDA with counsel.

---

## 8. Buyer diligence checklist

- [ ] Confirm Rightsholder identity and authority to sell/license
- [ ] Inventory Materials (`docs/acquisition/ASSET_INVENTORY.md`)
- [ ] Review IP posture (`IP_PROVENANCE.md`) and dependencies (`DEPENDENCY_INVENTORY.md`)
- [ ] Run evaluation script (`BUYER_EVALUATION.md`)
- [ ] Review risks (`RISK_REGISTER.md`)
- [ ] Agree transfer scope (`TRANSFER_MANIFEST.md`) and handoff (`HANDOFF_CHECKLIST.md`)
- [ ] Supersede root `LICENSE` at closing via definitive agreement

---

## 9. Related documents

| Document | Purpose |
|----------|---------|
| `LICENSE` | Proprietary â€” no default grant |
| `docs/acquisition/README.md` | Data-room index |
| `docs/acquisition/EXECUTIVE_SUMMARY.md` | One-page thesis |
| `README.md` | Product overview |
| `SECURITY.md` | Vulnerability reporting |
| `COMMERCIAL.md` | Licensing contact path |
| `.github/FUNDING.yml` | Sponsors / thanks.dev |

---

## 10. Disclaimer

This package is informational and **does not** create a binding offer, grant of rights, or investment advice. Engage counsel for any transaction.

---

*Document version: 2.0.0 / 2026-09-22 Â· Classification: acquisition briefing*
