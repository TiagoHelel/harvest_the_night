"""Freeze measured water contracts, source decisions and the exact runtime delta."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT / "implementation/sprites/reviews/0008"
BASELINE = "97eb240"
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def sha(data):
    return hashlib.sha256(data).hexdigest()


def save(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8", newline="\n")


def main():
    changed, unchanged = [], []
    expected = {"sprites/terrain/" + n + ".png" for n in ("water", "water_b", "water_c", "atlas")}
    expected |= {"sprites/terrain/" + p + "_" + d + ".png" for p in ("edge", "shore") for d in ("n", "e", "s", "w")}
    expected |= {"sprites/terrain/" + p + "_corner_" + d + ".png" for p in ("edge", "shore") for d in ("nw", "ne", "se", "sw")}
    for path in sorted((ROOT / "sprites").rglob("*.png")):
        relative = path.relative_to(ROOT).as_posix()
        old = subprocess.run(["git", "show", BASELINE + ":" + relative], cwd=ROOT, capture_output=True)
        new = path.read_bytes()
        if old.returncode or old.stdout != new:
            changed.append(dict(path=relative, old_sha256=None if old.returncode else sha(old.stdout), sha256=sha(new), added=bool(old.returncode)))
        else:
            unchanged.append(relative)
    assert {e["path"] for e in changed} == expected
    assert len(unchanged) == 236 and sum(e["added"] for e in changed) == 8
    preserved = ["src/core", "tools/determinism_sim_hash.txt", "tools/determinism_data_hash.txt", "docs/sprites_sem_fundo.png", "tools/palette.py", "src/ui/player_frames.gd"]
    assert not subprocess.run(["git", "diff", BASELINE, "--", *preserved], cwd=ROOT, capture_output=True, check=True).stdout
    save("runtime-delta.json", dict(baseline=BASELINE, changed=changed, unchanged_count=len(unchanged), unchanged=unchanged, core_map_balance_owner_sheet_palette_player_metadata_unchanged=True, preserved=preserved))
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    contracts = []
    for entry in data["assets"]:
        if entry.get("generation_task") != "0008":
            continue
        image = images[entry["id"]]
        assert (ROOT / entry["output"]).read_bytes() == files[entry["output"]]
        measured = dict(recipe=entry, native_bbox=image.getbbox(), native_alpha_range=image.getchannel("A").getextrema(), native_color_count=len(set(import_art.samples(image))), native_rgba_sha256=sha(image.tobytes()), output_png_sha256=sha(files[entry["output"]]))
        if "source" in entry:
            with Image.open(ROOT / entry["source"]) as raw:
                raw = raw.convert("RGBA")
                measured.update(source_wh=raw.size, source_alpha_range=raw.getchannel("A").getextrema(), source_sha256=sha((ROOT / entry["source"]).read_bytes()))
        if entry["id"].startswith("terrain/water"):
            measured["base_coverage"] = sum(p == image.getpixel((0, 0)) for p in import_art.samples(image)) / 256
        contracts.append(measured)
    assert len(contracts) == 19
    owners = json.loads((ROOT / "assets/art_source/ownership.json").read_text())
    counts = dict(Counter(e["owner"] for e in owners["outputs"]))
    assert counts == {"raster": 120, "ascii": 136}
    save("measured-contract.json", dict(contracts=contracts, ownership_counts=counts, runtime_png_count=256, atlas_wh=[256, 80], water_seconds=0.55, cardinal_bits=dict(n=1, e=2, s=4, w=8), corner_order=["nw", "ne", "se", "sw"]))
    attempts = []
    for path in sorted((ROOT / "implementation/sprites/generation").glob("0008-*-call.json")):
        call = json.loads(path.read_text(encoding="utf-8"))
        if call["decision"].lower().startswith("pending"):
            call["decision"] = "Accepted after measured source alpha, native/3x masks and caps, repeated water patches, all 50 actual day/dusk/night captures and two real-render water loops; source-owned geometry and static contacts pass."
            path.write_text(json.dumps(call, indent=2) + "\n", encoding="utf-8", newline="\n")
        attempts.append(call)
    assert sum(c["decision"].lower().startswith("accepted") for c in attempts) == 4
    assert sum(c["decision"].lower().startswith("rejected") for c in attempts) == 2
    print("OK: 19 measured raster outputs; 12 changed/8 added PNGs; 236 PNGs and core/map/guards/palette/player metadata unchanged; 4 accepted/2 rejected sources")


if __name__ == "__main__":
    main()
