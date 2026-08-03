# Phase 5 — Planning and design

> **Question it answers:** how am I going to do it, in what order, with what risks?
> **Precondition:** verdict ✅ from the gate (Phase 4). With ⚠️/⛔ this phase is NOT executed.
> **MANDATORY support in the LLM repo:**
> - [`process/change-playbook.md`](change-playbook.md) steps 1–6 — re-read the approved analysis, confirm the load-bearing
>   facts in the code, plan with citations, where each piece goes
>   (`documents/architecture/conventions.md`, `patterns-cqrs.md`), new error codes (never
>   reuse — `documents/cross-module/error-codes.md`), kill switch.
> - `guidelines/README.md` + categories `STY`/`ARC`/`ROB`/`PRC` — **normative (GOLDEN RULE,
>   `../CLAUDE.md` rule 5)**: the plan cites the
>   rule IDs it must honor; a plan that violates a 🐛/❗ rule is not ready.
> - `documents/operations/testing.md` — where coverage exists and where it doesn't; **where there
>   are no tests, writing them is part of this change's scope, not optional**.

**Objective:** decide *how* before typing, and leave it written down and validated. Planning ends
when the implementation is mechanical and boring.

## 5.1 Solution design

1. **Generate at least two solution options.** If you can only think of one, you haven't thought;
   you've remembered.
2. **Compare with explicit trade-offs:** effort, risk, reversibility, performance,
   maintainability, debt it creates or removes, impact on the team.
3. **Choose and justify.** Default criterion: the simplest solution that meets the acceptance
   criteria and does not close future doors.
4. **Record an ADR** if the decision is structural, hard to reverse, or affects other teams.
5. **Design the boundaries, not just the center:** what happens with empty, null, maximum,
   negative, duplicate, concurrent, out-of-order inputs, with insufficient permissions, with the
   external service down.
6. **Contract-first design:** define and agree on the contract (request/response/errors/events)
   *before* implementing, and share it with the consumers so they can work in parallel.

## 5.2 Mandatory specific plans

Each one is a short section written in the ticket, not a thought:

1. **Data/migration plan:** DDL, expand–contract strategy (add → write to both →
   migrate data → read from the new one → remove the old one), reversibility, estimated duration
   over real volume, required window.
2. **Backward-compatibility plan:** how old and new coexist during the deployment and during the
   grace period for old clients. Include **in-flight sessions**: baskets/bookings created before
   the change that are processed after it.
3. **Feature flag plan:** name, default value (off), scope (global / per client / by percentage),
   who turns it on, criterion for turning it on, and **cleanup ticket created from day one**. In
   this system the natural kill switch is the Admin Portal config parts
   (`documents/_meta/flags-and-rules.md`).
4. **Observability plan:** which logs (with which structured fields and no PII), which metrics
   (counters, latency, error rate), which traces, which alerts and at what threshold, which
   dashboard shows whether this works.
5. **Test plan** (written before coding): what is tested at the unit level, what at integration,
   what at contract, what e2e, what manually, what test data is needed, which negative and edge
   cases. The acceptance criteria are converted one-to-one into test cases. ⚠️ **Both the
   implementation steps and the test scenarios are NUMBERED with stable ids** (`P-NN` / `S-NN`,
   template: `process/_templates/plan.md`): Phase 7 executes against the `S-NN` list row by row,
   and Phase 9's `COMPLETENESS: VERIFIED` is earned by auditing both lists one-to-one — an
   unnumbered plan cannot be audited. If the ticket carries a test-case matrix (evidence
   subtask, §0.0), the `S-NN` list subsumes it: every live matrix row maps to an `S-NN`.
6. **Rollout and rollback plan:** how it is deployed, in what order, how it is verified, how it is
   reverted, what the kill switch is, what is irreversible (⚠️ destructive migrations, email
   sends, charges, published events).
7. **Non-functional budget:** maximum acceptable latency, maximum number of queries per request,
   maximum payload size.
8. **Security and permissions plan:** which roles can do what, where it is validated (always on
   the server), what data is exposed.

## 5.3 Work breakdown

1. **Split into deliverable steps** of ideally less than half a day each, every one leaving the
   system working (green) and meaningful on its own.
2. **Vertical slices, not horizontal:** "complete endpoint for case A" is better than "all the
   repositories for all the entities".
3. **Define the order:** first what reduces the most uncertainty (the riskiest or most unknown
   goes early, not at the end).
4. **Separate into distinct PRs:** preparatory refactor | migration | functional change | cleanup.
   Mixing them makes review impossible and rollback dangerous.
5. **Explicitly define what will NOT be done** in this work (anti-scope).
6. **Record risks** with probability, impact and mitigation or plan B.
7. **Update the estimate** with what has been learned and communicate if it changed.

## 5.4 Plan validation (design review)

1. Share the plan (10–15 min or in writing) with the tech lead and with whoever owns the impacted
   code.
2. Goal of the review: find missing elements of the impact radius and simpler alternatives.
3. Adjust the plan with the feedback and leave the approval on record.
4. Confirm with QA that the test plan is sufficient, and with the contract's consumer that the
   contract works for them.
5. Confirm with the PO that the expected outcome is the one they want (especially if there was a
   reinterpretation in Phase 0.3).

---

**Artifacts:** `work/<KEY>/phase-05-plan.md` — design document, ADR if applicable, test plan,
rollout plan, list of steps, risk log, updated estimate — all with citations and with the
`guidelines/**` IDs the code will have to honor. The plan is the **contract against which
deviations are audited in Phase 9**: it ends with a `## Deviations (approved)` section, initially
empty. Any deviation that appears later (Phase 6/9) is either (a) approved by the user and
appended there — what changed, why, who approved, when — or (b) not approved, in which case the
work goes back to Phase 4/5. A deviation that is neither documented nor approved blocks
publication (`DEVIATIONS:` line, Phase 9). If the task is at the *risky* level
(`HUMAN-GATE-REQUIRED`), the human approves the plan by creating `work/<KEY>/HUMAN-GATE-OK`
by hand — the agent never creates that file.

**Exit criterion:** the plan is approved and you could hand it to another person on the team to
implement it.

**Next:** [Phase 6 — Implementation](phase-06-implementation.md)
