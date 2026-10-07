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

import importlib  # noqa: E402
import glob  # noqa: E402

## **Every part file, found rather than listed.** The import line used to
## name part1..part4 by hand, and a part added without editing it was a set
## of tasks nobody could see - verify compiled the file and printed PASS. Now
## a `tools/backlog/partN.py` is part of the backlog by existing, in N order.
PARTS = [importlib.import_module("backlog." + os.path.basename(p)[:-3])
         for p in sorted(glob.glob(os.path.join(ROOT, "tools", "backlog",
                                                "part*.py")),
                         key=lambda p: int(re.sub(r"\D", "",
                                                  os.path.basename(p))))]

GAME = "HARVEST THE NIGHT"
OUT = os.path.join(ROOT, "implementation", "prompts")
INDEX = os.path.join(ROOT, "implementation", "BACKLOG.md")

RE_STATUS = re.compile(r"^- \*\*Status:\*\* (\w+)(.*)$", re.M)

## The Codex art queue (implementation/backlog/packs/A001-*.md). An art task
## names its packs, and the index says when one is still waiting for them.
PACKS = os.path.join(ROOT, "implementation", "backlog", "packs")
ART_READY = ("approved", "integrated")

TEMPLATE = """# {id:04d} - {title}

- **Phase:** {phase}
- **Status:** todo
- **Depends on:** {deps}
- **Likely files:** {files}{art_line}

## Goal

{goal}
{dresses_block}
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
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
"""

## The paragraph every code task gets when Codex art will dress it later.
DRESSES = """
## Art

What this task puts on screen will be dressed by Codex art pack(s) {packs}
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.
"""


def all_tasks():
    tasks = [t for part in PARTS for t in part.TASKS]
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
    art = t.get("art", [])
    dresses = t.get("dresses", [])
    return TEMPLATE.format(
        id=t["id"], title=t["title"], phase=t["phase"], deps=deps,
        files=t.get("files", "-"), goal=t["goal"], req=req, dod=dod,
        art_line=("\n- **Art packs:** " + ", ".join(art)) if art else "",
        dresses_block=DRESSES.format(packs=", ".join(dresses))
        if dresses else "",
    )


def pack_states():
    """Status of every Codex art pack, by id, from its Status line."""
    out = {}
    for path in glob.glob(os.path.join(PACKS, "A*.md")):
        m = RE_STATUS.search(open(path, encoding="utf-8").read())
        out[os.path.basename(path)[:4]] = m.group(1) if m else "todo"
    return out


def art_waiting(t, packs):
    """The packs an art task still waits for, or an empty list."""
    return [a for a in t.get("art", []) if packs.get(a, "todo") not in ART_READY]


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
    packs = pack_states()
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
            waiting_art = art_waiting(t, packs)
            if waiting_art:
                head = ("Waits for Codex art "
                        + ", ".join(waiting_art) + ".")
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
            if st != "done" and art_waiting(t, packs):
                tail.append("waits for art " + ", ".join(art_waiting(t, packs)))
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
