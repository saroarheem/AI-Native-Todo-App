# Repository Automation Bots

This repo uses three Claude-powered GitHub Actions bots. Each one is deliberately
scoped, and every action it can take is classified as either **✅ AUTOMATIC**
(the bot does it on its own, because it is low-risk and reversible or gated by a
later human step) or **🛑 NEEDS HUMAN APPROVAL** (the bot will *recommend* it but
never perform it — a maintainer must act).

## Quick reference

| Bot | Trigger | ✅ Automatic actions | 🛑 Needs human approval |
| --- | --- | --- | --- |
| **Typo review** (`claude-typo-review.yml`) | PR opened / updated | Post one comment listing typos in changed lines | Any edit, suggestion apply, push, or merge |
| **Auto-fix tests** (`claude-autofix-tests.yml`) | PR opened / updated | Run tests; if red, apply a fix **touching only `*.spec.ts`**, re-verify the suite is green, commit & push to the **PR branch**, and comment | Any fix needing non-test source changes; a still-red suite; ambiguous/flaky failures; fork PRs; **merging** |
| **Issue triage** (`claude-issue-triage.yml`) | Issue opened / reopened | Add a `type:` label, a `priority:` label, optional `needs-info`, and post a triage summary | Closing, assigning, editing title/body, or converting the issue |

---

## 1. Typo review — `claude-typo-review.yml`

Scans the added/changed lines of every pull request for spelling mistakes and
posts a short report.

- **✅ Automatic:** posts exactly one read-only PR comment.
- **🛑 Needs human approval:** everything else. It never edits files, pushes,
  applies suggestions, or merges. The human decides what to do with the report.

## 2. Auto-fix failing tests — `claude-autofix-tests.yml`

Runs `npm test` on each PR. When the suite fails, the bot attempts a **safe**
fix.

- **✅ Automatic — a fix is applied and pushed only when ALL hold:**
  - it changes **only** test files (`*.spec.ts`);
  - the full suite is **green** afterwards;
  - the PR is from **this repo** (not a fork).

  The commit is pushed to the **PR branch only — never to `main`** — so normal PR
  review and merge remain the human gate before anything protected changes.

- **🛑 Needs human approval (the bot changes nothing and comments instead) when:**
  - the fix would require editing non-test source under `src/` (the failing test
    may be correctly catching a real bug);
  - the suite is still red after the bot's edits;
  - the failure is ambiguous, flaky, or environmental;
  - the PR comes from a fork (no write token / secrets available).

  In these cases it posts a diagnosis and a proposed fix marked
  `🛑 [NEEDS HUMAN APPROVAL]`.

> The "test-files-only" and "suite must be green" guarantees are enforced by the
> workflow steps themselves (staged-diff inspection + a re-run of the suite),
> not by trusting the model's self-report.

## 3. Issue triage — `claude-issue-triage.yml`

Triages newly opened/reopened issues using a fixed label vocabulary that the
workflow creates up front (idempotently).

- **✅ Automatic:** applies exactly one `type:` label, one `priority:` label,
  optionally `needs-info`, and posts a short triage summary comment. Labels are
  low-risk and easily reversed.
- **🛑 Needs human approval:** closing (duplicate / invalid / spam / wontfix /
  expected-behavior), assigning to a person, editing the title/body, or
  converting the issue. The bot never does these — it adds the
  `needs-human-triage` label and writes its recommendation in the comment marked
  `🛑 [NEEDS HUMAN APPROVAL]`.

### Label vocabulary

| Group | Labels |
| --- | --- |
| Type | `type: bug`, `type: feature`, `type: docs`, `type: question`, `type: chore` |
| Priority | `priority: P0` (critical), `priority: P1` (high), `priority: P2` (medium), `priority: P3` (low) |
| Flags | `needs-info`, `needs-human-triage` |

---

## Configuration / secrets

All three bots use `anthropics/claude-code-action@v1` and require the
`CLAUDE_CODE_OAUTH_TOKEN` repository secret. They rely on the built-in
`GITHUB_TOKEN`; the auto-fix bot additionally needs `contents: write` (declared
in its workflow) to push safe fixes to PR branches.
