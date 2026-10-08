# -*- coding: utf-8 -*-
"""Read and write the Status line of a backlog prompt.

    python tools/task.py next                 -> prints the next actionable task
    python tools/task.py list [todo|done|...] -> lists tasks by status
    python tools/task.py doing 0042
    python tools/task.py done 0042
    python tools/task.py blocked 0042 "waiting on a decision"
    python tools/task.py stats
    python tools/task.py index                -> rebuild the BACKLOG.md checkboxes

Every status change rebuilds implementation/BACKLOG.md, so the checkboxes there
always match the Status lines in the prompt files.
"""
import glob
import os
import re
import subprocess
import sys

from textfile import write_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS = os.path.join(ROOT, "implementation", "prompts")
STATUSES = ("todo", "doing", "done", "blocked")

RE_STATUS = re.compile(r"^- \*\*Status:\*\* (\w+)(.*)$", re.M)
RE_DEPS = re.compile(r"^- \*\*Depends on:\*\* (.+)$", re.M)
RE_ART = re.compile(r"^- \*\*Art packs:\*\* (.+)$", re.M)

## **Art tasks wait for their art.** A task with an `Art packs:` line puts a
## Codex delivery into the game, and it is not ready until every pack it
## names is approved in implementation/backlog/packs/. Without this the loop
## spent a whole turn on each one just to find the art missing.
PACKS = os.path.join(ROOT, "implementation", "backlog", "packs")
ART_READY = ("approved", "integrated")


def pack_states():
    out = {}
    for path in glob.glob(os.path.join(PACKS, "A*.md")):
        m = RE_STATUS.search(open(path, encoding="utf-8").read())
        out[os.path.basename(path)[:4]] = m.group(1) if m else "todo"
    return out


def art_waiting(t, packs):
    return [a for a in t["art"] if packs.get(a, "todo") not in ART_READY]


def load():
    tasks = []
    for path in sorted(glob.glob(os.path.join(PROMPTS, "*.md"))):
        base = os.path.basename(path)
        if not base[:4].isdigit():
            continue          # 00-RUNNER-LOOP.md and friends are not tasks
        text = open(path, encoding="utf-8").read()
        m = RE_STATUS.search(text)
        d = RE_DEPS.search(text)
        a = RE_ART.search(text)
        deps = []
        if d and "nothing" not in d.group(1):
            deps = [int(x) for x in re.findall(r"\d+", d.group(1))]
        # The prompt's heading is "# 0042 - Title"; drop the number so the
        # id is not printed twice on every line of output.
        head = text.split("\n", 1)[0].lstrip("# ").strip()
        head = re.sub(r"^\d{4}\s*-\s*", "", head)
        tasks.append({
            "id": int(base[:4]),
            "path": path,
            "title": head,
            "status": m.group(1) if m else "todo",
            "note": (m.group(2) or "").strip() if m else "",
            "deps": deps,
            "art": re.findall(r"A\d{3}", a.group(1)) if a else [],
        })
    return tasks


def by_id(tasks):
    return {t["id"]: t for t in tasks}


def refresh_index():
    """Keep the checkbox index in step with the Status lines."""
    try:
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_backlog.py"),
                        "--index-only"], cwd=ROOT, check=True,
                       capture_output=True, text=True)
    except Exception as e:                      # never block a status change
        print("  (could not rebuild BACKLOG.md: %s)" % e)


def set_status(tid, status, note=""):
    tasks = by_id(load())
    if tid not in tasks:
        sys.exit("no task %04d" % tid)
    t = tasks[tid]
    text = open(t["path"], encoding="utf-8").read()
    line = "- **Status:** " + status
    if note:
        line += " - " + note
    text, n = RE_STATUS.subn(line.replace("\\", "\\\\"), text, count=1)
    if n == 0:
        sys.exit("%s has no Status line" % t["path"])
    write_text(t["path"], text)
    print("%04d %s -> %s%s" % (tid, t["title"], status,
                               (" (%s)" % note) if note else ""))
    refresh_index()


def next_task():
    tasks = load()
    ids = by_id(tasks)
    for t in tasks:
        if t["status"] == "doing":
            return t, "resume (was left doing)"
    packs = pack_states()
    for t in tasks:
        if t["status"] != "todo":
            continue
        pending = [d for d in t["deps"]
                   if d in ids and ids[d]["status"] != "done"]
        if pending or art_waiting(t, packs):
            continue
        return t, "ready"
    return None, "nothing actionable"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "next":
        t, why = next_task()
        if t is None:
            everything = load()
            blocked = [x for x in everything if x["status"] == "blocked"]
            packs = pack_states()
            art = [x for x in everything
                   if x["status"] == "todo" and art_waiting(x, packs)]
            print("nothing actionable. blocked: %d, waiting for Codex art: %d"
                  % (len(blocked), len(art)))
            for b in blocked:
                print("  %04d %s - %s" % (b["id"], b["title"], b["note"]))
            for w in art:
                print("  %04d %s - waits for %s" % (
                    w["id"], w["title"], ", ".join(art_waiting(w, packs))))
            return
        print("%04d %s  [%s]" % (t["id"], t["title"], why))
        print(os.path.relpath(t["path"], ROOT).replace("\\", "/"))
    elif cmd == "list":
        want = sys.argv[2] if len(sys.argv) > 2 else None
        for t in load():
            if want and t["status"] != want:
                continue
            print("%04d %-8s %s" % (t["id"], t["status"], t["title"]))
    elif cmd == "index":
        refresh_index()
        print("BACKLOG.md rebuilt")
    elif cmd == "stats":
        tasks = load()
        counts = {s: 0 for s in STATUSES}
        for t in tasks:
            counts[t["status"]] = counts.get(t["status"], 0) + 1
        total = len(tasks)
        done = counts["done"]
        packs = pack_states()
        waiting = sum(1 for t in tasks
                      if t["status"] == "todo" and art_waiting(t, packs))
        print("%d tasks: %d done, %d doing, %d todo, %d blocked  (%.0f%%)" % (
            total, done, counts["doing"], counts["todo"], counts["blocked"],
            100.0 * done / max(1, total))
              + ("  - %d of the todo wait for Codex art" % waiting
                 if waiting else ""))
    elif cmd in STATUSES:
        if len(sys.argv) < 3:
            sys.exit("usage: task.py %s <id> [note]" % cmd)
        note = sys.argv[3] if len(sys.argv) > 3 else ""
        set_status(int(sys.argv[2]), cmd, note)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
