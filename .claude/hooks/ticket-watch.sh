#!/usr/bin/env bash
# ticket-watch.sh — SessionStart + UserPromptSubmit hook.
# Surfaces what changed ON THE JIRA SIDE of every open task: test-matrix drift since the accepted
# baseline (new/changed/retired rows, stale subtask results, description ≠ subtask, new comments)
# and the due date's state (missing, or overtaken by a devolution / block / estimate change).
#
# It never calls Jira inline — a prompt must not wait on the network. It prints the cached result
# (work/<KEY>/ticket-snapshots/watch.txt) and, when a cache is older than the TTL, starts
# `jira_sync.py watch` in the background to refresh it for the next prompt. Read-only on Jira;
# fails open (no jira-sync configured, no python, errors ⇒ silence or a one-line note).
#
# Knobs: VIVA_TICKET_WATCH_OFF=1 (disable) · VIVA_TICKET_WATCH_TTL=<seconds> (default 1800)
#        VIVA_TICKET_WATCH_NO_REFRESH=1 (print the cache only — the test suite)
#        CODER_WATCH_JIRA_DIR (where jira_sync.py lives; default tools/jira-sync)
# Must stay bash-3.2 compatible.

set -uo pipefail
[ "${VIVA_TICKET_WATCH_OFF:-}" = "1" ] && exit 0
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HOOK_DIR/lib-gate.sh"

JS="${CODER_WATCH_JIRA_DIR:-$CODER_ROOT/tools/jira-sync}"
TTL="${VIVA_TICKET_WATCH_TTL:-1800}"
STATE_DIR="$WORK_DIR/.ticket-watch"
[ -d "$WORK_DIR" ] || exit 0

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
NOW="$(date +%s)"

OUT=""; STALE=""
for DIR in "$WORK_DIR"/*/; do
  [ -d "$DIR" ] || continue
  KEY="$(basename "$DIR")"
  case "$KEY" in *[A-Z]-[0-9]*) : ;; *) continue ;; esac
  # a closed task is not watched (delivery-state.md is the board; see process/_templates)
  if grep -qiE '^- `overall_status`: *closed' "$DIR/delivery-state.md" 2>/dev/null; then continue; fi
  CACHE="$DIR/ticket-snapshots/watch.txt"
  if [ -f "$CACHE" ]; then
    AGE=$(( (NOW - $(mtime "$CACHE")) / 60 ))
    if [ -s "$CACHE" ]; then
      OUT="$OUT$(sed "s/\$/  (checked ${AGE} min ago)/" "$CACHE")"$'\n'
    fi
    [ $(( AGE * 60 )) -ge "$TTL" ] && STALE="$STALE $KEY"
  else
    STALE="$STALE $KEY"
  fi
done

if [ -n "$OUT" ]; then
  echo "TICKET WATCH (Jira side of the open tasks — matrix drift vs the accepted baseline + due date):"
  printf '%s' "$OUT"
  echo "→ Tell the user at the TOP of your answer. Matrix changed ⇒ update the subtask results to the new cases; SPEC-CHANGED/ADDED ⇒ likely re-implementation (back through Phase 4/5, rework window above). Deadline ⏰ ⇒ propose the suggested date (or theirs) and the estimate increase. Every Jira write (subtask results, estimate, due date) needs the user's explicit yes and a --dry-run first (Annex D §D.2). Once handled: jira_sync.py matrix <KEY> --accept."
fi

# --- background refresh --------------------------------------------------------
[ -n "$STALE" ] || exit 0
[ "${VIVA_TICKET_WATCH_NO_REFRESH:-}" = "1" ] && exit 0
PY="$JS/.venv/Scripts/python.exe"; [ -x "$PY" ] || PY="$JS/.venv/bin/python"
[ -x "$PY" ] && [ -f "$JS/.env" ] && [ -f "$JS/jira_sync.py" ] || exit 0

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
LOCK="$STATE_DIR/lock"
# one refresh at a time; a lock older than 10 min is a crashed run
if [ -d "$LOCK" ] && [ $(( NOW - $(mtime "$LOCK") )) -gt 600 ]; then rmdir "$LOCK" 2>/dev/null; fi
mkdir "$LOCK" 2>/dev/null || exit 0
# shellcheck disable=SC2086  # $STALE is a space-separated key list on purpose
( cd "$JS" && "$PY" jira_sync.py watch $STALE --work-dir "$WORK_DIR" >"$STATE_DIR/last-run.log" 2>&1
  rmdir "$LOCK" 2>/dev/null ) </dev/null >/dev/null 2>&1 &
exit 0
