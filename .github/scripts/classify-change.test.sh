#!/usr/bin/env bash
#
# Behavior spec for the typo-review bot's decision layer.
# These tests DEFINE what correct bot behavior looks like; the logic in
# classify-change.sh must satisfy them.
#
# Run:  bash .github/scripts/classify-change.test.sh
#
# Note: this covers the deterministic decision/safety layer only. The LLM typo
# DETECTION step is validated end-to-end by opening a real sample PR with a
# seeded typo (see BOT.md), because it is nondeterministic and cannot be pinned
# by a unit test.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SUT="$DIR/classify-change.sh"

pass=0; fail=0
check() { # desc expected actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); printf 'ok   - %s\n' "$1"
  else
    fail=$((fail + 1)); printf 'FAIL - %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
  fi
}
inspect() { printf '%s\n' "$1" | bash "$SUT" inspect; }
decide()  { bash "$SUT" decide "$@"; }
status()  { printf '%s' "$1" | bash "$SUT" status; }

echo "== Report parsing: a sample PR flagging a known typo =="

# A sample bot report for a PR whose only change is a misspelled code comment.
sample_fixed=$'STATUS: FIXED\n\n## \xe2\x9c\x85 Auto-fixed (comments & docs)\n- `src/app/app.ts:3` \xe2\x80\x94 "recieve" -> "receive"\n\n## Needs human approval\n- None\n'
check "sample PR report that flags a known typo parses as FIXED" \
  FIXED "$(status "$sample_fixed")"

sample_approval=$'STATUS: APPROVAL_ONLY\n\n- `src/app/header.html:3` \xe2\x80\x94 "Todoo" (UI text)\n'
check "report with only string/UI typos parses as APPROVAL_ONLY" \
  APPROVAL_ONLY "$(status "$sample_approval")"

check "report with no STATUS line parses as UNKNOWN" \
  UNKNOWN "$(status $'no status line here\nblah\n')"

echo "== End-to-end routing: what the bot does with a sample PR =="

# Sample PR: a known typo in a CODE COMMENT (Bucket A). The bot fixed it in a
# .ts file and the project still builds -> the fix is pushed automatically.
check "known typo in a code comment, build passes -> auto-fix pushed" \
  PUSH "$(decide FIXED "$(inspect 'src/app/app.ts')" pass)"

# Sample PR: a known typo in Markdown docs (Bucket A) -> pushed, no build needed.
check "known typo in README prose -> auto-fix pushed" \
  PUSH "$(decide FIXED "$(inspect 'README.md')" skip)"

# Sample PR: the typo is in USER-FACING STRING / UI text (Bucket B). The bot must
# NOT edit it; it changes nothing and escalates for a human.
check "typo only in a UI string -> needs human approval, nothing pushed" \
  APPROVAL_ONLY "$(decide APPROVAL_ONLY "$(inspect '')" skip)"

# Sample PR: no typos anywhere.
check "clean PR -> posts a no-typos comment" \
  CLEAN "$(decide CLEAN "$(inspect '')" skip)"

echo "== Safety gates: the bot must never push something unsafe =="

check "bot tried to change package.json -> refuse & escalate" \
  ESCALATE_UNSAFE "$(decide FIXED "$(inspect 'package.json')" skip)"

check "bot tried to change a .json config -> refuse & escalate" \
  ESCALATE_UNSAFE "$(decide FIXED "$(inspect 'src/config.json')" skip)"

check "a comment fix in .ts that BREAKS THE BUILD -> escalate, do not push" \
  ESCALATE_BUILD "$(decide FIXED "$(inspect 'src/app/app.ts')" fail)"

check "mixed .md + .ts, build passes -> push" \
  PUSH "$(decide FIXED "$(inspect $'README.md\nsrc/app/app.ts')" pass)"

check "one unsafe file among allowed ones -> the unsafe file wins, escalate" \
  ESCALATE_UNSAFE "$(decide FIXED "$(inspect $'README.md\nsrc/app/app.ts\nangular.json')" pass)"

check "run did not complete (no changes, no valid status) -> error comment" \
  ERROR "$(decide UNKNOWN "$(inspect '')" skip)"

echo "== inspect(): file classification units =="

check "inspect: no files -> NONE"                NONE        "$(inspect '')"
check "inspect: prose only -> PROSE_ONLY"        PROSE_ONLY  "$(inspect $'README.md\nnotes.txt')"
check "inspect: source present -> NEEDS_BUILD"   NEEDS_BUILD "$(inspect 'src/app/app.ts')"
check "inspect: template source -> NEEDS_BUILD"  NEEDS_BUILD "$(inspect 'src/app/app.html')"
check "inspect: unexpected type -> UNSAFE"       UNSAFE      "$(inspect 'data.json')"

echo "== Dummy TDD examples (illustrative — safe to delete) =="
# The TDD beat: write the check FIRST (it fails = RED), implement in
# classify-change.sh until it prints the expected token (GREEN), then refactor.
# The checks below are already GREEN against the current script.

# arrange a prose doc fix, act via decide(), assert it is push-safe.
check "dummy: a single .md doc fix is push-safe" \
  PUSH "$(decide FIXED "$(inspect 'docs/guide.md')" skip)"

check "dummy: a .txt note classifies as prose" \
  PROSE_ONLY "$(inspect 'notes/todo.txt')"

check "dummy: a .scss stylesheet is buildable source" \
  NEEDS_BUILD "$(inspect 'src/styles/app.scss')"

check "dummy: no files + unrecognized status -> ERROR" \
  ERROR "$(decide UNKNOWN "$(inspect '')" skip)"

check "dummy: STATUS parsing tolerates extra spaces after the colon" \
  CLEAN "$(status $'STATUS:   CLEAN\n')"

# --- TDD RED example (kept commented so the suite stays green) ---------------
# To add a NEW behavior, uncomment this FIRST and watch it fail, then make it
# pass in classify-change.sh. It fails today because `decide` has no DRAFT rule
# (an unknown inspect token falls through to ERROR), which is exactly the RED
# state you want before implementing draft-PR handling:
#
#   check "dummy(RED): a draft PR should yield a DRAFT decision" \
#     DRAFT "$(decide FIXED DRAFT skip)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
