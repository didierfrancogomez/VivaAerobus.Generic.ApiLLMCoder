#!/usr/bin/env bash
# code-style.sh — apply / verify the team's `Ezy` code style on a task's diff.
#   tools/code-style.sh API-9999 apply     # Phase 6 §6.5 — last implementation step
#   tools/code-style.sh API-9999 verify    # Phase 9 §9.5 — the gate, after the squashed commit
#   options: --base <ref>  (default: merge-base of origin/master|master and HEAD)
#
# Runs `jb cleanupcode VivaAerobus.Generic.Api.sln --profile=Ezy --include=<task .cs files>`
# (JetBrains.ReSharper.GlobalTools — the CLI of Rider's Code Cleanup) from the solution dir.
# `apply` keeps only the cleanup deltas that land on lines the task added/modified (KB §25.9.1);
# `verify` re-runs it, restores the files byte-for-byte, and records CODE-STYLE: VERIFIED +
# STYLE-SHA in work/<KEY>/phase-06-code-style.md only when zero deltas land on our lines.
# The push/PR hook requires that marker and STYLE-SHA == HEAD. Logic: tools/code-style.py.
# Must stay bash-3.2 compatible.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$(printf '%s' "${1:?usage: code-style.sh API-9999 apply|verify [--base <ref>]}" | tr '[:lower:]' '[:upper:]')"
MODE="${2:?usage: code-style.sh API-9999 apply|verify [--base <ref>]}"
shift 2

. "$ROOT/.claude/hooks/lib-gate.sh"

# The sibling may be checked out under its lowercase folder name (aerobus.generic.api).
if [ ! -d "$CODE_REPO" ] && [ -z "${CODER_GATE_CODE_REPO:-}" ]; then
  ALT="$(cd "$CODER_ROOT/.." && pwd)/aerobus.generic.api"
  [ -d "$ALT" ] && CODE_REPO="$ALT"
fi
[ -d "$CODE_REPO" ] || { echo "⛔ no API repo at '$CODE_REPO' (set CODER_GATE_CODE_REPO)"; exit 2; }

MISSING="$(gate_missing_analysis "$KEY")"
if [ -n "$MISSING" ]; then
  echo "⛔ the analysis gate of $KEY is not open — style runs only on implemented work:"
  printf '%s\n' "$MISSING"
  exit 2
fi

# python3 may be the Microsoft Store alias on Windows: probe that it actually runs.
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 6))' >/dev/null 2>&1; then
    PY="$c"; break
  fi
done
[ -n "$PY" ] || { echo "⛔ no working Python 3 found (python3/python/py)"; exit 2; }

exec "$PY" "$ROOT/tools/code-style.py" "$MODE" "$KEY" --repo "$CODE_REPO" --work "$WORK_DIR" "$@"
