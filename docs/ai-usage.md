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

## Prompts worth keeping

Lightly edited for spelling.

### 1. Initial context
> I am a Ruby on Rails developer. I got an assignment which I need to complete.
> The tech stack is Rails + React JS. I have attached the assignment. I asked
> the Incubyte team some functional and non-functional questions and gathered
> the answers: [The full answers are recorded in [clarifications.md](clarifications.md).]

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