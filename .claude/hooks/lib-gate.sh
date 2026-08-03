#!/usr/bin/env bash
# lib-gate.sh — shared helpers for the Coder pipeline gate.
# Sourced by pipeline-state.sh, guard-writes.sh and guard-bash.sh.
#
# The gate is DETERMINISTIC: it checks that the per-task artifacts exist under
# work/<KEY>/ with the required markers. It cannot judge their quality — that
# is what the process files and the human review are for — but it makes
# skipping a phase impossible by accident: the write is denied until the
# artifact exists.
#
# Artifact contract (fixed names, defined in ../CLAUDE.md):
#   work/_active                        ← key of the task in progress (one line)
#   work/<KEY>/phase-00-intake.md
#   work/<KEY>/phase-01-contrast.md
#   work/<KEY>/phase-02-impact-matrix.md
#   work/<KEY>/phase-03-feasibility.md
#   work/<KEY>/phase-04-verdict.md      ← must contain "VERDICT: ✅" to open the gate
#   work/<KEY>/phase-05-plan.md         ← required before any code write
#   work/<KEY>/phase-09-pre-review.md   ← must contain "REVIEW-CODE: APPROVED" before push/PR
#   work/<KEY>/HUMAN-GATE-REQUIRED      ← optional (risky level): if present,
#   work/<KEY>/HUMAN-GATE-OK              a HUMAN must create this file by hand
#
# Must stay bash-3.2 compatible (macOS default bash).

GATE_HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODER_ROOT="$(cd "$GATE_HOOK_DIR/../.." && pwd)"
WORK_DIR="$CODER_ROOT/work"

# The code repo is a sibling folder. Note: its name is a prefix of this repo's
# name and of the ApiLLM repo's name — match it exactly, never by substring.
CODE_REPO="$(cd "$CODER_ROOT/.." 2>/dev/null && pwd)/VivaAerobus.Generic.Api"

gate_active_key() {
  [ -f "$WORK_DIR/_active" ] || return 1
  head -1 "$WORK_DIR/_active" | tr -d '[:space:]'
}

# Prints the missing analysis artifacts (phases 0-5) for a task key, one per
# line. Empty output = analysis gate satisfied.
gate_missing_analysis() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  [ -f "$DIR/phase-00-intake.md" ]        || echo "work/$KEY/phase-00-intake.md (Phase 0)"
  [ -f "$DIR/phase-01-contrast.md" ]      || echo "work/$KEY/phase-01-contrast.md (Phase 1)"
  [ -f "$DIR/phase-02-impact-matrix.md" ] || echo "work/$KEY/phase-02-impact-matrix.md (Phase 2)"
  [ -f "$DIR/phase-03-feasibility.md" ]   || echo "work/$KEY/phase-03-feasibility.md (Phase 3)"
  if [ ! -f "$DIR/phase-04-verdict.md" ]; then
    echo "work/$KEY/phase-04-verdict.md (Phase 4 — the GATE)"
  elif ! grep -q "VERDICT: ✅" "$DIR/phase-04-verdict.md" 2>/dev/null; then
    if grep -q "VERDICT: ⚠️\|VERDICT: ⛔" "$DIR/phase-04-verdict.md" 2>/dev/null; then
      echo "VERDICT-NOT-APPROVED"
    else
      echo "work/$KEY/phase-04-verdict.md missing the 'VERDICT: ✅' line (Phase 4)"
    fi
  fi
  [ -f "$DIR/phase-05-plan.md" ]          || echo "work/$KEY/phase-05-plan.md (Phase 5)"
  if [ -f "$DIR/HUMAN-GATE-REQUIRED" ] && [ ! -f "$DIR/HUMAN-GATE-OK" ]; then
    echo "HUMAN-GATE-PENDING"
  fi
}

# Prints missing pre-review artifacts for push/PR. Empty = ok.
gate_missing_prereview() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  if [ ! -f "$DIR/phase-09-pre-review.md" ]; then
    echo "work/$KEY/phase-09-pre-review.md (Phase 9)"
  elif ! grep -q "REVIEW-CODE: APPROVED" "$DIR/phase-09-pre-review.md" 2>/dev/null; then
    echo "work/$KEY/phase-09-pre-review.md missing the 'REVIEW-CODE: APPROVED' line (Phase 9 — run the ApiLLM's llm/REVIEW-CODE.md)"
  fi
}

# Emits a PreToolUse deny decision and exits 0 (Claude Code reads the JSON).
gate_deny() {
  REASON="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json,sys
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PreToolUse",
  "permissionDecision": "deny",
  "permissionDecisionReason": sys.argv[1]}}))' "$REASON" 2>/dev/null && exit 0
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by pipeline gate: analysis artifacts missing under work/<KEY>/. See CLAUDE.md."}}\n'
  exit 0
}

# Builds the full deny message for a code write, given the missing list.
gate_deny_message() {
  KEY="$1"; MISSING="$2"; ACTION="$3"
  if printf '%s' "$MISSING" | grep -q "VERDICT-NOT-APPROVED"; then
    printf '⛔ GATE (Phase 4): the verdict recorded in work/%s/phase-04-verdict.md is ⚠️/⛔. The pipeline requires STOPPING: surface the blocking questions to the user and do NOT %s. Only a "VERDICT: ✅" (after resolving the blockers with the requester) opens the gate. See process/phase-04-blockers.md.' "$KEY" "$ACTION"
    return
  fi
  if printf '%s' "$MISSING" | grep -q "HUMAN-GATE-PENDING"; then
    printf '⛔ HUMAN GATE: task %s is flagged as risky (work/%s/HUMAN-GATE-REQUIRED). A human must approve the plan by creating work/%s/HUMAN-GATE-OK by hand (touch work/%s/HUMAN-GATE-OK). The agent is FORBIDDEN from creating that file — ask the user to create it once the plan has been reviewed.' "$KEY" "$KEY" "$KEY" "$KEY"
    return
  fi
  printf '⛔ PIPELINE GATE: cannot %s — analysis artifacts for task %s are missing (phases 0-5):\n%s\nComplete the phases in order (process/phase-NN-*.md) and record each artifact in work/%s/. The Phase 4 gate requires "VERDICT: ✅" before touching code.' "$ACTION" "$KEY" "$MISSING" "$KEY"
}
