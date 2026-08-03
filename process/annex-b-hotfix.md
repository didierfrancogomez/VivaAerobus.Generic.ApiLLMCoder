# Annex B — Compressed path for hotfix / production incident

> The full process does not apply to a fire, but **nothing is dropped: it is deferred**.
> Even in an incident, the evidence rule holds: the fix is based on what the code and the logs
> prove, not on the first hypothesis that fits.

## During the incident (minutes)

1. **Mitigate first** (flag off / config part in the Admin Portal, rollback, scale resources)
   before fixing the root cause.
2. **Impact:** who is affected, since when, how many, whether there is data corruption.
3. **Communicate:** incident channel, one person responsible for communication, support informed.
4. **Minimal, surgical, reversible fix.** No refactors.
5. **Express impact radius:** only what could make the situation worse (consult the reverse index
   of the LLM repo's dependency-map if the touched module is shared — 2 minutes that prevent a
   second incident).
6. **One test covering the case**, if time allows. If not, it becomes immediate debt.
7. **Review by at least one person**, even if it is a 5-minute one. Never merge without another
   pair of eyes.
8. **Deployment with explicit verification and continuous monitoring.**

## Within the next 48 hours (mandatory, not optional)

9. **Ticket with the full analysis**, blameless postmortem.
10. **Missing tests, alerts that did not exist, real root cause fixed.**
11. **Preventive actions turned into prioritized tickets.**
12. **Update the process or the checklist with what was learned** (change in `process/` of this
    repo).
13. **Re-sync the ApiLLM docs** (doc-sync) — the hotfix changed the code too.
