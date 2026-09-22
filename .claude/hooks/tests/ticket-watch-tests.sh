#!/usr/bin/env bash
# ticket-watch-tests.sh — deterministic tests for .claude/hooks/ticket-watch.sh.
# No Jira, no network: a sandbox work/ dir and a fake jira-sync dir whose "python" is a stub.
# The Python logic behind `jira_sync.py watch` has its own offline suite:
#   tools/jira-sync/.venv/<bin|Scripts>/python tools/jira-sync/test_ticket_watch.py
#
# Run from anywhere:  bash .claude/hooks/tests/ticket-watch-tests.sh     (exit 0 = all green)
# Must stay bash-3.2 compatible.

set -u
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$(cd "$TESTS_DIR/.." && pwd)/ticket-watch.sh"

TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT
export CODER_GATE_WORK_DIR="$TMP/work"
export CODER_WATCH_JIRA_DIR="$TMP/jira-sync"
W="$CODER_GATE_WORK_DIR"
mkdir -p "$W/API-1/ticket-snapshots" "$W/API-2/ticket-snapshots" "$W/API-3/ticket-snapshots"

PASS=0; FAIL=0
check() { # check <name> <0|1 condition-result> <output>
  if [ "$2" = "0" ]; then PASS=$((PASS+1)); echo "  ok   $1"
  else FAIL=$((FAIL+1)); echo "  FAIL $1"; echo "       got: ${3:-<empty>}"; fi
}
run() { bash "$HOOK" </dev/null 2>/dev/null; }

echo "ticket-watch hook:"
printf -- '- API-1 · matrix ⚠️ row 3 SPEC-CHANGED\n' > "$W/API-1/ticket-snapshots/watch.txt"
: > "$W/API-2/ticket-snapshots/watch.txt"
printf -- '- API-3 · deadline ⏰ MISSING\n' > "$W/API-3/ticket-snapshots/watch.txt"
printf -- '- `overall_status`: closed\n' > "$W/API-3/delivery-state.md"

OUT="$(VIVA_TICKET_WATCH_NO_REFRESH=1 run)"
printf '%s' "$OUT" | grep -q "TICKET WATCH" && printf '%s' "$OUT" | grep -q "API-1 · matrix ⚠️ row 3 SPEC-CHANGED  (checked 0 min ago)"
check "cached finding is printed with its age" $? "$OUT"
printf '%s' "$OUT" | grep -q "explicit yes and a --dry-run first"
check "the directive requires the user's yes for Jira writes" $? "$OUT"
printf '%s' "$OUT" | grep -q "API-3"; [ $? -ne 0 ]
check "a closed task is not watched" $? "$OUT"
[ "$(printf '%s' "$OUT" | grep -c "API-2")" = "0" ]
check "an empty cache prints nothing" $? "$OUT"

OUT="$(VIVA_TICKET_WATCH_OFF=1 run)"
[ -z "$OUT" ]
check "VIVA_TICKET_WATCH_OFF=1 silences the hook" $? "$OUT"

rm -f "$W/API-1/ticket-snapshots/watch.txt"
OUT="$(VIVA_TICKET_WATCH_NO_REFRESH=1 run)"
[ -z "$OUT" ] && [ ! -d "$W/.ticket-watch" ]
check "no cache + NO_REFRESH → silent, nothing spawned" $? "$OUT"

OUT="$(run)"
[ -z "$OUT" ] && [ ! -d "$W/.ticket-watch" ]
check "jira-sync not configured → fails open (no spawn)" $? "$OUT"

# configured: a stub "python" that records its args and writes the cache like `watch` does
mkdir -p "$CODER_WATCH_JIRA_DIR/.venv/bin"; : > "$CODER_WATCH_JIRA_DIR/.env"; : > "$CODER_WATCH_JIRA_DIR/jira_sync.py"
cat > "$CODER_WATCH_JIRA_DIR/.venv/bin/python" <<EOF
#!/usr/bin/env bash
echo "\$*" > "$TMP/args"
printf -- '- API-1 · matrix ⚠️ refreshed\n' > "$W/API-1/ticket-snapshots/watch.txt"
EOF
chmod +x "$CODER_WATCH_JIRA_DIR/.venv/bin/python"
START=$(date +%s); OUT="$(run)"; END=$(date +%s)
[ $((END - START)) -le 3 ]
check "the refresh never blocks the prompt" $? "took $((END - START))s"
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$TMP/args" ] && [ ! -d "$W/.ticket-watch/lock" ] && break; sleep 1; done
grep -q "watch API-1 --work-dir $W" "$TMP/args" 2>/dev/null
check "only missing/stale caches are refreshed, in the background (fresh API-2 and closed API-3 skipped)" $? "$(cat "$TMP/args" 2>/dev/null)"
OUT="$(VIVA_TICKET_WATCH_NO_REFRESH=1 run)"
printf '%s' "$OUT" | grep -q "refreshed"
check "the next prompt shows the refreshed cache" $? "$OUT"

rm -f "$TMP/args"; mkdir -p "$W/.ticket-watch/lock"
VIVA_TICKET_WATCH_TTL=0 run >/dev/null; sleep 1
[ ! -f "$TMP/args" ]
check "a fresh lock prevents a second concurrent refresh" $? "$(cat "$TMP/args" 2>/dev/null)"

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" = "0" ] || exit 1
exit 0
