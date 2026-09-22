#!/usr/bin/env bash
# docs-sync.sh — UserPromptSubmit hook (runs AFTER llm-update.sh).
#
# Why: phase 1 orders "sync first" (process/phase-01-code-contrast.md), but an
# instruction can be skipped by a model — that is exactly why the ApiLLM stopped
# relying on one and added a hook that MEASURES the drift before the model sees the
# prompt (ApiLLM .claude/hooks/sync-check.sh, header). A Coder session was getting
# none of that signal while planning and reviewing against documents/**.
#
# This is a THIN WRAPPER, not a copy: sync-check.sh is location-independent and
# parameterised by env vars, so it is invoked where it lives. The measurement logic
# has ONE home (the ApiLLM, which owns the knowledge) and improvements there reach
# the Coder for free. The Coder only supplies the paths and fails loud when its
# documentary source is missing.
#
# It never blocks the session (the ApiLLM's `Stop` gate is deliberately NOT adopted
# here: it would block turns that have nothing to do with a ticket). What blocks in
# this repo is the PHASE, not the answer — phase 1 does not close without the
# "DOCS-ANCHOR:" marker (lib-gate.sh).
#
# Env:
#   VIVA_DOCS_REPO / VIVA_CODE_REPO / VIVA_CODE_BRANCH — forwarded to sync-check.sh
#   (defaults: the sibling layout declared in CLAUDE.md §Repository layout)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"
export VIVA_DOCS_REPO="${VIVA_DOCS_REPO:-$PARENT/VivaAerobus.Generic.ApiLLM}"
export VIVA_CODE_REPO="${VIVA_CODE_REPO:-$PARENT/VivaAerobus.Generic.Api}"
export VIVA_CODE_BRANCH="${VIVA_CODE_BRANCH:-master}"

CHECK="$VIVA_DOCS_REPO/.claude/hooks/sync-check.sh"

if [ ! -f "$CHECK" ]; then
  cat >/dev/null 2>&1 || true   # consume hook stdin
  echo "DOCS SYNC — ⛔ cannot measure: '$CHECK' not found. The Coder has no knowledge of its own (CLAUDE.md rule 2): documents/** and guidelines/** live in the ApiLLM and the drift is measured by ITS hook. Do NOT treat documents/** as current: check out VivaAerobus.Generic.ApiLLM as a sibling folder (or set VIVA_DOCS_REPO), and until then reason from the code and say so in the phase artifact."
  exit 0
fi

# sync-check.sh consumes stdin itself and emits its own UserPromptSubmit payload.
OUT="$(bash "$CHECK")"

# Its report ends with the ApiLLM's own enforcement clause ("the Stop hook will
# refuse to let you end this turn"), which is FALSE here: that hook belongs to the
# ApiLLM's settings.json and does not run in a Coder session. Injecting an
# enforcement promise that nothing backs is worse than injecting none, so the
# paragraph is replaced with what actually binds in this repo. Everything else is
# passed through untouched. Without python3 the report is forwarded verbatim.
if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$OUT" | python3 -c '
import json, re, sys
CODER = ("ENFORCED HERE (Coder): this repo does NOT run the ApiLLM\u0027s Stop gate — what blocks is the "
         "PHASE, not the answer. Phase 1 does not close without a line at column 0 "
         "\"DOCS-ANCHOR: <sha> FRESH\" or \"DOCS-ANCHOR: <sha> STALE <n> commits — <how it was handled>\" "
         "in work/<KEY>/phase-01-contrast.md (CLAUDE.md, Work artifacts). And this repo NEVER writes "
         "documents/** itself: the sync runs through the ApiLLM doc-sync pipeline and is published from "
         "that repo (rule 2).")
try:
    d = json.load(sys.stdin)
    hso = d.get("hookSpecificOutput") or {}
    ctx = hso.get("additionalContext") or ""
    new, n = re.subn(r"ENFORCED:.*?(?=\n\n|\Z)", CODER, ctx, count=1, flags=re.S)
    if n == 0:
        new = ctx.rstrip() + "\n\n" + CODER
    hso["additionalContext"] = new
    d["hookSpecificOutput"] = hso
    print(json.dumps(d))
except Exception:
    sys.exit(1)
' && exit 0
fi

printf '%s\n' "$OUT"
exit 0
