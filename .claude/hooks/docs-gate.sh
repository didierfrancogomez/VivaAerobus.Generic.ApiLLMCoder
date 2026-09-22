#!/usr/bin/env bash
# docs-gate.sh — Stop hook. The docs-sync gate that actually blocks.
#
# Why: docs-sync.sh (UserPromptSubmit) MEASURES the drift, but measuring is not
# syncing — and a hook cannot sync by itself: mapping a diff onto the right docs and
# writing them with citations needs a model. The only mechanism left is refusing to
# let the turn END until the anchor has moved. That is what the ApiLLM's own Stop
# gate does, and why it exists: on 2026-09-04 an analysis there ran on documents/**
# 104 commits behind — the advisory hook reported STALE, the model judged a
# 104-commit sync out of scope, said so, and answered anyway. Correct behaviour
# under an advisory gate, and exactly the outcome the gate had to prevent.
#
# The same applies here, by owner's decision (2026-09-22): a Coder session must not
# end a turn on stale knowledge either. The scope is deliberately the WHOLE session,
# not only ticket work — the sync is scoped to the repository, never to the question.
#
# THIN WRAPPER, not a copy: the ApiLLM's sync-gate.sh is location-independent and
# parameterised by env vars, so it is invoked where it lives. Its safety properties
# come along unchanged — it fails OPEN whenever the sync is impossible from here (no
# sync-state.md, no code repo, unresolvable anchor after a failed fetch), because a
# gate that fires when the work cannot be done is a lockout, not enforcement; it
# counts consecutive refusals and gives up after VIVA_SYNC_GATE_MAX (default 5),
# warning that the answer rests on stale docs; and VIVA_SYNC_GATE_OFF=1 disables it
# for one session (using it means saying so in the answer).
#
# This wrapper adds only what the ApiLLM's message cannot know: that the sync runs
# from HERE against the sibling checkout, with the doc-sync subagent, and that
# publishing it is not gated by the API repo's publication signature.
#
# One divergence from the wrapped script, by owner's decision (2026-09-22): when the
# ApiLLM checkout is ABSENT this hook BLOCKS instead of standing down. Upstream that
# case means "the sync cannot be run from here, so do not lock the session"; here it
# means the Coder has no knowledge base at all, and a Coder that answers without one
# is guessing. The refusal is bounded (VIVA_LLM_GATE_MAX, default 3) so the session
# degrades into a loud warning instead of a deadlock — the remedy (cloning the repo)
# is the user's, and they have to be told.
#
# Env: VIVA_DOCS_REPO / VIVA_CODE_REPO / VIVA_CODE_BRANCH (defaults: sibling layout)
#      VIVA_LLM_GATE_MAX  consecutive refusals when the ApiLLM is missing (default 3)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"
export VIVA_DOCS_REPO="${VIVA_DOCS_REPO:-$PARENT/VivaAerobus.Generic.ApiLLM}"
export VIVA_CODE_REPO="${VIVA_CODE_REPO:-$PARENT/VivaAerobus.Generic.Api}"
export VIVA_CODE_BRANCH="${VIVA_CODE_BRANCH:-master}"

GATE="$VIVA_DOCS_REPO/.claude/hooks/sync-gate.sh"

# Emits a Stop-hook refusal (the reason is handed back to the model).
block_json() {
  s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\r'/}
  s=${s//$'\t'/\\t}
  s=${s//$'\n'/\\n}
  printf '{"decision":"block","reason":"%s"}\n' "$s"
  exit 0
}

if [ ! -f "$GATE" ]; then
  cat >/dev/null 2>&1 || true   # consume hook stdin
  COUNTER="$ROOT/.git/viva-llm-missing-count"
  MAX="${VIVA_LLM_GATE_MAX:-3}"
  N=0; [ -f "$COUNTER" ] && N="$(cat "$COUNTER" 2>/dev/null || echo 0)"
  case "$N" in ''|*[!0-9]*) N=0 ;; esac
  N=$((N + 1)); printf '%s' "$N" > "$COUNTER" 2>/dev/null

  if [ "$MAX" -gt 0 ] && [ "$N" -gt "$MAX" ]; then
    rm -f "$COUNTER" 2>/dev/null
    echo "DOCS SYNC GATE — GAVE UP after $MAX attempts: there is still no ApiLLM at '$VIVA_DOCS_REPO'. THIS ANSWER HAS NO KNOWLEDGE BASE BEHIND IT. Say that to the user, plainly, and ask them to clone VivaAerobus.Generic.ApiLLM as a sibling folder (or set VIVA_DOCS_REPO)." >&2
    exit 0
  fi

  block_json "⛔ NO KNOWLEDGE BASE (attempt $N of $MAX). There is no ApiLLM at '$VIVA_DOCS_REPO' (expected its .claude/hooks/sync-gate.sh), so documents/** and guidelines/** — the only evidence this repo may cite and the only bar it may apply (CLAUDE.md rules 2 and 5) — are not reachable. A Coder session without them is guessing, and the evidence rule forbids guessing.

You may not end the turn by answering as if the pipeline were operational. Do this instead:
1. Check whether the checkout is simply elsewhere: if so, set VIVA_DOCS_REPO to it and say so.
2. Otherwise TELL THE USER, in one clear sentence, that the Coder cannot operate until VivaAerobus.Generic.ApiLLM is cloned as a sibling folder of this repo, and that every code write and every publication is denied meanwhile.
3. Do not start phases, do not plan, do not review, do not touch the API repo.

This refusal is bounded: after $MAX attempts the turn is let through with a warning, so say the above rather than retrying in silence."
fi

OUT="$(bash "$GATE")"

case "$OUT" in
  *'"decision":"block"'*) ;;
  *) [ -n "$OUT" ] && printf '%s\n' "$OUT"; exit 0 ;;
esac

# Blocked: append the Coder-specific part of the instruction. Without python3 the
# ApiLLM's reason is forwarded verbatim — still correct, just less precise.
if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$OUT" | python3 -c '
import json, sys, os
EXTRA = """

IN THIS REPO (Coder), concretely:
- The sync runs from here against {docs}. Delegate to the committed "doc-sync" subagent — it lives in that repo and is reachable from this session; it restates the evidence rule and writes only under documents/**. This repo never edits documents/** by hand (CLAUDE.md rule 2).
- Publishing it is NOT gated by the API repo publication signature (work/<KEY>/PUSH-APPROVED covers Phase 10 section 10.0 only). Commit and push the ApiLLM in the same run — its repo-guard.sh stashes uncommitted documents/** at the next session start, so an unpublished sync is a discarded one. Do not ask for permission.
- If a ticket is in flight, record the resulting anchor in work/<KEY>/phase-01-contrast.md as "DOCS-ANCHOR: <sha> FRESH" at column 0 (process/phase-01 section 1.0).
- Break-glass, owner only: VIVA_SYNC_GATE_OFF=1 for one session. Using it means saying so in the answer.""".format(docs=os.environ.get("VIVA_DOCS_REPO", "../VivaAerobus.Generic.ApiLLM"))
try:
    d = json.load(sys.stdin)
    d["reason"] = (d.get("reason") or "") + EXTRA
    print(json.dumps(d))
except Exception:
    sys.exit(1)
' && exit 0
fi

printf '%s\n' "$OUT"
exit 0
