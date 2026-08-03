# Phase 4 — Blocking questions and assumption log ══ THE GATE ══

> **Question it answers:** what can I not decide on my own?
> **This phase IS the pipeline's gate** (`../CLAUDE.md`): here it is decided whether the agent
> **stops** or **continues to implementation**.
> **Support in the LLM repo:** question and verdict rules from `process/ANALYZE-TASK.md` §Phase 5
> ("you may recommend, but never resolve"; separate business questions from our own verification
> tasks; prioritize; every question with its why; group by owner; few and good).

**Objective:** turn all uncertainty into (a) an answer, or (b) a documented and accepted
assumption. Never into a silent guess.

## 4.0 Gate rule (mandatory, no exceptions)

When this phase closes, an **explicit verdict** is issued (same format as `process/ANALYZE-TASK.md`):

| Verdict | Meaning | Agent's action |
|---|---|---|
| ✅ **Ready to implement** | Objective, contracts, acceptance criteria and impact are clear; zero hard blockers | **Continue** to [Phase 5](phase-05-planning.md) |
| ⚠️ **Needs definition** | Implementable, but there are undefined blockers | **STOP.** Issue the questions (format 4.2), mark the ticket *Blocked*, do NOT code |
| ⛔ **Not implementable as stated** | The source of truth lives outside the repo, depends on a stub, or contradicts an existing rule/contract | **STOP.** Explain why + 2–3 alternatives with a recommendation |

- The verdict is written in the ticket and delivered to the user. With ⚠️/⛔ the agent **produces
  no code and no implementation plan** — only the analysis, the questions and (if possible) the
  non-blocked work described in 4.5.
- **Two kinds of missing information — never confuse them** (rule from `ANALYZE-TASK.md`):
  - **Business gap** → the requester defines it. It is a *question*.
  - **Documentation/verification gap** → **we** verify it in the code. It is a
    *pre-verification task*, not a question for the business (and if the LLM doc was wrong, its
    `doc-sync` pipeline is invoked).

## 4.1 Classifying the doubts

| Type | Definition | Handling |
|---|---|---|
| **Hard blocker** | Without the answer I cannot start, or 100% of the work could be thrown away | Escalate immediately, mark the ticket as *Blocked*, do not start |
| **Partial blocker** | Blocks one part; I can move forward on another | Ask and parallelize the non-blocked work |
| **Business/product decision** | Not technical; only the PO/business can decide | Ask with options and a recommendation |
| **Team technical decision** | Affects others or the standard (architecture, contract, library) | Take it to the tech lead / design review |
| **Domain ambiguity** | Terms or rules with more than one reading | Resolve with the domain expert; document the definition |
| **Low-risk assumption** | I can assume something reasonable; if I'm wrong the cost is low | Document as an assumption, proceed, validate in review/QA |
| **Irrelevant detail** | Does not change the outcome | Decide and move on. Don't ask about everything: it erodes the channel |

## 4.2 How to formulate a blocking question (format)

A badly formed question generates two days of ping-pong. Structure:

```
[BLOCKER] <Short title of the decision>
Context: <2–3 lines. What I found and why this is not defined.>
Evidence: <link to the code, the data, the impact matrix.>
The concrete question: <a single question, closed-ended if possible.>
Options:
  A) <description> — cost: <X>; implies: <Y>; risk: <Z>
  B) <description> — cost: <X>; implies: <Y>; risk: <Z>
My recommendation: <A or B, and why in one line.>
What happens if it goes unanswered: <impact and by when it is needed: "I need an answer before
<date> or the ticket does not make the sprint">
While I wait, I will move forward on: <what I can do.>
```

Rules:

- **Always with options and a recommendation.** Asking open-ended ("what do we do?") transfers your
  work to someone else and delays the answer.
- **You may recommend, but never resolve.** Even if the recommendation is obvious, the decision
  remains a blocking question until the owner confirms (ApiLLM evidence rule).
- **One question per block.** If there are three, they are three numbered blocks, not one
  paragraph.
- **No jargon** if the recipient is the business.
- **With an explicit deadline.**

## 4.3 Whom and where to ask

1. **Routing:** product/business → PO. Architecture/standard → tech lead. Expected behavior and
   edge cases → QA + PO. UI/UX and empty/error states → design. Data and permissions → domain
   owner or security. API contract → consumer team. Infra → platform/DevOps. Rules that live in
   DotRez or another vendor → whoever manages the vendor.
2. **Always leave the question written in the ticket**, even if it is resolved over chat or in
   person. The ticket is the project's memory; chat is not.
3. **After a verbal conversation, write the summary and the decision in the ticket** and ask for
   explicit confirmation ("do you confirm we settled on A?").
4. **Label and make the block visible:** *Blocked* status, reason, person responsible for
   unblocking, date since when it has been blocked.

## 4.4 Assumption log

Table that lives in the ticket and is reviewed in Phase 9 and in the PR:

| # | Assumption | Why I assume it | Risk if false | How it is validated | Status |
|---|---|---|---|---|---|

Every assumption must have a validation mechanism: a test, a question in the PR, a QA
verification. **An assumption without validation is a scheduled bug.**

## 4.5 Escalation and parallel work

1. **Define the clock:** if a hard blocker is not answered within X hours (team agreement,
   typically 4–24h), escalate to the next level. No drama, by process.
2. **Don't sit still waiting:** move forward on what is not blocked (tests, preparatory refactor,
   scaffolding, documentation, another ticket).
3. **Do not "move forward guessing" on what is blocked.** If you decide to proceed with an
   assumption to avoid losing time, make it explicit and isolated so it is easy to change (behind
   an interface, a flag, a single point of change).
4. **If the block drags on:** return the ticket to the backlog and take another one. A blocked
   ticket in progress lies about the state of the sprint.

---

**Artifacts:** `work/<KEY>/phase-04-verdict.md` — MUST contain **exactly one** line starting at
column 0 with `VERDICT: ` — `VERDICT: ✅` / `VERDICT: ⚠️` / `VERDICT: ⛔` (the hooks match it
anchored and reject the file if there are zero or several; an indented or quoted copy does not
count), plus the blocking questions and the assumption table. The questions also go into the ticket. ⚠️ The verdict is written
**upon finishing the real analysis**, never before: recording ✅ without having closed the
blockers is falsifying the gate.

**Exit criterion (to cross the gate):** verdict ✅ — zero open hard blockers and every assumption
documented with its validation plan. With any other verdict, the pipeline stops here.

**Next (only with ✅):** [Phase 5 — Planning and design](phase-05-planning.md)
