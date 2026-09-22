# <Phase NN — name>: <KEY> <ticket title>

<!-- Minimum structure for every work/<KEY>/phase-NN-*.md artifact. The phase file
     (process/phase-NN-*.md) defines the CONTENT; this template defines the SKELETON
     and the mandatory handoff footer. Gate markers (DOCS-ANCHOR:, VERDICT:, TESTS:,
     REVIEW-CODE:, VALIDATED-SHA:, COMPLETENESS:, DEVIATIONS:) go at column 0 where the
     phase requires them — the hooks match them anchored. -->

<!-- Phase 1 ONLY — first line of the Work section, at column 0 (process/phase-01 §1.0):
     DOCS-ANCHOR: <sha> FRESH
     DOCS-ANCHOR: <sha> STALE <n> commits — <how it was handled>
     The ApiLLM anchor every documents/** citation below was read at. -->

## Work

<The phase's actual output: findings, tables, matrices — everything cited per the evidence rule.>

## Ticket comment (pending publication)

<Full text to post on the Jira ticket, self-contained. Delete this section if the phase
posts nothing.>

PUBLICATION: pending

## Handoff

- `phase_status`: <pass | fail | blocked | needs_previous_phase>
- `highest_severity`: <BLOCKER | P1 | P2 | P3 | none>   <!-- process findings; code findings keep the guidelines taxonomy 🐛/❗/🏭/✋ -->
- `next_phase`: <phase NN | none>
- `blocking_reason`: <reason | n/a>
- `required_inputs_for_next_phase`: <paths / decisions / answers>
- `evidence_paths`: <files, runs, links>
- `delivery_state_updated`: <yes | no>
