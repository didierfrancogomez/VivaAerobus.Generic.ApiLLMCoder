#!/usr/bin/env bash
# run-tests.sh — deterministic test suite for the Coder pipeline gate hooks.
#
# Exercises guard-writes.sh, guard-bash.sh and pipeline-state.sh against a
# throwaway sandbox: a fake code repo (named VivaAerobus.Generic.Api, as the
# guards match it by name) and an overridden work dir, via the two env
# overrides the hooks support:
#   CODER_GATE_CODE_REPO  — path of the code repo
#   CODER_GATE_WORK_DIR   — path of the work/ dir
#
# Run from anywhere:  bash .claude/hooks/tests/run-tests.sh
# Exit 0 = all green. Must stay bash-3.2 compatible.

set -u
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CODER_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"

TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

export CODER_GATE_CODE_REPO="$TMP/VivaAerobus.Generic.Api"
export CODER_GATE_WORK_DIR="$TMP/work"
CODE="$CODER_GATE_CODE_REPO"
WORK="$CODER_GATE_WORK_DIR"
mkdir -p "$CODE" "$WORK"

git -C "$CODE" init -q -b master
git -C "$CODE" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
HEAD_SHA="$(git -C "$CODE" rev-parse HEAD)"

PASS=0; FAIL=0

# --- helpers -----------------------------------------------------------------
write_json() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }
bash_json()  { printf '{"tool_input":{"command":"%s"}}' "$1"; }

run_writes() { printf '%s' "$1" | bash "$HOOKS_DIR/guard-writes.sh" 2>/dev/null; }
run_bash()   { printf '%s' "$1" | bash "$HOOKS_DIR/guard-bash.sh" 2>/dev/null; }

check() { # check <name> <expect: allow|deny> <output> [required-substring]
  NAME="$1"; EXPECT="$2"; OUT="$3"; SUB="${4:-}"
  OK=1
  if [ "$EXPECT" = "deny" ]; then
    printf '%s' "$OUT" | grep -q '"deny"' || OK=0
    if [ -n "$SUB" ] && ! printf '%s' "$OUT" | grep -qF "$SUB"; then OK=0; fi
  else
    printf '%s' "$OUT" | grep -q '"deny"' && OK=0
  fi
  if [ "$OK" = "1" ]; then
    PASS=$((PASS+1)); echo "  ok   $NAME"
  else
    FAIL=$((FAIL+1)); echo "  FAIL $NAME"
    echo "       expected: $EXPECT ${SUB:+(containing: $SUB)}"
    echo "       got     : ${OUT:-<empty>}"
  fi
}

make_analysis() { # make_analysis <KEY> — full phase 0-5 artifacts, verdict ✅
  D="$WORK/$1"; mkdir -p "$D"
  echo intake    > "$D/phase-00-intake.md"
  echo contrast  > "$D/phase-01-contrast.md"
  echo matrix    > "$D/phase-02-impact-matrix.md"
  echo feasible  > "$D/phase-03-feasibility.md"
  printf 'analysis done\nVERDICT: ✅\n' > "$D/phase-04-verdict.md"
  printf 'plan\n\n## Deviations (approved)\n' > "$D/phase-05-plan.md"
}

make_publication() { # make_publication <KEY> <sha> — phase 7 + 9 artifacts
  D="$WORK/$1"
  printf 'suite output...\nTESTS: GREEN\n' > "$D/phase-07-testing.md"
  printf 'REVIEW-CODE: APPROVED\nVALIDATED-SHA: %s\nCOMPLETENESS: VERIFIED\nDEVIATIONS: NONE\n' \
    "$2" > "$D/phase-09-pre-review.md"
}

reset_work() { rm -rf "$WORK"; mkdir -p "$WORK"; }

# --- guard-writes: task resolution and the analysis gate ---------------------
echo "guard-writes:"

check "write outside any repo → allow" allow \
  "$(run_writes "$(write_json "$TMP/scratch/notes.md")")"

check "write to code repo, no resolvable task → deny" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "PIPELINE GATE"

echo "ABC-1" > "$WORK/_active"
check "write to code repo, artifacts missing → deny" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "phase-00-intake.md"

make_analysis ABC-1
check "write to code repo, phases 0-5 + ✅ → allow" allow \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")"

printf 'VERDICT: ⚠️\nquestions...\n' > "$WORK/ABC-1/phase-04-verdict.md"
check "verdict ⚠️ → deny (STOP)" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "GATE (Phase 4)"

printf 'VERDICT: ⛔\nVERDICT: ✅\n' > "$WORK/ABC-1/phase-04-verdict.md"
check "two VERDICT lines → deny (exactly one required)" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "exactly ONE"

printf '  VERDICT: ✅\n' > "$WORK/ABC-1/phase-04-verdict.md"
check "indented/quoted verdict → deny (anchored match)" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")"

printf 'VERDICT: ✅\n' > "$WORK/ABC-1/phase-04-verdict.md"
touch "$WORK/ABC-1/HUMAN-GATE-REQUIRED"
check "risky level without HUMAN-GATE-OK → deny" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "HUMAN GATE"

touch "$WORK/ABC-1/HUMAN-GATE-OK"
check "risky level with HUMAN-GATE-OK → allow" allow \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")"

# --- guard-writes: human signatures and the protected surface ----------------
check "agent writes HUMAN-GATE-OK → deny" deny \
  "$(run_writes "$(write_json "$WORK/ABC-1/HUMAN-GATE-OK")")" "FORBIDDEN"
check "agent writes PUSH-APPROVED → deny" deny \
  "$(run_writes "$(write_json "$WORK/ABC-1/PUSH-APPROVED")")" "FORBIDDEN"
check "agent writes _PROCESS-CHANGE-OK → deny" deny \
  "$(run_writes "$(write_json "$WORK/_PROCESS-CHANGE-OK")")" "FORBIDDEN"

check "write to process/ without authorization → deny" deny \
  "$(run_writes "$(write_json "$CODER_ROOT/process/phase-00-intake.md")")" "PROTECTED SURFACE"
check "write to CLAUDE.md without authorization → deny" deny \
  "$(run_writes "$(write_json "$CODER_ROOT/CLAUDE.md")")" "PROTECTED SURFACE"
check "write to .claude/ without authorization → deny" deny \
  "$(run_writes "$(write_json "$CODER_ROOT/.claude/hooks/lib-gate.sh")")" "PROTECTED SURFACE"

touch "$WORK/_PROCESS-CHANGE-OK"
check "write to process/ WITH _PROCESS-CHANGE-OK → allow" allow \
  "$(run_writes "$(write_json "$CODER_ROOT/process/phase-00-intake.md")")"
rm -f "$WORK/_PROCESS-CHANGE-OK"

# --- guard-bash: mutations, publication, drift, user approval ----------------
echo "guard-bash:"

check "read-only command on code repo → allow" allow \
  "$(run_bash "$(bash_json "git -C $CODE log --oneline")")"

reset_work
check "shell mutation of code repo, no task → deny" deny \
  "$(run_bash "$(bash_json "echo x > $CODE/src/Foo.cs")")" "PIPELINE GATE"

echo "ABC-1" > "$WORK/_active"; make_analysis ABC-1
check "shell mutation, gate open → allow" allow \
  "$(run_bash "$(bash_json "echo x > $CODE/src/Foo.cs")")"

check "git commit in code repo, gate open → allow" allow \
  "$(run_bash "$(bash_json "git -C $CODE commit -m msg")")"

check "push without phase 7/9 artifacts → deny" deny \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")" "PRE-PUBLICATION GATE"

printf 'REVIEW-CODE: APPROVED\n' > "$WORK/ABC-1/phase-09-pre-review.md"
check "push with APPROVED but no TESTS/SHA/COMPLETENESS/DEVIATIONS → deny" deny \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")" "TESTS: GREEN"

make_publication ABC-1 "$HEAD_SHA"
check "push, everything present but no PUSH-APPROVED → deny" deny \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")" "USER APPROVAL GATE"

touch "$WORK/ABC-1/PUSH-APPROVED"
check "push fully gated (tests+review+SHA+user approval) → allow" allow \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")"

git -C "$CODE" -c user.email=t@t -c user.name=t commit -q --allow-empty -m drift
check "push after a new commit (diff drift) → deny" deny \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")" "DIFF DRIFT"
make_publication ABC-1 "$(git -C "$CODE" rev-parse HEAD)"
check "push after re-anchoring VALIDATED-SHA → allow" allow \
  "$(run_bash "$(bash_json "git -C $CODE push origin feat/ABC-1-x")")"

check "bash touch of HUMAN-GATE-OK → deny" deny \
  "$(run_bash "$(bash_json "touch $WORK/ABC-1/HUMAN-GATE-OK")")" "FORBIDDEN"
check "bash touch of PUSH-APPROVED → deny" deny \
  "$(run_bash "$(bash_json "touch $WORK/XYZ-9/PUSH-APPROVED")")" "FORBIDDEN"

check "shell mutation of process/ → deny" deny \
  "$(run_bash "$(bash_json "sed -i .bak s/a/b/ process/phase-00-intake.md")")" "PROTECTED SURFACE"
check "redirect into CLAUDE.md → deny" deny \
  "$(run_bash "$(bash_json "echo x > CLAUDE.md")")" "PROTECTED SURFACE"
check "reading process/ → allow" allow \
  "$(run_bash "$(bash_json "cat process/phase-00-intake.md")")"
touch "$WORK/_PROCESS-CHANGE-OK"
check "shell mutation of process/ WITH authorization → allow" allow \
  "$(run_bash "$(bash_json "sed -i .bak s/a/b/ process/phase-00-intake.md")")"
rm -f "$WORK/_PROCESS-CHANGE-OK"

# --- guard-bash / guard-writes: branch-based task resolution -----------------
echo "task resolution by branch:"

git -C "$CODE" checkout -q -b feat/XYZ-9-new-thing
check "branch key XYZ-9 without artifacts → deny naming XYZ-9" deny \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")" "XYZ-9"

make_analysis XYZ-9
check "branch key XYZ-9 with artifacts → allow (ignores _active=ABC-1)" allow \
  "$(run_writes "$(write_json "$CODE/src/Foo.cs")")"
git -C "$CODE" checkout -q master

# --- pipeline-state: smoke ----------------------------------------------------
echo "pipeline-state:"
STATE="$(bash "$HOOKS_DIR/pipeline-state.sh" 2>/dev/null)"
if printf '%s' "$STATE" | grep -q "PIPELINE GATE" && printf '%s' "$STATE" | grep -q "ABC-1"; then
  PASS=$((PASS+1)); echo "  ok   state report runs and lists tasks"
else
  FAIL=$((FAIL+1)); echo "  FAIL state report"; echo "$STATE"
fi

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" = "0" ] || exit 1
exit 0
