#!/usr/bin/env bash
# new-run.sh — start a new validation run for a task (immutable evidence history).
#   tools/new-run.sh API-9999
# Archives the CURRENT phase-07/phase-09 artifacts into work/<KEY>/validation/run-NNN/
# (next number) and removes them from the task root. Side effect by design: the
# publication gate re-closes mechanically (the hooks stop finding TESTS: GREEN /
# REVIEW-CODE: APPROVED) until the rework re-earns them. Runs are NEVER overwritten
# or deleted — a fix without a fresh run is not evidence.
# Must stay bash-3.2 compatible.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$(printf '%s' "${1:?usage: new-run.sh API-9999}" | tr '[:lower:]' '[:upper:]')"
DIR="$ROOT/work/$KEY"
[ -d "$DIR" ] || { echo "⛔ no work/$KEY — nothing to archive"; exit 2; }

N=1
while [ -d "$DIR/validation/run-$(printf '%03d' "$N")" ]; do N=$((N+1)); done
RUN="$DIR/validation/run-$(printf '%03d' "$N")"

MOVED=0
mkdir -p "$RUN"
# PUSH-APPROVED is archived too: the user approved the PREVIOUS diff, and an approval
# must never outlive the evidence it approved. Archiving only CLOSES gates (the agent
# still cannot create these files), so it is safe for this script to move it.
for f in phase-07-testing.md phase-09-pre-review.md PUSH-APPROVED; do
  if [ -f "$DIR/$f" ]; then
    mv "$DIR/$f" "$RUN/$f"
    echo "✔ archived $f → validation/run-$(printf '%03d' "$N")/"
    MOVED=1
  fi
done

if [ "$MOVED" = "0" ]; then
  rmdir "$RUN" 2>/dev/null || true
  echo "· nothing to archive (no phase-07/phase-09 artifacts at the task root)"
else
  echo "⛔ gates re-closed for $KEY: re-earn TESTS: GREEN and the four Phase 9 markers in fresh artifacts."
  echo "   Previous evidence preserved at work/$KEY/validation/run-$(printf '%03d' "$N")/ (never edit it)."
fi
