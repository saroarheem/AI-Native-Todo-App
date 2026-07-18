# AI-Native ToDo — PR Automation Bot Report

> **Before you submit:** replace every `[TODO: …]` placeholder with your real
> evidence (PR URL, Actions run link, screenshots, the bot's actual comment).
> The technical sections below describe the system as built; the *end-to-end run*
> evidence in §7 must come from your own live run so nothing is fabricated.

**Project:** `saroarheem/AI-Native-Todo-App` — a front-end-only Angular 22 todo
app (standalone components, signals, in-memory data service).
**Deliverable:** a Claude-powered GitHub Actions bot that reviews pull requests,
plus a designed extension that auto-fixes safe issues and triages issues.
**Author:** [TODO: your name] **Date:** [TODO: date]

---

## 1. Review Logic Definition

The bot's job is a **scoped, deterministic-in-intent review**: it looks only at
what changed in a PR and reports a narrow, well-defined class of problems.

**Inputs**
- The PR's unified diff, fetched with `gh pr diff <number>`.
- Only **added/changed lines** (lines beginning with `+`) are in scope. Existing
  code is never re-reviewed, which keeps the signal focused on the change itself.

**What it flags (in scope)**
- Spelling mistakes / typos in:
  - code comments,
  - documentation & Markdown,
  - user-facing strings and UI text,
  - identifiers (variable/function names) **only when clearly misspelled**.

**What it ignores (out of scope)** — to keep precision high and avoid noise:
- code style, logic, formatting, naming preferences,
- intentional abbreviations, technical jargon, framework keywords, valid tokens.

**Output contract**
- Exactly **one** PR comment, in a fixed format:
  - First line: a summary (`✅ No typos found` or `📝 Found N typo(s)`).
  - If any: a bullet list, one per line — `path/to/file:line — "wrong" → "correct"`.
  - Nothing else (no praise, no unrelated commentary, no full code review).

**Classification policy (automatic vs. human approval).**
Every candidate action is sorted into one of two buckets, and this is the core of
the review logic for the *extended* bot:

| Bucket | Examples | Action |
| --- | --- | --- |
| ✅ **Safe → automatic** | typos in comments / Markdown / docs; a test-only fix (`*.spec.ts`) that turns the suite green | Apply and push to the **PR branch** (never `main`) |
| 🛑 **Risky → needs human approval** | typos in string literals / UI text; identifier renames; any change to non-test source; a still-red suite; edits that break the build | **Report only** — leave a comment, change nothing |

The bright line is *blast radius*: an action is automatic only when a mechanical
check can prove it did not change program behavior (e.g. "only test files changed
**and** the suite is green", or "only comments/docs changed **and** the project
still builds"). Everything else is escalated.

---

## 2. Subagent Architecture

The system is a set of **single-purpose agents**, each triggered by a specific
GitHub event and each granted the minimum tools it needs (principle of least
privilege). This is more robust and auditable than one general agent.

```
                         GitHub events
        ┌────────────────────┼─────────────────────┐
   pull_request         pull_request              issues
        │                    │                       │
 ┌──────▼──────┐    ┌────────▼────────┐    ┌─────────▼────────┐
 │ Typo Review │    │ Test Auto-Fix   │    │ Issue Triage      │
 │   agent     │    │   agent         │    │   agent           │
 └──────┬──────┘    └────────┬────────┘    └─────────┬────────┘
        │  proposes           │  proposes             │  proposes
 ┌──────▼───────────────────────────────────────────────────────┐
 │  Deterministic "supervisor" step (plain shell in the workflow) │
 │  — re-verifies and ENFORCES the safety gates before any write  │
 └────────────────────────────────────────────────────────────────┘
```

**Two-layer pattern (the key design idea).**
Each agent is an LLM that *proposes* changes; a deterministic workflow step then
*disposes* — it re-checks the work and only then commits/pushes/comments. The LLM
is never trusted to enforce its own safety rules. Concretely:

- **Typo agent** edits only comments/docs and writes a report. The supervisor
  then confirms *only comment/doc file types changed* and *the build still passes*
  before pushing.
- **Test Auto-Fix agent** edits only `*.spec.ts` and writes a report. The
  supervisor confirms *only spec files changed* and *re-runs the suite* to confirm
  it is green before pushing.
- **Issue Triage agent** proposes labels/priority; label creation is pre-seeded
  by the workflow so the vocabulary stays fixed; closing/assigning is escalated.

**Per-agent tool scoping** (`--allowedTools`) — e.g. the typo agent gets
`Bash(gh pr diff:*), Read, Grep, Glob, Edit, Write` but **not** `git push` or
`gh pr comment`; those privileged actions belong to the deterministic layer.

**Agent ↔ supervisor handoff** is via a small on-disk report file
(`typo-report.md`), not conversational state — see §3.

**Development-time subagents.** During construction, Claude Code's own
`Explore` and `Plan` subagents were used to survey the codebase and design the
workflows before writing them.

---

## 3. Context Management Strategy

The bot deliberately keeps each agent's context **small, fresh, and bounded**:

1. **Task-scoped prompts.** Each agent receives only the repository name, the PR/
   issue number, and its instructions — not the whole history.
2. **Diff-only reading.** The agent reads the change via `gh pr diff` rather than
   loading the entire repository, bounding token usage to the size of the change.
3. **Persistent project context via `CLAUDE.md`.** Repo-wide conventions (Angular
   22, standalone components, in-memory data service, "no backend") live in
   `CLAUDE.md` so every agent shares the same ground truth without re-deriving it.
4. **Least-privilege tools.** `--allowedTools` restricts what each agent can pull
   into context and act on, which also caps the blast radius.
5. **Turn caps.** `--max-turns` bounds each agent's loop (8 for the typo review,
   higher for the fix agents that must run tests).
6. **File-based handoff instead of long context.** The agent writes a compact
   report file; the deterministic supervisor reads *that*, not a long transcript.
   The report is written inside the workspace (the agent's file tools are
   sandboxed to the repo) and moved out before the git safety check.
7. **Ephemeral runners.** Every run starts from a clean checkout, so no state
   leaks between runs.

---

## 4. TDD Tests

**Stack:** Vitest + jsdom. Spec files live beside their components
(`src/app/**/*.spec.ts`). CI runs the suite once with:

```bash
npm test -- --watch=false
```

**TDD workflow (red → green → refactor):**
1. Write a failing test that specifies the desired behavior (**red**).
2. Write the minimum code to pass it (**green**).
3. Clean up while keeping the suite green (**refactor**).

The **Test Auto-Fix agent** is the automation of the red→green step for the
*safe* case: when a change makes a test red because the **test** is now outdated,
the agent updates the `*.spec.ts` and the supervisor confirms green before push.
When the *production* code is at fault, it refuses and escalates — a human decides.

**Representative existing spec** — `src/app/services/data.spec.ts`:

```ts
import { TestBed } from '@angular/core/testing';
import { Data } from './data';

describe('Data', () => {
  let service: Data;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(Data);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
```

**Illustrative TDD example** for the `Data` service (write the test first, then
implement) — *example to demonstrate the approach*:

```ts
it('getTodoById returns the matching todo', () => {
  const todo = service.getTodoById(1);        // red: assert before implementing
  expect(todo?.id).toBe(1);
});

it('addTodo appends a new item', () => {
  const before = service.getTodos().length;
  service.addTodo({ id: 99, title: 'Test', description: '', status: 'due' });
  expect(service.getTodos().length).toBe(before + 1);
});
```

**Current suite status:** [TODO: paste the output of `npm test -- --watch=false`].
_Note: at the time of writing, several component specs fail with
`No provider found for ActivatedRoute` — components that use `RouterLink` need
router test providers (`provideRouter([])`) in their `TestBed`. This is exactly
the kind of test-only, safe fix the auto-fix agent is designed to handle._

---

## 5. Refactoring Notes

Notable refactors made while building the bot:

1. **Report file location (bug fix).** The fix agents originally wrote their
   report to `${{ runner.temp }}` — *outside* the checked-out repo. The action's
   file tools are sandboxed to the workspace, so the write silently failed and the
   supervisor always hit its fallback ("did not produce a report"). **Fix:** write
   the report *inside* the repo and have the supervisor move it out **before** the
   git diff check, so it never counts as a code change.
2. **Two-layer safety (LLM proposes / workflow disposes).** Instead of trusting
   the model's self-report, the workflow re-verifies invariants itself
   (changed-file types + suite-green / build-green) before any push.
3. **Outcome-aware fallback.** The supervisor distinguishes "the agent step
   errored" (`outcome != success`) from "the agent ran but changed nothing", so
   failures are diagnosable from the PR comment alone.
4. **Consolidated typo detect-and-fix.** Detection and fixing happen in one agent
   run that re-scans the diff, rather than a second bot parsing the first bot's
   comment (which would be fragile across runs).
5. **Fork-PR gating.** PR fix jobs are gated to same-repo PRs
   (`head.repo.full_name == github.repository`) because fork PRs get a read-only
   token and no secrets — the bot can neither push nor comment there.
6. **Shell-safety fixes.** e.g. `paste -sd ', '` treats `,` and space as
   *alternating* delimiters (`a,b c,d`); corrected to
   `paste -sd ',' - | sed 's/,/, /g'` to get a proper `a, b, c` list. All shell
   snippets were checked under `set -euo pipefail`.

---

## 6. GitHub Actions Workflow File

The active workflow, `.github/workflows/claude-typo-review.yml`:

```yaml
name: Claude Typo Review

# Runs a Claude-powered bot on every pull request that scans the changed lines
# for typos/spelling mistakes and posts a short report as a PR comment.

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write
  id-token: write  # required by claude-code-action to request an OIDC token

jobs:
  typo-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Claude typo review
        uses: anthropics/claude-code-action@v1
        env:
          # Lets the `gh` CLI calls Claude makes authenticate against this repo.
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          prompt: |
            You are a typo-checking bot for pull requests. Be strict and concise.

            Repository: ${{ github.repository }}
            PR number: ${{ github.event.pull_request.number }}

            Steps:
            1. Run `gh pr diff ${{ github.event.pull_request.number }}` to get the
               diff for this PR.
            2. Review ONLY the added/changed lines (lines starting with `+`) for
               spelling mistakes and typos in:
                 - code comments
                 - documentation and Markdown
                 - user-facing strings and UI text
                 - identifiers (variable/function names) only when clearly misspelled
            3. Ignore everything that is not a typo: code style, logic, formatting,
               naming preferences. Do NOT flag intentional abbreviations, technical
               jargon, framework keywords, or valid code tokens.
            4. Post exactly ONE short PR comment with your findings using:
               `gh pr comment ${{ github.event.pull_request.number }} --body "<report>"`

            Report format (keep it short — this is a quick check, not a full review):
              - First line: a summary, e.g. `✅ No typos found` or `📝 Found N typo(s)`.
              - If typos exist, a bullet list. Each bullet on its own line:
                `path/to/file:line — "wrong" → "correct"`
              - Nothing else. No praise, no unrelated commentary, no code review.
          claude_args: |
            --max-turns 8
            --allowedTools "Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr comment:*),Read,Grep,Glob"
```

**Key design points in the workflow**
- **Trigger:** `pull_request` (`opened`, `synchronize`, `reopened`) — runs on
  every PR and on every new push to an open PR.
- **Permissions (least privilege):** `contents: read` (never writes source in the
  review-only version), `pull-requests: write` (to comment), `id-token: write`
  (OIDC token for `claude-code-action`).
- **Secrets:** `CLAUDE_CODE_OAUTH_TOKEN` (auth to Claude) + the built-in
  `GITHUB_TOKEN` (auth for `gh`).
- **Tool allow-list:** the agent may only read the diff and post one comment.

> The **extended** fix/triage workflows (auto-fix tests, issue triage) follow the
> same skeleton but add `contents: write`, a re-verification step, and the
> automatic/human-approval gates described in §1–§2. See Appendix A for their
> status.

---

## 7. End-to-End Run (Live Evidence)

Steps performed to run the bot end-to-end through GitHub Actions:

1. Created a feature branch and pushed a change containing an intentional typo
   (e.g. in a comment or in `README.md`).
2. Opened a **real pull request** into `main`:
   - PR: **[TODO: paste PR URL]**
3. The `Claude Typo Review` workflow triggered automatically on `pull_request`:
   - Actions run: **[TODO: paste the Actions run URL]**
   - Result: [TODO: ✅ success / ❌ failure]
4. The bot posted its review comment on the PR:

   > **[TODO: paste the bot's actual PR comment here]**
   >
   > _Illustrative example of the expected format:_
   > `📝 Found 2 typo(s)`
   > `README.md:14 — "dooing" → "doing"`
   > `src/app/app.ts:3 — "recieve" → "receive"`

**Screenshots:** [TODO: attach/paste screenshots of (a) the PR, (b) the green
Actions run, (c) the bot's comment].

---

## Appendix A — Extended workflows status

At the time of writing, the active branch contains the **review-only** typo bot
(§6). The auto-fix-tests and issue-triage agents described in §1–§2 were designed
and prototyped during development but are **not currently committed to this
branch**. To make the repository match this report before submission, they should
be re-added under `.github/workflows/` (auto-fix uses `contents: write` +
`npm test` re-verification; triage uses `issues: write` + a pre-seeded label
taxonomy).

## Appendix B — How to complete this report

- [ ] Fill in author/date (top).
- [ ] Open the PR and paste its URL (§7).
- [ ] Paste the Actions run URL and result (§7).
- [ ] Paste the bot's real comment (§7).
- [ ] Attach screenshots (§7).
- [ ] Paste `npm test -- --watch=false` output (§4).
- [ ] (Optional) Commit the extended workflows and update §6/Appendix A.
