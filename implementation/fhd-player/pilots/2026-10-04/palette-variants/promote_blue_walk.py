"""Promote the APPROVED blue 32px farmer walk into the game, pixel for pixel.

    python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py
    python tools/import_art.py
    python implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py --check

History. 2026-10-05: the blue walk of `palette-variants/blue/frames` entered
the game; its full-detail frames are the masters in
assets/art_source/player-fhd/walk-blue/frames. 2026-10-06: the owner chose the
"32px" detail (farmer32) and the importer sampled those masters 80 -> 40 -> 80.

**Since 2026-10-06 the walking source is the final approved pack**
`fhd-player/pilots/2026-10-06/walk-final-mirrored/runtime-80/walk`. It is that
32px walk with up-right phases 1, 3, 4, 5, 7 and 8 re-footed with lower boots
(walk-up-right-low-step, approved "excelente") and three exact whole-canvas
mirrors: left of right, down-right of down-left and - at the owner's
instruction - up-left of that NEW up-right. Every older review folder is a
superseded walking source, the old up-left kept in walk-up-right-low-step
included. This promoter

* checks all 128 exports of the pack against its contract.json, traces each
  pose to the approved low-step frame it copies (or, for up-left, flips) and
  checks the three mirror pairs in every phase, at both sizes;
* copies the 64 runtime-80 frames into versioned owned sources,
  assets/art_source/player-fhd/walk-blue-32px/2026-10-06/<direction>/NN.png,
  leaving the full-detail masters where they were;
* writes one manifest entry per frame: exact source colours, binary alpha,
  80x80 canvas, pivot (40, 72), draw scale 0.5, 0.1 s, `detail_wh` [40, 40] -
  pixel-idempotent on this art, whose pixels are already 2x2 blocks (checked),
  so the density guard stays without reducing anything again;
* and its --check (verify's "FHD player sources") holds every generated walk
  PNG pixel-identical to its approved frame and the generated mirror pairs
  exact, so a rebuild cannot quietly bring back an older walk.

Directions map down, right, up, left, down-right, up-right, up-left and
down-left to walk_south, _east, _north, _west, _south_east, _north_east,
_north_west and _south_west; file 01 is engine frame 0. Each pack directory is
bound as it is: the mirrors are already in its pixels, nothing is flipped
twice. Running plays the same eight phases at PlayerArt.RUN_FRAME_SECONDS.
Idle stays on the separate grounded poses (idle-grounded-review/
promote_idle.py); work verbs keep their art.
"""
from pathlib import Path
import argparse
import colorsys
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
sys.path.insert(0, str(HERE.parent / "idle-grounded-review"))
import promote_idle  # noqa: E402
sys.path.insert(0, str(PILOT))
import farmer_density  # noqa: E402

PACK = ROOT / "implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored"
PACK_CONTRACT = PACK / "contract.json"
LOW_STEP = ROOT / "implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step"
LOW_STEP_CONTRACT = LOW_STEP / "contract.json"
APPROVAL = LOW_STEP / "APPROVAL.json"
EDIT_PROMPTS = LOW_STEP / "individual-frame-prompts.json"
SOURCES = ROOT / "assets/art_source/player-fhd/walk-blue-32px/2026-10-06"
MASTERS = ROOT / "assets/art_source/player-fhd/walk-blue/frames"
CONTRACT = HERE / "runtime-blue-walk-contract.json"
OWNERSHIP = ROOT / "assets/art_source/ownership.json"
DATE = "2026-10-06"

CANVAS = [80, 80]
PIVOT = [40, 72]
DRAW_SCALE = 0.5
NATIVE_CANVAS = [40, 40]
NATIVE_PIVOT = [20, 36]
WALK_SECONDS = 0.1      # the approved cycle: eight phases at 10 FPS
FRAMES = 8

# Pack folder -> runtime direction suffix, in the approved "all eight" order.
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

# Mirrored folder -> the folder it is the exact whole-canvas flip of.
MIRRORS = {"left": "right", "down-right": "down-left", "up-left": "up-right"}

# The generation prompt each drawn (unmirrored) direction's cycle came from.
PROMPTS = {
    "down": "walk-down-size-review/down-r3.prompt.json",
    "right": "walk-right/materials-r3.prompt.txt",
    "up": "walk-up/materials-r1.prompt.txt",
    "down-left": "walk-down-left/materials-r1.prompt.json",
    "up-right": "walk-up-right/materials-r5.prompt.txt",
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


def rgba(path):
    with Image.open(path) as image:
        return image.convert("RGBA")


def flipped(path):
    return rgba(path).transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes()


def approved_pack():
    """The final pack's 64 poses, after checking all 128 of its exports, their
    descent from the approved low-step pack and the three mirror pairs."""
    approval = json.loads(APPROVAL.read_text(encoding="utf-8"))
    assert approval["status"] == "approved for integration" and approval["directions"] == list(DIRECTIONS)
    low_step = json.loads(LOW_STEP_CONTRACT.read_text(encoding="utf-8"))
    upstream = {(a["direction"], a["frame"]): a for a in low_step["assets"]}
    pack = json.loads(PACK_CONTRACT.read_text(encoding="utf-8"))
    assert pack["status"].startswith("approved source pack"), pack["status"]
    assert pack["directions"] == list(DIRECTIONS) and pack["frames_per_direction"] == FRAMES
    assert pack["mirror_pairs"] == MIRRORS and pack["frame_seconds"] == WALK_SECONDS
    assert pack["runtime_canvas_wh"] == CANVAS and pack["runtime_pivot_xy"] == PIVOT
    assert pack["runtime_draw_scale"] == DRAW_SCALE
    assert pack["native_canvas_wh"] == NATIVE_CANVAS and pack["native_pivot_xy"] == NATIVE_PIVOT
    poses = {}
    for asset in pack["assets"]:
        for kind in ("native-40", "runtime-80"):
            out = asset["outputs"][kind]
            assert sha((ROOT / out["path"]).read_bytes()) == out["sha256"], ("approved export changed", out["path"])
        # Each pose is an approved low-step frame, copied - up-left alone is
        # the flip of the new up-right, never the old up-left.
        direction, frame = asset["direction"], asset["frame"]
        mirror = direction == "up-left"
        assert asset["source_direction"] == ("up-right" if mirror else direction) and asset["mirrored"] == mirror
        origin = upstream[(asset["source_direction"], frame)]["outputs"]["runtime-80"]
        assert asset["source"] == origin["path"] and asset["source_sha256"] == origin["sha256"]
        assert sha((ROOT / origin["path"]).read_bytes()) == origin["sha256"], ("approved frame changed", origin["path"])
        runtime = ROOT / asset["outputs"]["runtime-80"]["path"]
        if mirror:
            assert rgba(runtime).tobytes() == flipped(ROOT / origin["path"]), ("up-left is not the new up-right", frame)
        else:
            assert runtime.read_bytes() == (ROOT / origin["path"]).read_bytes(), ("pose is not its approved frame", direction, frame)
        poses[(direction, frame)] = asset
    assert sorted(poses) == sorted((d, i) for d in DIRECTIONS for i in range(1, FRAMES + 1))
    for frame in range(1, FRAMES + 1):
        for kind in ("native-40", "runtime-80"):
            for mirror, master in MIRRORS.items():
                assert rgba(ROOT / poses[(mirror, frame)]["outputs"][kind]["path"]).tobytes() == \
                    flipped(ROOT / poses[(master, frame)]["outputs"][kind]["path"]), ("mirror pair", mirror, kind, frame)
        for direction in DIRECTIONS:
            small = rgba(ROOT / poses[(direction, frame)]["outputs"]["native-40"]["path"])
            large = rgba(ROOT / poses[(direction, frame)]["outputs"]["runtime-80"]["path"])
            assert small.resize(large.size, Image.Resampling.NEAREST).tobytes() == large.tobytes(), \
                ("runtime-80 is not native-40 at 2x", direction, frame)
    return pack, low_step, upstream, poses


def build_contract():
    pack, low_step, upstream, poses = approved_pack()
    frames = []
    for folder, suffix in DIRECTIONS.items():
        master = MIRRORS.get(folder, folder)
        for index in range(FRAMES):
            name = "%02d.png" % (index + 1)
            asset = poses[(folder, index + 1)]
            approved = ROOT / asset["outputs"]["runtime-80"]["path"]
            with Image.open(approved) as image:
                assert image.size == tuple(CANVAS) and image.mode == "RGBA", (folder, name)
                assert set(image.getchannel("A").get_flattened_data()) <= {0, 255}, ("partial alpha", folder, name)
                assert farmer_density.detailed(approved).tobytes() == image.tobytes(), \
                    ("approved frame is not at 32px detail", folder, name)
            # A mirror carries the edit of the frame it flips.
            edited = bool(upstream[(master, index + 1)]["edited"])
            frame = {
                "id": "walk_%s_%d" % (suffix, index),
                "direction": folder,
                "animation": "walk_" + suffix,
                "frame": index,
                "approved": file_entry(approved),
                "native_40": file_entry(ROOT / asset["outputs"]["native-40"]["path"]),
                "source": rel(SOURCES / folder / name),
                "master": file_entry(MASTERS / master / name),
                "prompt": file_entry(EDIT_PROMPTS if edited else PILOT / PROMPTS[master]),
                "edited": edited,
            }
            if master != folder:
                frame["mirrored_from"] = master
            frames.append(frame)
    return {
        "version": 2,
        "integration": "Final approved blue 32px walk integrated at the owner's request on %s" % DATE,
        "approval": file_entry(APPROVAL),
        "approved_pack": file_entry(PACK_CONTRACT),
        "approved_from": file_entry(LOW_STEP_CONTRACT),
        "supersedes": "the 2026-10-05 blue walk sampled to 32px from its full-detail masters (commit 5d4051ab); "
                      "walk-mirror-review and walk-up-right-low-step as walking sources, the old up-left included",
        "canvas_wh": CANVAS,
        "pivot_xy": PIVOT,
        "draw_scale": DRAW_SCALE,
        "detail_wh": farmer_density.DETAIL_WH,
        "screen_detail_1080p": "4x4 physical pixels per art pixel: the 32px farmer",
        "screen_height_1080p": "about 128 px: two 64px tiles, as Stardew Valley's 16x32 farmer at 4x",
        "walk_seconds": WALK_SECONDS,
        "run_seconds": "PlayerArt.RUN_FRAME_SECONDS, the same eight phases",
        "mirrors": MIRRORS,
        "edited_up_right_frames": low_step["edited_up_right_frames"],
        "garment_palette": low_step["blue_palette"],
        "frames": frames,
    }


def references(frame, contract_hash):
    master = "Full-detail master this frame descends from"
    if "mirrored_from" in frame:
        master += " (the frame is the exact mirror of %s)" % frame["mirrored_from"]
    return [
        {"path": frame["approved"]["path"], "sha256": frame["approved"]["sha256"],
         "role": "Final approved walking frame; the owned source is a byte-identical copy"},
        {"path": rel(PACK_CONTRACT), "sha256": sha(PACK_CONTRACT.read_bytes()),
         "role": "Final pack contract: 128 export hashes, three exact mirror pairs, up-left flipped from the new up-right"},
        {"path": rel(APPROVAL), "sha256": sha(APPROVAL.read_bytes()),
         "role": "Owner's approval of the low-step up-right and the other directions; its up-left policy is superseded"},
        {"path": frame["master"]["path"], "sha256": frame["master"]["sha256"], "role": master},
        {"path": rel(CONTRACT), "sha256": contract_hash,
         "role": "Runtime walk contract: canvas, ground pivot, frame order, timing, sources"},
    ]


def walk_entry(frame, contract_hash):
    source = ROOT / frame["source"]
    entry = {
        "id": "actors/" + frame["id"], "owner": "raster",
        "source": frame["source"], "source_sha256": frame["approved"]["sha256"],
        "crop_xywh": [0, 0, *CANVAS], "canvas_wh": CANVAS, "pivot_xy": PIVOT,
        "content_anchor_xy": PIVOT, "content_scale": 1.0,
        "detail_wh": farmer_density.DETAIL_WH, "draw_scale": DRAW_SCALE,
        "alpha_threshold": 128, "palette": import_art.EXACT_SOURCE,
        "animation": frame["animation"], "frame": frame["frame"],
        "seconds": WALK_SECONDS, "loop": True,
        "output": "sprites/actors/%s.png" % frame["id"],
        "prompt": frame["prompt"]["path"], "prompt_sha256": frame["prompt"]["sha256"],
        "references": references(frame, contract_hash),
        "tool": "built-in ImageGen", "generation_task": "fhd-walk-blue-32px",
        "approval": "Final approved eight-direction walking pack (walk-final-mirrored), integrated %s" % DATE,
    }
    assert source.is_file(), ("owned walk source missing; run this without --check", frame["source"])
    entry["output_sha256"] = import_art.sha(import_art.png(import_art.render_source(entry)))
    return entry


def runtime_entries(contract, contract_hash):
    walks = []
    for frame in contract["frames"]:
        walks.append(walk_entry(frame, contract_hash))
    return walks + promote_idle.runtime_entries()


def owned(entry):
    return entry["output"].startswith("sprites/actors/") and entry["animation"].startswith(FAMILIES)


def garment_drift(path, palette):
    """Blue garment pixels outside the approved twelve-colour palette."""
    image = rgba(path)
    drift = 0
    for y in range(28, image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            h, s, _v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if a and 185 <= h * 360 <= 270 and s >= .3 and b >= 6 and (r, g, b) not in palette:
                drift += 1
    return drift


def check(contract, content, entries):
    assert CONTRACT.read_bytes() == content, "Contract differs from the approved walking pack"
    for frame in contract["frames"]:
        source, approved = ROOT / frame["source"], ROOT / frame["approved"]["path"]
        assert source.read_bytes() == approved.read_bytes(), ("source is not the approved frame", frame["id"])
    manifest = json.loads(import_art.MANIFEST.read_text(encoding="utf-8"))
    present = {e["id"]: e for e in manifest["assets"] if owned(e)}
    wanted = {e["id"]: e for e in entries}
    assert present == wanted, "Runtime locomotion ownership/geometry drift: %s" % sorted(set(present) ^ set(wanted))
    palette = {tuple(rgb) for rgb in contract["garment_palette"]}
    walks = {"actors/" + f["id"]: f for f in contract["frames"]}
    for entry in entries:
        frame = walks.get(entry["id"])
        if frame is None:
            # Idle: the grounded pose at the farmer32 review's 32px detail.
            farmer_density.check_runtime(entry)
            continue
        # The approved frame, pixel for pixel: never the older walk, the
        # 64px masters or the 16px comparison variant.
        farmer_density.check_runtime(entry, ROOT / frame["approved"]["path"])
        assert entry["frame"] == int(Path(frame["approved"]["path"]).stem) - 1, ("phase order", entry["id"])
        assert entry["seconds"] == WALK_SECONDS and entry["loop"], ("timing", entry["id"])
        assert garment_drift(ROOT / entry["output"], palette) == 0, ("garment palette drift", entry["id"])
    # The three mirror pairs, as the game draws them, in every phase.
    output = {(f["direction"], f["frame"]): ROOT / ("sprites/actors/%s.png" % f["id"]) for f in contract["frames"]}
    for mirror, master in contract["mirrors"].items():
        for index in range(FRAMES):
            assert rgba(output[(mirror, index)]).tobytes() == flipped(output[(master, index)]), \
                ("runtime mirror pair broken", mirror, master, index)
    promote_idle.check()
    print("FHD RUNTIME: final approved 2026-10-06 walk, 8 directions x %d phases (pixel-identical to "
          "walk-final-mirrored/runtime-80, 3 mirror pairs exact), + 8 grounded idle poses; 32px detail, "
          "exact colours, 80x80 canvas, pivot (40,72), 0.5 draw scale, 0.1 s (two tiles, 128px at 1080p)." % FRAMES)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    contract = build_contract()
    if not args.check:
        for frame in contract["frames"]:
            target = ROOT / frame["source"]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / frame["approved"]["path"], target)
        (SOURCES.parent / ".gdignore").write_text("", encoding="utf-8")
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
    print("Registered %d locomotion frames from the final approved walking pack, retired %d files; "
          "run python tools/import_art.py." % (len(entries), removed))


if __name__ == "__main__":
    main()
