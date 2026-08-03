# Phase 7 — Testing

> **Question it answers:** does it work, and did I not break the impact radius?
> **Support in the LLM repo:** `documents/operations/testing.md` — the real coverage map. Where
> coverage is **absent** (Basket, Booking, Checkin, Irop, Train, Transfer, Vehicle, Admin,
> Internal, integration clients), writing the tests **is part of the scope**, not a follow-up.
> ⚠️ Several flows depend on **external test systems** (DotRez, PSPs, Hopper, TrenMaya…) —
> "testable" is not an assumption, it is verified.

**Objective:** demonstrate that the new work functions **and** that nothing in the impact radius
broke. Phase 2 defines exactly what must be tested here — it is the same list, and the plan's
**numbered `S-NN` scenarios (Phase 5) are the mandatory coverage matrix**: every row gets
executed or a written justification of non-applicability; a missing row is a gap.

## 7.0 GenericApi test ladder — validate the run first, then climb

The environment is proven **in this order** (each step invalidates the next when skipped);
specifics in the LLM repo's `llm/testing-scripts.md`:

1. **Build**: `dotnet build … -c Release` → 0 errors. 2. **API answers** locally.
   3. **Swagger renders** (routing/startup finished — eyeball the changed contract there).
4. **Seed config when the ticket touches an Admin config part**: the local seeder is
   create-only — apply the value with `docker\seed-marten-document.ps1 … -FlushRedis` **and
   restart the API** (two cache layers; L1 is in-process). A config change that skips this looks
   "not applied" and poisons every later result.
5. **Happy-path smoke** (`scripts\run-happy-path-smoke-tests.ps1`): a broken baseline makes every
   later failure ambiguous.

Then the ladder: **xUnit first** — a matrix row marked `[Automated]` requires an xUnit test **in
the PR** (a PS1 runner or Postman collection does not satisfy it) → **PS1 runner**
(`run-api-<ticket>-<slug>-tests.ps1`, iterate to green) → **Postman collection + newman run**
(built only after PS1 is green; `docs/Postman/**` is tracked — **no credentials in it**) →
**prove causation**: run the case on the base commit too; evidence pairs are `Issue`(base)/
`Solution`(branch) per PRC-104.

## 7.1 Test levels

1. **Unit:** business logic, conditional branches, pure functions, transformations. Fast and with
   no external dependencies.
2. **Integration:** data layer against a real database (container), transactions, queries,
   migrations, serialization, integration between modules.
3. **Contract:** that the request/response complies with the agreed schema; contract tests with
   the consumer if they exist.
4. **End-to-end / flow:** the user's complete journey through the main paths.
5. **Manual exploratory:** what no automated test sees. Use the product as a user, trying to
   break it.
6. **Regression over the impact radius:** explicitly test **every element of the matrix** from
   Phase 2, not just what you changed.

## 7.2 What to test (cases)

- **Happy path** of every acceptance criterion (one by one, with the criterion in view).
- **Negative cases:** invalid inputs, missing inputs, wrong types, out-of-range values.
- **Edges:** zero, one, many, the maximum, the maximum+1, empty, null, empty string, very long
  strings, special characters and emojis, boundary dates, month/year rollover, time zones,
  daylight saving time.
- **Authorization:** **every existing role**, including the user without permissions and the user
  from another tenant/client. Direct access to the endpoint bypassing the UI.
- **Resource states:** nonexistent, deleted (soft delete), archived, in progress, already
  processed. ⚠️ In this API: Basket states (Active/Passive/Expired, two independent clocks).
- **Concurrency:** two simultaneous requests, double click, double delivery of the same event,
  parallel execution of the same job. ⚠️ Verify the interaction with `BOOKING_WAS_MODIFIED`.
- **Idempotency:** run the same operation twice and verify the result is not duplicated. Critical
  in payments and check-in.
- **Dependency failures:** external service down, slow (timeout), returning an error, returning
  garbage.
- **Legacy data:** old records in the old format, historical nulls, real inconsistent data.
  ⚠️ Marten documents stored before the change.
- **Version compatibility:** old client against new server, and **new client against old server**
  (this is what blows up during deployment and rollback).
- **Feature flag:** off (previous behavior intact) and on (new behavior), and the hot switch
  between the two.
- **Performance:** number of queries per request (detect N+1), execution plan of the new queries,
  time under realistic volume, response size.
- **Security:** injection, XSS, IDOR (changing the id in the URL), sensitive data in the response
  and **in the logs**, rate limits.
- **UI:** supported browsers and versions, mobile/tablet/desktop, loading, empty, error and
  partial states; accessibility (keyboard, focus, contrast, screen reader); i18n in every
  supported language.
- **Migration:** apply it, verify the data, **revert it**, apply it again; measure duration over a
  production-like volume; verify the backfill is resumable.

## 7.3 Test hygiene and validation

1. **Verify that the tests actually fail without the change** (invert the fix and see the red). A
   test that always passes proves nothing.
2. **Deterministic tests:** no dependence on the real clock, execution order, the network or
   shared data. Zero new flaky tests.
3. **Coverage with judgment:** cover the risky branches, don't chase a percentage. No critical
   path without a test.
4. **Run the full suite**, not just the tests you wrote (that is where regressions show up).
5. **Review the complete pipeline in CI**, not just locally (environment differences, time zone,
   locale, ordering).
6. **Test in a production-like environment** (staging) with realistic data and configuration
   before calling it done.

## 7.4 Handoff to QA

1. Deliver **test notes**: what changed, what to test, how to reproduce, test users/data, what did
   NOT change but is worth looking at (the impact radius), known risks, assumptions pending
   validation.
2. Attach evidence: screenshots, video of the flow, sample responses.
3. Define the flag's state during QA testing.
4. Fix cycle: every defect found → fix → **add a test that covers it** → re-test the complete
   flow, not just the defect.
5. Record QA and PO approval (functional acceptance) in the ticket.

---

**Artifacts:** automated tests, evidence of manual testing, notes for QA, performance/migration
results, and `work/<KEY>/phase-07-testing.md` (skeleton:
`process/_templates/validation-report.md`) — it MUST contain the literal line `TESTS: GREEN`
at column 0 (the hooks read it: without it, `git push` / `gh pr create` stay blocked), followed by
the evidence: the full-suite run output (command + summary), the **numbered scenario matrix**
(`S-NN → test executed → result`, every plan row present), and the impact-radius regression
notes. ⚠️ The line is written **only after the FULL suite actually ran green** — recording it
without running the suite is falsifying the gate. On rework, `tools/new-run.sh <KEY>` archived
the previous artifact into `validation/run-NNN/` — never edit an archived run.

**Exit criterion:** all acceptance criteria verified with evidence, impact radius tested, CI
green, zero open high-severity defects.

**Next:** [Phase 8 — Release preparation](phase-08-release.md)
