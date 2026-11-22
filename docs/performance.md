# Performance

Measured on a development laptop (ThinkPad L13 Yoga Gen 2), PostgreSQL, local.

## Seeding

| Data | Rows |
|---|---|
| Employees | 10,000 |
| Salary revisions | 23,071 |
| Employee assignments | 10,192 |

Full seed: 4.9 s (5.6 s including Rails boot).

How: all rows are planned in memory from one seeded random generator, then
written with `insert_all!` in batches of 1,000 inside one transaction.
`insert_all` skips model validations and normalization, so the generator
normalizes values itself, and a spec checks that generated records pass every
model validation and that current values match the latest history rows.

Query timings for search and insights will be added as those features land.

## Employee list API

GET /api/employees through the full Rails stack (auth, query, JSON),
in-process, on 10,000 employees. 30 runs per case, logging off.

| Case | Median | p95 |
|---|---|---|
| No parameters (active, sorted by last name) | 10.5 ms | 23.5 ms |
| Search by name (q=smith) | 30.8 ms | 45.8 ms |
| Search by employee code | 33.1 ms | 34.4 ms |
| Country filter | 9.9 ms | 11.2 ms |
| Country filter + salary sort | 9.4 ms | 11.3 ms |
| Search + all filters, 100 per page | 13.2 ms | 14.8 ms |
| Deep page (page 300) | 17.5 ms | 22.8 ms |

Search is the most expensive case: ILIKE scans the whole table (about
10.5 ms per scan, per EXPLAIN ANALYZE), once for the page and once for the
total count. That is still about 10 times under the 300 ms target, so no
trigram index was added. If the data grew enough for search to approach the
target, a pg_trgm GIN index on the searched columns is the next step.

Country, department and job title are preloaded; a spec checks the query
count stays constant as the list grows.

## Insights API

On 10,000 employees (9,711 active), full Rails stack, 30 runs each.

| Endpoint | Median | p95 |
|---|---|---|
| Statistics by country | 29.7 ms | 57.6 ms |
| One country by department | 20.4 ms | 24.6 ms |
| One country by job title | 22.0 ms | 24.6 ms |
| Org-wide summary | 39.5 ms | 59.7 ms |

All aggregation (min, max, average, median, totals, currency conversion)
runs in SQL, so no employee rows are loaded into Ruby. The summary runs three
grouped queries.

## Frontend test suite

109 tests. Full run: 13–15 s on a laptop in balanced mode, about 26 s in
power-saver mode (CPU at 0.7–1.1 GHz). The two slowest tests are full flows
(hiring an employee, and returning to page 1 of a filtered list) at about
2.5–3 s, or about 5 s in power-saver mode.

The suite must pass on slow machines, since reviewers may run it on
laptops on battery. Ant Design's runtime styles are turned off in tests
(jsdom spent most of each first render processing them). Waits allow 3 s
and tests 15 s; these limits only matter when a test is failing. Speed is
tracked with the slowest-tests report instead.

## Frontend bundle

Each page route loads on demand (React.lazy), so the login page doesn't
download employee or insights code.

| | Before | After |
|---|---|---|
| Login page downloads | 1,212.5 kB (382.9 kB gzipped) | 820.3 kB (268.1 kB gzipped), 32% less |
| Total across all chunks | 1,212.5 kB, one file | 1,227.3 kB, 22 files |

Splitting adds 15 kB in total, but each page only downloads what it uses.
Most of what the login page still loads is Ant Design's shared core, a
single 600 kB chunk every page needs; the browser caches it after the first
visit. The build's 500 kB chunk warning refers to that chunk, and is left in
place rather than silenced.

Ten consecutive runs passed on battery (15–20 s each). One earlier failure
happened while the backend suite and a production server were running at the
same time and didn't recur; the suite is reliable under normal load.