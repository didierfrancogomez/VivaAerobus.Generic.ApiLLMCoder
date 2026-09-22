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
# Artifact contract (fixed names, defined in ../CLAUDE.md). Every marker line
# is matched ANCHORED at column 0 — a quoted template or an indented copy does
# not open a gate:
#   work/_active                        ← key of the task in progress (one line)
#   work/<KEY>/phase-00-intake.md
#   work/<KEY>/phase-01-contrast.md   ← must contain "DOCS-ANCHOR: <sha> FRESH" or
#                                       "DOCS-ANCHOR: <sha> STALE <n> commits — <how
#                                       it was handled>": the ApiLLM anchor the whole
#                                       analysis was built on (the Coder holds no
#                                       knowledge of its own — CLAUDE.md rule 2)
#   work/<KEY>/phase-02-impact-matrix.md
#   work/<KEY>/phase-03-feasibility.md
#   work/<KEY>/phase-04-verdict.md      ← exactly ONE line "VERDICT: ..." — "VERDICT: ✅" opens the gate
#   work/<KEY>/phase-05-plan.md         ← required before any code write
#   work/<KEY>/phase-06-code-style.md   ← written ONLY by tools/code-style.sh verify: must
#                                         contain "CODE-STYLE: VERIFIED" (the Ezy cleanup
#                                         leaves zero deltas on the task's lines) and
#                                         "STYLE-SHA: <commit>" before push/PR; push is
#                                         denied if HEAD drifted from the styled commit
#   work/<KEY>/phase-07-testing.md      ← must contain "TESTS: GREEN" before push/PR
#   work/<KEY>/phase-09-pre-review.md   ← must contain "REVIEW-CODE: APPROVED",
#                                         "VALIDATED-SHA: <commit>", "COMPLETENESS: VERIFIED"
#                                         and "DEVIATIONS: NONE|APPROVED-AND-DOCUMENTED"
#                                         before push/PR; push is denied if HEAD drifted
#                                         from the validated commit
#   work/<KEY>/PUSH-APPROVED            ← the USER's explicit approval to publish
#                                         (push + PR) — a human creates it by hand
#   work/<KEY>/HUMAN-GATE-REQUIRED      ← optional (risky level): if present,
#   work/<KEY>/HUMAN-GATE-OK              a HUMAN must create this file by hand
#   work/_PROCESS-CHANGE-OK             ← human-created: unlocks edits to the process
#                                         surface (process/, CLAUDE.md, .claude/)
#
# Hard prerequisite, checked before any of the above: the ApiLLM checkout must be
# present (gate_llm_missing). Without it every code write and every publication is
# denied — see gate_llm_deny_message.
#
# Must stay bash-3.2 compatible (macOS default bash).

GATE_HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODER_ROOT="$(cd "$GATE_HOOK_DIR/../.." && pwd)"
# CODER_GATE_WORK_DIR overrides the work dir (used by the hook test suite).
WORK_DIR="${CODER_GATE_WORK_DIR:-$CODER_ROOT/work}"

# The code repo is a sibling folder. Note: its name is a prefix of this repo's
# name and of the ApiLLM repo's name — match it exactly, never by substring.
# CODER_GATE_CODE_REPO overrides the default sibling layout (also used by the
# hook test suite).
CODE_REPO="${CODER_GATE_CODE_REPO:-$(cd "$CODER_ROOT/.." 2>/dev/null && pwd)/VivaAerobus.Generic.Api}"

# The ApiLLM checkout: this repo's ONLY knowledge (documents/**) and its ONLY
# normative bar (guidelines/**). Without it the Coder cannot analyse, plan or review
# — it can only guess, which is the one thing the evidence rule forbids. So its
# absence is not a warning, it is a stop (owner's decision, 2026-09-22).
# CODER_GATE_LLM_REPO / VIVA_DOCS_REPO override the sibling layout (and the tests).
LLM_REPO="${CODER_GATE_LLM_REPO:-${VIVA_DOCS_REPO:-$(cd "$CODER_ROOT/.." 2>/dev/null && pwd)/VivaAerobus.Generic.ApiLLM}}"

# Does <repo>'s origin/main carry <path>? ls-tree takes the ref and the path as
# separate arguments on purpose: a "ref:path" argument is rewritten by Git Bash's
# MSYS path conversion (origin/main:a/b → origin\main;a\b) and silently fails.
llm_main_has() { # llm_main_has <repo> <path>
  [ -n "$(git -C "$1" ls-tree origin/main "$2" 2>/dev/null)" ]
}

# Diagnoses an ApiLLM path. Empty output = usable. Otherwise ONE sentence naming
# what is wrong AND its remedy. The remedies differ, and "clone it" handed to a
# user whose checkout exists — on a branch that lacks a file — sends them to fix
# the wrong thing (2026-09-22). Cases, in order:
#   (a) folder absent             → clone it / set VIVA_DOCS_REPO
#   (b) not a git checkout        → freshness unverifiable: replace it with a clone
#   (c) <path> missing on the checked-out branch, present on origin/main
#                                 → switch to main or merge origin/main (user's tree)
#   (d) <path> missing everywhere → wrong folder: point VIVA_DOCS_REPO at the ApiLLM
# Args after <repo>: the paths that must exist (default: the knowledge base).
# `.git` is tested with -e, not -d: in a linked worktree it is a file.
llm_diagnose() { # llm_diagnose <repo> [required-path...]
  R="$1"; shift
  [ "$#" -gt 0 ] || set -- documents/_meta/sync-state.md guidelines
  if [ ! -d "$R" ]; then
    echo "there is no folder at '$R'. Remedy: clone VivaAerobus.Generic.ApiLLM there, as a sibling folder of this repo, or set VIVA_DOCS_REPO to the real checkout"
    return
  fi
  if [ ! -e "$R/.git" ]; then
    echo "'$R' exists but is not a git checkout, so its freshness against origin/main cannot be verified (golden rule 4). Remedy: replace it with a git clone of VivaAerobus.Generic.ApiLLM, or set VIVA_DOCS_REPO to the real checkout"
    return
  fi
  for P in "$@"; do
    [ -e "$R/$P" ] && continue
    if llm_main_has "$R" "$P"; then
      BR="$(git -C "$R" branch --show-current 2>/dev/null)"
      echo "the ApiLLM checkout at '$R' exists, but its checked-out branch '${BR:-detached HEAD}' has no $P (origin/main does). Remedy — the user's tree, so the user's call: switch it to main (git -C '$R' switch main) or merge origin/main into it. Do NOT clone it again"
    else
      echo "'$R' is a git checkout but has no $P, neither on its branch nor on origin/main — it is not the ApiLLM (or origin/main was never fetched). Remedy: set VIVA_DOCS_REPO to the real VivaAerobus.Generic.ApiLLM checkout, or fetch it"
    fi
    return
  done
}

# Empty output = the ApiLLM is usable. Otherwise, the reason it is not + remedy.
gate_llm_missing() {
  llm_diagnose "$LLM_REPO"
}

gate_llm_deny_message() {
  printf '⛔ KNOWLEDGE BASE UNUSABLE: %s. The Coder documents nothing itself (CLAUDE.md rule 2) and invents no standard of its own (rule 5): documents/** and guidelines/** are the only evidence it may cite and the only bar it may apply, so without them it cannot analyse, plan, implement or review — only guess, which the evidence rule forbids. This is not a warning to work around. Tell the user exactly that remedy, and stop.' "$1"
}

gate_active_key() {
  [ -f "$WORK_DIR/_active" ] || return 1
  head -1 "$WORK_DIR/_active" | tr -d '[:space:]'
}

# Resolves WHICH task a code-repo mutation belongs to. The branch checked out
# in the code repo is authoritative: branch names follow
# type/KEY-123-short-desc (phase-06 §6.1), so the Jira key in the branch binds
# the working branch to its plan — that is what makes several plans safe in
# parallel (each plan on its own branch, each branch gated by its own
# work/<KEY>/ artifacts). Fallback: work/_active (no branch checked out yet,
# detached HEAD, or a branch without a parseable key — e.g. master).
# Prints "KEY<TAB>source"; source is "branch:<name>" or "_active".
gate_task_key() {
  BR="$(git -C "$CODE_REPO" branch --show-current 2>/dev/null || true)"
  if [ -n "$BR" ]; then
    K="$(printf '%s' "$BR" | grep -oE '[A-Za-z][A-Za-z0-9]*-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]')"
    if [ -n "$K" ]; then
      printf '%s\tbranch:%s\n' "$K" "$BR"
      return 0
    fi
  fi
  K="$(gate_active_key)" || return 1
  [ -n "$K" ] || return 1
  printf '%s\t_active\n' "$K"
}

# Prints the missing analysis artifacts (phases 0-5) for a task key, one per
# line. Empty output = analysis gate satisfied.
gate_missing_analysis() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  [ -f "$DIR/phase-00-intake.md" ]        || echo "work/$KEY/phase-00-intake.md (Phase 0)"
  if [ ! -f "$DIR/phase-01-contrast.md" ]; then
    echo "work/$KEY/phase-01-contrast.md (Phase 1)"
  elif ! grep -Eq '^DOCS-ANCHOR: [0-9a-fA-F]{7,40} (FRESH|STALE)' "$DIR/phase-01-contrast.md" 2>/dev/null; then
    # The docs-sync status is measured on every prompt (docs-sync.sh) but seeing it
    # is not recording it: phase 1 states WHICH anchor the analysis stands on, so a
    # later reader can tell an evidence-backed claim from one made on stale docs.
    echo "work/$KEY/phase-01-contrast.md missing the 'DOCS-ANCHOR: <sha> FRESH' (or 'DOCS-ANCHOR: <sha> STALE <n> commits — <how it was handled>') line at column 0 (Phase 1 — the ApiLLM anchor the analysis was built on: grep last_documented_commit ../VivaAerobus.Generic.ApiLLM/documents/_meta/sync-state.md)"
  fi
  [ -f "$DIR/phase-02-impact-matrix.md" ] || echo "work/$KEY/phase-02-impact-matrix.md (Phase 2)"
  [ -f "$DIR/phase-03-feasibility.md" ]   || echo "work/$KEY/phase-03-feasibility.md (Phase 3)"
  if [ ! -f "$DIR/phase-04-verdict.md" ]; then
    echo "work/$KEY/phase-04-verdict.md (Phase 4 — the GATE)"
  else
    # Anchored + exactly-one: a quoted template ("  VERDICT: ✅") or a stale
    # second verdict line must never open the gate.
    N_VERDICT="$(grep -c '^VERDICT: ' "$DIR/phase-04-verdict.md" 2>/dev/null || true)"
    if [ "$N_VERDICT" != "1" ]; then
      echo "work/$KEY/phase-04-verdict.md must contain exactly ONE line starting with 'VERDICT: ' at column 0 (found: ${N_VERDICT:-0}) (Phase 4)"
    elif grep -q '^VERDICT: ✅' "$DIR/phase-04-verdict.md" 2>/dev/null; then
      : # gate open
    elif grep -q '^VERDICT: ⚠' "$DIR/phase-04-verdict.md" 2>/dev/null || \
         grep -q '^VERDICT: ⛔' "$DIR/phase-04-verdict.md" 2>/dev/null; then
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

# Prints missing pre-publication artifacts for push/PR (Ezy code style, phases 7
# and 9). Empty = ok.
gate_missing_prereview() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  if [ ! -f "$DIR/phase-06-code-style.md" ]; then
    echo "work/$KEY/phase-06-code-style.md (Ezy code style — run: tools/code-style.sh $KEY apply, then tools/code-style.sh $KEY verify)"
  else
    grep -q '^CODE-STYLE: VERIFIED' "$DIR/phase-06-code-style.md" 2>/dev/null ||       echo "work/$KEY/phase-06-code-style.md missing the 'CODE-STYLE: VERIFIED' line (the Ezy cleanup still changes lines this task added/modified — tools/code-style.sh $KEY apply, fix the MANUAL deltas, re-run verify)"
    grep -Eq '^STYLE-SHA: [0-9a-fA-F]{7,40}' "$DIR/phase-06-code-style.md" 2>/dev/null ||       echo "work/$KEY/phase-06-code-style.md missing the 'STYLE-SHA: <commit>' line (verify ran on uncommitted files — re-run tools/code-style.sh $KEY verify on the final commit)"
  fi
  if [ ! -f "$DIR/phase-07-testing.md" ]; then
    echo "work/$KEY/phase-07-testing.md (Phase 7)"
  elif ! grep -q '^TESTS: GREEN' "$DIR/phase-07-testing.md" 2>/dev/null; then
    echo "work/$KEY/phase-07-testing.md missing the 'TESTS: GREEN' line (Phase 7 — run the FULL suite and record its output)"
  fi
  if [ ! -f "$DIR/phase-09-pre-review.md" ]; then
    echo "work/$KEY/phase-09-pre-review.md (Phase 9)"
  else
    grep -q '^REVIEW-CODE: APPROVED' "$DIR/phase-09-pre-review.md" 2>/dev/null || \
      echo "work/$KEY/phase-09-pre-review.md missing the 'REVIEW-CODE: APPROVED' line (Phase 9 — run the local validator process/REVIEW-CODE.md)"
    grep -q '^VALIDATED-SHA: ' "$DIR/phase-09-pre-review.md" 2>/dev/null || \
      echo "work/$KEY/phase-09-pre-review.md missing the 'VALIDATED-SHA: <commit>' line (Phase 9 — anchors the approval to the reviewed commit: git -C <code-repo> rev-parse HEAD)"
    grep -q '^COMPLETENESS: VERIFIED' "$DIR/phase-09-pre-review.md" 2>/dev/null || \
      echo "work/$KEY/phase-09-pre-review.md missing the 'COMPLETENESS: VERIFIED' line (Phase 9 — re-validate Jira task + plan + code: nothing left uninvolved)"
    grep -Eq '^DEVIATIONS: (NONE|APPROVED-AND-DOCUMENTED)' "$DIR/phase-09-pre-review.md" 2>/dev/null || \
      echo "work/$KEY/phase-09-pre-review.md missing the 'DEVIATIONS: NONE' or 'DEVIATIONS: APPROVED-AND-DOCUMENTED' line (Phase 9 — no deviation without user approval; approved ones documented in the plan)"
  fi
}

# The USER's explicit approval to publish (push + PR). Human-created file —
# the agent is forbidden from creating it. Prints what is missing; empty = ok.
gate_missing_push_approval() {
  KEY="$1"
  [ -f "$WORK_DIR/$KEY/PUSH-APPROVED" ] || \
    echo "work/$KEY/PUSH-APPROVED (the user's publication approval — ask the user; they create it: touch work/$KEY/PUSH-APPROVED)"
}

# Diff-drift check: the commit approved in Phase 9 must be the code repo's
# current HEAD at publication time. Prints a description of the drift; empty =
# no drift (or no SHA recorded — that case is reported by
# gate_missing_prereview). Abbreviated SHAs (>= 7 hex chars) are accepted as a
# prefix of HEAD.
gate_sha_drift() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  WANT="$(sed -n 's/^VALIDATED-SHA:[[:space:]]*//p' "$DIR/phase-09-pre-review.md" 2>/dev/null | head -1 | tr -d '[:space:]')"
  [ -n "$WANT" ] || return 0
  HAVE="$(git -C "$CODE_REPO" rev-parse HEAD 2>/dev/null || true)"
  [ -n "$HAVE" ] || return 0
  if [ "${#WANT}" -ge 7 ]; then
    case "$HAVE" in "$WANT"*) return 0 ;; esac
  fi
  printf 'approved commit %s vs current HEAD %s' "$WANT" "$HAVE"
}

# Style-drift check: the commit the Ezy style was verified on must be the code
# repo's current HEAD at publication time. Same contract as gate_sha_drift.
gate_style_drift() {
  KEY="$1"; DIR="$WORK_DIR/$KEY"
  WANT="$(sed -n 's/^STYLE-SHA:[[:space:]]*//p' "$DIR/phase-06-code-style.md" 2>/dev/null | head -1 | tr -d '[:space:]')"
  [ -n "$WANT" ] || return 0
  HAVE="$(git -C "$CODE_REPO" rev-parse HEAD 2>/dev/null || true)"
  [ -n "$HAVE" ] || return 0
  if [ "${#WANT}" -ge 7 ]; then
    case "$HAVE" in "$WANT"*) return 0 ;; esac
  fi
  printf 'styled commit %s vs current HEAD %s' "$WANT" "$HAVE"
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
