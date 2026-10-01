# Phase 7 §7.5 Evidence audit: <KEY> — run-<NNN>

<!-- Skeleton for work/<KEY>/phase-07-evidence-audit.md, written by the parent agent from the
     tc-evidence-auditor report (process/phase-07-testing.md §7.5). INFORMATIONAL: no hook reads it.
     On rework, tools/new-run.sh archives it together with work/<KEY>/evidence/. -->

- **Matrix source:** `jira_sync.py matrix <KEY> --state` @ <fetched_at> | baseline `ticket-snapshots/matrix-baseline.json` @ <fetched_at> · rows: <n> (<subtask | description>) · <in sync | OUT-OF-SYNC: …>
- **Docs-sync status given to the auditor:** <DOCS-ANCHOR line | not provided>
- **Package inventory:** classic <n> TC files · story <yes | no> · cards <n> · newman <n> · Admin Portal <n | not applicable>
- **Credential check:** `mask-credentials.py --check --git work/<KEY>` → <summary line>

## Row by row

| Matrix # | Scenario (verbatim) | Expected (verbatim) | Classic | Story | Card | Admin Portal | Verdict | Why |
|---|---|---|---|---|---|---|---|---|
| 1 | | | `classic/TC01.md:<line>` | `story/<KEY>-evidence-story.md:<line>` | `captures/test-cases/<file>.png` | `<file>.png` · n/a | | |

<!-- ✅ BACKED   the classic shows the expected result; story and card agree with it
     ⚠️ WEAK     evidence exists but does not show the expected result, the formats disagree, or a
                 required piece (card, Admin Portal capture) is missing
     ❌ MISSING  no classic TC file, or no executed request/response in it
     ➖ N/A      retired by a ticket comment or justified n/a in the plan — cite where -->

## Package-level findings

- Extra TCs not in the matrix: <none | list>
- Broken relative links: <none | list>
- Story ↔ classic mismatches: <none | list>

## Gaps surfaced to the user

| Matrix # | What is missing | Fix proposed | User decision |
|---|---|---|---|

## Summary

<!-- ONE line at column 0, only when it is true:
       EVIDENCE-AUDIT: COMPLETE        every row ✅ or ➖
       EVIDENCE-AUDIT: GAPS <n>        <n> rows ⚠️ or ❌, each listed above
     Informational — it does not open or close any gate. -->

## Handoff

- `phase_status`:
- `highest_severity`:
- `next_phase`:
- `blocking_reason`:
- `required_inputs_for_next_phase`:
- `evidence_paths`:
- `delivery_state_updated`:
