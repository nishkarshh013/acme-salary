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