"""Promote the reviewed BLUE farmer walk into the game, pixel for pixel.

    python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py
    python tools/import_art.py
    python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py --check

User request, 2026-10-05: integrate the walking sprites of
`palette-variants/blue/frames`, blue only, preserving size, alignment and
frame order, with the farmer as tall as Stardew Valley's on a 1920x1080 screen.

* **Size.** Every 80x80 native frame is copied unchanged (all 33k source
  colours, binary alpha) and drawn at 0.5 of the 480x270 viewport, so one
  authored pixel is 2x2 screen pixels at 1920x1080. The farmer is ~64 native
  pixels tall: 32 logical pixels, two 16px tiles, 128 screen pixels - the
  height of Stardew Valley's 16x32 farmer drawn at its 4x scale.
* **Alignment.** One ground pivot (40, 72) for all 64 frames. No frame is
  re-registered, so the reviewed bob and sway are what the game shows.
* **Order.** Files 01..08 become frames 0..7, in the reviewed 10 FPS cycle.

There was no idle or run art for this farmer, and the old (different) farmer
appearing whenever the player stops would be worse than a held pose. So each
direction's idle is one of its own walk frames, held (`IDLE_FRAME`), and the
run plays the same cycle faster in `PlayerArt`. Work verbs and reactions keep
their existing art until replacements are drawn.

Supersedes `implementation/fhd-player/directional/promote_locomotion.py` for
the runtime idle/walk/run families; that review and its sources are retained.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import sys

from PIL import Image

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "tools"))
import import_art  # noqa: E402

REVIEW = HERE / "blue" / "frames"
SOURCES = ROOT / "assets/art_source/player-fhd/walk-blue/frames"
CONTRACT = HERE / "runtime-blue-walk-contract.json"
OWNERSHIP = ROOT / "assets/art_source/ownership.json"
DATE = "2026-10-05"

CANVAS = [80, 80]
PIVOT = [40, 72]
DRAW_SCALE = 0.5
WALK_SECONDS = 0.1      # the reviewed cycle: eight frames at 10 FPS
IDLE_SECONDS = 0.55
IDLE_SLOTS = 3
FRAMES = 8

# Review folder -> runtime direction suffix, in the reviewed "all eight" order.
DIRECTIONS = {
    "down": "south",
    "right": "east",
    "up": "north",
    "left": "west",
    "down-right": "south_east",
    "up-right": "north_east",
    "up-left": "north_west",
    "down-left": "south_west",
}

# The held standing pose per direction (1-based file number): feet closest to
# planted or together. A stand-in until idle art is drawn for this farmer.
IDLE_FRAME = {
    "down": 1, "up": 5, "left": 7, "right": 7,
    "down-left": 3, "down-right": 3, "up-left": 7, "up-right": 3,
}

# The generation prompt each direction's approved cycle came from.
PROMPTS = {
    "down": "walk-down-size-review/down-r3.prompt.json",
    "right": "walk-right/materials-r3.prompt.txt",
    "up": "walk-up/materials-r1.prompt.txt",
    "left": "walk-left/materials-r2.prompt.txt",
    "down-right": "walk-down-right/materials-r5.prompt.txt",
    "down-left": "walk-down-left/materials-r1.prompt.json",
    "up-right": "walk-up-right/materials-r5.prompt.txt",
    "up-left": "walk-up-left/rebuild-materials-r7.prompt.txt",
}

# Every runtime family this promotion owns. Anything else under
# sprites/actors (work verbs, reactions, shadow) is left alone.
FAMILIES = ("idle_", "walk_", "run_")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def rel(path):
    return Path(path).resolve().relative_to(ROOT).as_posix()


def file_entry(path):
    return {"path": rel(path), "sha256": sha(Path(path).read_bytes())}


def build_contract():
    selection = json.loads((HERE / "selection.json").read_text(encoding="utf-8"))
    frames = []
    for folder, suffix in DIRECTIONS.items():
        approved = selection[folder]
        assert len(approved) == FRAMES, folder
        for index in range(FRAMES):
            name = "%02d.png" % (index + 1)
            review = REVIEW / folder / name
            before = PILOT / approved[index]["path"]
            assert sha(before.read_bytes()) == approved[index]["sha256"], ("approved pose changed", folder, name)
            with Image.open(review) as image:
                assert image.size == tuple(CANVAS) and image.mode == "RGBA", (folder, name)
                alpha = set(image.getchannel("A").get_flattened_data())
                assert alpha <= {0, 255}, ("reviewed frame has partial alpha", folder, name)
            frames.append({
                "id": "walk_%s_%d" % (suffix, index),
                "direction": folder,
                "animation": "walk_" + suffix,
                "frame": index,
                "review": file_entry(review),
                "source": rel(SOURCES / folder / name),
                "approved_pose": file_entry(before),
                "prompt": file_entry(PILOT / PROMPTS[folder]),
            })
    idle = {DIRECTIONS[folder]: "walk_%s_%d" % (DIRECTIONS[folder], IDLE_FRAME[folder] - 1)
            for folder in DIRECTIONS}
    return {
        "version": 1,
        "integration": "User requested runtime integration of the blue walk on %s" % DATE,
        "palette_review": file_entry(HERE / "validation.json"),
        "canvas_wh": CANVAS,
        "pivot_xy": PIVOT,
        "draw_scale": DRAW_SCALE,
        "native_body_height": [63, 65],
        "screen_height_1080p": "about 128 px: two 64px tiles, as Stardew Valley's 16x32 farmer at 4x",
        "walk_seconds": WALK_SECONDS,
        "idle_seconds": IDLE_SECONDS,
        "idle_slots": IDLE_SLOTS,
        "idle_from_walk_frame": idle,
        "frames": frames,
    }


def references(frame, contract_hash):
    return [
        {"path": frame["approved_pose"]["path"], "sha256": frame["approved_pose"]["sha256"],
         "role": "Approved walking pose before the blue garment palette"},
        {"path": frame["review"]["path"], "sha256": frame["review"]["sha256"],
         "role": "Reviewed blue frame; the source is a byte-identical copy"},
        {"path": rel(CONTRACT), "sha256": contract_hash,
         "role": "Runtime blue walk contract: canvas, ground pivot, frame order, idle choice"},
    ]


def walk_entry(frame, contract_hash):
    source = ROOT / frame["source"]
    entry = {
        "id": "actors/" + frame["id"], "owner": "raster",
        "source": frame["source"], "source_sha256": sha(source.read_bytes()),
        "crop_xywh": [0, 0, *CANVAS], "canvas_wh": CANVAS, "pivot_xy": PIVOT,
        "content_anchor_xy": PIVOT, "content_scale": 1.0, "draw_scale": DRAW_SCALE,
        "alpha_threshold": 128, "palette": import_art.EXACT_SOURCE,
        "animation": frame["animation"], "frame": frame["frame"],
        "seconds": WALK_SECONDS, "loop": True,
        "output": "sprites/actors/%s.png" % frame["id"],
        "prompt": frame["prompt"]["path"], "prompt_sha256": frame["prompt"]["sha256"],
        "references": references(frame, contract_hash),
        "tool": "built-in ImageGen", "generation_task": "fhd-walk-blue",
        "approval": "Blue walk integrated at user request on %s" % DATE,
    }
    entry["output_sha256"] = import_art.sha(import_art.png(import_art.render_source(entry)))
    return entry


def idle_entry(suffix, index, walk, contract_hash, frame):
    return {
        "id": "actors/idle_%s_%d" % (suffix, index), "owner": "raster",
        "canvas_wh": CANVAS, "pivot_xy": PIVOT, "draw_scale": DRAW_SCALE,
        "palette": import_art.EXACT_SOURCE,
        "animation": "idle_" + suffix, "frame": index, "seconds": IDLE_SECONDS, "loop": True,
        "output": "sprites/actors/idle_%s_%d.png" % (suffix, index),
        "output_sha256": walk["output_sha256"],
        "prompt": walk["prompt"], "prompt_sha256": walk["prompt_sha256"],
        "references": references(frame, contract_hash),
        "tool": "built-in ImageGen", "generation_task": "fhd-walk-blue",
        "approval": "Held walk frame as idle until idle art exists; %s" % DATE,
        "input": walk["id"], "operation": "copy", "alias_of": walk["id"],
    }


def runtime_entries(contract, contract_hash):
    walks, by_id = [], {}
    for frame in contract["frames"]:
        entry = walk_entry(frame, contract_hash)
        walks.append(entry)
        by_id[frame["id"]] = (entry, frame)
    idles = []
    for suffix, walk_id in contract["idle_from_walk_frame"].items():
        entry, frame = by_id[walk_id]
        # Three slots, the shape the idle blink (and the legacy sheet's idle
        # rows) expect. All three hold the same pose until idle art exists.
        for index in range(IDLE_SLOTS):
            idles.append(idle_entry(suffix, index, entry, contract_hash, frame))
    return walks + idles


def owned(entry):
    return entry["output"].startswith("sprites/actors/") and entry["animation"].startswith(FAMILIES)


def pixels(path):
    with Image.open(path) as image:
        return image.convert("RGBA").tobytes()


def check(contract, content, entries):
    assert CONTRACT.read_bytes() == content, "Contract differs from the reviewed blue frames"
    for frame in contract["frames"]:
        source, review = ROOT / frame["source"], ROOT / frame["review"]["path"]
        assert source.read_bytes() == review.read_bytes(), ("source is not the reviewed frame", frame["id"])
    manifest = json.loads(import_art.MANIFEST.read_text(encoding="utf-8"))
    present = {e["id"]: e for e in manifest["assets"] if owned(e)}
    wanted = {e["id"]: e for e in entries}
    assert present == wanted, "Runtime locomotion ownership/geometry drift: %s" % sorted(set(present) ^ set(wanted))
    for entry in entries:
        origin = ROOT / (entry["source"] if "source" in entry else wanted[entry["input"]]["source"])
        assert pixels(ROOT / entry["output"]) == pixels(origin), ("runtime pixels differ from source", entry["id"])
    print("FHD RUNTIME: blue walk, 8 directions x %d frames + 8 held idle poses; exact source pixels, "
          "80x80 canvas, pivot (40,72), 0.5 draw scale (two tiles, 128px at 1080p)." % FRAMES)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if not args.check:
        for folder in DIRECTIONS:
            (SOURCES / folder).mkdir(parents=True, exist_ok=True)
            for index in range(FRAMES):
                name = "%02d.png" % (index + 1)
                shutil.copyfile(REVIEW / folder / name, SOURCES / folder / name)
        (SOURCES.parent / ".gdignore").write_text("", encoding="utf-8")
    contract = build_contract()
    content = (json.dumps(contract, indent=2) + "\n").encode()
    entries = runtime_entries(contract, sha(content))
    if args.check:
        check(contract, content, entries)
        return
    CONTRACT.write_bytes(content)
    manifest = json.loads(import_art.MANIFEST.read_text(encoding="utf-8"))
    old = [e for e in manifest["assets"] if owned(e)]
    first = min(i for i, e in enumerate(manifest["assets"]) if owned(e))
    kept = [e for e in manifest["assets"] if not owned(e)]
    kept[first:first] = entries
    manifest["assets"] = kept
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    old_paths, new_paths = {e["output"] for e in old}, {e["output"] for e in entries}
    registry = json.loads(OWNERSHIP.read_text(encoding="utf-8"))
    registry["outputs"] = [e for e in registry["outputs"] if e["output"] not in old_paths]
    registry["outputs"] += [{"output": p, "owner": "raster"} for p in sorted(new_paths)]
    registry["outputs"].sort(key=lambda e: e["output"])
    OWNERSHIP.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8", newline="\n")
    removed = 0
    for path in sorted(old_paths - new_paths):
        for stale in (ROOT / path, ROOT / (path + ".import")):
            if stale.exists():
                stale.unlink()
                removed += 1
    print("Registered %d blue locomotion frames, retired %d files; run python tools/import_art.py."
          % (len(entries), removed))


if __name__ == "__main__":
    main()
