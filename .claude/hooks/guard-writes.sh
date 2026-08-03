#!/usr/bin/env bash
# guard-writes.sh — PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit).
#
# Rule: NO file inside the code repo (../VivaAerobus.Generic.Api) may be
# written until the analysis gate is open for the active task:
#   phase 0-5 artifacts present in work/<KEY>/ + "VERDICT: ✅" in phase-04.
# Writes anywhere else (this repo's work/, scratchpad, memory) pass through.
#
# Also: the agent must NEVER create work/*/HUMAN-GATE-OK nor
# work/_PROCESS-CHANGE-OK — those files are the human's signature. Any attempt
# is denied here.
#
# Protected process surface: this repo's process/, CLAUDE.md and .claude/
# change only by team decision (CLAUDE.md §Conventions, Phase 11.9 retro).
# Writes there are denied unless the human has created work/_PROCESS-CHANGE-OK.
#
# Classification uses python3 realpath (case-insensitive on darwin). Without
# python3 the fallback classifies by string prefix and FAILS CLOSED for
# anything that looks like the code repo.

set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HOOK_DIR/lib-gate.sh"

INPUT="$(cat 2>/dev/null)" || INPUT=""

classify() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    p = ti.get("file_path") or ti.get("notebook_path") or ""
    if not p:
        print("OUTSIDE"); sys.exit(0)
    if not os.path.isabs(p):
        p = os.path.join(os.getcwd(), p)
    p = os.path.realpath(p)
    if os.path.basename(p) in ("HUMAN-GATE-OK", "_PROCESS-CHANGE-OK", "PUSH-APPROVED"):
        print("HUMANGATE"); sys.exit(0)
    norm = (lambda s: s.lower()) if sys.platform == "darwin" else (lambda s: s)
    def under(child, parent):
        rel = os.path.relpath(norm(child), norm(os.path.realpath(parent)))
        return not (rel == ".." or rel.startswith(".." + os.sep))
    if under(p, sys.argv[1]):
        print("CODE"); sys.exit(0)
    coder = sys.argv[2]
    if (under(p, os.path.join(coder, "process"))
            or under(p, os.path.join(coder, ".claude"))
            or norm(p) == norm(os.path.realpath(os.path.join(coder, "CLAUDE.md")))):
        print("PROTECTED"); sys.exit(0)
    print("OUTSIDE")
except Exception:
    print("")' "$CODE_REPO" "$CODER_ROOT" 2>/dev/null
  else
    FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    [ -n "$FILE" ] || { echo "OUTSIDE"; return; }
    case "$FILE" in *HUMAN-GATE-OK|*_PROCESS-CHANGE-OK|*PUSH-APPROVED) echo "HUMANGATE"; return ;; esac
    LOW_FILE="$(printf '%s' "$FILE" | tr '[:upper:]' '[:lower:]')"
    LOW_CODE="$(printf '%s' "$CODE_REPO" | tr '[:upper:]' '[:lower:]')"
    LOW_CODER="$(printf '%s' "$CODER_ROOT" | tr '[:upper:]' '[:lower:]')"
    case "$LOW_FILE" in
      "$LOW_CODE"|"$LOW_CODE/"*) echo "CODE"; return ;;
      "$LOW_CODER/process/"*|"$LOW_CODER/.claude/"*|"$LOW_CODER/claude.md") echo "PROTECTED"; return ;;
      *"vivaaerobus.generic.apillmcoder/process/"*|*"vivaaerobus.generic.apillmcoder/.claude/"*|*"vivaaerobus.generic.apillmcoder/claude.md") echo "PROTECTED"; return ;;
    esac
    case "$LOW_FILE" in
      *"vivaaerobus.generic.api/"*)
        case "$LOW_FILE" in
          *"vivaaerobus.generic.apillm"*) echo "OUTSIDE" ;;   # ApiLLM / ApiLLMCoder
          *) echo "CODE" ;;                                    # fail closed
        esac ;;
      *) echo "OUTSIDE" ;;
    esac
  fi
}

case "$(classify)" in
  OUTSIDE|"") exit 0 ;;
  HUMANGATE)
    gate_deny "⛔ FORBIDDEN: HUMAN-GATE-OK, PUSH-APPROVED and _PROCESS-CHANGE-OK are the human's signature. The agent never creates them — ask the user to run the touch command once they have reviewed the plan, the publication or the process change." ;;
  PROTECTED)
    [ -f "$WORK_DIR/_PROCESS-CHANGE-OK" ] && exit 0
    gate_deny "⛔ PROTECTED SURFACE: process/, CLAUDE.md and .claude/ define the team's mandatory process — they change only by team decision (CLAUDE.md §Conventions; Phase 11.9 retro). Ask the user to authorize the agreed change by running: touch work/_PROCESS-CHANGE-OK (and to delete that file when the change is done)." ;;
  CODE)
    RES="$(gate_task_key || echo "")"
    if [ -z "$RES" ]; then
      gate_deny "⛔ PIPELINE GATE: cannot resolve a task for this write — the code-repo branch has no Jira key and work/_active does not exist. Before touching the API repo: create work/<KEY>/, write the key into work/_active (or check out a type/KEY-123-desc branch) and complete phases 0-5 (process/). See CLAUDE.md §Enforcement."
    fi
    KEY="${RES%%$'\t'*}"; SRC="${RES#*$'\t'}"
    MISSING="$(gate_missing_analysis "$KEY")"
    if [ -n "$MISSING" ]; then
      gate_deny "$(gate_deny_message "$KEY" "$MISSING" "write code in the API repo") [task resolved from ${SRC}]"
    fi
    exit 0 ;;
esac
exit 0
