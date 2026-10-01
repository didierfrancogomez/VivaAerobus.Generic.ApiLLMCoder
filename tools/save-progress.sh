#!/usr/bin/env bash
# save-progress.sh — version a task's work artifacts and tell the user where to resume.
#   tools/save-progress.sh API-9999 ["phase 2 — impact matrix"] [--no-push]
# Commits ONLY work/<KEY>/ (human signatures, _active and ticket dumps are gitignored)
# and pushes, then prints the folder + resume instructions. Run it at the close of
# EVERY phase (CLAUDE.md §Rules) — progress that only lives on one disk is not progress.
# Must stay bash-3.2 compatible.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$(printf '%s' "${1:?usage: save-progress.sh API-9999 [\"note\"] [--no-push]}" | tr '[:lower:]' '[:upper:]')"
NOTE="${2:-checkpoint}"
PUSH=1
for a in "$@"; do [ "$a" = "--no-push" ] && PUSH=0; done
[ "$NOTE" = "--no-push" ] && NOTE="checkpoint"

DIR="$ROOT/work/$KEY"
[ -d "$DIR" ] || { echo "⛔ no work/$KEY — nothing to save"; exit 2; }

# This repo is public and work/<KEY>/evidence/ is versioned: nothing is committed while a
# credential value is still in clear (Phase 7 §7.4). Fail closed when the scan cannot run.
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys' >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$PY" ] || { echo "⛔ python not found — the credential scan cannot run, so work/$KEY is not versioned"; exit 2; }
if ! (cd "$ROOT" && "$PY" tools/evidence/mask-credentials.py --check --git "work/$KEY"); then
  echo "⛔ work/$KEY holds unmasked credentials and this repo is PUBLIC — nothing was committed."
  echo "   Mask them, review the diff, then re-run:  $PY tools/evidence/mask-credentials.py work/$KEY"
  exit 3
fi

bash "$ROOT/tools/update-index.sh"
git -C "$ROOT" add -- "work/$KEY" work/README.md 2>/dev/null || true
if git -C "$ROOT" diff --cached --quiet -- "work/$KEY" work/README.md; then
  echo "· work/$KEY has no new changes to version"
else
  git -C "$ROOT" commit -q -m "progress($KEY): $NOTE" -- "work/$KEY" work/README.md
  SHA="$(git -C "$ROOT" rev-parse --short HEAD)"
  echo "✔ committed $SHA — progress($KEY): $NOTE"
fi

if [ "$PUSH" = "1" ]; then
  if git -C "$ROOT" push -q origin HEAD 2>/dev/null; then
    echo "✔ pushed to origin"
  else
    echo "⚠ push failed (offline / auth?) — the commit is safe locally; push when possible"
  fi
fi

echo ""
echo "📁 Tu avance quedó en: work/$KEY/  (tablero: work/$KEY/delivery-state.md)"
echo "   Para retomar en cualquier momento: abre una sesión en este repo y corre  /implement $KEY"
