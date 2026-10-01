"""Install measured terrain recipes; atlas consumes these validated sources."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def reference(path, role):
    return dict(path=path, role=role, sha256=import_art.sha((ROOT / path).read_bytes()))


def main():
    measured = json.loads((ROOT / "implementation/sprites/reviews/0007/measured-contract.json").read_text())
    assert len(measured["assets"]) == 8
    calls = {c["id"]: c for c in json.loads((ROOT / "implementation/sprites/generation/0007-generations.json").read_text())["attempts"]}
    manifest = json.loads(import_art.MANIFEST.read_text())
    ids = {e["id"] for e in measured["assets"]}
    manifest["assets"] = [e for e in manifest["assets"] if e["id"] not in ids]
    owner_path = ROOT / "assets/art_source/ownership.json"
    owners = json.loads(owner_path.read_text())
    by_output = {o["output"]: o for o in owners["outputs"]}
    for asset in measured["assets"]:
        name = asset["name"]
        revision = 1 if name in {"soil", "path", "floor", "rock"} else 0
        call_id = name + ("-r1" if revision else "")
        prompt = "implementation/sprites/generation/0007-" + call_id + ".prompt.txt"
        refs = [reference(p, "generation reference or original edit target; roles in exact prompt") for p in calls[call_id]["references"]]
        if revision:
            refs += [reference("implementation/sprites/generation/0007-" + name + ".prompt.txt", "original full production brief in revision chain")]
        entry = {k: asset[k] for k in ["id", "source", "source_sha256", "crop_xywh", "canvas_wh", "pivot_xy", "content_scale", "content_anchor_xy", "alpha_threshold"]}
        w, h = asset["source_wh"]
        x, y, cw, ch = asset["crop_xywh"]
        output = "sprites/" + asset["id"] + ".png"
        entry.update(owner="raster", output=output, output_sha256=asset["native_sha256"],
                     sheet_cell_xywh=[0, 0, w, h], gutter_xy=[min(x, w-x-cw), min(y, h-y-ch)],
                     palette="tools/palette.py:COLOURS", animation="terrain_" + name, frame=0, seconds=0.55, loop=False,
                     prompt=prompt, prompt_sha256=import_art.sha((ROOT / prompt).read_bytes()), references=refs,
                     tool="built-in ImageGen", generation_task="0007", revision=revision,
                     approval="Native/3x tiling reviewed; runtime evidence in implementation/sprites/reviews/0007/REVIEW.md")
        manifest["assets"].append(entry)
        by_output[output]["owner"] = "raster"
    owners["outputs"] = [by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    owner_path.write_text(json.dumps(owners, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Installed eight source-owned 16x16 terrain materials; atlas rows unchanged")


if __name__ == "__main__":
    main()
