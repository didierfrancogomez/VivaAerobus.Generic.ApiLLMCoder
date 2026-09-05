#!/usr/bin/env bash
# run-tc.sh — run ONE test-case folder of the API-1738 Postman collection with newman and
# produce: CLI log, JSON run, htmlextra HTML report and a PNG render of the report (Chrome headless).
#
#   work/API-1738/evidence/run-tc.sh TC01 solution [http://localhost:9050]
#   work/API-1738/evidence/run-tc.sh TC01 issue    http://localhost:9051     # master build
#
# Outputs go to work/API-1738/attachments/evidence-runs/<timestamp>-<TC>-<side>/ (gitignored: the
# reports embed request/response bodies). Credential-bearing request bodies (admin/customer/staff
# logins) are hidden in the HTML report and the Authorization header is skipped, so the PNG render
# can be shared as evidence. The collection itself lives in work/API-1738/attachments/ (gitignored,
# it carries QA credentials as collection variables — Q6 decision 2026-09-05: left as the team has it).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TC="${1:?usage: run-tc.sh TCnn issue|solution [baseUrl]}"
SIDE="${2:?usage: run-tc.sh TCnn issue|solution [baseUrl]}"
BASE="${3:-http://localhost:9050}"
COL="$HERE/../attachments/API-1738-Display-Passenger-Changes.postman_collection.json"
[ -f "$COL" ] || { echo "⛔ collection not found: $COL"; exit 2; }

FOLDER="$(PYTHONIOENCODING=utf-8 python3 - "$COL" "$TC" <<'EOF'
import io, json, sys
c = json.load(io.open(sys.argv[1], encoding="utf-8"))
print(next(i["name"] for i in c["item"] if i["name"].startswith(sys.argv[2])))
EOF
)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/../attachments/evidence-runs/$STAMP-$TC-$SIDE"
mkdir -p "$OUT"

echo "▶ $TC ($SIDE) against $BASE — folder: $FOLDER"
newman run "$COL" --folder "$FOLDER" \
  --env-var "api1738BaseUrl=$BASE" \
  --reporters cli,htmlextra,json \
  --reporter-htmlextra-export "$OUT/report.html" \
  --reporter-json-export "$OUT/run.json" \
  --reporter-htmlextra-title "API-1738 $TC ($SIDE) — $FOLDER" \
  --reporter-htmlextra-browserTitle "API-1738 $TC $SIDE" \
  --reporter-htmlextra-skipHeaders "Authorization" \
  --reporter-htmlextra-hideRequestBody "01 Admin login and initialize $TC" \
  --reporter-htmlextra-hideRequestBody "01 Login as Customer evidence viewer" \
  --reporter-htmlextra-hideRequestBody "06 Login as Customer evidence viewer" \
  --reporter-htmlextra-hideRequestBody "06 Login as Staff creator/viewer for persistent basket access" \
  --insecure --timeout-request 90000 --delay-request 250 \
  2>&1 | tee "$OUT/cli.txt"
RC=${PIPESTATUS[0]}

CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
[ -x "$CHROME" ] || CHROME="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
if [ -f "$OUT/report.html" ] && [ -x "$CHROME" ]; then
  PROFILE="$HERE/../attachments/.chrome-profile"; mkdir -p "$PROFILE"
  "$CHROME" --headless=new --disable-gpu --no-first-run --hide-scrollbars \
    --user-data-dir="$(cygpath -w "$PROFILE")" --window-size=1600,2400 \
    --screenshot="$(cygpath -w "$OUT/report.png")" "file:///$(cygpath -w "$OUT/report.html")" >/dev/null 2>&1 \
    && echo "🖼  $OUT/report.png"
fi
echo "📁 $OUT  (newman exit $RC)"
exit "$RC"
