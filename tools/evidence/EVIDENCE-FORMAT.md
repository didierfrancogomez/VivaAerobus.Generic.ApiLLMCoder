# Evidence format

How the evidence of a ticket is built, what the folder must contain and what gets attached to Jira.
Translated from the team's engineering KB (§10.2, §10.2.1, §10.2.2, §10.2.2.a and the evidence half of
§25.18), where these rules were adopted as team decisions between 2026-08-04 and 2026-09-25. The scripts
that produce every image described here are in this folder ([`README.md`](README.md)).

## 0. What a ticket delivers

| Piece | Where | What it is for |
|---|---|---|
| **Classic** main `.md` + one `captures/TCnn.md` per test case | `docs/evidencias/{TICKET}/` | The complete, reproducible proof: full `curl`, full request, full response (§1) |
| **Story** `{TICKET}-evidence-story.md` | same folder | The one people read: each test case told as a short story with images (§3) |
| **One card per test case** `captures/test-cases/*.png` | same folder | **What gets attached to Jira** (§4) |
| newman captures `captures/postman/*.png` | same folder | Run summary + one image per request + cards (§3.4) |
| Admin Portal captures `captures/admin-portal/*.png` | same folder | Only when the ticket requires or mentions the Admin Portal (§2) |
| `PR-template.md` + a `PR DOC` section in the main `.md` | same folder | The filled PR template, ready to paste (§1.4) |

The classic proves, the story explains, the card is what gets attached. EZY asked for something more
readable; the classic is not dropped.

`docs/evidencias/{TICKET}/` lives **outside every repo**, next to the sibling repos. It is never committed:
raw evidence carries tokens, test-user credentials and booking data.

## 1. Classic format — `curl + request + response` per test case

> **Decision (mandatory).** Every **test case** of a ticket is documented with **the `curl` of the flow
> (taken from the Postman collection) + Request + Response**, clear and self-contained, so it can be
> copied straight into the Jira ticket.

**Canonical paths**
- **Postman collection (source of the flow):** `docs/Postman/VivaAerobus.Generic.API.postman_collection.json` in the API repo.
- **Local environment:** `docs/Postman/VB.Generic.Api_Local.postman_environment.json` in the API repo.
- **Evidence folder:** `docs/evidencias/{TICKET}/` — one main `.md` + a `captures/` subfolder with **one
  self-contained file per TC** + the `{TICKET}-evidence-story.md` and its images in `captures/postman/`
  and `captures/admin-portal/`.

### 1.1 What each test case contains
1. A reproducible **`curl`** of the step (or of every step, when the TC chains requests).
2. **Request** — method, path, relevant headers (`X-Channel`, `Authorization`), body.
3. **Response** — HTTP status + `type` + the body.
4. **Measured duration** + verdict (✅/❌).
5. **📸 Admin Portal capture — conditional.** If the change requires or mentions the Admin Portal, the
   TC's *Prerequisites* section carries the capture of the section + channel with the value it ran with.
   If it does not apply, one line in the main `.md` says so. When, what, how and where: §2.

### 1.2 Rules
- 🔴 **The raw `curl` is MANDATORY in EVERY test case.** The Response alone is not self-contained or
  reproducible evidence. Every TC always includes the full `curl` of the **Request** (method, URL, every
  relevant header and the body) — for **each** step when the TC chains requests (login → … → endpoint).
  A TC without its raw `curl` is **incomplete** and is not attached to Jira.
- 🔴🔴 **"Complete" means EVERYTHING, nothing left out.** The **full Request** (method, absolute URL,
  **every** sent header, query params and the **whole body**) **and** the **full Response** (HTTP status,
  **every** response header and the **whole body**). Truncating, summarising or eliding with `...`,
  `// rest`, `[snip]`, or showing only "the proving fragment", is **forbidden**. If the body is long it is
  still documented whole — in `captures/` when it does not fit comfortably in the `.md`.
- ⚠️ **Windows / local:** `curl.exe` does not connect to `localhost:9050`, so the real call runs with
  `Invoke-RestMethod` — **but the `curl` is documented anyway** (the canonical format for Jira and other
  environments).
- The `curl` matches **1:1** a request of the Postman collection (same endpoint, headers and body shape),
  so it is traceable to the official runner.
- Recommended layout per TC: a **`curl` (Request)** block followed by a **Response** block (status +
  `type` + body), one after the other.

### 1.3 Hard rules (2026-08-04)
- 🔴 **The documented TCs are EXACTLY the ticket's Test Case Matrix.** No invented or extra TCs (no
  reproduction, exploration or other-environment "extras"). Anything relevant found outside the matrix
  goes into a **findings / notes** section of the main `.md`, **never** as a new TC. Each matrix TC carries
  **everything needed to show it passed** (full curl + request + proving response + verdict).
- 🔴 **ONE capture file per TC** — not two (no `tcX_request.json` + `tcX_response.txt`). Each TC = **one
  self-contained file** (`captures/{TCid}.md`) holding, in order: the **COMPLETE bash `curl`**
  (copy-paste runnable: method, absolute URL, **every** header, whole body), the **Request** and the
  **full Response** (status + headers + whole body). It can be pasted into Jira as is.
- 🔴 **Prerequisites live in the SAME TC file.** Seed / preparation steps (login, create / clone / mutate
  and **reactivate** a basket, select a bundle…) go in a **"Prerequisites"** section **at the top of the TC
  file**, with their full `curl`s / commands too. The TC is **100% reproducible and self-contained**.

### 1.4 Closing the development — PR template and the `PR DOC` section
When the development ends, the evidence folder holds **two PR-related deliverables**:
1. A separate **`PR-template.md`** with the API repo's PR template (`.github/pull_request_template.md`)
   filled in, **in English** (*About*, *Release notes*, *Checklist*). It is pasted straight into the PR.
2. A **`PR DOC`** section at the end of the main evidence `.md` with the same content, so the evidence
   document is self-contained.

Both carry the three parts: **About** (summary + root cause + technical fix), **Release notes** (friendly
bullets `Fixed` / `Changed` / `Added`, with the ticket reference) and **Checklist** (code, testing,
documentation, breaking changes, PCI, Admin Portal, performance). Re-read the template file every time:
it changed on 2026-09-10 and the polarity of its checkboxes is inverted between its two groups.

## 2. Conditional step: Admin Portal captures (2026-09-24)

> **Decision.** If the change **requires** the Admin Portal or **refers** to it, the evidence includes
> **Admin Portal captures** showing the configuration the TCs ran with. They **enrich** the evidence and
> **replace nothing** of §1: the raw `curl` + full Request + Response stay mandatory in every TC. The
> capture proves the *state of the config*; the `curl` proves the *behaviour*. Both are needed so a
> reviewer does not have to take it on trust.

### 2.1 Does it apply? — ONE trigger is enough

| Trigger | Example |
|---|---|
| The diff adds or changes a `ConfigPart` / `ConfigPartSchema` / seed `Assets/Seed/**.json` | moving a hardcoded value to config |
| The TC's result depends on a config flag or value (`FeatureConfig`, allow-list, date range, `limit`) | `hotelPlus.enabledForSelectedCurrencies`, `train.enabled` |
| A TC **prerequisite** is changing config (UPDATE + cache invalidation: Postgres → Redis `DEL` → restart) | re-enabling a service the seed leaves off |
| The response **projects** Admin Portal config | `enabledCustomerPrograms` |
| The flag is **per channel** and the TC sets an `X-Channel` | `CheckinValues.<channel>` |
| The ticket or its matrix names the Admin Portal, or the PR will tick `Admin Portal changes in this PR` or `Release impact and required actions` | PR template |

**It does not apply** when the change is pure code that reads no config. Record it anyway, in English, in
the main `.md`: `Admin Portal: not applicable — the change reads no Admin Portal configuration.` That shows
the step was evaluated, not forgotten.

### 2.2 What to capture
1. The exact **section** (`/Services`, `/Features`, `/Checkin`…) and **channel** the TC uses: **the config
   block** holding the property (`--node <path>`) with the property under test **outlined**
   (`--field <path>`). Never the whole section: `Services` measures 1440 × 37,441 px.
2. If the TC depends on a value change (before/after, Issue/Solution): **one capture per state**, taken
   **in the same state the TC ran in** — i.e. after the cache invalidation. Colour convention: **red** =
   Issue / before, **green** = Solution / after.
3. If the PR adds a field to the Schema: the form showing the **new field**. It is the visual proof that
   the POCO and the Schema mirror each other.
4. On channels other than `web`, the **"Inherit From Web Channel"** checkbox: when ticked, what you see
   (and what the API reads) is the `web` value, not the channel's. The script prints its state; the capture
   must show it.

### 2.3 How — recipe
```bash
cd tools/evidence
# 1) session: once, and again when it expires. Opens a visible Chrome; log in there and close the window
node admin-portal.mjs --login
node admin-portal.mjs --check          # ✔ = saved token still valid, with the minutes left (never printed)
# 2) capture: section + channel + block (--node) + outlined property (--field), both by JSON PATH
node admin-portal.mjs --section Services --channel mobile --node train --field train.enabled --color green --caption auto \
  --out "<evidence-root>/API-XXXX/captures/admin-portal/API-XXXX_AdminPortal_mobile_Services_train.enabled_Solution.png"
```
- `--node` / `--field` take the property's **JSON path**, the same one used in psql without `root.`:
  `train`, `train.enabled`, `hotelPlus.enabledForSelectedCurrencies`; array items go by index
  (`services.0.code`). A path that does not exist **lists the top-level nodes** of the section. Several
  `--field` are allowed. `--highlight "<text>"` remains as an alternative, but labels repeat (`Enabled`
  appears dozens of times in `Services`) and it outlines the first match.
- The capture includes the **header** (the active channel shows in red) + the whole block + nothing hidden:
  the script grows the window as needed. ~13–16 s per capture (the section loads completely).
- Exit code `2` = session missing or expired (the portal redirected to `/login`) → `--login` again.
  🔑 **The Admin Portal token lasts 60 minutes** (measured on the saved JWT, `nbf` → `exp`). Run `--check`
  before a batch of captures.
- `--caption auto` adds a banner above the block: **section > node [channel]: field=value … — time · local
  Admin Portal** (plus `inherit from web=…` outside `web`). A fixed text also works: `--caption "<text>"`.
- `--mask "<css>"` covers sensitive areas; `--headed` shows the browser while it runs; `--browser msedge`
  uses Edge. For any other page (Swagger, a newman HTML report, a multi-step flow) use `shot.mjs`
  (`node shot.mjs --help`), which replaces the `chrome --headless --screenshot` of
  [`work/API-1738/evidence/run-tc.sh`](../../work/API-1738/evidence/run-tc.sh) when a login, click or
  highlight is needed.
- It uses the **installed Chrome** (`playwright-core` 1.63.0, `channel: 'chrome'`): no Playwright browsers
  are downloaded. If `node_modules` is missing: `npm i` in this folder.

### 2.4 Where and how it is named
`docs/evidencias/{TICKET}/captures/admin-portal/{TICKET}_AdminPortal_{channel}_{Section}_{property}_{Issue|Solution|Before|After}.png`,
linked from the *Prerequisites* section of the TC file, with **an English caption that states the
environment**: `Local Admin Portal (localhost:9507 → local vbgeneric_adminportal)`.

### 2.5 Rules
- 🔴 **A capture is not a TC** and adds no TCs. The ticket's matrix rules (§1.3).
- 🔴 **Credentials never leave the login window.** `--login` opens a visible Chrome; a person logs in and
  closes it. No credential is written into a script, a doc, an evidence file or a repo, and the scripts
  refuse to fill password fields. `.auth/admin-portal.json` holds the **live token**: it is git-ignored and
  never copied into `docs/evidencias/`, Jira or a repo.
- ⚠️ **Review every capture before attaching it.** Sections such as `Payments`, `SystemSettings`, `Doters`
  or `Notifications` can show keys or internal endpoints; cover them with `--mask` or crop the area. It goes
  to Jira and the client reads it.
- ⚠️ **Always state the environment.** A local capture shows the **local** `vbgeneric_adminportal`
  database, not VB-Test's. It does not prove how the deployed environment is configured.
- Names and captions in **English**.

### 2.6 Verified facts about the local Admin Portal (2026-09-24 — reading `VivaAerobus.AdminPortal/src` and driving it with Playwright)
- URL `http://localhost:9507` (container `viva-vbgeneric.adminportal-1`). Vue 2 + Vuetify served by
  webpack-dev-server.
- 🔑 **It talks to the local API:** `window.runtimeConfig.apiHost = "http://localhost:9050"` and every call
  goes to `{apiHost}/v1/admin/...` (`src/api/api.config.js`). **Without the API running there is no login
  and no data.**
- **Two login paths** at `/login`: user/password (`POST {apiHost}/v1/admin/token`,
  `src/store/auth.js :: loginWithCredentials`) or **REDIRECT** to IdentityServer (`http://localhost:9505`,
  OIDC `client_id: 'vivaaerobus.adminportal'`, `src/core/identity-handler.js`).
- **The session persists in `localStorage`, key `vuex`**
  (`src/store/index.js :: createPersistedState({ paths: ['auth'] })`) ⇒ Playwright's `storageState` reuses
  it without logging in again until the token expires. Without a token every route redirects to
  `/login?redirect=…` (`src/router/routes.js :: requireAuth`); the script detects it and exits with `2`.
- **Route = `ConfigPart` name without the suffix:** `/Services` → `ServicesConfigPart` → document
  `ServicesValues.{channel}`. Exception: `/ProductClasses` → `ProductClassConfigPart` (singular). `/audit`
  and `/cache` are not config. ⚠️ The `ReimbursementOptions` route is declared with a **trailing space**
  (`"/ReimbursementOptions "`). Full list: `VivaAerobus.AdminPortal/src/router/routes.js`.
- 🔑 **The channel is NOT in the URL.** It lives in the store (`configPart/currentChannel`), **always**
  starts at `web` (`src/App.vue :: created`) and changes through the header buttons, which send `X-Channel`
  to the API (`src/api/index.js`). That is why the script clicks the channel button instead of navigating.
- The value editor is a JSON editor mounted in `#editor-holder` (`src/components/ValueEditor.vue`); the
  inherit checkbox is `#checkbox` and **does not exist on `web`**.

Measured with the first real session:
- 🔑 **The editor renders EVERYTHING expanded** (4,968 `Collapse` buttons in `Services`): the whole section
  measures **1440 × 37,441 px**. Hence capture by block (`--node`), never `--full`.
- 🔑 **Labels are the property name in title case** (`enabledForSelectedCurrencies` → "Enabled For
  Selected Currencies") and **they repeat**. But every node carries `data-schemapath="root.<path>"` (12,057
  in `Services`) and every input `name="root[<a>][<b>]"`: target **by path**, not by text.
- Layout: a **fixed** header (`nav.v-toolbar`, 64 px) and a **fixed** Save bar at the bottom
  (`.save-button-container`, 82 px) covering the end of the viewport. `captureNode` adds both heights.
- ⚠️ Channel button text is **lower case** (`mobile`); CSS shows it upper case. An exact match on `MOBILE`
  does not find it.
- Clicking a channel makes `App.vue :: setChannel` request `configpartgetschema` + `configpartgetvalues`
  again and the editor **unmounts and remounts**. The script waits for the `configpartgetvalues` response
  and the button with `active-channel`. `networkidle` is **not** reliable in this portal (one `page.goto`
  with `networkidle` ran past 60 s).
- ✅ **Cross-checked against Postgres:** `ServicesValues.web` → `train.enabled = true`,
  `ServicesValues.mobile` → `false`; the captures show exactly that.

**Still open:** whether, after an UPDATE through psql, the portal shows the new value before or after the
restart of the cache invalidation. Until measured, **capture after the restart**, when the portal and the
API see the same thing.

**Environment gotcha — local Admin Portal "broken": failing login or empty screens.** The portal serves its
login page even with the API down, so it looks alive. But both login paths and every section depend on
`http://localhost:9050`: a failed login **is not the password** and an empty section **is not missing
config**. First confirm the API is listening (`Get-NetTCPConnection -LocalPort 9050 -State Listen`).

## 3. Second format: the ticket's **story** (`{TICKET}-evidence-story.md`) (2026-09-24)

> **Decision.** On top of the classic format of §1 (unchanged and still mandatory), every ticket delivers
> **one file** `docs/evidencias/{TICKET}/{TICKET}-evidence-story.md`, **in English**, that tells each test
> case as a story: what I prepared, what I ran, what came back and **where the change shows**, with the
> captures interleaved. The trigger was EZY: after many tickets in production they said the classic `.md`
> is hard to read. The answer is not to drop the classic — it is the complete, reproducible proof — but to
> add the version people read.

### 3.1 How EZY builds its evidence (read on 2026-09-24 from API-1899, API-1912, API-1893 and API-1902)
- 🔑 **The evidence lives in the evidence subtask, inside the matrix.** Titles: *"Test execution —
  <feature>"* or *"Test Cases, execution and evidences"*. Columns: `# · Scenario type · Test case
  description · Expected result · Execution (MANUAL/AUTOMATED) · Postman update? · Notes/Evidence`.
- 🔑 **The Notes/Evidence cell is a short narration interleaved with images**, one sentence per step and one
  image per sentence, closing with **PNR / last name**. API-1899 TC1: *"Created basket / [img] / Load
  booking / [img] / Added contact type emergency / [img] / payment/process / [img] / Verified in the booking
  full response that the emergency contact information are present / [img]"*.
- **The captures are from Postman:** request + status + response, with the **cURL** panel open beside it,
  the field that proves the case **underlined in red** and `Authorization` masked. API-1893 uses the
  **Runner** with **numbered green boxes** and a legend on top saying what to look at in each.
- **The `pm.test` names narrate** (API-1893): `SCENARIO: …`, `RESULT: …`, `NO REGRESSION: …`,
  `CONSISTENCY: …`. Their per-ticket collection has three folders: `00 - Setup` (admin token + config
  **snapshot**) → `TC01 …` (baseline **BEFORE** → config change through the admin API → `Reset settings
  cache` → ASSERT) → `99 - Teardown` (restores the snapshot). The collection JSON is attached at the top of
  the subtask.
- **API-1902 opens with a "Common setup" in prose** covering four things: which Admin Portal settings
  decide what is observed (with the menu path: *Doters > Default Point Exchange Rates > Enabled*), the
  prerequisites (branch, account type, data), the request sequence of each case and **where the value is
  observed**. Then each TC is sentence + image + `PNR:`. The images are an **Admin Portal capture with a
  banner on top** (menu path: values — date) and **generated cards** with *Expected / Got*, the response
  fragment **the check looks at**, PASS, the code under test with its SHA and the time. The full response
  is **attached as JSON**.
- **When the review changes the code, the evidence is taken again** and a comment says which pieces became
  obsolete (API-1893).
- **Image names that say what they show:** `API-1858_TC01_CheckinStatusBlockedByBookingRule_01.png`,
  `API-1854-run15-14-TC1--Doters-is-offered-with-the-default-rate.png`.

### 3.2 File structure (template — copy and fill in)

````markdown
# API-XXXX — <ticket title>

<Two to four sentences for a reviewer who has not read the ticket: what was wrong or missing,
what changed, and what the evidence below is going to show.>

## Before you start
- **Code under test:** `feature/API-XXXX/<slug>` @ `<sha>` · issue side: `master` @ `<sha>` (only when the matrix compares both)
- **Environment:** local API `http://localhost:9050`, which talks to the Navitaire and FarePlace **test** backends; local Admin Portal
- **Settings that decide what you will see:** `<Admin Portal menu path>` = `<value>` on `<channel>` …
- **Test data:** PNR `ABC123` / `Lastname` · account type …
- **Postman:** `<collection>` v7.xxx, folder `TC01 …` (collection attached)

## TC01 — <what this row proves, in plain words> — ✅ PASS

> **From the matrix:** <scenario type> · *Expected:* <expected result, verbatim from the ticket>

To prove this, I first set `<setting>` to `<value>` in the Admin Portal, so the API reads … :

![Admin Portal — <menu path> = <value>](captures/admin-portal/API-XXXX_AdminPortal_web_<Section>_<property>_Solution.png)

Then I called `<endpoint>` for PNR `ABC123`:

```bash
curl --location 'http://localhost:9050/v1/…' \
--header 'X-Channel: web' \
--header 'Authorization: Bearer <token>' \
--data '{ … }'
```

It answers `200 SUCCESS`, and this is the part that matters:

```json
{ "status": "Blocked", "statusDetails": [{ "code": "CheckinBlockedByBookingRule" }] }
```

Here you can see the change: `status` is now `Blocked`, where `master` returns `Open` for the same booking.

![TC01 — check-in blocked by the booking rule](captures/postman/API-XXXX_TC01_05_check-in-blocked-by-the-booking-rule_card.png)

Full request and response: [captures/TC01.md](captures/TC01.md) · newman run: `captures/postman/API-XXXX_TC01_00_newman-summary.png`

**PNR:** `ABC123` / `Lastname`
````

### 3.3 Writing rules
- **English, colloquial, told as a story:** *"to prove this TC I first seed X in Y, then run this curl,
  which returns this response, where you can see the change…"*.
- 🔴 **First person singular:** *"I set…"*, *"I called…"*, *"I checked…"*. Never "we" and never the
  impersonal passive. What is observed goes in the present tense: *"the response now shows…"*.
- **One idea per sentence** and at most **one image per step**, right under the sentence that describes it,
  like EZY's cell.
- **The `curl` goes complete** (method, URL, headers, body; `Authorization` → `Bearer <token>`). **The
  response is trimmed** to the fields that prove the case, with the link to the classic TC file for the
  full one. 🔑 **This is the only place where §1's "complete = EVERYTHING" is relaxed**, and it can be
  because completeness still lives in the classic, which is delivered anyway.
- **The same TCs as the matrix, in the same order and with the same verdict as the classic.** If the two
  formats disagree, one of them is wrong and is fixed **before** delivering.
- **Issue/Solution:** tell both halves: *"On `master` the same request returns …; on the branch it returns
  …"*.
- If something did not go as expected (a slow backend, a forced prerequisite, expired data), say it **in one
  sentence**, not in a section.
- **Left out:** internal analysis, code, file lists, discarded alternatives. Those belong in the classic
  main `.md` and in the PR.
- **Each TC section must paste as is into the Evidence cell** of the Jira subtask (images uploaded with
  it). Publishing to Jira is done by the developer.

### 3.4 Execution captures: **both sources**

Tool: [`newman-evidence.mjs`](newman-evidence.mjs). It runs **the TC's folder** of the collection with
**newman** (Postman's CLI runner: the `User-Agent` is `PostmanRuntime/7.39.1`) and writes, into
`captures/postman/`:

| File | What it is |
|---|---|
| `{TICKET}_{TC}_00_newman-summary.png` | run summary: requests, assertions, failures |
| `{TICKET}_{TC}_{NN}_{request}_newman.png` | **one per request**: method, URL, headers, response, `pm.test` in green/red |
| `{TICKET}_{TC}_{NN}_{slug}_card.png` | **readable card** per check (from `cards.json`): Expected/Got, highlighted fragment, PASS/FAIL, code under test @ SHA, time |

```bash
cd tools/evidence
node newman-evidence.mjs --collection "<the ticket's collection or the canonical one>" \
  --environment "<api-repo>/docs/Postman/VB.Generic.Api_Local.postman_environment.json" \
  --folder "TC01 …" --ticket API-XXXX --tc TC01 --cards cards.json \
  --out "<evidence-root>/API-XXXX/captures/postman"
# re-render without running again (e.g. to fix a card):
node newman-evidence.mjs --from-run .runs/API-XXXX/<stamp>-TC01 --ticket API-XXXX --tc TC01 --cards cards.json --out <same dir>
```

`cards.json`, one object per check:
`{ "request": "<request name>", "title": "…", "subtitle": "…", "expected": "…", "got": "…", "excerpt": ["data.journeys[0].status", "data.passengers[?type=EXST]"] }`.
Excerpt paths: `a.b`, `a[0]`, `a[*]`, `a[?key=value]`.

- 🔴 **`report.html` and `run.json` stay in `tools/evidence/.runs/`** and are **private** (git-ignored):
  they carry tokens and full bodies. **Only the PNGs** go to the evidence folder.
- Requests whose name matches `/login|token/i` get their **request and response hidden** in the report
  (htmlextra `hideRequestBody` / `hideResponseBody`, the same options as `run-tc.sh`) and on the card. Any
  other request with sensitive data: `--hide-body "<name>"`. On the card, keys matching
  `password|token|secret|cvv|cardNumber` are masked automatically.
- 🐛 **Fixed 2026-09-24 (API-1682): the sensitive-key regex was hiding `passengers`.** It was
  `/pass(word)?|token|…/i`, **unanchored**, so it masked every key that *contains* "pass": `passengers`,
  `passengerKey`, `passport` — exactly what any booking ticket tests. It is now
  `/^pass$|password|passwd|token|secret|cvv|cvc|cardnumber|^pan$/i`. **Look at every card before using
  it** — that is how this one was found.
- 🔑 **Both formats come from the SAME run** (lesson from API-1682). dotREZ test inventory changes during
  the day: the same search gave 11 fares in the morning and 8 in the afternoon, with other amounts. If the
  classic comes from one run and the story from another, the numbers disagree and the reviewer sees two
  truths. Recipe: run newman, convert its `run.json` into the classic raw files
  ([`run2capture.py`](run2capture.py)) and build the classic captures from there. An earlier run made with
  another tool is **archived**, not deleted (`tools/new-run.sh`).
- The body in the newman capture is cut to **40 lines** (`--max-lines`) with a visible note saying how many
  it had. The card shows only the fragment.
- The card footer says **which code ran**: `branch @ sha`, plus `+ uncommitted changes` when the working
  tree is dirty.
- 🔑 **Why not the Postman app:** Playwright does not drive it reliably, and it runs with the user's
  account syncing to the cloud. If EZY ever asks for captures of the Postman UI as is, those are taken by
  hand; newman runs the same collection with the same engine.
- **EZY ideas to adopt in the ticket's collections** (when the ticket asks to update Postman): `pm.test`
  names that narrate (`RESULT: …`, `NO REGRESSION: …`) — they show as is in the capture and on the card —
  and the `00 - Setup` / `TCnn` / `99 - Teardown` folders, with config snapshot and restore.
- **Admin Portal:** §2, with `--caption auto` for the banner on top, like API-1902's.

**Verified** (2026-09-24, folder `1. Resources` of the canonical collection v7.160 against the local API):
4 requests, 8 assertions, summary capture + 4 per request + 2 cards. A **42,154-line** body (stations) was
cut to 40 with the note. Re-rendering from a saved run takes ~11 s. Three traps solved in the script:
- the report loads Bootstrap / jQuery / highlight.js **from a CDN** and the network was dropping them
  (`ECONNRESET`), so they are copied into [`vendor/`](vendor/) and Playwright serves them from there;
- highlight.js colouring 42,000 lines **froze** the page, so blocks are cut **before** it runs (init
  script);
- each request sits inside a closed **folder collapsible** and a 350 px `div.dyn-height`, so both are
  opened.

## 4. **One card per test case** — what actually gets attached (API-1901, 2026-09-25)

> 🔴 **Rule.** What gets attached to Jira is **one self-contained image per test case**. Neither the
> classic `.md` (270–580 KB, 8 to 24 steps) nor the step-by-step series of captures work as attachments:
> they cannot be uploaded comfortably and the reviewer does not read them. *"Everybody knows how to log
> in"* — the setup steps (login, search, basket, journeys, bundles) **are not evidence**, they are plumbing
> identical in every case, and they live in the full log. The card carries **only the request that decides
> the case**.

Tool: [`evidence-card.mjs`](evidence-card.mjs). It reads **the classic raw files** (the
`### NN-step` / `**curl (Request)**` / `**Response**` format already written) and renders one PNG per case,
so the card **never drifts** from the capture: if a number changes, it is because the run changed.

```bash
cd tools/evidence
node evidence-card.mjs --spec "<evidence-root>/API-XXXX/cards.json" \
  --out "<evidence-root>/API-XXXX/captures/test-cases"
```

At a glance the card shows: the **PASS/FAIL** verdict, **Expected/Got**, the **Admin Portal configuration
under test** (key → value table: the first thing the reviewer asks for), the **isolated `curl`** with the
`Bearer` redacted and `number` / `cvv` / `storedPaymentKey` masked, the **response trimmed** to the paths
that prove the case, a note on why it matters, and the `branch @ sha` footer.

- 🔑 **One case, one card, every endpoint.** If the ticket touches several endpoints, there is **one card
  per endpoint and per direction** — accepted *and* rejected. API-1901 had 11: `methodsavailable` × 7,
  `selectmethod` × 2, `process` × 2. A rejection only means something **next to an acceptance** with the
  same config: same call, same bank, same instalment, accepted when a criterion matches and rejected when
  none does.
- 🔑 **`verdict: PASS` with HTTP 400 is correct** when the case expects the rejection. Expected/Got
  explains it; the badge belongs to the *test case*, not to the status.
- A TC run with newman is converted to the raw format with [`run2capture.py`](run2capture.py)
  (`run.json` + request name → classic `.md`) and goes through the same renderer, so **every card of the
  ticket looks the same** whether it came from newman or by hand.
- 🔑 **The raw file is a contract, not prose.** The parser expects those three markers. Two shapes coexist
  and both are accepted: `**Response** — HTTP \`400\` in \`1150 ms\`` and the bulleted
  `- HTTP \`200 OK\`` / `- Duration: \`3242 ms\``. Changing the raw format breaks the renderer.
- ⚠️ **Links in the classic `.md` rot.** In API-1901 the seven links to `captures/TC*.md` pointed to files
  already moved to `raw/`. Before delivering: check that **every relative link resolves** — and that the
  numbers in the `.md` come from a capture that still exists. Two figures of the headline table came from
  deleted runs and matched no attached file.

**Two tool traps found on the way:**
- 🐛 **`newman-evidence.mjs` only hides `Authorization` when it comes from the collection's `auth` block.**
  htmlextra skips the headers newman marks `system`, and only those injected by the collection-level `auth`
  are. If the token is an explicit request header, the card **prints the whole JWT** and pushes the
  Response panel off the canvas: the card comes out with no evidence. Fix:
  `"auth": {"type":"bearer","bearer":[{"key":"token","value":"{{authToken}}"}]}` at collection level and
  `"auth": {"type":"noauth"}` on the login request.
- 🐛 **`admin-portal.mjs --node` does not work for tabbed arrays** (`banks`, `installments`, `criteria`):
  *"Cannot destructure property 'height' of null"*. The node **is in the DOM** but only the selected item
  is visible, so `boundingBox()` returns `null`. Way out: `shot.mjs --steps` with a JSON flow that **clicks
  the tabs** before capturing, targeting the full `data-schemapath` — see
  [`examples/shot-steps-tabbed-array.json`](examples/shot-steps-tabbed-array.json). To discover the real
  paths: `dump-paths.mjs --prefix cardPayment.banks` — the `--node` error only lists depth-2 nodes.

**So, per ticket:** classic (§1, as always) + `{TICKET}-evidence-story.md` +
**`captures/test-cases/*.png` — one card per TC, what gets attached** + `captures/postman/*.png` +
`captures/admin-portal/*.png` when it applies (§2).

## 5. Evidence is asked for **per endpoint**, with the config in view (review of API-1901)

The same review asked, verbatim, for captures of **the configuration changes in the Admin Portal**, the
**response of `/payment/methodsavailable`**, and in particular *"the response or error message received when
attempting to use an installment option that is disabled by an SSR in `/payment/process`"* — and for **all
three endpoints** (`methodsavailable`, `selectmethod`, `process`) to be tested, each with its capture and
its result.

🔑 The takeaway: **covering the behaviour is not covering the surface**. The original delivery proved the
business logic end to end, but ordered it by *business case*, and the reviewer reads it by *endpoint*. When
a change cuts across several endpoints — the typical single-resolution-point case — the evidence carries
**one card per endpoint and per direction** (accepted and rejected), even when the code is the same for
all three. Format: §4.
