# continue-recovery — API-1738 — recorded 2026-09-05 00:01 -0400 (before any mutation)

Code repo: `C:\VivaAerobus.Generic.Api`

- Checked-out branch: `feature/API-1738/display-passengers-changes`
- Local HEAD: `5aab3a22e` (2026-09-03 10:48 -0400, "API-1738 ♻️ Move contact masking decision into ManageAndCheckinRulesValidator")
- Remote PR head `origin/feature/API-1738/display-passengers-changes`: `5f26398c0` (pre-rewrite SHA for the history-rewrite policy)
- `origin/feature/API-1738/display-passengers-changes-v2`: `ea9817aa4`
- `origin/feature/API-1738/display-passengers-changes-v3`: `abe4bb5d8`
- `origin/master`: `e004bf9d8`

## `git status --porcelain` (tracked modifications — NOT ours, never staged)
```
 M VivaAerobus.Generic.Api/global.json                     (SDK 3.1.426 + rollForward — local build prerequisite)
 M VivaAerobus.Generic.Api/src/app/VivaAerobus.Generic.Api/appsettings.Development.json   (Yuno TimeoutSeconds + Security.PasswordEncryption — local env)
```
Untracked (35 paths, developer toolkit of other tickets — left untouched): `API-1446-testing-guide.md`, `VivaAerobus.Generic.Api/run-cleanup.bat`, `VivaAerobus.Generic.Api/scripts/`, `VivaAerobus.Generic.Api/src/tests/VivaAerobus.Generic.Api.Tests/TestResults/`, `docker/DEV-SCRIPTS-GUIDE.md`, `docker/flush-redis.ps1`, `docker/seed-marten-document.ps1`, `docs/API-1584-*`, `docs/API-1598-*`, `docs/API-1624-*`, `docs/API-1653-*`, `docs/API-1694-*`, `docs/Postman/API-1584-*`, `docs/Postman/API-1598-*`, `docs/Postman/API-1624-*`, `docs/Postman/API-1667-*`, `docs/Postman/API-1694-*`, `docs/Postman/API-1738-Display-Passenger-Changes.postman_collection.json`, `docs/docker-db-generic-seed-guide.md`, `docs/sq-vul-sol.png`, `docs/testing/`, `global.json`, `pr_body_API-1598.md`, `pr_body_API-1680.md`, `scripts/`.

## Stashes (pre-existing — never popped, never dropped)
```
stash@{0}: On feature/API-1624/Transfer-Block-booking-rules-for-transfered-bookings: API-1584 review: local Irop.json seed edits (restore with: git stash pop)
stash@{1}: On feature/API-1598/encrypt-input-password: API-1598 working tree changes
```

## Update 2026-09-05 ~00:50 -0400 (read-only refresh)
- The user force-pushed the PR branch: `origin/feature/API-1738/display-passengers-changes` **5f26398c0 → ea9817aa4** (single squashed commit, = former `-v2`). Pre-rewrite lineage still reachable on GitHub (`-v3` abe4bb5d8 contains rebased copies of all 7 commits) and locally via reflog (5aab3a22e).
- Local branch still 5aab3a22e; when re-pointed to `origin/…`, the recovery SHA for the local lineage is **5aab3a22e**.

## Stage C mutations (2026-09-05, after HUMAN-GATE-OK)
- Local branch re-pointed: `git switch -C feature/API-1738/display-passengers-changes origin/…` → ea9817aa4 (old local lineage 5aab3a22e kept in reflog).
- Local amend: cherry-pick -n abe4bb5d8 + `commit --amend --no-edit` → **1e65eb8a3** (= -v3 tree; 1 commit ahead of origin/master). Not pushed. Pre-rewrite remote SHA for `--force-with-lease`: **ea9817aa4**.
- PID 7148 (stale 2026-09-03 build on :9050) stopped with the user's authorization (Q2).

## Stash created by this run
None (nothing dirty overlaps the planned paths or master's changes).

## Processes
- Pre-existing: `VivaAerobus.Generic.Api.exe` PID 7148 on :9050 (build 2026-09-03 16:28 -0400, orphan). User authorized stop/restart (Q2, 2026-09-05).
- Started by this run (2026-09-05 01:23 -0400): **PID 3132** — branch build 1e65eb8a3 on http://localhost:9050 (`ASPNETCORE_URLS`, env Development; log `work/API-1738/attachments/api-9050-1e65eb8a3.log`); **PID 25700** — master e004bf9d8 from the detached worktree `C:\VivaAerobus.Generic.Api-master` on http://localhost:9051 (Issue side; log `attachments/api-9051-master.log`). Stop both with `Stop-Process -Id 3132,25700` when done; remove the worktree with `git -C C:\VivaAerobus.Generic.Api worktree remove C:\VivaAerobus.Generic.Api-master --force`.
- Earlier this run: PID 2876 (branch build bound to 5000/5001 by mistake) started 01:20 and stopped 01:23.
- 2026-09-07: PID 3132 stopped; code repo switched to `master` b83df54a0 (PR #2484 merged 12:52Z); docker `vbgeneric-*` containers (all exited ~7 h earlier) restarted with `docker start`; **PID 1708** — master build on http://localhost:9050 (log `attachments/api-9050-master-b83df54a0.log`). TC07/TC08 re-run on master: 33/33 and 49/49 assertions.

## How to restore the pre-run state (only if asked)
- Local branch back to the recorded HEAD: `git -C C:\VivaAerobus.Generic.Api branch -f feature/API-1738/display-passengers-changes 5aab3a22e` while on another ref (a rewrite — user OK required).
- Remote PR head before this run: `5f26398c0` (`origin/feature/API-1738/display-passengers-changes`).
- Working tree modifications were never touched; nothing to restore.
