#!/usr/bin/env bash
# self-update.sh — SessionStart + UserPromptSubmit hook (runs BEFORE pipeline-state.sh).
#
# Before attending ANY user request, bring THIS repo (the Coder) up to origin/main's
# latest commit, so no session reasons from stale process files, gates or work/
# progress saved from another machine/session.
#
# Safety contract:
#   - fetch is read-only, hard-bounded (8s) and never prompts for credentials;
#   - the update is FAST-FORWARD ONLY: local commits or conflicting uncommitted
#     changes make it degrade to a warning — it never rewrites or discards work;
#   - it never blocks the session: every path exits 0 with a note.
# Plain-stdout output (same style as pipeline-state.sh) — injected as context.
# Must stay bash-3.2 compatible.

set -uo pipefail
cat >/dev/null 2>&1 || true   # consume hook stdin; not needed

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

BR="$(git branch --show-current 2>/dev/null || true)"
if [ "$BR" != "main" ]; then
  echo "CODER SELF-UPDATE — ⛔ GOLDEN RULE: this checkout is on '${BR:-detached HEAD}', but the Coder works ONLY on main (the default branch). Do NOT attend the user's request from this state — tell them and switch back to an up-to-date main first."
  exit 0
fi

TO=""
command -v timeout  >/dev/null 2>&1 && TO="timeout 8"
command -v gtimeout >/dev/null 2>&1 && TO="gtimeout 8"

if ! GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS=true \
     $TO git fetch --quiet --no-tags origin main 2>/dev/null; then
  echo "CODER SELF-UPDATE — ⛔ GOLDEN RULE: fetch failed or timed out (offline?), so it CANNOT be verified that this repo is current with origin/main — and working on a possibly-stale main is forbidden. Do NOT attend the user's request yet: tell them, and proceed only if they explicitly accept working from the local copy at $(git rev-parse --short HEAD 2>/dev/null)."
  exit 0
fi

BEHIND="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
AHEAD="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"

if [ "$BEHIND" = "0" ]; then
  NOTE=""
  [ "$AHEAD" != "0" ] && NOTE=" ($AHEAD local commit(s) not pushed yet — save-progress pushes them)"
  echo "CODER SELF-UPDATE — OK: already at origin/main ($(git rev-parse --short HEAD))$NOTE."
  exit 0
fi

if git merge --ff-only --quiet origin/main 2>/dev/null; then
  echo "CODER SELF-UPDATE — pulled $BEHIND commit(s) from origin/main: now at $(git rev-parse --short HEAD). If you had process/ or work/ files loaded in context, RE-READ them before acting — they may have changed."
else
  echo "CODER SELF-UPDATE — ⛔ GOLDEN RULE: $BEHIND commit(s) behind origin/main and a fast-forward is not possible ($AHEAD local commit(s) ahead, or uncommitted changes conflict). Nothing was touched — but working on a stale main is forbidden. Do NOT attend the user's request yet: surface this, reconcile (git pull / push the local commits), and only then proceed."
fi
exit 0
