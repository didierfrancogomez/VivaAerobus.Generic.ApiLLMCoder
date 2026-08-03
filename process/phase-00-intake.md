# Phase 0 — Intake and ticket comprehension

> **Question it answers:** what am I really being asked for, and why?
> **Support from the LLM repo:** `../VivaAerobus.Generic.ApiLLM/documents/concepts/_catalog.md` to
> resolve domain terms (one line per concept — do not open the full doc if the catalog answers).

**Objective:** understand the *intent* behind the ticket, not just its text. A ticket is an
imperfect summary of a conversation that already happened.

## 0.1 Reading and classification

1. **Read the entire ticket**, including: description, acceptance criteria, comments (all of them,
   in chronological order), attachments, links, custom fields.
2. **Read the ticket's change history** (Jira: *History* tab). Changes in scope, estimation,
   priority or assignee are signals of undocumented discussion.
3. **Classify the type of work**, because it determines the rigor of the rest of the process:
   - Bug (with or without data impact)
   - Hotfix / production incident → *compressed path*, see [Annex B](annex-b-hotfix.md)
   - New feature
   - Modification of existing behavior
   - Refactor / technical debt (no observable behavior change)
   - Spike / investigation (the deliverable is knowledge, not code)
   - Data or infrastructure migration
   - Configuration change

   Also assign the **rigor level** (trivial / normal / risky) according to the table in
   `../CLAUDE.md` and write it in the ticket.
4. **Identify the "why"**: what business or user problem it solves. If you cannot explain it in one
   sentence without using technical terms, you do not understand it yet.
5. **Identify the affected actors**: which user role, which customer segment, which internal team,
   which external system.
6. **Identify the expected observable outcome**: how will someone other than you know this is done?
   If the answer is not in the ticket, that is a gap.

## 0.2 Verify the ticket is ready (Definition of Ready)

Minimum checklist. If anything fails, the ticket **should not be in progress** — it goes back or
gets completed via Phase 4.

- [ ] It has a description of the problem, not just of the proposed solution.
- [ ] It has explicit, verifiable, unambiguous acceptance criteria.
- [ ] It has design/mockups attached if there is a UI change (and they are up to date, not an old
      version).
- [ ] It has the API contract defined or a link to it, if applicable.
- [ ] It has test data, concrete examples or real cases (for bugs: reproduction steps +
      environment + user + timestamp + evidence).
- [ ] It has dependencies identified along with their status.
- [ ] It is estimated / sized and fits in the sprint.
- [ ] It has a priority and an identifiable business owner (who do I ask).
- [ ] The scope is delimited: it also says **what it does NOT include**.
- [ ] There is no ambiguity in domain terms (e.g.: "active user" — active according to which
      definition?). Check the term against `documents/concepts/_catalog.md` in the LLM repo before
      asking about it: if the catalog defines it with a citation, it is not an ambiguity.

## 0.3 Distinguish the literal request vs. the real need

1. **Separate the "what" from the "how"**. Many tickets come written as a solution ("add a field X
   to table Y"). Reconstruct the original problem.
2. **Ask for the concrete use case**: "in what real situation does a user need this?"
3. **Look for the simplest solution that solves the real problem** — it may be different from the
   proposed one and much cheaper.
4. **Detect XY problems**: they ask for X because they believe it solves Y; sometimes X does not
   solve Y, or Y is already solved another way.
5. **Record the reinterpretation** in a ticket comment before coding. Never reinterpret silently.

## 0.4 Historical and organizational context

1. Look for **related tickets**: same component, same keywords, same epic, same reporter.
2. Look for **duplicate or already-resolved tickets**.
3. Look for whether **it was attempted before and reverted** (this is gold: there is a documented
   reason why it failed).
4. Identify the **epic/initiative** and where this ticket fits in it: is it the first of a series?
   the last? does it enable others?
5. Identify **who else is touching that area of the code right now** (to avoid conflicts and
   duplicated work).

---

**Artifacts:** create `work/<KEY>/` and write the key into `work/_active`; save
`work/<KEY>/phase-00-intake.md` (restated understanding + initial list of doubts + classification
of work type and rigor level — if the level is *risky*, also create
`work/<KEY>/HUMAN-GATE-REQUIRED`); publish the same content as a comment on the ticket.

**Exit criterion:** you can explain out loud the problem, the expected outcome, who asked for it
and why, without reading the ticket.

**Next:** [Phase 1 — Contrast against the code](phase-01-code-contrast.md)
