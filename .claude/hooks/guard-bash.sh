#!/usr/bin/env bash
# guard-bash.sh — PreToolUse hook (Bash).
#
# Closes the side door: code-repo mutations executed through the shell instead
# of the file tools, and publication (git push / gh pr create) before the
# pre-review gate.
#
# Policy on commands that reference the code repo (VivaAerobus.Generic.Api,
# matched exactly — never its ...LLM / ...LLMCoder siblings):
#   - mutation patterns (redirects into the repo, sed -i, tee, rm/mv/cp,
#     touch/mkdir, patch, git commit/apply/restore/checkout -b/switch -c/
#     merge/rebase/cherry-pick, dotnet new/add) → require the analysis gate
#     (phases 0-5 + VERDICT ✅).
#   - publication (git push, gh pr create/merge) → additionally require
#     phase-09-pre-review.md with "REVIEW-CODE: APPROVED".
#   - read-only (git log/diff/status, grep, ls, cat, dotnet build/test) → pass.
# Everything not referencing the code repo passes through, except creating
# HUMAN-GATE-OK (the human's signature — always denied to the agent).
#
# Known limit (documented, accepted — same stance as ApiLLM protect-paths.sh):
# pattern-matching a shell command is a guard, not a sandbox. Exotic quoting
# can evade it; the PR review and repo permissions are the outer layers.

set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HOOK_DIR/lib-gate.sh"

INPUT="$(cat 2>/dev/null)" || INPUT=""

CMD="$(printf '%s' "$INPUT" | python3 -c '
import json,sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except Exception:
    print("")' 2>/dev/null)"
[ -n "$CMD" ] || exit 0

# The agent must never sign the human gate, wherever the file lives.
if printf '%s' "$CMD" | grep -Eq 'HUMAN-GATE-OK'; then
  gate_deny "⛔ FORBIDDEN: HUMAN-GATE-OK is the human's signature. The agent never creates or touches it — ask the user to run: touch work/<KEY>/HUMAN-GATE-OK."
fi

# Does the command reference the CODE repo (and not only the LLM/Coder repos)?
# "VivaAerobus.Generic.Api" not followed by "L" — excludes ApiLLM/ApiLLMCoder.
CODE_RE='vivaaerobus\.generic\.api($|[^l])'
printf '%s' "$CMD" | grep -Eiq "$CODE_RE" || exit 0

MUTATES=0
PUBLISHES=0
if printf '%s' "$CMD" | grep -Eq '(^|[;&| ])(git)[^;&|]*(push)|gh[^;&|]*pr[^;&|]*(create|merge)'; then
  PUBLISHES=1
fi
# File-level mutations gate only when the code-repo path appears in the same
# sub-command (so "git -C <code> diff > scratch.txt" stays allowed).
if printf '%s' "$CMD" | grep -Eiq ">>?[^;&|<]*$CODE_RE" || \
   printf '%s' "$CMD" | grep -Eiq "(^|[;&| ])(sed +-i[^;&|]*|tee +[^;&|]*|rm +[^;&|]*|mv +[^;&|]*|cp +[^;&|]*|touch +[^;&|]*|mkdir +[^;&|]*|patch +[^;&|]*|ln +[^;&|]*)$CODE_RE" || \
   printf '%s' "$CMD" | grep -Eq '(^|[;&| ])git[^;&|]*(commit|apply|restore|revert|merge|rebase|cherry-pick|stash +pop|checkout +-b|switch +-c)|(^|[;&| ])dotnet +(new|add|remove)'; then
  MUTATES=1
fi
[ "$MUTATES" = "1" ] || [ "$PUBLISHES" = "1" ] || exit 0

RES="$(gate_task_key || echo "")"
if [ -z "$RES" ]; then
  gate_deny "⛔ PIPELINE GATE: this command mutates the API repo and no task can be resolved (no Jira key in the code-repo branch, no work/_active). Complete phases 0-5 first (process/). See CLAUDE.md §Enforcement."
fi
KEY="${RES%%$'\t'*}"; SRC="${RES#*$'\t'}"

MISSING="$(gate_missing_analysis "$KEY")"
if [ -n "$MISSING" ]; then
  gate_deny "$(gate_deny_message "$KEY" "$MISSING" "mutate the API repo via Bash") [task resolved from ${SRC}]"
fi

if [ "$PUBLISHES" = "1" ]; then
  PRE="$(gate_missing_prereview "$KEY")"
  if [ -n "$PRE" ]; then
    gate_deny "⛔ PRE-REVIEW GATE (Phase 9): cannot publish (push / PR) — missing: $PRE. Run the ApiLLM's local validator llm/REVIEW-CODE.md on the diff; only with APPROVED do you record 'REVIEW-CODE: APPROVED' in work/$KEY/phase-09-pre-review.md, which enables publication."
  fi
fi
exit 0
