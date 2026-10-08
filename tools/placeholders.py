# -*- coding: utf-8 -*-
"""Which Codex packs the game still draws with stand-ins (task 0120).

    python tools/placeholders.py            the packs still on stand-ins
    python tools/placeholders.py --check    fail on a stale or wrong entry

Reads `src/ui/placeholder_art.gd`'s `POSES`, one entry per line, the way the
registry's header asks them to be written. `--check` (run by verify) fails on
an entry that names a pack with no request in `implementation/backlog/packs/`,
a pack that is already `integrated` - its leaf forgot to delete the entry - a
runtime path that is already raster-owned in `assets/art_source/ownership.json`,
or a stand-in whose first frame is not on disk. Task 0290's visual gate reads
the listing.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
REGISTRY = os.path.join(ROOT, "src", "ui", "placeholder_art.gd")
OWNERSHIP = os.path.join(ROOT, "assets", "art_source", "ownership.json")
ACTORS = "sprites/actors/"

sys.path.insert(0, os.path.join(ROOT, "implementation", "backlog"))
import assets  # noqa: E402  - the art queue's own loader

ENTRY = re.compile(r'^\t&"([a-z0-9_]+)": \{"pack": "(A\d{3})", "frames": (\d+),'
                   r'.*"stand_in": &"([a-z0-9_]+)"')


def entries():
    out = []
    for line in open(REGISTRY, encoding="utf-8"):
        m = ENTRY.match(line)
        if m:
            out.append({"name": m.group(1), "pack": m.group(2),
                        "frames": int(m.group(3)), "stand_in": m.group(4)})
    return out


def raster_owned():
    data = json.load(open(OWNERSHIP, encoding="utf-8"))
    return {row["output"] for row in data.get("outputs", [])
            if row.get("owner") == "raster"}


def check(rows, packs):
    problems = []
    owned = raster_owned()
    for row in rows:
        pack = packs.get(row["pack"])
        if pack is None:
            problems.append("%s names %s, which has no request in packs/"
                            % (row["name"], row["pack"]))
        elif pack["status"] == "integrated":
            problems.append("%s names %s, which is already integrated - delete "
                            "the entry" % (row["name"], row["pack"]))
        for i in range(row["frames"]):
            path = "%s%s_%d.png" % (ACTORS, row["name"], i)
            if path in owned:
                problems.append("%s is raster-owned and still has a stand-in"
                                % path)
        first = os.path.join(ROOT, ACTORS, "%s_0.png" % row["stand_in"])
        if not os.path.exists(first):
            problems.append("%s's stand-in %s has no frame on disk"
                            % (row["name"], row["stand_in"]))
    return problems


def main():
    rows = entries()
    packs = assets.by_id(assets.load())
    if "--check" in sys.argv:
        problems = check(rows, packs)
        for line in problems:
            print("  " + line)
        print("%d stand-ins over %d packs, %d problem(s)" % (
            len(rows), len({r["pack"] for r in rows}), len(problems)))
        return 1 if problems else 0

    by_pack = {}
    for row in rows:
        by_pack.setdefault(row["pack"], []).append(row["name"])
    print("Packs the game still draws with stand-ins:")
    for pid in sorted(by_pack):
        pack = packs.get(pid)
        print("  %s %-10s %2d animations  %s" % (
            pid, pack["status"] if pack else "?", len(by_pack[pid]),
            pack["title"] if pack else "(no request)"))
    print("%d stand-ins over %d packs" % (len(rows), len(by_pack)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
