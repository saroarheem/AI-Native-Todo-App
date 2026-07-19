#!/usr/bin/env bash
#
# Deterministic decision logic for the Claude typo-review bot's safety gate.
#
# This is the part of the bot that MUST be reliable: given what the LLM claims
# (its STATUS) and what actually changed on disk (the staged file list + whether
# the build passed), it decides what the workflow should do. It is pure and
# side-effect-free (no git, no gh, no network) so it can be unit-tested on its
# own, independently of GitHub Actions and the (nondeterministic) LLM step.
#
# The workflow performs the real side effects (commit / push / comment / reset);
# this script only DECIDES. See classify-change.test.sh for the behavior spec.
#
# Subcommands:
#   status            read a typo-report on stdin, echo its STATUS token
#   inspect           read changed file paths on stdin, echo a file-class token
#   decide S I B      echo the final action token for (status, inspect, build)
set -euo pipefail

# status: extract the mandatory first-line "STATUS: X" from the bot's report.
# Echoes FIXED | APPROVAL_ONLY | CLEAN | ERROR | ... , or UNKNOWN if absent.
parse_status() {
  local s
  s=$(head -n 1 | sed -n 's/^STATUS:[[:space:]]*//p')
  [ -z "$s" ] && s=UNKNOWN
  echo "$s"
}

# inspect: read changed file paths (one per line) on stdin, echo one of:
#   NONE        - no files changed
#   UNSAFE      - a file outside the allowed comment/doc/source set was touched
#   NEEDS_BUILD - only allowed files, at least one buildable source (.ts/.html/.css/.scss)
#   PROSE_ONLY  - only prose files (.md/.markdown/.txt)
classify_files() {
  local any=0 unsafe=0 needs_build=0 f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    any=1
    case "$f" in
      *.md|*.markdown|*.txt) ;;                  # prose: no build impact
      *.ts|*.html|*.css|*.scss) needs_build=1 ;; # source: must still build
      *) unsafe=1 ;;                             # anything else: refuse
    esac
  done
  if [ "$any" -eq 0 ]; then echo NONE; return; fi
  if [ "$unsafe" -eq 1 ]; then echo UNSAFE; return; fi
  if [ "$needs_build" -eq 1 ]; then echo NEEDS_BUILD; return; fi
  echo PROSE_ONLY
}

# decide: given the report STATUS, the inspect result, and the build result
# (pass|fail|skip), echo the final action token:
#   PUSH            - safe fix, commit & push to the PR branch
#   ESCALATE_UNSAFE - bot touched a disallowed file type; reset & ask a human
#   ESCALATE_BUILD  - the edits break the build; reset & ask a human
#   CLEAN           - nothing changed, no typos found
#   APPROVAL_ONLY   - nothing changed, typos found that a human must decide on
#   ERROR           - nothing changed and the run did not complete normally
decide() {
  local status="$1" inspect="$2" build="${3:-skip}"
  case "$inspect" in
    UNSAFE) echo ESCALATE_UNSAFE ;;
    NEEDS_BUILD)
      if [ "$build" = fail ]; then echo ESCALATE_BUILD; else echo PUSH; fi ;;
    PROSE_ONLY) echo PUSH ;;
    NONE)
      case "$status" in
        CLEAN) echo CLEAN ;;
        APPROVAL_ONLY) echo APPROVAL_ONLY ;;
        *) echo ERROR ;;
      esac ;;
    *) echo ERROR ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  status)  parse_status ;;
  inspect) classify_files ;;
  decide)  shift; decide "$@" ;;
  *) echo "usage: $0 {status | inspect | decide <status> <inspect> <build>}" >&2; exit 2 ;;
esac
