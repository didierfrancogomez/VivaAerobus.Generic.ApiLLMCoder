#!/usr/bin/env bash
# pipeline-state.sh — SessionStart + UserPromptSubmit hook.
# Injects the DETERMINISTIC pipeline state into context on every prompt, so the
# agent can never claim ignorance of which phase each task is in. Read-only.

set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HOOK_DIR/lib-gate.sh"

echo "PIPELINE GATE (Coder) — deterministic state of work/:"

if [ -f "$WORK_DIR/_PROCESS-CHANGE-OK" ]; then
  echo "- ⚠️ _PROCESS-CHANGE-OK is present: the process surface (process/, CLAUDE.md, .claude/) is UNLOCKED for edits. Delete the file as soon as the agreed change is done."
fi

if [ ! -d "$WORK_DIR" ] || [ -z "$(ls -A "$WORK_DIR" 2>/dev/null | grep -v '^_active$\|^_PROCESS-CHANGE-OK$' || true)" ]; then
  echo "- No active tasks. When a Jira task arrives: create work/<KEY>/, write the key into work/_active and execute the phases in order (process/). The PreToolUse hook BLOCKS every write to the API repo until the phase 0-5 artifacts exist with 'VERDICT: ✅'."
  exit 0
fi

RES="$(gate_task_key || echo "")"
if [ -n "$RES" ]; then
  echo "- Gate resolves to task ${RES%%$'\t'*} (from ${RES#*$'\t'}). Code writes are validated against that task's artifacts — parallel plans each live on their own type/KEY-123-desc branch."
else
  echo "- ⚠️ No resolvable task (no Jira key in the code-repo branch, no work/_active) — the gate will deny code writes until one is set."
fi

for DIR in "$WORK_DIR"/*/; do
  [ -d "$DIR" ] || continue
  KEY="$(basename "$DIR")"
  MISSING="$(gate_missing_analysis "$KEY")"
  if [ -z "$MISSING" ]; then
    PRE="$(gate_missing_prereview "$KEY")"
    if [ -z "$PRE" ]; then
      DRIFT="$(gate_sha_drift "$KEY")"
      APPROVAL="$(gate_missing_push_approval "$KEY")"
      if [ -n "$DRIFT" ]; then
        echo "- $KEY: phases 0-5 complete ✅ · tests+pre-review recorded, but ⛔ DIFF DRIFT ($DRIFT) — the approval is void; re-run REVIEW-CODE.md and update VALIDATED-SHA."
      elif [ -n "$APPROVAL" ]; then
        echo "- $KEY: phases 0-5 complete ✅ · tests GREEN ✅ · pre-review APPROVED ✅ (SHA anchored) — push/PR WAITING for the user's approval: $APPROVAL"
      else
        echo "- $KEY: phases 0-5 complete ✅ · tests GREEN ✅ · pre-review APPROVED ✅ · user approved publication ✅ — push/PR enabled (phases 10-11 still owe their evidence)."
      fi
    else
      echo "- $KEY: phases 0-5 complete ✅ — implementation enabled. Push/PR BLOCKED: missing $(printf '%s' "$PRE" | tr '\n' ';')"
    fi
  elif printf '%s' "$MISSING" | grep -q "VERDICT-NOT-APPROVED"; then
    echo "- $KEY: ⛔ STOPPED at the gate (verdict ⚠️/⛔ in phase-04-verdict.md). Surface the blocking questions; do NOT code."
  else
    N=$(printf '%s\n' "$MISSING" | grep -c . || true)
    echo "- $KEY: gate CLOSED — $N analysis artifact(s) missing: $(printf '%s' "$MISSING" | tr '\n' ';' )"
  fi
done

echo "Rule: phases run in order and each one records its artifact in work/<KEY>/ BEFORE moving to the next (contract in CLAUDE.md). Writing an artifact without having done the phase's work is falsifying the gate — forbidden."
exit 0
