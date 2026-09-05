# API-1738 — Postman screenshot checklist (rows 1–3 and 10–12; rows 4–9 keep the 2026-09-04 evidence)

Collection to import: `work/API-1738/attachments/API-1738-Display-Passenger-Changes.postman_collection.json` (= the one attached to API-1870 on 2026-09-04 19:35, with ONE fix: TC09 step 02 now asserts the Trips/Add email is **masked** — ticket Part 4 / row 9 / VB #5). Base URL variable `api1738BaseUrl`:
- **Solution** (ticket branch `1e65eb8a3`): `http://localhost:9050` (running, PID 3132)
- **Issue** (master `e004bf9d8`): `http://localhost:9051` (running, PID 25700)

Naming (PRC-104): `API-1738_TC<row>_Issue_<slug>.png` / `API-1738_TC<row>_Solution_<slug>.png`. Capture the Runner result with the evidence request's response open (as in the existing pairs), annotate Issue in red / Solution in green. Save into `work/API-1738/evidence/screenshots/` — that folder is what `deliver --evidence` uploads.

| Row | Collection folder | Run against | Evidence request to open | What the screenshot must show | File name |
|---|---|---|---|---|---|
| 1 | TC01 | 9051 (Issue) | 11 Evidence - GET booking search | rule passes: every field plain (same on both builds — regression guard) | `API-1738_TC01_Issue_RulePassesAllFieldsPlain.png` |
| 1 | TC01 | 9050 (Solution) | 11 Evidence - GET booking search | same, plus assertions "only required email/phone fields are plain" green | `API-1738_TC01_Solution_RulePassesAllFieldsPlain.png` |
| 2 | TC02 | 9051 | 10 Evidence - GET booking full | rule denies: passenger identity fields `***`/null (old behaviour) | `API-1738_TC02_Issue_AllPassengerFieldsMasked.png` |
| 2 | TC02 | 9050 | 10 Evidence - GET booking full | identity fields plain; `contacts[].email`, `phoneNumbers.*`, `passengers[].emailAddress/phone` masked; `user.username` masked (Customer creator) | `API-1738_TC02_Solution_OnlyContactDataMasked.png` |
| 3 | TC03 | 9051 | 09 Evidence - GET booking by basket | Staff-created PNR XEFKMG: identity masked, username plain (old) | `API-1738_TC03_Issue_StaffCreatorIdentityMasked.png` |
| 3 | TC03 | 9050 | 09 Evidence - GET booking by basket | identity plain, contact data masked, `user.username` **plain** (Staff creator) | `API-1738_TC03_Solution_StaffCreatorPlainContactMasked.png` |
| 10 | TC09 | 9051 | 03 Evidence - GET account trips (+ 04 GET account) | linked trip YG4MJQ: `email` **null/plain** (old) | `API-1738_TC10_Issue_LinkedTripEmailExposed.png` |
| 10 | TC09 | 9050 | 03 Evidence - GET account trips (+ 04 GET account) | linked trip `email` masked on both GET /Account/Trips and GET /Account | `API-1738_TC10_Solution_LinkedTripEmailMasked.png` |
| 11 | TC10 | 9051 | evidence GET account | `basket.travelSummary.email` plain (old) | `API-1738_TC11_Issue_TravelSummaryEmailPlain.png` |
| 11 | TC10 | 9050 | evidence GET account | `basket.travelSummary.email` masked | `API-1738_TC11_Solution_TravelSummaryEmailMasked.png` |
| 12 | TC11 | 9051 | evidence GET account trips | genuinely owned trip W8TMQI, rule passes: `email` plain (old) | `API-1738_TC12_Issue_OwnedTripEmailPlain.png` |
| 12 | TC11 | 9050 | evidence GET account trips | rule passes but account endpoints still mask: `email` masked | `API-1738_TC12_Solution_OwnedTripEmailMasked.png` |

Known limitation for row 3: the Staff login (`06 Login as Staff…`) is rejected by DotRez QA on both builds (`nsk-server:Credentials:Failed` for WWW/55162517 — the credentials QA posted on 2026-08-27). The folder continues anonymously and every other assertion passes (creator username plain, contact data masked). If QA cannot restore the account, the evidence is captured as is and the login failure is stated in the delivery comment.

Machine-run reports (newman + htmlextra, PNG renders) for every row and both sides are in `work/API-1738/attachments/evidence-runs/` — they complement, they do not replace, the Postman captures the team expects.
