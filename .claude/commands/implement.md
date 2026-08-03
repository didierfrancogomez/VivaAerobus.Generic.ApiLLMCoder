---
description: Run the 12-phase Coder pipeline for a Jira ticket (scaffold → gates → implement → deliver)
argument-hint: API-9999
---

Run the complete Coder pipeline for **$ARGUMENTS**. `CLAUDE.md` is the orchestrator and
`process/phase-NN-*.md` are the authoritative phases — read `CLAUDE.md` first and follow it, not
this summary. The four NON-NEGOTIABLE rules apply in full (analysis before code; system knowledge
lives in the ApiLLM; evidence first; the LLM repo's `guidelines/**` govern HOW code is written).

Hard sequence:

0. **Scaffold + intake gate**: `tools/new-task.sh $ARGUMENTS` — creates `work/<KEY>/` +
   `delivery-state.md`, fetches the ticket and runs `ready` when jira-sync is configured
   (Phase 0 §0.0). `ready` exit 1 → **STOP**: report the blockers as questions to the requester;
   do not improvise a test plan. Research ticket → the research route (Phase 0 §0.1): written
   finding, no PR.
1. **Stage A — phases 0–4** (`process/phase-00` … `phase-04`), each recording its artifact from
   `process/_templates/phase-artifact.md`, updating `delivery-state.md`, and **closing with
   `tools/save-progress.sh $ARGUMENTS "<phase>"`** — then tell the user the folder
   (`work/$ARGUMENTS/`) so they can resume anytime. Same at every phase close in Stage B.
   If `work/$ARGUMENTS/` already exists, this IS a resume: read `delivery-state.md` first and
   continue from `current_phase` — never restart phases that already passed. Phase 1 syncs the
   ApiLLM first. The Phase 4 gate: verdict ⚠️/⛔ → **STOP**, surface the questions, no code.
2. **Stage B — phases 5–11** only with `VERDICT: ✅` (the hooks enforce it): numbered plan
   (`_templates/plan.md`, guideline IDs cited) → implement on `feature/$ARGUMENTS/<kebab-slug>`
   (PRC-102) → Phase 7 ladder until every `S-NN` is green (`TESTS: GREEN`) → release prep →
   Phase 9 (squash to ONE commit, run `process/REVIEW-CODE.md`, the four markers, SHA-anchored)
   → Phase 10.
3. **Publication is the user's**: present the summary and WAIT for them to create
   `work/<KEY>/PUSH-APPROVED` (never create it). Then push, PR (explicit title, PRC-103), and
   `jira_sync.py deliver $ARGUMENTS … --dry-run` first — show the plan, deliver only on their yes.
4. **Rework** (comments/QA return): `tools/new-run.sh $ARGUMENTS` re-closes the gates, then
   Phase 10 §10.2's loop.
5. **Close**: Phase 11 — invoke the ApiLLM `doc-sync`, evidence, ticket closure.

At every human gate (ready, Phase 4 verdict, HUMAN-GATE for risky, PUSH-APPROVED, deliver)
surface the findings and wait. Steps owned by humans are never claimed done — record
`DONE-BY-HUMAN` / `HANDED-OFF` / `N/A` (Annex D §D.1).
