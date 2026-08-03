# <Phase 7 Testing | Phase 9 Pre-review>: <KEY> — run-<NNN>

<!-- Skeleton for work/<KEY>/phase-07-testing.md and phase-09-pre-review.md. Immutable-run
     rule: on rework, tools/new-run.sh <KEY> archives the current pair into
     work/<KEY>/validation/run-NNN/ BEFORE the new one is written — evidence history is
     never overwritten. Gate markers at column 0, written only when true. -->

## Execution

| Command / check | Result | Evidence |
|---|---|---|

## Scenario coverage (against phase-05-plan.md, numbered)

| # | Scenario | Test executed | Result | Notes |
|---|---|---|---|---|
| S-01 | | | | |

<!-- Every S-NN from the plan appears here — passed, or justified n/a. A missing row is a
     gap, not an omission. -->

## Findings

| Severity | Rule (STY/ARC/ROB/PRC or process) | Where | Issue | Fix |
|---|---|---|---|---|

## Plan alignment

- Deviations found vs `phase-05-plan.md`: <none | listed — each user-approved and recorded
  in the plan's §Deviations (approved)>

## Gate markers (phase-07: TESTS · phase-09: all four)

<!-- ⚠️ The lines below are INDENTED on purpose so a freshly scaffolded artifact can NEVER
     open a gate (hooks match markers anchored at column 0). Write the real line at column 0
     yourself, ONLY when it is actually true — doing it earlier is falsifying the gate.

       TESTS: GREEN              phase-07, after the FULL suite ran green
       REVIEW-CODE: APPROVED     phase-09, after REVIEW-CODE.md returned APPROVED
       VALIDATED-SHA: <sha>      phase-09 — git -C <code-repo> rev-parse HEAD (squashed commit)
       COMPLETENESS: VERIFIED    phase-09 — ticket+plan+code audited, nothing uninvolved
       DEVIATIONS: NONE          phase-09 — or DEVIATIONS: APPROVED-AND-DOCUMENTED
-->


## Handoff

- `phase_status`:
- `highest_severity`:
- `next_phase`:
- `blocking_reason`:
- `required_inputs_for_next_phase`:
- `evidence_paths`:
- `delivery_state_updated`:
