# Phase 1 — Contrasting the request against the real code

> **Question it answers:** what exists today in reality?
> **MANDATORY support from the LLM repo — in this order:**
> 1. **Sync first**: run step 1 of `../VivaAerobus.Generic.ApiLLM/CLAUDE.md`
>    (`llm/SYNC.md`). If the docs end up/are stale, reason from the code and **say so explicitly**
>    in the output.
> 2. Locate the code via `documents/concepts/_catalog.md` → the concept doc →
>    `documents/integrations/_catalog.md` if an external service is involved.
> 3. Apply `llm/ANALYZE-TASK.md` phases 0–2 (restatement, channel/flow/version classification,
>    clarity gates) as part of this phase.
> 4. **If an LLM doc contradicts the code or is incomplete:** that is a finding — report it and
>    **invoke the ApiLLM `doc-sync` pipeline** to fix it. It is never documented here.

**Objective:** close the gap between what the ticket *assumes* exists and what *really* exists.
This is the phase that prevents the most rework.

## 1.1 Locate the code involved

1. **Find the entry point**: endpoint, handler, command, job, listener, screen, component.
2. **Trace the full flow** from the entry point to persistence and back:
   controller → service → repository → database → response → client.
3. **Identify all layers involved** and which repositories they live in (is it a single repo or 3
   services?).
4. **Look for duplications**: the same logic implemented in two or three places (very common: web +
   mobile + batch, or a copy in a legacy service). If they exist, all of them are in scope or an
   explicit decision must be made that they are not.
5. **Identify nearby "dead or nearly dead code"**: things that look relevant but no longer run.
   ⚠️ In this API there are files present but **excluded from compilation**
   (`<Compile Remove>` in the `.csproj`) — never assume a file in the tree is active
   (see `llm/ANALYZE-TASK.md` §Phase 4, "Build traps").

## 1.2 Understand the current behavior

1. **Read the code, don't guess it.** Also read the existing tests: they are the real specification
   of the current behavior.
2. **Run it locally** and observe the current behavior with real or realistic data (setup in
   `documents/operations/local-setup.md` of the LLM repo).
3. **For bugs: reproduce first.** If you can't reproduce, you can't fix. If it doesn't reproduce,
   that is already a finding that goes to Phase 4.
4. **Document the current behavior** in 3–5 bullets **with citations** (`path/File.cs :: Symbol`).
   This becomes the baseline against which the "after" is defined.
5. **Identify undocumented behaviors someone depends on** (side effects, execution order,
   tolerances, response formats).

## 1.3 Archaeology: why it is the way it is

1. `git log` / `git blame` on the relevant lines. Find the original commit and its message.
2. From the commit → to the PR → to the ticket → to the discussion. Many oddities have an explicit
   reason.
3. Look for comments in the code like `// don't change this because...`, `HACK`, `WORKAROUND`,
   `TODO`.
4. Look for ADRs (Architecture Decision Records) or module design documentation (in the LLM repo:
   `documents/architecture/**`).
5. **Rule:** if something looks absurd and you can't find the reason, assume there is a reason you
   don't see and ask. The default option is not "I'll fix it".

## 1.4 Discrepancy detection (the key output of this phase)

Compare ticket vs. reality and classify:

| Discrepancy type | Example | Action |
|---|---|---|
| Already implemented | The ticket asks for something that already works | Verify and close / reclassify as a configuration bug |
| Partially implemented | 60% exists, the rest is missing | Adjust scope and estimation |
| Exists but in another form | The field has a different name, the flow is different | Adjust the ticket description |
| The precondition does not exist | The ticket assumes a table/service/permission that isn't there | **Blocker or new dependency** |
| The ticket contradicts the current design | What is requested breaks a system invariant | **Design blocker** |
| Impossible as requested | Real technical limitation | **Blocker; bring alternatives** |
| Costs 10x more than estimated | Due to coupling or debt | Re-estimate and renegotiate scope |
| The ticket assumes a stub is functional | Endpoints that return empty despite what Swagger promises (`documents/concepts/_catalog.md` §Known implementation gaps) | **It is greenfield, not a modification** — say so |

---

**Artifacts:** `work/<KEY>/phase-01-contrast.md` — a "current state vs. requested" note with the
discrepancy table, everything cited, opening with the docs' sync status.

**Exit criterion:** zero assumptions about the code; everything asserted was verified by reading or
running it, with a citation.

**Next:** [Phase 2 — Impact radius](phase-02-impact-radius.md)
