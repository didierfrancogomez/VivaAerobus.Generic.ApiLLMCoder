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
# ApiLLM knowledge base is NOT USABLE this hook BLOCKS instead of standing down.
# Upstream that case means "the sync cannot be run from here, so do not lock the
# session"; here it means the Coder has no knowledge base at all, and a Coder that
# answers without one is guessing. The refusal is bounded (VIVA_LLM_GATE_MAX,
# default 3) so the session degrades into a loud warning instead of a deadlock — the
# remedy is the user's, and they have to be told.
#
# "Not usable" is DIAGNOSED, not assumed (lib-gate.sh :: llm_diagnose): folder
# absent, not a git checkout, the checked-out branch lacking a file origin/main has,
# or the wrong folder — each with its own remedy. Until 2026-09-22 a missing
# sync-gate.sh read as "there is no ApiLLM, clone it" while the checkout existed and
# was merely on a user branch cut before sync-gate.sh landed on main.
#
# That case — knowledge base present, only sync-gate.sh missing from the checked-out
# branch — is NOT a refusal: the gate runs origin/main's copy of sync-gate.sh (read
# with git, never checked out: the user's tree is not touched) against origin/main's
# documents/_meta/sync-state.md, i.e. the PUBLISHED docs — what llm-update.sh tells
# a session on a non-main checkout to read. Main's script against the branch's
# anchor would measure a state nobody reads. Both files are materialised in a shadow
# folder under this repo's .git/ (whose own .git/ holds the upstream refusal
# counter), and paths in the verdict are mapped back to the real checkout. A refusal
# in that mode leads with a note overriding the upstream "pull main" step: the sync
# must not run on — or merge into — the user's branch. Only when origin/main has no
# sync-gate.sh either does the hook refuse (bounded, as above).
#
# Env: VIVA_DOCS_REPO / VIVA_CODE_REPO / VIVA_CODE_BRANCH (defaults: sibling layout)
#      VIVA_LLM_GATE_MAX  consecutive refusals while the ApiLLM is unusable (default 3)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"
export VIVA_DOCS_REPO="${VIVA_DOCS_REPO:-$PARENT/VivaAerobus.Generic.ApiLLM}"
export VIVA_CODE_REPO="${VIVA_CODE_REPO:-$PARENT/VivaAerobus.Generic.Api}"
export VIVA_CODE_BRANCH="${VIVA_CODE_BRANCH:-master}"

. "$ROOT/.claude/hooks/lib-gate.sh"   # llm_diagnose, llm_main_has

GATE="$VIVA_DOCS_REPO/.claude/hooks/sync-gate.sh"
COUNTER="$ROOT/.git/viva-llm-missing-count"

json_esc() {
  s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\r'/}
  s=${s//$'\t'/\\t}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

# Emits a Stop-hook refusal (the reason is handed back to the model).
block_json() {
  printf '{"decision":"block","reason":"%s"}\n' "$(json_esc "$1")"
  exit 0
}

# Bounded refusal while the ApiLLM is unusable: refuse_unusable <diagnosis> <headline>
refuse_unusable() {
  cat >/dev/null 2>&1 || true   # consume hook stdin
  MAX="${VIVA_LLM_GATE_MAX:-3}"
  N=0; [ -f "$COUNTER" ] && N="$(cat "$COUNTER" 2>/dev/null || echo 0)"
  case "$N" in ''|*[!0-9]*) N=0 ;; esac
  N=$((N + 1)); printf '%s' "$N" > "$COUNTER" 2>/dev/null

  if [ "$MAX" -gt 0 ] && [ "$N" -gt "$MAX" ]; then
    rm -f "$COUNTER" 2>/dev/null
    echo "DOCS SYNC GATE — GAVE UP after $MAX attempts. $2: $1. Say that to the user, plainly, with that remedy." >&2
    exit 0
  fi

  block_json "⛔ $2 (attempt $N of $MAX): $1.

documents/** and guidelines/** are the only evidence this repo may cite and the only bar it may apply (CLAUDE.md rules 2 and 5), and the sync gate that keeps them current is part of that contract. You may not end the turn by answering as if the pipeline were operational. Do this instead:
1. If the checkout simply lives elsewhere, set VIVA_DOCS_REPO to it and say so.
2. Otherwise TELL THE USER, in one clear sentence, what is wrong and the remedy above — that remedy exactly, not a generic 'clone the repo' — and that every code write and every publication is denied while the knowledge base is unusable.
3. Do not start phases, do not plan, do not review, do not touch the API repo, and do not repair the ApiLLM checkout yourself: it is the user's tree.

This refusal is bounded: after $MAX attempts the turn is let through with a warning, so say the above rather than retrying in silence."
}

DIAG="$(llm_diagnose "$VIVA_DOCS_REPO")"
[ -n "$DIAG" ] && refuse_unusable "$DIAG" "KNOWLEDGE BASE UNUSABLE"

FALLBACK=0
if [ ! -f "$GATE" ]; then
  # Knowledge base present; sync-gate.sh missing from the checked-out branch.
  llm_main_has "$VIVA_DOCS_REPO" .claude/hooks/sync-gate.sh || \
    refuse_unusable "$(llm_diagnose "$VIVA_DOCS_REPO" .claude/hooks/sync-gate.sh)" "SYNC GATE UNAVAILABLE (the knowledge base is present, the gate that keeps it current is not)"

  # Case (c): the published gate against the published anchor. Blob ids come from
  # ls-tree, never from "ref:path" (Git Bash's path conversion mangles it).
  blob_of() { git -C "$VIVA_DOCS_REPO" ls-tree origin/main "$1" 2>/dev/null | awk '{print $3}'; }
  SHADOW_BASE="$ROOT/.git"; [ -d "$SHADOW_BASE" ] || SHADOW_BASE="${TMPDIR:-/tmp}"
  SHADOW="$SHADOW_BASE/viva-llm-published"
  mkdir -p "$SHADOW/.git" "$SHADOW/.claude/hooks" "$SHADOW/documents/_meta" 2>/dev/null
  if ! git -C "$VIVA_DOCS_REPO" cat-file blob "$(blob_of .claude/hooks/sync-gate.sh)" \
         > "$SHADOW/.claude/hooks/sync-gate.sh" 2>/dev/null; then
    refuse_unusable "origin/main's .claude/hooks/sync-gate.sh could not be read from '$VIVA_DOCS_REPO', and its checked-out branch has none. Remedy — the user's tree, so the user's call: switch it to main (git -C '$VIVA_DOCS_REPO' switch main) or merge origin/main into it" "SYNC GATE UNAVAILABLE"
  fi
  SS_BLOB="$(blob_of documents/_meta/sync-state.md)"
  if [ -n "$SS_BLOB" ]; then
    git -C "$VIVA_DOCS_REPO" cat-file blob "$SS_BLOB" > "$SHADOW/documents/_meta/sync-state.md" 2>/dev/null
  else
    rm -f "$SHADOW/documents/_meta/sync-state.md"   # upstream then stands down, as it would on main
  fi
  FALLBACK=1
fi

rm -f "$COUNTER" 2>/dev/null   # usable: a later outage starts again at attempt 1

if [ "$FALLBACK" = "0" ]; then
  OUT="$(bash "$GATE")"
else
  BR="$(git -C "$VIVA_DOCS_REPO" branch --show-current 2>/dev/null)"; BR="${BR:-detached HEAD}"
  OUT="$(VIVA_DOCS_REPO="$SHADOW" bash "$SHADOW/.claude/hooks/sync-gate.sh" 2>"$SHADOW/last-stderr")"
  {
    [ -s "$SHADOW/last-stderr" ] && sed "s#$SHADOW#$VIVA_DOCS_REPO#g" "$SHADOW/last-stderr"
    echo "DOCS SYNC GATE — ran origin/main's sync-gate.sh against origin/main's sync-state.md: the ApiLLM checkout is on '$BR', which has no .claude/hooks/sync-gate.sh."
  } >&2
  OUT="${OUT//"$SHADOW"/"$VIVA_DOCS_REPO"}"
  # Prepend by splitting on upstream block()'s literal prefix — not ${OUT/pat/rep},
  # whose replacement bash 5.2 (patsub_replacement) re-parses, eating the \n escapes.
  PRE='{"decision":"block","reason":"'
  case "$OUT" in
    "$PRE"*)
      NOTE="READ FIRST — the ApiLLM checkout at '$VIVA_DOCS_REPO' is on the user's branch '$BR', which has no .claude/hooks/sync-gate.sh. This verdict comes from origin/main's copy of the gate, measured against origin/main's documents/_meta/sync-state.md (the published docs). The sync must happen on main, NOT on '$BR': do not pull or merge main into it, do not commit to it, do not switch it yourself — that tree is the user's. This OVERRIDES step 1 below and every 'publish without asking' instruction. Tell the user the docs are stale and ask them to switch the checkout to main (git -C '$VIVA_DOCS_REPO' switch main) or merge origin/main into '$BR'; the sync then runs as described.

"
      OUT="$PRE$(json_esc "$NOTE")${OUT#"$PRE"}"
      ;;
  esac
fi

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
    # Bytes, decoded as UTF-8: on Windows sys.stdin uses the locale code page
    # (cp1252), which turns every em dash in the reason into mojibake.
    d = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    d["reason"] = (d.get("reason") or "") + EXTRA
    print(json.dumps(d))
except Exception:
    sys.exit(1)
' && exit 0
fi

printf '%s\n' "$OUT"
exit 0
