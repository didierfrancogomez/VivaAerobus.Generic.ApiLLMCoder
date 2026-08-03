<!-- MOVED HERE from VivaAerobus.Generic.ApiLLM/llm/ — this file is Coder process methodology.
     Paths like documents/**, guidelines/**, llm/SYNC.md remain RELATIVE TO THE ApiLLM REPO ROOT
     (../VivaAerobus.Generic.ApiLLM/). Knowledge and guidelines stay there; only the procedure moved. -->

---
module: change-playbook
type: architecture
last_reviewed_commit: 1311864e
---

**Summary:** **STEP 3 of the pipeline** (`../CLAUDE.md`). Turns an **already-approved** analysis into
a safe implementation. Runs only after `ANALYZE-TASK.md` returned verdict **✅ Ready to implement**.

> Prerequisites — do not start without them:
> 1. `SYNC.md` completed (docs match the code repo's `master` HEAD, and are published).
> 2. `ANALYZE-TASK.md` produced a **✅** verdict — objective, contracts, acceptance criteria and
>    impact are defined, and blocking questions are answered.
>
> If the verdict is ⚠️ or ⛔, **stop**: go back to `ANALYZE-TASK.md`, don't plan or code.
>
> Bound by the evidence rule (`../CLAUDE.md §Non-negotiable`): reason only from cited facts. An
> `unverified` doc line must be confirmed in code **before** it can carry weight in a plan.

## Steps

1. **Re-read the approved analysis.** Carry over its classification (code vs config, channels/flows,
   versions, source of truth) and its impact list — do not re-derive them from scratch.
2. **Confirm the load-bearing facts in code.** For every doc line the plan depends on, open the cited
   file and verify it still says what the doc says. Patch the doc if it drifted (that is a `SYNC.md`
   step-6/7 update, including the anchor).
3. **Write the implementation plan**, with citations:
   - files to create/modify, and **where** each piece goes per
     `../documents/architecture/conventions.md` (controller, handler, models, output builders, validators) and
     `../documents/architecture/patterns-cqrs.md`;
   - the **normative rules the code must comply with**: `../guidelines/README.md` → the relevant
     `STY`/`ARC`/`ROB`/`PRC` items. These are the bar the human reviewers apply; cite the rule IDs
     the plan must honor (a plan that violates a 🐛/❗ rule is not ready);
   - config parts to add/change (`../documents/_meta/flags-and-rules.md`) — remember these ship **without a
     deploy**;
   - error codes to add (never repurpose an existing one — see `../documents/cross-module/error-codes.md`);
   - the **kill switch** (flag/config) when the change is risky enough to need one.
4. **Plan the tests explicitly.** Check `../documents/operations/testing.md`: where coverage exists, extend it;
   where it is absent (Basket, Booking, Checkin, Irop, Train, Transfer, Vehicle, Admin, Internal,
   integration clients) **writing tests is part of this change**, not a follow-up.
5. **Plan for the failure paths**, not just the happy one: partial failure (no transaction boundary
   across multi-step handlers), retries/idempotency, concurrency (`BOOKING_WAS_MODIFIED`), and
   async side effects that fail silently (enqueued insurances/child-companion/comments, dispatcher
   notifications, confirmation email).
6. **Plan the rollout**: environments/sub-environments, cache invalidation if reference data or
   config is involved, coordination with front-end/partners/vendor, and what to observe in production
   (log/metric/trace) to know it actually works.
7. **Implement**, keeping changes scoped to the plan. If implementation reveals something the
   analysis missed, **stop and return to `ANALYZE-TASK.md`** instead of improvising.
8. **Verify before declaring done**: run/extend the tests, re-check each cited claim, and run the
   review gate (`REVIEW-CODE.md`) on the diff — the verdict must be **APPROVED** (any 🐛/❗ finding
   blocks). For high-risk changes, also run an independent verification pass (subagent) against
   the code.
9. **Update the docs** for whatever the change altered (endpoints, contracts, rules, error codes,
   dependency edges) and publish per `SYNC.md` §4.

## Output

A cited implementation plan → the implementation → updated tests → updated docs, published.

> Never invent a missing requirement to keep moving. Anything undefined goes back through
> `ANALYZE-TASK.md` as a question.
