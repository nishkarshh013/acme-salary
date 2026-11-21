# AI Usage Log

This log records how I used AI tools while building this project: what I asked,
what I accepted, and where I corrected or overrode the output.

## Tools

- **Claude (claude.ai)** — requirements drafting, architecture discussion, design trade-offs, reviewing my docs
- **Claude Code** — code generation, tests, refactoring

## How I worked with AI

- I gathered requirements myself first, by asking the Incubyte team
  [clarifying questions](clarifications.md), and gave the AI those answers as context instead of letting it guess scope.
- I asked for reasoning and trade-offs, not just output, so I could judge decisions.
- Standing conventions for the coding agent live in [CLAUDE.md](../CLAUDE.md)
  (money as decimals, append-only history, no commits by the agent), so every
  session starts from the same rules. The agent stops after each chunk for my review.
- I review every generated change before committing.
- I run the test suite myself (`bundle exec rspec` for the backend, `npm test` for
  the frontend) before every commit, and only commit when it is green.
- AI drafts; I decide. Where I disagreed, I recorded it below.

## Log

| # | Phase | What I asked | What AI produced | What I changed or rejected, and why |
|---|-------|--------------|------------------|-------------------------------------|
| 1 | Requirements | Shared the assignment and the team's answers; asked for an approach | Architecture proposal: Rails API + Postgres, React + Ant Design, data model, test strategy | Accepted Postgres over SQLite because SQLite has no median function |
| 2 | Requirements | Asked for a one-page [requirements doc](requirements.md) | Draft with goal, scope, non-functional requirements, out-of-scope list | The draft treated transfer history as out of scope. I wanted country, department and role history preserved too, because losing history is a core problem with Excel. I had it moved into scope and made history append-only. |
| 3 | Requirements | Checked whether the history change was applied throughout the doc | Updates to consistency, testing and success criteria sections | The goal paragraph still did not mention history. I pointed to it and had it rewritten so the goal matches the features. |
| 4 | Setup | Asked for project setup steps | Commands for a Rails 8 API, Vite + React + TypeScript app, and test tooling | Chose RSpec over Rails' default Minitest: readable specs and FactoryBot support. Generated the app with `-T` and installed `rspec-rails`. |
| 5 | Architecture | Asked why one repo instead of separate FE and BE projects | Trade-off explanation | Kept one repo; same-origin deployment lets me use httpOnly cookies instead of JWTs in localStorage |
| 6 | Docs | Asked what to write in this log | A template with pre-filled entries | Removed tools I did not use, so the log reflects my actual workflow |
| 7 | Architecture | Asked AI to review my [architecture.md](architecture.md) | Review: I had pasted its earlier answer verbatim, including chat phrasing, and the note covered only the repo decision | Rewrote the note as short decision records and expanded it to cover the stack, data model, currency handling and append-only history |
| 8 | Docs | Asked AI to check this log | Review: the client's answers were pasted into the middle of the log and broke its structure | Moved them into their own file, [clarifications.md](clarifications.md), and linked to it from here |
| 9 | Models | Gave Claude Code (guided by CLAUDE.md) a scoped prompt for countries, departments, job titles and employees | Migrations, models, factories and specs, plus a report flagging its own extra choices and two open questions | Accepted its extra choices (currency must match country, DB check constraints, normalization, delete guards, locking spec). Dropped the redundant country_id index, since the composite index covers it. Made department and job title names case-insensitive, because "Engineering" and "engineering" as separate rows would split one department in the insights. |
| 10 | Setup | Investigated the nested repo Claude Code reported | — | Removed backend/.git and tracked the backend files directly in a fix commit, keeping the fix separate from the model work |
| 11 | Models | Asked Claude Code for the history tables and exchange rates | Models and specs, plus a report showing that `delete`, `update_all`, `delete_all` and raw SQL bypass `readonly?` | Chose to override `delete` and document the rest instead of adding a Postgres trigger, because triggers would force a switch from schema.rb to structure.sql. Removed schema-structure specs and made "test behaviour, not structure" a CLAUDE.md rule. |
| 12 | Services | Asked Claude Code for Employees::Hire and Salaries::Revise, with the rules, transaction and lock_version behaviour specified | Both services, a result object, and specs including rollback cases that fail partway through. It also found that an oversized amount caused a database range error. | Kept its double stale check, because it guarantees previous_amount is the salary the HR manager actually saw. Had it return failures instead of exceptions for the duplicate-hire race and unparseable or oversized input, and chose to reject amounts with more than two decimals rather than round them silently. |
| 13 | Services | Asked Claude Code for Employees::ChangeAssignment and a previous_currency column, without duplicating the revision rules | The service, shared rule objects extracted from Revise, and specs including a rollback of two inserted history rows. It flagged four behaviours I might not expect. | Changed the rule so a new salary is required only when the currency changes, since a same-currency move would otherwise create a revision with no real change. Moved the post-failure reload into the services instead of relying on controllers, and aligned Hire's messages with the shared rules. |
| 14 | Seeding | Asked Claude Code for a deterministic, testable 10,000-employee seed with consistent history | A generator class with reference data, salary bands per title and country, and a spec checking history consistency and determinism. Seed runs in 4.9 s. It flagged that Faker was missing in production. | Moved Faker to the default gem group so the deployed demo can seed itself. Kept the inactive employees it added, and decided insights will exclude inactive employees by default. |
| 15 | Auth | Asked Claude Code for cookie-based authentication with Origin-based CSRF protection and rate limiting | Auth adapted for API mode, with request specs. It found that json 3 broke every JSON response under Rails 8.0 and pinned it, and noticed the test cache made the rate limit untestable. | Set sessions to expire after 12 hours instead of the generator's 20-year cookie. Made the seed skip existing data with exit 0, so it's safe to run on deploy. Removed unused ActionCable code. |
| 16 | API | Asked Claude Code for the read side of the employee API, with salary sorting allowed only within one country and money sent as strings | Lookup, list and detail endpoints, a search query object, a history timeline, serializers, and measured timings on the full data set | Decided employee codes are generated automatically rather than typed by HR. Kept search without a trigram index because measurements showed it 10 times under target. Unified all error responses into one shape before the frontend could depend on two. |
| 17 | API | Asked Claude Code for the write endpoints, auto-generated employee codes with retry on collision, and 409 for stale edits | Four endpoints wrapping the services, a typed error result so controllers never compare message text, and specs checking nothing changes on failure | Made unknown request fields raise in development and test so frontend typos surface immediately, while production keeps Rails' default. Kept the unrequested Detail query object, since it was flagged and harmless. |
| 18 | Insights | Asked Claude Code for insights in SQL: full statistics within a country, only converted totals org-wide, inactive employees excluded | Three endpoints, a statistics query object, labelled conversions, and specs on a hand-built data set with medians worked out by hand | Checked that the expected medians were calculated independently, not copied from the code's output. Kept the one-cent rounding difference between breakdowns and decided to explain it in the UI rather than force totals to add up. |
| 19 | Frontend | Asked Claude Code for the frontend foundation: API client, auth, layout, exact money formatting and test setup | The foundation with tests, verified through tests only | Checked it in the browser against the running Rails app and checked that no amount is converted to a JavaScript number. Switched tests to user-event. Added a session re-check when the tab regains focus, so an expired session is noticed immediately; Claude Code found that the obvious setting would have done nothing, and the tests proved it. |


## Prompts worth keeping

Lightly edited for spelling.

### 1. Initial context
> I am a Ruby on Rails developer. I got an assignment which I need to complete.
> The tech stack is Rails + React JS. I have attached the assignment. I asked
> the Incubyte team some functional and non-functional questions and gathered
> the answers: [answers pasted in full]

The full answers are recorded in [clarifications.md](clarifications.md).

### 2. Requirements document
> OK, go ahead please. (Asking for the one-page requirements document.)

### 3. Preserving history
> I think we should preserve history as well.

Followed by pointing at the goal paragraph, which still described the old
behaviour: "I am talking about this: 'Today salary data lives in Excel files...'"

### 4. Repository structure
> Why do we choose backend and frontend in the same repo? Why not create two
> separate projects, one for FE and the other for BE?

### 5. Reviewing my own docs
> Are these correct, or should we rephrase them? (Shared my [architecture.md](architecture.md)
> and this log for review.)

### 6. First models (Claude Code)
> Read CLAUDE.md and docs/architecture.md first. Create the first part of the
> data model in backend/: migrations and models for countries, departments,
> job_titles and employees... Do not create the history tables or exchange
> rates yet. Run bundle exec rspec and stop when it passes, so I can review.

## Where AI got it wrong

- **Incomplete edit.** When I asked to preserve history, the first change updated
  the scope tables but left other sections describing the old behaviour. I caught
  this by rereading the doc and asked twice before every section was consistent.
  Lesson: after asking for a change, check the whole document, not just the part
  that was edited.
- **Chat output in a project file.** My first architecture.md was an AI answer
  pasted verbatim, including a sentence addressed to me ("that's worth saying in
  your architecture note"). A review caught it before commit. Lesson: AI text is
  a draft; project docs must be rewritten in my own voice.
- **Nested git repository.** The setup command from Claude (claude.ai) ran
  `rails new backend` without `--skip-git`, so Rails created its own repository
  inside backend/. The outer repo stored only a pointer to it, and the scaffold
  commit pushed to GitHub contained no backend code. Claude Code noticed the
  mismatch later while building the models. Lesson: after scaffolding, check
  that `git ls-files` lists the files.

- **Silently skipped task.** I asked Claude Code for two changes in one
  prompt: re-check the session on tab focus, and switch tests to user-event.
  Its report described only the first, and didn't say the second was
  missing. A grep of package.json showed user-event was never installed.
  Lesson: verify each item in a multi-part request, and prefer one task per
  prompt.
  
  - **Untestable manual check.** The browser test plan from Claude (claude.ai)
  said to delete the session cookie and click Insights, but Insights was a
  placeholder that makes no API calls, so no 401 could happen. I questioned
  the result instead of assuming a bug or a pass. Reloading the page and
  calling the API directly showed the server rejects requests without a
  session. It also exposed a real gap, an expired session going unnoticed
  until the next data request, which I fixed.