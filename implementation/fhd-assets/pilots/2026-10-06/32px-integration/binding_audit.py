"""Audit how the game binds the 320 non-character runtime PNGs of the 32px review.

    python implementation/fhd-assets/pilots/2026-10-06/32px-integration/binding_audit.py
    python implementation/fhd-assets/pilots/2026-10-06/32px-integration/binding_audit.py --report

For every path in ../32px-review/contract.json this checks the bytes against
the inventory hash, the production owner (ownership.json) and recipe (the
raster manifest or the ASCII generator), and then **where the running game
actually uses it**: each probe under probe/ extends an existing showcase or
the real shot scenarios and records, once a frame, which inventory textures
are alive in Godot's resource cache (probe/probe_common.gd). The views load
by computed names, so this asks the views rather than guessing their string
formats. A path no view holds is then looked up in the source text.

Writes binding-report.json and binding-report.md next to this file. Reads
production files only; the shot probe's pictures go to a scratch folder that
is deleted afterwards.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
REVIEW = HERE.parent / "32px-review"
PROBE = HERE / "probe"
RES_PROBE = "res://" + PROBE.relative_to(ROOT).as_posix() + "/"
GODOT = os.environ.get("GODOT", "C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe")
SCRATCH_ID = "assets32-probe"

# (probe script base, label, arguments, needs a real window)
RUNS = [
    ("art_showcase", "art", ["--check"], False),
    *[("art_showcase", "art", ["--" + flag, "--check"], False)
      for flag in ("terrain", "water", "props", "crops", "house", "stations",
                   "locomotion", "work", "reactions", "fishing-hold")],
    ("visibility_showcase", "visibility", ["--check"], False),
    ("house_check", "house_check", ["--check"], False),
    ("tower_showcase", "towers", ["--check"], False),
    ("barrier_showcase", "barriers", ["--check"], False),
    ("enemy_showcase", "enemies", ["--check"], False),
    ("giant_showcase", "giant", ["--check"], False),
    ("effect_showcase", "effects", ["--check"], False),
    ("ui_art_showcase", "ui", ["--check"], False),
    ("atmosphere_showcase", "atmosphere", ["--check"], False),
    ("tree_wind_showcase", "tree_wind", ["--check"], True),
    ("shot", "shot", [SCRATCH_ID], True),
]

PROBE_SCRIPT = '''extends "res://src/tools/{base}.gd"

## Binding probe: the unchanged {base} plus a once-a-frame look at
## which inventory textures are alive. See probe_common.gd.

const PROBE := preload("{res}probe_common.gd")


func _process(_delta: float) -> bool:
	PROBE.poll("{label}")
	return false
'''


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def inventory():
    contract = json.loads((REVIEW / "contract.json").read_text(encoding="utf-8"))
    entries = contract["entries"]
    assert len(entries) == 320 and len({e["path"] for e in entries}) == 320
    return entries


def write_probes(entries):
    PROBE.mkdir(parents=True, exist_ok=True)
    (PROBE / "inventory.txt").write_text(
        "".join("res://%s\n" % e["path"] for e in sorted(entries, key=lambda e: e["path"])),
        encoding="utf-8", newline="\n")
    for base, label, _args, _window in RUNS:
        text = PROBE_SCRIPT.format(base=base, res=RES_PROBE, label=label)
        target = PROBE / ("probe_%s.gd" % base)
        if not target.exists() or target.read_text(encoding="utf-8") != text:
            target.write_text(text, encoding="utf-8", newline="\n")


def run_probes():
    for base, label, args, window in RUNS:
        flags = ["--position", "-4000,-4000"] if window else ["--headless"]
        command = [GODOT, "--path", str(ROOT), "--fixed-fps", "60", *flags,
                   "--script", RES_PROBE + "probe_%s.gd" % base, "--", *args]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=900)
        tail = [line for line in result.stdout.splitlines() if line.strip()][-1:] or [""]
        print("  %-22s %-28s exit %d  %s" % (base, " ".join(args), result.returncode, tail[0][:90]))
    scratch = ROOT / "implementation/shots" / SCRATCH_ID
    if scratch.exists():
        shutil.rmtree(scratch)


def seen_by():
    out = {}
    for path in sorted((PROBE / "seen").glob("*.txt")):
        for line in path.read_text(encoding="utf-8").splitlines():
            out.setdefault(line.strip(), []).append(path.stem)
    return out


def source_text():
    texts = {}
    for folder in ("src", "scenes", "assets/theme", "assets"):
        for path in (ROOT / folder).rglob("*"):
            if path.suffix in (".gd", ".tscn", ".tres") and "art_source" not in path.parts:
                texts[path.relative_to(ROOT).as_posix()] = path.read_text(encoding="utf-8", errors="replace")
    return texts


def static_refs(path, texts):
    name = Path(path).stem
    found = []
    for where, text in texts.items():
        if "res://" + path in text or re.search(r'["/]%s(\.png)?"' % re.escape(name), text):
            found.append(where)
    return sorted(set(found))


def recipe(entry, manifest, owners):
    owner = owners.get(entry["path"], "UNREGISTERED")
    if owner != "raster":
        return owner, "ASCII map in tools/gen_sprites.py" if owner == "ascii" else ""
    m = manifest[entry["path"]]
    if "source" in m:
        return owner, "source " + m["source"]
    return owner, "%s of %s" % (m["operation"], m["input"])


def report(entries):
    manifest = {e["output"]: e for e in json.loads((ROOT / "assets/art_source/manifest.json").read_text(encoding="utf-8"))["assets"]}
    owners = {o["output"]: o["owner"] for o in json.loads((ROOT / "assets/art_source/ownership.json").read_text(encoding="utf-8"))["outputs"]}
    seen = seen_by()
    texts = source_text()
    derived_from = {}
    for m in manifest.values():
        if "input" in m:
            derived_from.setdefault(manifest_output(manifest, m["input"]), []).append(m["output"])
        for part in m.get("parts", []):
            derived_from.setdefault(manifest_output(manifest, part["input"]), []).append(m["output"])
    rows = []
    for entry in sorted(entries, key=lambda e: e["path"]):
        path = entry["path"]
        owner, how = recipe(entry, manifest, owners)
        row = {
            "path": path, "group": entry["group"],
            "hash_unchanged": sha(ROOT / path) == entry["sha256"],
            "owner": owner, "recipe": how,
            "runtime_seen_in": seen.get("res://" + path, []),
            "feeds": sorted(derived_from.get(path, [])),
        }
        if not row["runtime_seen_in"]:
            row["source_refs"] = static_refs(path, texts)
        rows.append(row)
    seen_paths = {r["path"] for r in rows if r["runtime_seen_in"]}
    for row in rows:
        row["role"] = role(row, manifest, seen_paths)
    return rows


def role(row, manifest, seen_paths):
    """What the file is for, judged from how the game consumes it."""
    if row["runtime_seen_in"]:
        return "drawn at runtime"
    path = row["path"]
    if path.startswith("sprites/terrain/") and path != "sprites/terrain/atlas.png":
        return "terrain atlas source: atlas.png is built from it, cell for cell (check_terrain_art)"
    if row["feeds"] and all(manifest[f].get("operation") == "compose" or "input" in manifest[f] for f in row["feeds"]):
        return "module composed into %d runtime joins" % len(set(row["feeds"]))
    entry = manifest[path]
    if entry.get("operation") == "slice":
        master = manifest_output(manifest, entry["input"])
        if master in seen_paths:
            return "exact cut of %s, which WorldView draws whole; per-cell fallback" % master
    return "UNBOUND"


def manifest_output(manifest, ident):
    for m in manifest.values():
        if m["id"] == ident:
            return m["output"]
    return ident


def write_report(rows):
    (HERE / "binding-report.json").write_text(json.dumps(rows, indent=1) + "\n", encoding="utf-8", newline="\n")
    groups = {}
    for row in rows:
        g = groups.setdefault(row["group"], {"total": 0, "seen": 0, "unseen": []})
        g["total"] += 1
        if row["runtime_seen_in"]:
            g["seen"] += 1
        else:
            g["unseen"].append(row)
    lines = ["# Runtime bindings of the 320 non-character PNGs", "",
             "Generated by binding_audit.py. *Seen* = alive in a running view's",
             "resource cache during a showcase or a real shot scenario.", "",
             "| group | files | seen at runtime | not seen |", "|---|---|---|---|"]
    for name in sorted(groups):
        g = groups[name]
        lines.append("| %s | %d | %d | %d |" % (name, g["total"], g["seen"], len(g["unseen"])))
    roles = {}
    for row in rows:
        key = row["role"].split(":")[0].split(" of ")[0].split(" composed")[0]
        roles[key] = roles.get(key, 0) + 1
    lines += ["", "| role | files |", "|---|---|"]
    for key in sorted(roles):
        lines.append("| %s | %d |" % (key, roles[key]))
    lines += ["", "## Not drawn directly, and why", ""]
    for name in sorted(groups):
        for row in groups[name]["unseen"]:
            lines.append("- `%s` - %s (%s)" % (row["path"], row["role"], row["recipe"]))
    (HERE / "binding-report.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    seen = sum(1 for r in rows if r["runtime_seen_in"])
    unbound = [r["path"] for r in rows if r["role"] == "UNBOUND"]
    print("BINDINGS: %d inventory files, %d hashes unchanged, %d seen at runtime, %d consumed "
          "offline in their role, %d unbound %s" % (len(rows), sum(r["hash_unchanged"] for r in rows),
          seen, len(rows) - seen - len(unbound), len(unbound), unbound))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", action="store_true", help="only rebuild the report from probe/seen")
    args = parser.parse_args()
    entries = inventory()
    if not args.report:
        write_probes(entries)
        shutil.rmtree(PROBE / "seen", ignore_errors=True)
        run_probes()
    write_report(report(entries))


if __name__ == "__main__":
    sys.exit(main())
