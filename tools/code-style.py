#!/usr/bin/env python3
"""code-style.py — apply / verify the team's `Ezy` code-cleanup profile on a task's diff.

Invoked through tools/code-style.sh (which resolves a working Python). Two modes:

  apply   (Phase 6, last step) — runs `jb cleanupcode --profile=Ezy` scoped to the task's
          .cs files, then keeps ONLY the cleanup deltas that land on lines the task added or
          modified; every pre-existing line stays as the base branch has it (KB §25.9.1, the
          4-step cycle). Deltas that mix our lines with foreign ones, or that MOVE one of our
          members (CSReorderTypeMembers), are not adopted — they are reported for a manual fix.

  verify  (Phase 9, the gate) — runs the cleanup again on the final files and requires ZERO
          deltas on our lines. The files are always restored byte-for-byte afterwards. Writes
          work/<KEY>/phase-06-code-style.md with, at column 0:
              CODE-STYLE: VERIFIED            (only when zero deltas land on our lines)
              STYLE-SHA: <code-repo HEAD>     (UNCOMMITTED when in-scope files are dirty)
          The pre-publication hook denies push / PR without VERIFIED, or when HEAD drifted
          from STYLE-SHA.

"Our lines" = the new-side lines of `git diff -U0 <merge-base>` for each tracked file (committed
+ uncommitted work), and every line of an untracked new file.
"""

import argparse
import datetime
import difflib
import os
import re
import shutil
import subprocess
import sys

PROFILE = "Ezy"
SLN_DIR = "VivaAerobus.Generic.Api"
SLN = "VivaAerobus.Generic.Api.sln"
ARTIFACT = "phase-06-code-style.md"


def git(repo, *args, check=True):
    r = subprocess.run(["git", "-C", repo] + list(args), capture_output=True)
    if check and r.returncode != 0:
        sys.exit("⛔ git %s failed: %s" % (" ".join(args), r.stderr.decode(errors="replace").strip()))
    return r.stdout.decode("utf-8", errors="replace")


def resolve_base(repo, base):
    if base:
        return git(repo, "rev-parse", base).strip()
    for ref in ("origin/master", "master"):
        r = subprocess.run(["git", "-C", repo, "merge-base", ref, "HEAD"], capture_output=True)
        if r.returncode == 0:
            return r.stdout.decode().strip()
    sys.exit("⛔ cannot resolve a base (no origin/master nor master) — pass --base <ref>")


def scope_files(repo, base):
    tracked = git(repo, "diff", "--name-only", "--diff-filter=AMR", base).split("\n")
    untracked = git(repo, "ls-files", "--others", "--exclude-standard").split("\n")
    files, new = [], set()
    for f in tracked + untracked:
        f = f.strip()
        if not f.endswith(".cs") or not f.startswith(SLN_DIR + "/"):
            continue
        if f not in files:
            files.append(f)
    for f in untracked:
        if f.strip() in files:
            new.add(f.strip())
    return files, new


HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def our_lines(repo, base, path, is_new, n_lines):
    if is_new:
        return set(range(1, n_lines + 1))
    ours = set()
    for line in git(repo, "diff", "-U0", base, "--", path).split("\n"):
        m = HUNK.match(line)
        if m:
            start, count = int(m.group(1)), int(m.group(2) or "1")
            ours.update(range(start, start + count))
    return ours


def read(path):
    with open(path, "rb") as fh:
        return fh.read()


def write(path, data):
    with open(path, "wb") as fh:
        fh.write(data)


def run_cleanup(repo, files):
    """Runs jb cleanupcode on `files` and returns {path: cleaned_bytes}. Every file it touches
    is restored byte-for-byte before returning (including global.json)."""
    jb = shutil.which("jb")
    if not jb:
        sys.exit("⛔ `jb` not found — install once: dotnet tool install -g JetBrains.ReSharper.GlobalTools")
    sln_dir = os.path.join(repo, SLN_DIR)
    status_before = git(repo, "status", "--porcelain")
    snap = {f: read(os.path.join(repo, f)) for f in files}
    gj = os.path.join(sln_dir, "global.json")
    gj_bytes = read(gj) if os.path.exists(gj) else None
    cleaned = {}
    try:
        if gj_bytes is not None and b"rollForward" not in gj_bytes:
            write(gj, b'{\r\n  "sdk": {\r\n    "version": "3.1.200",\r\n    "rollForward": "latestFeature"\r\n  }\r\n}\r\n')
        if not os.path.exists(os.path.join(sln_dir, "src", "app", SLN_DIR, "obj", "project.assets.json")):
            print("» dotnet restore %s (cleanupcode needs restored projects)" % SLN, flush=True)
            rr = subprocess.run(["dotnet", "restore", SLN], cwd=sln_dir, capture_output=True)
            if rr.returncode != 0:
                sys.stderr.write(rr.stdout.decode(errors="replace")[-2000:])
                sys.exit("⛔ dotnet restore failed — cleanupcode cannot load the solution")
        include = ";".join(f[len(SLN_DIR) + 1:] for f in files)
        cmd = [jb, "cleanupcode", SLN, "--profile=" + PROFILE, "--include=" + include, "--verbosity=WARN"]
        print("» " + " ".join('"%s"' % c if " " in c else c for c in cmd[1:]), flush=True)
        r = subprocess.run(cmd, cwd=sln_dir, capture_output=True)
        if r.returncode != 0:
            sys.stderr.write(r.stdout.decode(errors="replace")[-4000:])
            sys.stderr.write(r.stderr.decode(errors="replace")[-4000:])
            sys.exit("⛔ jb cleanupcode exited %d" % r.returncode)
        for f in files:
            cleaned[f] = read(os.path.join(repo, f))
    finally:
        for f, data in snap.items():
            write(os.path.join(repo, f), data)
        if gj_bytes is not None:
            write(gj, gj_bytes)
    leaked = []
    before = set(status_before.split("\n"))
    for line in git(repo, "status", "--porcelain").split("\n"):
        if line and line not in before:
            path = line[3:].strip().strip('"')
            if path not in files:
                leaked.append(path)
    for path in leaked:
        git(repo, "checkout", "--", path, check=False)
    if leaked:
        print("⚠️  cleanup touched files outside the scope (restored from the index): " + ", ".join(leaked))
    return cleaned


def classify(mine, cleaned, ours):
    """Returns the cleanup deltas as dicts: kind OURS | FOREIGN | MIXED | MOVE | EDGE.
    EDGE = an insertion on the boundary between one of our lines and a pre-existing one (typically
    the blank line that separates members): reported for review, never adopted nor blocking."""
    a, b = mine.splitlines(keepends=True), cleaned.splitlines(keepends=True)
    ops = [op for op in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes() if op[0] != "equal"]
    deltas = []
    for tag, i1, i2, j1, j2 in ops:
        if tag == "insert":
            touched = {i1, i1 + 1} & set(range(1, len(a) + 1))
            hit = touched & ours
            kind = "OURS" if hit and hit == touched else ("EDGE" if hit else "FOREIGN")
        else:
            touched = set(range(i1 + 1, i2 + 1))
            hit = touched & ours
            kind = "OURS" if hit == touched else ("FOREIGN" if not hit else "MIXED")
        deltas.append({"tag": tag, "i1": i1, "i2": i2, "j1": j1, "j2": j2, "kind": kind,
                       "old": a[i1:i2], "new": b[j1:j2]})
    foreign_new = [d["new"] for d in deltas if d["kind"] != "OURS"]
    for d in deltas:
        if d["kind"] == "OURS" and d["tag"] in ("delete", "replace"):
            body = [x.strip() for x in d["old"] if x.strip()]
            if body and any(contains(block, body) for block in foreign_new):
                d["kind"] = "MOVE"
    return a, b, deltas


def contains(block, body):
    stripped = [x.strip() for x in block if x.strip()]
    n = len(body)
    return any(stripped[k:k + n] == body for k in range(len(stripped) - n + 1))


def rebuild(a, b, deltas):
    out, pos = [], 0
    for d in deltas:
        if d["kind"] != "OURS":
            continue
        out.extend(a[pos:d["i1"]])
        out.extend(b[d["j1"]:d["j2"]])
        pos = d["i2"]
    out.extend(a[pos:])
    return b"".join(out)


def label(d):
    if d["tag"] == "insert":
        return "insert after L%d" % d["i1"]
    return "L%d-L%d" % (d["i1"] + 1, d["i2"]) if d["i2"] - d["i1"] > 1 else "L%d" % (d["i1"] + 1)


def preview(lines):
    txt = " ⏎ ".join(x.decode("utf-8", errors="replace").strip() for x in lines[:3])
    return (txt[:110] + "…") if len(txt) > 110 else txt


def main():
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["apply", "verify"])
    ap.add_argument("key")
    ap.add_argument("--repo", required=True)
    ap.add_argument("--work", required=True)
    ap.add_argument("--base")
    args = ap.parse_args()

    key, repo = args.key.upper(), os.path.abspath(args.repo)
    if not os.path.isfile(os.path.join(repo, SLN_DIR, SLN)):
        sys.exit("⛔ %s is not the API repo (no %s/%s)" % (repo, SLN_DIR, SLN))
    base = resolve_base(repo, args.base)
    files, new = scope_files(repo, base)
    if not files:
        sys.exit("⛔ no .cs files changed against %s — nothing to style" % base[:10])

    out = os.path.join(args.work, key, ARTIFACT)
    if args.mode == "verify" and os.path.exists(out):
        os.remove(out)
    mine = {f: read(os.path.join(repo, f)) for f in files}
    cleaned = run_cleanup(repo, files)

    report, touching = [], 0
    for f in files:
        ours = our_lines(repo, base, f, f in new, len(mine[f].splitlines()))
        a, b, deltas = classify(mine[f], cleaned[f], ours)
        if args.mode == "apply":
            result = rebuild(a, b, deltas)
            if result != mine[f]:
                write(os.path.join(repo, f), result)
        for d in deltas:
            if d["kind"] not in ("FOREIGN", "EDGE"):
                touching += 1
            report.append((f, d))

    if args.mode == "apply":
        adopted = sum(1 for _, d in report if d["kind"] == "OURS")
        manual = [(f, d) for f, d in report if d["kind"] in ("MIXED", "MOVE")]
        print("✔ Ezy applied to %d file(s): %d delta(s) adopted on our lines, %d rejected on pre-existing lines."
              % (len(files), adopted, sum(1 for _, d in report if d["kind"] == "FOREIGN")))
        for f, d in report:
            if d["kind"] == "EDGE":
                print("·  EDGE %s:%s — boundary insertion (%s), not adopted: keep it only if it separates OUR member"
                      % (f, label(d), preview(d["new"]) or "blank line"))
        for f, d in manual:
            print("⚠️  MANUAL %s %s:%s — %s" % (d["kind"], f, label(d), preview(d["new"] or d["old"])))
        if manual:
            print("   Fix those by hand (MOVE = the profile relocates one of our members: put it where the "
                  "cleanup wants it), then run: tools/code-style.sh %s verify" % key)
        else:
            print("   Next: review the diff, run the tests, then: tools/code-style.sh %s verify" % key)
        return 0

    head = git(repo, "rev-parse", "HEAD").strip()
    dirty = git(repo, "status", "--porcelain", "--", *files).strip()
    sha = "UNCOMMITTED" if dirty else head
    ok = touching == 0
    lines = [
        "# %s — Ezy code style (Phase 6 §6.5 · gate checked before push)" % key,
        "",
        "Generated by `tools/code-style.sh %s verify` on %s — never edit by hand."
        % (key, datetime.datetime.now().strftime("%Y-%m-%d %H:%M")),
        "",
        "- Profile: `%s` (`%s/%s.DotSettings`)" % (PROFILE, SLN_DIR, SLN),
        "- Command: `jb cleanupcode %s --profile=%s --include=<scope> --verbosity=WARN`" % (SLN, PROFILE),
        "- Base: `%s` · HEAD: `%s`%s" % (base, head, " · ⚠️ in-scope files have uncommitted changes" if dirty else ""),
        "- Scope (%d .cs file(s)):" % len(files),
    ]
    lines += ["  - `%s`%s" % (f, " (new)" if f in new else "") for f in files]
    lines += ["", "## Cleanup deltas on a second pass", ""]
    if report:
        lines += ["| File | Where | Lands on | Cleanup would write |", "|---|---|---|---|"]
        for f, d in report:
            where = {"FOREIGN": "pre-existing — kept as base (expected)",
                     "EDGE": "boundary ours/pre-existing — review, not blocking"}.get(d["kind"], "**our lines — ⛔ %s**" % d["kind"])
            lines.append("| `%s` | %s | %s | `%s` |" % (os.path.basename(f), label(d), where,
                                                       preview(d["new"] or d["old"]).replace("|", "\\|")))
    else:
        lines.append("None — the files are idempotent under the profile.")
    lines += ["", "## Result", ""]
    if ok:
        lines += ["CODE-STYLE: VERIFIED", "STYLE-SHA: %s" % sha]
    else:
        lines += ["CODE-STYLE: FAILED — %d delta(s) on lines this task added/modified; run `tools/code-style.sh %s apply` "
                  "and fix the MANUAL ones" % (touching, key)]
    os.makedirs(os.path.join(args.work, key), exist_ok=True)
    write(out, ("\n".join(lines) + "\n").encode("utf-8"))

    if ok:
        print("✔ CODE-STYLE: VERIFIED — zero deltas on our lines (%d pre-existing/boundary kept). STYLE-SHA: %s"
              % (len(report), sha))
        if dirty:
            print("⚠️  in-scope files are uncommitted: the push gate needs STYLE-SHA == HEAD — re-run verify after the commit.")
        print("   Evidence: work/%s/%s" % (key, ARTIFACT))
        return 0
    print("⛔ CODE-STYLE: FAILED — %d delta(s) on our lines. Details: work/%s/%s" % (touching, key, ARTIFACT))
    return 1


if __name__ == "__main__":
    sys.exit(main())
