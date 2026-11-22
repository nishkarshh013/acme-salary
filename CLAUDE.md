# CLAUDE.md

Instructions for AI coding agents working in this repository.

## Project

Salary management app for one HR Manager at ACME (10,000 employees, multiple
countries). Read these before making changes:

- docs/requirements.md — scope and what is out of scope
- docs/architecture.md — stack, data model and key decisions
- docs/clarifications.md — client answers that define the scope

## Structure

- backend/  — Rails 8 API (JSON only), PostgreSQL, RSpec
- frontend/ — React + TypeScript + Vite, Ant Design, TanStack Query, Vitest

## Commands

- Backend tests: `cd backend && bundle exec rspec`
- Backend lint: `cd backend && bin/rubocop`
- Frontend tests: `cd frontend && npm test`
- Frontend build and lint: `cd frontend && npm run build && npm run lint`
- Seed data: `cd backend && bin/rails db:seed`

## Rules

- Money is `decimal(15,2)` with an ISO currency code. Never use floats for money.
- Salary revisions and employee assignments are append-only. Never update or
  delete a history row; corrections are new entries.
- A history entry and the matching update to the employee's current values
  must be saved in one transaction, inside a service object (app/services).
- Keep controllers thin: params, call a service or query object, render.
- Aggregations (min, max, average, median, totals) run in SQL, not Ruby.
- All API endpoints require authentication.
- Never log salary values.
- Every API error response uses { errors: [...] }, an array of human-readable messages.

## Testing

- Every model, service and query object gets a spec in the same change.
- Tests must be fast and deterministic: no network calls, no reliance on
  random data or the current time without freezing it.
- Use FactoryBot factories with explicit attributes for anything a test asserts on.
- Test behaviour, not schema structure: no specs that only check index or column names.

## Frontend

- API calls live in frontend/src/api/: one module per resource (e.g.
  session.ts) built on `apiRequest` in client.ts, with response types in
  types.ts. Components never call fetch directly; they use TanStack Query
  hooks around those functions.
- Every failed request throws an `ApiError` with `status` and `messages`
  (the API's `errors` array; status 0 means the server was unreachable).
  Show `messages` as they are, in an Ant Design Alert or on the form field;
  don't reword API errors.
- A 401 ends the session and sends the user to /login. Requests where a
  401 is an expected answer (login, the session check) pass
  `redirectOnUnauthorized: false`. A 409 means stale data: show the message
  and reload. Queries never retry a 4xx.
- Money arrives as `{ amount, currency }` strings. Display it only with
  `formatMoney` or `<MoneyText>` (src/money/), which pass the string to
  Intl.NumberFormat. Never `Number()` or `parseFloat` an amount, and don't
  do money arithmetic in the browser.
- A converted value (`converted: true`) is always shown with its `label`.
- Tests use Vitest and React Testing Library with fetch mocked by
  `mockFetch`, and `renderApp(path)` for whole-app flows (src/test/). No
  network calls.

## Working style

- Make small changes that fit in one commit, and stop after each one so I can
  review and commit.
- Do not run `git commit` or `git push`. I commit after reviewing.
- Do not edit files in docs/ unless I ask.
- If a requirement is unclear, ask instead of guessing.
- Don't change system settings outside this repository (power profile, global
  packages, services). Ask me instead.