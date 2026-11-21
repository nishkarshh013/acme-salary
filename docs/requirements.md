# ACME Salary Management — Requirements

Nov 20, 2026 · @Nishkarsh Sahu

Scope is based on the [clarifications](clarifications.md) received from the
Incubyte team. The technical design that implements it is in
[architecture.md](architecture.md).

## Goal

Replace ACME's spreadsheet-based salary management with a web app that lets one HR Manager maintain salary data for 10,000 employees across countries and answer "how do we pay people?" in seconds.

Today salary data lives in Excel files. Finding an employee, recording a raise, or computing a country's median salary means manual filtering and formulas, and once a cell is overwritten, the previous salary, role or country and the reason for the change are lost. The app serves two jobs: **maintain** (find an employee, update their pay or role, and preserve a permanent history of every change, when it took effect and why) and **understand** (pay statistics by country, department and job title).

## User, assumptions and key decisions

The single user is the HR Manager, who is trusted with all salary data. There is no employee self-service and no second role.

- **Salaries stay in local currency.** Each employee's salary is stored in their country's currency. Statistics are computed per country, because averaging INR and USD figures together is meaningless.
- **Org-wide figures are an explicit, labeled conversion.** A fixed exchange-rate table (seeded, with an "as of" date) converts to USD only for org-wide totals. Every converted number is marked "USD, converted at fixed rates as of \<date>".
- **Base salary only.** Salary means annual gross base salary. One current value per employee, with a revision history behind it.
- **One identity per employee.** An employee keeps the same unique employee ID when they change country, department or job title. Each change is recorded as a dated assignment in their history. A country change also requires a salary revision in the new currency, saved in the same transaction.
- **Seeded data.** 10,000 realistic dummy employees, generated deterministically, with salary bands that vary by country and job title so the insights look meaningful.

## Scope and features

| Area | Feature | Why it matters to the HR Manager |
| --- | --- | --- |
| Employees | Paginated list with search by name, email or employee ID; filter by country, department, job title; sort by any column | Finding one person among 10,000 is the most frequent task |
| Employees | Create, view and edit an employee (name, email, employee ID, country, department, job title, hire date, status) | Replaces editing rows in Excel |
| Salary | Revise salary with amount, effective date and reason | Every pay change is recorded with its context |
| History | Salary history: every revision with amount, currency, effective date and reason | Answers "when and why did this person's pay change?" |
| History | Assignment history: every change of country, department or job title with effective date and reason | Answers "where and in what role was this person at any point?" |
| History | One combined timeline of pay and assignment changes on the employee page | Shows a person's full story in one place instead of across old spreadsheets |
| Insights | Per-country stats in local currency: headcount, min, max, average, median, total payroll | Core "how do we pay people" question |
| Insights | Drill-down by department and job title within a country | Spots pay gaps and outliers within comparable groups |
| Insights | Org-wide totals by country and department in USD, labeled as converted | Gives leadership one number without hiding the conversion |
| Access | Login for the HR Manager; every page and API endpoint requires authentication | Salary data is sensitive |

## Non-functional requirements

- **Performance:** employee search and pages respond in under 300 ms and the insights dashboard loads in under 1 s at 10,000 employees. Achieved with server-side pagination, indexed lookups, and aggregation in SQL (PostgreSQL `percentile_cont` for medians) rather than in Ruby.
- **Security:** session-cookie authentication (httpOnly, same origin as the React app), rate-limited login, strong parameters, salary fields filtered from logs, and no salary data in URLs.
- **Data consistency:** a salary revision or assignment change and the employee's current values update in one database transaction, and history rows are never updated or deleted. Optimistic locking rejects an edit made on stale data instead of silently overwriting it.
- **Money handling:** amounts stored as fixed-precision decimals with an ISO currency code, never floats.
- **Testing:** fast, deterministic tests on the business-critical paths: salary revision, assignment changes and their history, statistics (including median with odd and even counts), search and filtering, and authentication. Meaningful coverage over a percentage target.
- **Deployability:** one Rails service serving the built React app, backed by managed PostgreSQL, publicly reachable with seeded data.

## Deliberately out of scope

| Left out | Reasoning |
| --- | --- |
| Bonuses, allowances, deductions | Base salary answers the core pay questions; extra components multiply the data model without changing the product's shape |
| Approval workflows | One trusted HR Manager makes the decisions; the history with reasons provides the audit trail |
| Multiple users and role-based access | Single persona per the brief; the auth layer is a clean place to add roles later |
| Excel/CSV import | Seeded data covers the demo; import needs validation and error reporting that deserves its own iteration |
| Editing or deleting history | History is append-only; a mistake is corrected with a new entry, so the audit trail stays trustworthy |
| Live exchange rates | An external dependency that makes reports change between views; a fixed, dated table keeps numbers reproducible |
| Payroll processing, payslips, tax | A different product; this tool manages and analyses salary data, it does not pay people |
| Enterprise-scale tuning (caching, read replicas) | 10,000 rows aggregate in milliseconds with proper indexes; added complexity would not be measurable |

## Success criteria

- The HR Manager finds any employee by name or ID in under 10 seconds.
- A salary revision takes one form submission and appears immediately in the employee's history and in the insights. The same holds for a change of country, department or job title.
- The median salary for any country, department or job title is one click away, in local currency.
- Every converted figure is visibly labeled with its currency and rate date.
- The deployed app runs on 10,000 seeded employees, and the test suite runs green in under a minute.
