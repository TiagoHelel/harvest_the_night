# -*- coding: utf-8 -*-
"""Generates implementation/prompts/*.md and the checkbox index BACKLOG.md.

The backlog lives as data in tools/backlog/part*.py so it stays easy to reorder,
re-scope or extend.

    python tools/gen_backlog.py               write missing prompts + the index
    python tools/gen_backlog.py --index-only  only rebuild BACKLOG.md
    python tools/gen_backlog.py --force       rewrite every prompt from data

Existing prompt files are NOT overwritten unless --force is passed, so progress
(the Status line) is never lost. The checkboxes in BACKLOG.md are derived from
those Status lines: never tick them by hand.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

from backlog import part1, part2, part3, part4  # noqa: E402

GAME = "HARVEST THE NIGHT"
OUT = os.path.join(ROOT, "implementation", "prompts")
INDEX = os.path.join(ROOT, "implementation", "BACKLOG.md")

RE_STATUS = re.compile(r"^- \*\*Status:\*\* (\w+)(.*)$", re.M)

TEMPLATE = """# {id:04d} - {title}

- **Phase:** {phase}
- **Status:** todo
- **Depends on:** {deps}
- **Likely files:** {files}

## Goal

{goal}

## Requirements

{req}

## Done when

{dod}
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert in
`src/tools/headless_check.gd` and a new input path with a case in
`src/tools/input_check.gd` - same pass, not later.

Code, identifiers, comments and every player-facing string are in English.
Art is generated from ASCII maps in `tools/gen_sprites.py`: do not hand-author
PNGs, edit the map and regenerate.

`design.md` is the source of truth for intent and `docs/reference-sheet.png`
for the look. If this task contradicts either, follow the task and say so in
the journal.
"""


def all_tasks():
    tasks = part1.TASKS + part2.TASKS + part3.TASKS + part4.TASKS
    ids = [t["id"] for t in tasks]
    assert len(ids) == len(set(ids)), "duplicate ids: %s" % sorted(
        set(i for i in ids if ids.count(i) > 1))
    for t in tasks:
        for d in t.get("deps", []):
            assert d in ids, "task %04d depends on missing %04d" % (t["id"], d)
            assert d != t["id"], "task %04d depends on itself" % t["id"]
    return tasks


def path_of(t):
    return os.path.join(OUT, "%04d-%s.md" % (t["id"], t["slug"]))


def read_status(t):
    """Current status of a task, straight from its prompt file."""
    p = path_of(t)
    if not os.path.exists(p):
        return "todo", ""
    m = RE_STATUS.search(open(p, encoding="utf-8").read())
    if not m:
        return "todo", ""
    return m.group(1), (m.group(2) or "").strip(" -")


def render(t):
    deps = ", ".join("%04d" % d for d in t.get("deps", [])) or "nothing"
    req = "\n".join("- " + r for r in t["req"])
    dod = "\n".join("- [ ] " + d for d in t["dod"])
    return TEMPLATE.format(
        id=t["id"], title=t["title"], phase=t["phase"], deps=deps,
        files=t.get("files", "-"), goal=t["goal"], req=req, dod=dod,
    )


## **What to pick up first**: the open tasks, the ready ones ahead of what
## they unlock. Sorting by id alone would put a task above the two it waits
## on whenever the ids run backwards, and saying what is next is the whole
## point of the section below.
def unlock_order(open_ones):
    left = list(open_ones)
    out = []
    while left:
        waiting = set(t["id"] for t in left)
        ready = [t for t in left
                 if not any(d in waiting for d in t.get("deps", []))]
        if not ready:                 # a cycle: print the rest by id
            out.extend(sorted(left, key=lambda t: t["id"]))
            break
        ready.sort(key=lambda t: t["id"])
        out.extend(ready)
        for t in ready:
            left.remove(t)
    return out


def write_index(tasks):
    """BACKLOG.md: one checkbox per task, ticked from the real Status line."""
    states = {t["id"]: read_status(t) for t in tasks}
    counts = {"todo": 0, "doing": 0, "done": 0, "blocked": 0}
    for st, _ in states.values():
        counts[st] = counts.get(st, 0) + 1
    total = len(tasks)
    done = counts["done"]
    filled = int(round(24.0 * done / max(1, total)))

    phases = []
    for t in tasks:
        if t["phase"] not in phases:
            phases.append(t["phase"])

    L = ["# Backlog - " + GAME, ""]
    L.append("`%s%s`  **%d / %d done**" % (
        "#" * filled, "." * (24 - filled), done, total))
    L.append("")
    L.append("%d doing / %d todo / %d blocked across %d phases." % (
        counts["doing"], counts["todo"], counts["blocked"], len(phases)))
    L.append("")
    # **What the loop will pick up next**, printed here because the first
    # thing anyone opening this file wants to know is where the work starts,
    # and counting checkboxes by eye is not an answer.
    nxt = None
    for t in unlock_order([t for t in tasks if states[t["id"]][0] != "done"]):
        nxt = t
        break
    L.append("Run one task - `/next-task`, which reads")
    L.append("`implementation/prompts/00-RUNNER-LOOP.md` and does exactly one:")
    L.append("")
    L.append("```")
    L.append("/next-task")
    L.append("```")
    L.append("")
    L.append("Keep going until it is all ticked:")
    L.append("")
    L.append("```")
    L.append("/loop /next-task")
    L.append("```")
    L.append("")
    if nxt is not None:
        L.append("First up: **%04d - %s**. The whole of what is left is"
                 % (nxt["id"], nxt["title"]))
        L.append("spelled out under *What is open* below, ready ones first.")
    else:
        L.append("Nothing is open: every task below is ticked.")
    L.append("")
    L.append("The boxes below are **generated** from the `Status:` line inside each")
    L.append("prompt file. Do not tick them by hand: use `python tools/task.py done 0042`,")
    L.append("which rewrites this file for you.")
    L.append("")

    # **The plan, not only the boxes.** A checkbox says WHAT is left and
    # nothing about why it matters or which one to start on, so every task
    # that is not done prints its goal and its requirements here. Written
    # from the same dicts the prompt files come from, which is the point: a
    # plan kept by hand in this file would go stale the first time a task is
    # re-scoped.
    open_ones = [t for t in tasks if states[t["id"]][0] != "done"]
    if open_ones:
        L.append("## What is open")
        L.append("")
        L.append("%d task(s) left, the ready ones first, then what they"
                 % len(open_ones))
        L.append("unlock. Generated from `tools/backlog/part*.py` together")
        L.append("with the prompt files, so the two cannot disagree.")
        L.append("")
        for t in unlock_order(open_ones):
            st, note = states[t["id"]]
            pending = [d for d in t.get("deps", [])
                       if states.get(d, ("todo", ""))[0] != "done"]
            head = "Ready to pick up."
            if pending:
                head = ("Waits on "
                        + ", ".join("%04d" % d for d in pending) + ".")
            if st == "doing":
                head = "In progress."
            elif st == "blocked":
                head = "Blocked" + ((": " + note) if note else ".")
            L.append("### %04d - %s" % (t["id"], t["title"]))
            L.append("")
            L.append("%s  Likely files: `%s`." % (head, t.get("files", "-")))
            L.append("")
            L.append(t["goal"])
            L.append("")
            for r in t["req"]:
                L.append("- " + r)
            L.append("")
            for d in t["dod"]:
                L.append("  - done when: " + d)
            L.append("")

    for ph in phases:
        mine = [t for t in tasks if t["phase"] == ph]
        ph_done = sum(1 for t in mine if states[t["id"]][0] == "done")
        L.append("## %s  (%d/%d)" % (ph, ph_done, len(mine)))
        L.append("")
        for t in mine:
            st, note = states[t["id"]]
            box = "x" if st == "done" else " "
            line = "- [%s] **%04d** [%s](prompts/%04d-%s.md)" % (
                box, t["id"], t["title"], t["id"], t["slug"])
            tail = []
            deps = t.get("deps", [])
            pending = [d for d in deps
                       if states.get(d, ("todo", ""))[0] != "done"]
            if st == "doing":
                tail.append("**DOING**")
            elif st == "blocked":
                tail.append("**BLOCKED**" + ((": " + note) if note else ""))
            elif pending:
                tail.append("needs " + ", ".join("%04d" % d for d in pending))
            if tail:
                line += " - " + " - ".join(tail)
            L.append(line)
        L.append("")

    with open(INDEX, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))
    return counts, total


def main():
    force = "--force" in sys.argv
    index_only = "--index-only" in sys.argv
    tasks = all_tasks()
    os.makedirs(OUT, exist_ok=True)

    written = kept = 0
    if not index_only:
        for t in tasks:
            p = path_of(t)
            if os.path.exists(p) and not force:
                kept += 1
                continue
            with open(p, "w", encoding="utf-8", newline="\n") as f:
                f.write(render(t))
            written += 1

    counts, total = write_index(tasks)
    if not index_only:
        print("prompts: %d written, %d kept" % (written, kept))
    print("index:   %d tasks, %d done, %d doing, %d todo, %d blocked" % (
        total, counts["done"], counts["doing"], counts["todo"],
        counts["blocked"]))


if __name__ == "__main__":
    main()
