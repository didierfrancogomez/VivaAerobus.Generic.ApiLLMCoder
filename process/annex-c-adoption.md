# Annex C — How to enable this process in the team (adoption)

You do not roll it out in full on Monday. If you try, the team rejects it as bureaucratic and goes
back to chaos.

## Suggested adoption sequence

**Weeks 1–2: make visible what is already failing.**
Start with what gives immediate results and costs almost nothing:

1. **PR template** in the API repository (`.github/pull_request_template.md`, contents in
   [phase-10](phase-10-pr-review.md)). Zero cost, immediate benefit.
2. **Definition of Ready and Definition of Done** agreed and visible on the board. Rule: a ticket
   that does not meet the DoR is not moved to "In progress" ([phase-00 §0.2](phase-00-intake.md)).
3. **Ticket-as-memory rule:** every decision is written in the ticket, even if it was discussed in
   person.

**Weeks 3–4: introduce the impact radius.**

4. **Mandatory impact matrix** (even if it is 5 rows) before coding, pasted as a comment. It is
   the highest return in this entire document.
5. **10-minute cross-validation** of the matrix with another person. It starts spreading system
   knowledge as a side effect.
6. **Blocking-question format** with options and a recommendation ([phase-04 §4.2](phase-04-blockers.md)).

**Month 2: planning and quality.**

7. **Short design review** (15 min) mandatory for large or risky tickets; optional for small
   ones.
8. **Test plan before coding** (even if it is just a list of cases).
9. **Pre-review checklist** as an individual habit ([annex-a](annex-a-checklist.md)).
10. **PR size limit** agreed by the team.

**Month 3: operations.**

11. **Runbook and rollback plan** mandatory for changes with a migration or coordination between
    services.
12. **Feature flags** with a cleanup ticket created from the start.
13. **Observability as part of the change**, not as a separate task.
14. **Monthly process retro**: what was detected late, and in which phase should it have been
    detected?

## Rules so it does not turn into bureaucracy

- **Scale the rigor to the risk.** A text change needs neither an ADR nor a runbook. The 3 levels
  (trivial / normal / risky) and which steps apply to each are in `../CLAUDE.md`; the criterion is
  made explicit within the team.
- **Every step must have an evidence owner.** If nobody checks that it was done, the step does not
  exist.
- **Automate everything automatable:** linters, formatting, static analysis, commit-message
  validation, templates, CODEOWNERS, validation that the PR references a ticket, secret scanning.
  What a machine can validate must not consume human attention. (Reference for how it is done with
  hooks: `.claude/hooks/` in the ApiLLM repo.)
- **Measure the effect, not the compliance.** Useful indicators: rework due to misunderstood
  scope, defects escaped to production, ticket cycle time, time to first review, rollbacks,
  incidents with an avoidable cause, blocked tickets and for how long. If the process does not
  move those numbers, adjust it.
- **Review the process every month** and prune what adds nothing. A checklist nobody uses is worse
  than not having one, because it teaches that the rules are ignored.
- **One process owner** who maintains and defends it; without an owner, it fades away in 6 weeks.
