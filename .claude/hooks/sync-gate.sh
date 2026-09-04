#!/usr/bin/env bash
# Stop + UserPromptSubmit hook — delegates the docs-sync gate to the ApiLLM repo.
#
# Why this exists: the docs-sync check used to live ONLY in the ApiLLM repo, so analysing a
# ticket from a Coder session bypassed it entirely — no measurement, no block. The Coder
# pipeline asks for the sync in prose (`process/phase-01-code-contrast.md`: "Sync first"),
# which is precisely the kind of instruction the ApiLLM hooks exist because it gets skipped.
# The rule is "always, no exception", so it cannot depend on which repo the session opened in.
#
# This is a thin locator + exec: the gate logic has ONE home, in the ApiLLM repo.
#
# Env:
#   VIVA_DOCS_REPO   path to VivaAerobus.Generic.ApiLLM (default: sibling of this repo)
#   plus everything sync-gate.sh / sync-check.sh accept (see llm/hook-setup.md there)

set -uo pipefail

EVENT="${1:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODER_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCS_REPO="${VIVA_DOCS_REPO:-$CODER_ROOT/../VivaAerobus.Generic.ApiLLM}"

case "$EVENT" in
  Stop)              TARGET="$DOCS_REPO/.claude/hooks/sync-gate.sh"  ;;
  UserPromptSubmit)  TARGET="$DOCS_REPO/.claude/hooks/sync-check.sh" ;;
  *)                 exit 0 ;;
esac

if [ ! -f "$TARGET" ]; then
  # Never block on a missing sibling: a Coder checkout without the ApiLLM repo next to it is a
  # setup problem, not a reason to freeze the session. Say it and move on.
  echo "DOCS SYNC GATE — inactive: '$TARGET' not found. Set VIVA_DOCS_REPO to the VivaAerobus.Generic.ApiLLM checkout (see its llm/hook-setup.md). documents/** cannot be trusted as current." >&2
  exit 0
fi

export VIVA_DOCS_REPO="$DOCS_REPO"
exec bash "$TARGET"
