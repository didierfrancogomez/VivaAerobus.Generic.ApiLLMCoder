# Phase 7 — Testing

> **Question it answers:** does it work, and did I not break the impact radius?
> **Support in the LLM repo:** `documents/operations/testing.md` — the real coverage map. Where
> coverage is **absent** (Basket, Booking, Checkin, Irop, Train, Transfer, Vehicle, Admin,
> Internal, integration clients), writing the tests **is part of the scope**, not a follow-up.
> ⚠️ Several flows depend on **external test systems** (DotRez, PSPs, Hopper, TrenMaya…) —
> "testable" is not an assumption, it is verified.

**Objective:** demonstrate that the new work functions **and** that nothing in the impact radius
broke. Phase 2 defines exactly what must be tested here — it is the same list.

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
results.

**Exit criterion:** all acceptance criteria verified with evidence, impact radius tested, CI
green, zero open high-severity defects.

**Next:** [Phase 8 — Release preparation](phase-08-release.md)
