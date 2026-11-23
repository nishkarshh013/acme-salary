# ACME Salary Management

A web app for an HR manager to manage salaries for 10,000 employees across
eight countries, and to answer how the organisation pays people.

**Live demo:** <https://acme-salary-production-e3e96398.up.railway.app>

**Login:** `hr@acme.example` / `password123`

**Demo video:** <https://www.loom.com/share/10252659aa1b4d3c8a7744d71832a8ac>

## What it does

- **Find anyone fast:** search by name, email or employee code; filter by
  country, department, job title and status; sort and page through 10,000
  employees. Every view lives in the URL, so it can be bookmarked or shared.
- **Change pay and roles safely:** salary revisions, promotions and country
  moves each record an effective date and a reason. History is append-only,
  and two people editing the same employee can't overwrite each other.
- **Hire:** new employees get an automatic employee code and a complete
  history from day one.
- **Understand pay:** min, max, average and median salary by country, and by
  department or job title within a country, in local currency. Org-wide
  payroll is converted to USD at fixed, dated rates and clearly labelled.
  Every statistic links to the employees behind it.

## Key decisions

- Salaries stay in local currency, so averages and medians are only computed
  within one currency. An org-wide median would mix salary markets.
- History is append-only: corrections are new entries, never edits.
- Money is stored as exact decimals and sent to the browser as strings.
- One repository and one deployment: Rails serves the React app from the same
  origin, so authentication uses an httpOnly cookie instead of tokens.

The reasoning behind these and other decisions is in
[docs/architecture.md](docs/architecture.md).

## Run it locally

Prerequisites: Ruby (version in `backend/.ruby-version`), Node 20 or later,
and PostgreSQL.

```bash
# Backend (http://localhost:3000)
cd backend
bundle install
bin/rails db:prepare db:seed     # creates 10,000 employees in about 5 s
bin/rails server

# Frontend (http://localhost:5173), in a second terminal
cd frontend
npm ci
npm run dev
```

Open http://localhost:5173 and log in with `hr@acme.example` /
`demo-password-dev-only` (development only). Configuration variables are
described in [backend/.env.example](backend/.env.example). To regenerate the
data, run `bin/rails db:seed:replant`.

## Tests

```bash
cd backend && bundle exec rspec    # 399 examples
cd frontend && npm test            # 109 tests
```

The tests cover the business rules (salary revisions, assignment changes,
history, statistics including medians), the API, authentication, and the
main user flows in the UI. Timings are in
[docs/performance.md](docs/performance.md).

## Project structure

```
backend/    Rails 8 API: models, services (business rules), queries
            (search and statistics), serializers, seed generator
frontend/   React + TypeScript: pages, forms, API client, money formatting
docs/       Requirements, architecture, performance, AI usage, test plan
Dockerfile  One image that builds the frontend and serves it from Rails
```

## Documentation

- [Requirements](docs/requirements.md): goal, scope and what's left out
- [Clarifications](docs/clarifications.md): answers from the Incubyte team
- [Architecture](docs/architecture.md): stack, data model and key decisions
- [Performance](docs/performance.md): measured timings and bundle sizes
- [Manual test plan](docs/manual-test-plan.md): end-to-end checks and results
- [AI usage](docs/ai-usage.md): how AI tools were used, and mistakes caught
- [CLAUDE.md](CLAUDE.md): standing instructions for the coding agent