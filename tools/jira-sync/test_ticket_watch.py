"""
Offline tests for the ticket-watch logic in jira_sync.py (matrix drift, rework window, deadline).
No network: every Jira payload is built here.

    python test_ticket_watch.py        # exit 0 = all green
"""
import sys
from datetime import date

import jira_sync as j

ME, OTHER = "me-id", "other-id"
PASSED = FAILED = 0


def check(name, cond, got=None):
    global PASSED, FAILED
    if cond:
        PASSED += 1
        print(f"  ok   {name}")
    else:
        FAILED += 1
        print(f"  FAIL {name}\n       got: {got!r}")


# --- ADF builders -----------------------------------------------------------
def cell(text, header=False):
    return {"type": "tableHeader" if header else "tableCell",
            "content": [{"type": "paragraph", "content": [{"type": "text", "text": text}] if text else []}]}


def table(header, rows):
    return {"type": "doc", "version": 1, "content": [
        {"type": "heading", "content": [{"type": "text", "text": "Test Matrix"}]},
        {"type": "table", "content": [{"type": "tableRow", "content": [cell(h, True) for h in header]}]
         + [{"type": "tableRow", "content": [cell(v) for v in r]} for r in rows]}]}


H = ["#", "Scenario type", "Test case description", "Expected Result", "Notes", "Execution Result", "Evidences"]


def state(sub_rows, desc_rows=None, comments=()):
    return {"subtask": j.extract_matrix(table(H, sub_rows)),
            "description": j.extract_matrix(table(H, desc_rows)) if desc_rows is not None else [],
            "comments": [{"id": c, "source": "API-1", "author": "qa", "created": "2026-09-22 10:00"} for c in comments]}


def kinds(findings):
    return sorted((f["kind"], f["row"]) for f in findings)


print("matrix:")
R1 = ["1", "Happy", "do A", "A works", "", "PASS", "img1"]
R2 = ["2", "Alt", "do B", "B works", "", "PASS", "img2"]
base = state([R1, R2], comments=["10"])

check("extract keys rows on '#', classifies columns",
      [r["id"] for r in base["subtask"]] == ["1", "2"] and j._col_class("Expected Result") == "spec"
      and j._col_class("Notes") == "meta" and j._col_class("Evidences") == "result", base["subtask"])
check("no change → no findings", j.diff_matrix(base, state([R1, R2], comments=["10"])) == [])
check("result/evidence edits are not spec changes",
      j.diff_matrix(base, state([R1[:5] + ["FAIL", "new.png"], R2], comments=["10"])) == [])

moved = state([R1[:3] + ["A works differently"] + R1[4:], R2], comments=["10"])
check("expected result moved → SPEC-CHANGED + RESULT-STALE",
      kinds(j.diff_matrix(base, moved)) == [("RESULT-STALE", "1"), ("SPEC-CHANGED", "1")], kinds(j.diff_matrix(base, moved)))
rerun = state([R1[:3] + ["A works differently", "", "FAIL", "img1b"], R2], comments=["10"])
check("result re-recorded after the move → not stale",
      kinds(j.diff_matrix(base, rerun)) == [("SPEC-CHANGED", "1")], kinds(j.diff_matrix(base, rerun)))
check("notes moved → META-CHANGED (re-run only)",
      ("META-CHANGED", "2") in kinds(j.diff_matrix(base, state([R1, R2[:4] + ["run on QA2"] + R2[5:]], comments=["10"]))))
R3 = ["3", "New", "do C", "C works", "", "", ""]
added = j.diff_matrix(base, state([R1, R3], comments=["10", "11"]))
check("added / removed rows and new comments",
      kinds(added) == [("ADDED", "3"), ("NEW-COMMENT", ""), ("REMOVED", "2")], kinds(added))
check("description ≠ subtask → OUT-OF-SYNC even without a baseline",
      kinds(j.diff_matrix(None, state([R1, R2], [R1[:3] + ["A works?"] + R1[4:], R2]))) == [("OUT-OF-SYNC", "1")])
check("row missing in the subtask → OUT-OF-SYNC",
      kinds(j.diff_matrix(None, state([R1], [R1, R2]))) == [("OUT-OF-SYNC", "2")])

low, high, lines = j.rework_window(j.diff_matrix(base, moved))
check("rework window: one re-implemented row costed once + overhead", (low, high) == (4.0, 7.0), (low, high, lines))
low, high, _ = j.rework_window(j.diff_matrix(base, state([R1, R2[:4] + ["x"] + R2[5:]], comments=["10"])))
check("rework window: re-run only, no overhead", (low, high) == (0.5, 1.0), (low, high))


print("deadline:")
check("add_working_days skips the weekend", j.add_working_days(date(2026, 9, 18), 1) == date(2026, 9, 21))
check("add_working_days: 0 days = same day", j.add_working_days(date(2026, 9, 8), 0) == date(2026, 9, 8))


def h(ts, *items):
    return {"created": f"{ts}:00.000-0600", "items": list(items)}


def st(frm, to):
    return {"field": "status", "fromString": frm, "toString": to}


def asg(to):
    return {"field": "assignee", "to": to}


def issue(due=None, est_h=16, status="In Progress"):
    return {"fields": {"status": {"name": status}, "duedate": due,
                       "timetracking": {"originalEstimateSeconds": est_h * 3600}}}


GRAB = h("2026-09-08T16:00", st("To Do", "In Progress"), asg(ME))          # Tuesday
DUE_SET = h("2026-09-08T17:00", {"field": "duedate", "from": None, "to": "2026-09-10"})
today = date(2026, 9, 9)

s = j.deadline_state("API-1", ME, issue(), [GRAB], today=today)
check("grab + 2d estimate → due Thursday, missing on the ticket",
      (s["state"], s["grab"], s["suggested"]) == ("MISSING", "2026-09-08", "2026-09-10"), s)
s = j.deadline_state("API-1", ME, issue(due="2026-09-10"), [GRAB, DUE_SET], today=today)
check("due date set to the rule → OK", s["state"] == "OK" and not s["warnings"], s)
s = j.deadline_state("API-1", ME, issue(), [h("2026-09-01T09:00", st("To Do", "In Progress"), asg(OTHER))], today=today)
check("someone else started it → NOT-GRABBED", s["state"] == "NOT-GRABBED", s)
s = j.deadline_state("API-1", ME, issue(est_h=0), [GRAB], today=today)
check("no estimate → NO-ESTIMATE", s["state"] == "NO-ESTIMATE", s)
BLOCK = [h("2026-09-09T08:00", st("In Progress", "Blocked"), asg(OTHER)),
         h("2026-09-10T08:00", st("Blocked", "Feedback"), asg(ME))]
s = j.deadline_state("API-1", ME, issue(due="2026-09-10"), [GRAB, DUE_SET] + BLOCK, today=today)
check("a 24h block after the date was set → NEEDS-UPDATE, +1d",
      (s["state"], s["blocked_days"], s["suggested"]) == ("NEEDS-UPDATE", 1, "2026-09-11"), s)
DEV = h("2026-09-14T10:00", st("In review", "In Progress"))
s = j.deadline_state("API-1", ME, issue(due="2026-09-10"), [GRAB, DUE_SET, DEV], today=today)
check("devolution with no estimate bump → NEEDS-UPDATE + warning",
      s["state"] == "NEEDS-UPDATE" and s["devolutions"] == ["2026-09-14"]
      and any("never followed by an estimate increase" in w for w in s["warnings"]), s)
BUMP = h("2026-09-14T11:00", {"field": "timeoriginalestimate", "from": "57600", "to": "86400"})
s = j.deadline_state("API-1", ME, issue(due="2026-09-10", est_h=24), [GRAB, DUE_SET, DEV, BUMP], today=today)
check("devolution + estimate bump → no warning, rule includes the rework",
      s["state"] == "NEEDS-UPDATE" and not s["warnings"] and s["suggested"] == "2026-09-11", s)
s = j.deadline_state("API-1", ME, issue(due="2026-09-10", status="Done"), [GRAB, DEV], today=today)
check("done → CLOSED", s["state"] == "CLOSED", s)
check("parse_jira_date keeps the offset", j.parse_jira_date("2026-09-08T16:00:59.123-0600") is not None)

print(f"\npassed: {PASSED}  failed: {FAILED}")
sys.exit(1 if FAILED else 0)
