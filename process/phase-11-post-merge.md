# Phase 11 — Post-merge, verification and closure

> **Question it answers:** did it work in production and is the loop closed?
> **MANDATORY step with the LLM repo:** on merge, the code changed ⇒ the ApiLLM docs are stale by
> definition. **Invoke the ApiLLM's sync pipeline** (its `CLAUDE.md` step 1 / `llm/SYNC.md`, the
> `doc-sync` agent) to re-document what was altered (endpoints, contracts, rules, error codes,
> dependency-map edges) and publish. This repo NEVER edits `documents/**` directly — it is
> protected by the ApiLLM's hooks and manual changes are auto-discarded.
>
> **Two operational facts, because getting them wrong loses the work:**
> 1. **Commit and push the sync in the same run.** The ApiLLM's `repo-guard.sh` discards (stashes)
>    uncommitted `documents/**` changes at the start of every ApiLLM session, and its `SYNC.md` §4
>    is explicit that an unpublished sync is an unfinished one — publishing is what stops the next
>    run from redoing the work. A sync left dirty in that tree is a sync thrown away.
> 2. **The publication signature does not apply here.** `work/<KEY>/PUSH-APPROVED` gates publishing
>    to the **API repo** (Phase 10 §10.0), and the hooks scope it to that repo by name. Publishing
>    the docs sync needs no user approval — `SYNC.md` §4 says to run it and publish it without
>    asking. Do not self-block; do not ask.

**Goal:** confirm in reality and close the learning loop. Without this phase, the process does not
improve.

1. **Verify the deployment** in every environment it passes through; run the runbook's smoke test.
2. **Run migrations and backfills** per the runbook, verifying counts and consistency.
3. **Turn on the flag progressively** (internal → small % → full), verifying metrics at each step.
4. **Monitor actively** during the defined window (the first hours and the first full
   daily/nightly cycle, including the batch jobs).
5. **Verify the business metrics**, not just the technical ones: is the user doing what was
   expected?
6. **Re-document via the ApiLLM** (see the header): run the sync, verify that the anchor in
   `documents/_meta/sync-state.md` advanced to the new HEAD and that it was published.
7. **Close the ticket** with evidence and notify whoever requested it.
8. **Clean up:** remove the feature flag and the dead code (the ticket already exists from
   Phase 5), remove old columns/fields after the grace period, close the *contract* phase of the
   migration.
9. **Create/prioritize the debt tickets** detected along the way.
10. **Retro on the process:** in which phase should what was detected late have been detected? That
    is the adjustment to the process (a change in this repo's `process/`), not a reprimand for the
    person.
11. **Share the learning:** ADR, message to the team, update to the template or the checklist.
12. **Feed the review bar:** every human review finding from Phase 10 that no `STY`/`ARC`/`ROB`/`PRC`
    rule covered (the list built in §10.2.9) is a **candidate rule** for the LLM repo. It never
    enters from here, and never from an AI review alone: hand it to the ApiLLM's own procedure
    (`../VivaAerobus.Generic.ApiLLM/guidelines/CLAUDE.md` + `guidelines/README.md` — new ID, the
    four fields, `source` citing reviewer + `#PR`). Candidates without PR evidence are dropped, not
    argued. This is the loop that keeps Phase 9 reviewing against what the team actually enforces.

---

**Artifacts:** smoke test and monitoring evidence, ApiLLM docs re-synced and published, ticket
closed, debt/cleanup tickets created, process adjustment if applicable, guideline candidates handed
to the ApiLLM.

**Exit criterion:** change verified in production, ApiLLM docs anchored to the new HEAD, learning
loop recorded.
