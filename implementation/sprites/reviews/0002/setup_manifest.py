"""Record the accepted pilot's measured recipes and single output owners.

One-time migration helper, not a sprite generator. Import with tools/import_art.py.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]


def main():
    contract = json.loads((ROOT / "assets/art_source/masters/master-contract.json").read_text())
    records = json.loads((ROOT / "implementation/sprites/generation/0001-record.json").read_text())["records"]
    assets = []
    paths = {"farmer": "actors/idle_south_0", "house": "buildings/house",
             "tree": "props/tree", "walker": "enemies/walker"}
    for master in contract["masters"]:
        record = next(r for r in records if r["asset"] == master["id"])
        x0, y0, x1, y1 = master["crop_xyxy"]
        entry = dict(id=paths[master["id"]], owner="raster", source=master["source"],
                     source_sha256=master["source_sha256"], crop_xywh=[x0, y0, x1-x0, y1-y0],
                     sheet_cell_xywh=[0, 0, *record["source_dimensions"]], gutter_xy=[0, 0],
                     canvas_wh=master["canvas_wh"], pivot_xy=master["pivot_xy"],
                     content_scale=master["content_wh"][1]/(y1-y0), alpha_threshold=128,
                     palette="tools/palette.py:COLOURS", animation=paths[master["id"]],
                     frame=0, seconds=0.55, loop=True, output="sprites/"+paths[master["id"]]+".png",
                     output_sha256="0"*64, prompt=record["prompt"], prompt_sha256=record["prompt_sha256"],
                     references=record["inputs"], tool="built-in ImageGen", generation_task="0001")
        if master["id"] == "farmer":
            entry["animation"] = "idle_south"
            entry["provisional"] = "Static pilot hold; task 0004 supplies three authored idle frames."
        if master["id"] == "house":
            entry["cell_offset_xy"] = [-8, -12]
        if master["id"] == "tree":
            entry["cell_offset_xy"] = [-12, -28]
        assets.append(entry)
    by_id = {e["id"]: e for e in assets}

    def derived(parent, ident, operation, canvas, pivot, **extra):
        base = by_id[parent]
        entry = {k: base[k] for k in ("owner", "palette", "seconds", "loop", "prompt", "prompt_sha256", "references", "tool", "generation_task")}
        entry.update(id=ident, input=parent, operation=operation, canvas_wh=canvas, pivot_xy=pivot,
                     animation=ident, frame=0, output="sprites/"+ident+".png", output_sha256="0"*64, **extra)
        assets.append(entry)

    for frame in (1, 2):
        derived("actors/idle_south_0", "actors/idle_south_%d" % frame, "copy", [48, 48], [24, 44])
        assets[-1].update(animation="idle_south", frame=frame,
                          provisional="Static pilot hold; authored animation in task 0004.")
    # Exhaustive house slices preserve the entire roof and facade; their offset
    # metadata places the 64x64 art over the unchanged 48x48 logical footprint.
    xs, ys = [0, 24, 40, 64], [0, 28, 44, 64]
    for col in range(3):
        for row in range(3):
            w, h = xs[col+1]-xs[col], ys[row+1]-ys[row]
            derived("buildings/house", "buildings/house_%d_%d" % (col, row), "slice", [w,h], [w//2,h],
                    slice_xywh=[xs[col],ys[row],w,h],
                    cell_offset_xy=[xs[col]-col*16-8, ys[row]-row*16-12])
    for suffix, operation, canvas, pivot in (("walk_b","legacy_bob",[32,40],[16,36]),
                                           ("attack","legacy_lunge",[32,40],[16,36]),
                                           ("death","legacy_fall",[40,40],[20,36])):
        derived("enemies/walker", "enemies/walker_"+suffix, operation, canvas, pivot,
                provisional="Legacy procedural motion from new master; authored strips/death playback in task 0015.")
    inventory = json.loads((ROOT / "implementation/sprites/inventory.json").read_text())
    # The inventory is the original baseline; support its explicit wrapper.
    inventory = inventory["assets"] if isinstance(inventory, dict) else inventory
    raster = {e["output"] for e in assets}
    outputs = []
    for entry in inventory:
        path = entry["path"]
        owner = "raster" if path in raster else "player_sheet" if entry["owner"] == "tools/cut_sheet.py" else "ascii"
        outputs.append(dict(output=path, owner=owner))
    ownership = dict(version=1, outputs=sorted(outputs, key=lambda e:e["output"]))
    (ROOT / "assets/art_source/ownership.json").write_text(json.dumps(ownership, indent=2)+"\n", encoding="utf-8", newline="\n")
    manifest = dict(version=1, recipe="nearest-palette-alpha-v1", assets=assets)
    (ROOT / "assets/art_source/manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
