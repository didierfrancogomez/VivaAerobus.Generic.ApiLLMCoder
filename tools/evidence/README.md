# Evidence capture (Playwright + newman)

Playwright driving the **installed** Chrome (`playwright-core`, no bundled browsers downloaded) plus a local
newman 6.2.2 with the `htmlextra` reporter. The format these scripts produce — what a ticket's evidence
folder must contain and how each piece is written — is in [`EVIDENCE-FORMAT.md`](EVIDENCE-FORMAT.md).

```bash
cd tools/evidence
npm i
```

| Script | What it does |
|---|---|
| `newman-evidence.mjs` | Runs ONE test-case folder of a Postman collection with newman and captures: the run summary, one PNG per request (request, response, `pm.test` results) and, with `--cards`, readable evidence cards (Expected/Got, highlighted excerpt, PASS/FAIL, code under test). |
| `evidence-card.mjs` | ONE self-contained card per test case, rendered from the classic capture files (`### NN-step` / `**curl (Request)**` / `**Response**`). This is what gets attached to Jira. |
| `run2capture.py` | Converts one request of a newman `run.json` into the classic capture markdown, so newman-driven and manual test cases feed the same card renderer. |
| `admin-portal.mjs` | Admin Portal: section + channel + block (`--node`) + outlined properties (`--field`) + banner (`--caption auto`) → PNG, reusing the saved session. |
| `shot.mjs` | Any URL → PNG. Single shot from flags, or a multi-step flow from a JSON file (`--steps`) — see [`examples/`](examples/). |
| `dump-paths.mjs` | Lists the Admin Portal editor's `data-schemapath` values under a prefix (to find the real path of a tabbed array item). |
| `save-session.mjs` | Opens a visible Chrome; **you** log in and close the window; cookies + localStorage are saved. |

```bash
node newman-evidence.mjs --collection "<collection.json>" --environment "<env.json>" --folder "TC01 …" \
  --ticket API-XXXX --tc TC01 --cards cards.json \
  --out "<evidence-root>/API-XXXX/captures/postman"
node newman-evidence.mjs --from-run .runs/API-XXXX/<stamp>-TC01 --ticket API-XXXX --tc TC01 --cards cards.json --out <dir>

node evidence-card.mjs --spec "<evidence-root>/API-XXXX/cards.json" --out "<evidence-root>/API-XXXX/captures/test-cases"
python run2capture.py .runs/API-XXXX/<stamp>-TC01/run.json "<request name>" "<evidence-root>/API-XXXX/raw/TC01/08-step.md"

node admin-portal.mjs --login
node admin-portal.mjs --check
node admin-portal.mjs --section Services --channel mobile --node train --field train.enabled --color green --caption auto \
  --out "<evidence-root>/API-XXXX/captures/admin-portal/API-XXXX_AdminPortal_mobile_Services_train.enabled_Solution.png"
```

`<evidence-root>` is the local evidence folder (`docs/evidencias/` next to the sibling repos). It is **not**
part of this repo: raw evidence carries tokens, test-user credentials and booking data.

`newman-evidence.mjs --cards`:
```json
[{ "request": "Get checkin status", "title": "TC01 check-in is blocked by the booking rule",
   "expected": "status Blocked", "got": "status Blocked", "excerpt": ["data.journeys[0].status"] }]
```
Excerpt paths: `a.b`, `a[0]`, `a[*]`, `a[?key=value]`. The `evidence-card.mjs` spec is documented at the top
of the script.

The footer of every card says which code ran (`branch @ sha`). The code repo is taken from `--code-repo`,
then `VIVA_CODE_REPO`, then the sibling `../VivaAerobus.Generic.Api`; if none is a git checkout the footer
says `unknown`.

Rules:
- The scripts never type credentials (`fill` refuses password fields). Logging in is always a person's step.
- `.auth/` holds live tokens and `.runs/` holds raw newman reports (tokens, full bodies): both are git-ignored.
  Never copy them into a repo, an evidence folder or Jira. Only the PNGs go to the evidence folder.
- Requests named `/login|token/i` get request and response bodies hidden in the report and on the cards.
- The Admin Portal token lasts 60 minutes; exit code `2` = session missing or expired → `--login` again.
- `vendor/` = local copies of the CDN assets the htmlextra report loads (the network drops them); each file
  keeps its upstream license header.
- Capture a block, never `--full`: an Admin Portal section is rendered fully expanded (`Services` is 37,441 px).
- `--browser msedge` switches to Edge; `--headed` shows the window while it runs.
