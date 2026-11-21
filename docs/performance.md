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