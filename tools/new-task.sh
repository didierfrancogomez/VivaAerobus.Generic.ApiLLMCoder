#!/usr/bin/env bash
# new-task.sh — scaffold the work folder for a Jira task. Zero-effort setup:
#   tools/new-task.sh API-9999 ["ticket title"]
# Creates work/<KEY>/ + delivery-state.md from the template, points work/_active
# at the task, and (if tools/jira-sync is configured) fetches the ticket and runs
# the readiness gate. It never creates phase artifacts or gate markers — those
# are written by doing the phases' work (CLAUDE.md integrity rules).
# Must stay bash-3.2 compatible.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$(printf '%s' "${1:?usage: new-task.sh API-9999 [title]}" | tr '[:lower:]' '[:upper:]')"
TITLE="${2:-}"

case "$KEY" in
  *[A-Z]*-[0-9]*) : ;;
  *) echo "⛔ '$KEY' does not look like a Jira key (expected e.g. API-9999)"; exit 2 ;;
esac

DIR="$ROOT/work/$KEY"
mkdir -p "$DIR"

if [ ! -f "$DIR/delivery-state.md" ]; then
  sed -e "s/<KEY>/$KEY/g" -e "s/<ticket title>/${TITLE//\//\\/}/g" \
    "$ROOT/process/_templates/delivery-state.md" > "$DIR/delivery-state.md"
  echo "✔ created work/$KEY/delivery-state.md"
else
  echo "· work/$KEY/delivery-state.md already exists — left untouched"
fi

printf '%s\n' "$KEY" > "$ROOT/work/_active"
echo "✔ work/_active → $KEY"

# Optional Jira intake (Phase 0 support): fetch + readiness gate, when configured.
JS="$ROOT/tools/jira-sync"
PY="$JS/.venv/bin/python"; [ -x "$PY" ] || PY="$JS/.venv/Scripts/python.exe"
if [ -x "$PY" ] && [ -f "$JS/.env" ]; then
  echo "— jira-sync detected: fetching the ticket and running the readiness gate —"
  (cd "$JS" && "$PY" jira_sync.py ticket "$KEY") || echo "⚠ ticket fetch failed — proceed with the ticket content the user provides (Annex D §D.2)"
  if (cd "$JS" && "$PY" jira_sync.py ready "$KEY"); then
    echo "✔ READY — Phase 0 intake may proceed"
  else
    echo "⛔ NOT READY (see blockers above) — per Phase 0/§ready, report them to the requester; do NOT start"
  fi
else
  echo "· jira-sync not configured (tools/jira-sync/README.md) — Phase 0 runs from user-provided ticket content (Annex D §D.2)"
fi

echo "Next: process/phase-00-intake.md (artifacts skeleton: process/_templates/phase-artifact.md)"
