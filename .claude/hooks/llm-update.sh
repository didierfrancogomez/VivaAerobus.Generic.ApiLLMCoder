#!/usr/bin/env bash
# llm-update.sh — SessionStart + UserPromptSubmit hook (runs AFTER self-update.sh,
# BEFORE docs-sync.sh).
#
# Why: the Coder holds NO knowledge of its own. `documents/**` (what the system is)
# and `guidelines/**` (how code MUST be written — golden rule 5) live in the ApiLLM
# repo, so a stale ApiLLM checkout means planning and reviewing against outdated
# facts and outdated normative rules. Golden rule 4 ("never work on a stale main")
# is therefore not satisfied by updating THIS repo alone.
#
# The ApiLLM is a HARD DEPENDENCY, not an optional companion: if it cannot be found
# or cannot be verified, the request is not attended (the user may still choose to
# proceed explicitly). Never a silent degradation.
#
# Safety contract (identical to self-update.sh):
#   - fetch is read-only and never prompts for credentials; it is bounded by
#     timeout/gtimeout when present (macOS ships neither by default) and, in every
#     case, by this hook's timeout in .claude/settings.json;
#   - the update is FAST-FORWARD ONLY: local commits or conflicting uncommitted
#     changes degrade to a warning — it never rewrites or discards the user's work
#     (that repo has its own guard: ApiLLM/.claude/hooks/repo-guard.sh);
#   - it never blocks the session: every path exits 0 with a note.
# Plain-stdout output (same style as pipeline-state.sh) — injected as context.
# Must stay bash-3.2 compatible.
#
# Env:
#   VIVA_DOCS_REPO        path to VivaAerobus.Generic.ApiLLM (default: sibling folder)
#   VIVA_LLM_UPDATE_OFF=1 break-glass, owner only: skip the check for one session.
#                         Using it means saying so in the answer (same stance as the
#                         ApiLLM's VIVA_SYNC_GATE_OFF).

set -uo pipefail
cat >/dev/null 2>&1 || true   # consume hook stdin; not needed

if [ "${VIVA_LLM_UPDATE_OFF:-0}" = "1" ]; then
  echo "LLM SELF-UPDATE — ⚠️ SKIPPED by VIVA_LLM_UPDATE_OFF=1 (break-glass). The freshness of documents/** and guidelines/** is UNVERIFIED for this session — say so in the answer and in any phase artifact."
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LLM="${VIVA_DOCS_REPO:-$ROOT/../VivaAerobus.Generic.ApiLLM}"
. "$ROOT/.claude/hooks/lib-gate.sh"   # llm_diagnose

# Only cases (a) absent / (b) not a git checkout here — requiring just ".git" makes
# llm_diagnose stop there. Missing CONTENT is judged after the fetch, below, when
# origin/main is current enough to tell "wrong folder" from "user branch".
DIAG="$(llm_diagnose "$LLM" .git)"
if [ -n "$DIAG" ]; then
  echo "LLM SELF-UPDATE — ⛔ HARD DEPENDENCY MISSING: $DIAG. The Coder has no knowledge of its own — documents/** and guidelines/** live there (CLAUDE.md rules 2 and 5), so the pipeline CANNOT run. Do NOT attend the user's request: tell them that, with the remedy."
  exit 0
fi
LLM="$(cd "$LLM" && pwd)"

BR="$(git -C "$LLM" branch --show-current 2>/dev/null || true)"
SHORT="$(git -C "$LLM" rev-parse --short HEAD 2>/dev/null || echo '?')"

TO=""
command -v timeout  >/dev/null 2>&1 && TO="timeout 8"
command -v gtimeout >/dev/null 2>&1 && TO="gtimeout 8"

FETCH_ERR="$(GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS=true \
     $TO git -C "$LLM" fetch --quiet --no-tags origin main 2>&1)"
if [ "$?" != "0" ]; then
  URL="$(git -C "$LLM" remote get-url origin 2>/dev/null || echo 'origin')"
  case "$FETCH_ERR" in
    *"Repository not found"*|*"not found"*|*"does not exist"*)
      echo "LLM SELF-UPDATE — ⛔ the ApiLLM remote is UNREACHABLE ('$URL' → repository not found). Two causes look identical to git: the repo no longer exists, or the ACTIVE git/gh credential has no access to it (a private repo under another account reads as 'not found' — check with: gh auth status). Either way the local checkout at ${SHORT} cannot be verified, and the sync's publication step (ApiLLM llm/SYNC.md §4, which is what stops the next run from redoing the work) cannot run. Do NOT attend the user's request yet: surface this, and proceed only if they explicitly accept working from the unverifiable local copy." ;;
    *"Authentication"*|*"Permission denied"*|*"could not read Username"*|*"403"*)
      echo "LLM SELF-UPDATE — ⛔ cannot reach the ApiLLM remote ('$URL'): authentication failed. documents/** and guidelines/** cannot be verified against origin/main. Do NOT attend the user's request yet: tell the user to fix the credentials (gh auth status), or have them explicitly accept working from the local copy at ${SHORT}." ;;
    *)
      echo "LLM SELF-UPDATE — ⛔ cannot verify the ApiLLM is current (fetch failed or timed out — offline?). documents/** and guidelines/** may be stale and there is no way to measure it. Do NOT attend the user's request yet: tell them, and proceed only if they explicitly accept working from the local copy at ${SHORT}." ;;
  esac
  exit 0
fi

if [ "$BR" != "main" ]; then
  # A user branch cut before a hook landed on main lacks it; say which, so the
  # wrappers' fallback / refusal downstream is not mistaken for a missing repo.
  LACK=""
  for P in documents/_meta/sync-state.md guidelines .claude/hooks/sync-check.sh .claude/hooks/sync-gate.sh; do
    [ -e "$LLM/$P" ] || LACK="$LACK $P"
  done
  BEHIND_MAIN="$(git -C "$LLM" rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
  NOTE=""
  [ -n "$LACK" ] && NOTE=" This branch is $BEHIND_MAIN commit(s) behind origin/main and lacks:$LACK — the checkout EXISTS (do not tell the user to clone it); the remedy, theirs to take, is to switch it to main or merge origin/main."
  echo "LLM SELF-UPDATE — ⚠️ the ApiLLM checkout is on '${BR:-detached HEAD}', not main: it is the user's tree and was NOT touched.$NOTE Do not read documents/** or guidelines/** from the working tree — read the published state instead (git -C '$LLM' show origin/main:<path>; in Git Bash prefix MSYS_NO_PATHCONV=1, or the ref:path argument is mangled) and say so in the phase artifact."
  exit 0
fi

BEHIND="$(git -C "$LLM" rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
AHEAD="$(git -C "$LLM" rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"

if [ "$BEHIND" = "0" ]; then
  NOTE=""
  [ "$AHEAD" != "0" ] && NOTE=" ($AHEAD local commit(s) not pushed — publish them from an ApiLLM session)"
  echo "LLM SELF-UPDATE — OK: ApiLLM already at origin/main (${SHORT})${NOTE}."
  exit 0
fi

if git -C "$LLM" merge --ff-only --quiet origin/main 2>/dev/null; then
  echo "LLM SELF-UPDATE — pulled $BEHIND commit(s) into the ApiLLM: now at $(git -C "$LLM" rev-parse --short HEAD). If documents/** or guidelines/** were loaded in context, RE-READ them before acting."
else
  echo "LLM SELF-UPDATE — ⛔ the ApiLLM is $BEHIND commit(s) behind origin/main and a fast-forward is not possible ($AHEAD local commit(s) ahead, or uncommitted changes conflict). Nothing was touched, but documents/** and guidelines/** are NOT current. Do NOT attend the user's request yet: surface this and reconcile it from an ApiLLM session (its repo-guard.sh does it at session start), or read the published state with git show origin/main:<path>."
fi
exit 0
