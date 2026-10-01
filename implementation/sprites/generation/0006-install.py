"""Install reviewed reaction/shadow recipes; preserve accepted raw sources."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def reference(path, role):
    return {"path": path, "role": role, "sha256": import_art.sha((ROOT / path).read_bytes())}


def main():
    measured = json.loads((ROOT / "implementation/sprites/reviews/0006/measured-contract.json").read_text())
    manifest = json.loads(import_art.MANIFEST.read_text())
    owner_path = ROOT / "assets/art_source/ownership.json"
    owners = json.loads(owner_path.read_text())
    by_output = {o["output"]: o for o in owners["outputs"]}
    names = {a["name"] for a in measured["assets"]}
    manifest["assets"] = [e for e in manifest["assets"] if e["animation"] not in names]
    for asset in measured["assets"]:
        name = asset["name"]
        revision = 1 if name == "react_bang" else 0
        prompt = "implementation/sprites/generation/0006-" + name + ("-r1" if revision else "") + ".prompt.txt"
        refs = [reference("assets/art_source/masters/farmer.png", "approved identity and body scale reference"),
                reference("assets/art_source/player/idle_south.png", "accepted south idle/feet reference")]
        if revision:
            refs.append(reference("assets/art_source/player/candidates/react_bang-r0.png", "rejected thin-symbol edit target"))
            refs.append(reference("implementation/sprites/generation/0006-react_bang.prompt.txt", "original full prompt in exclamation revision chain"))
        output = "sprites/" + asset["id"] + ".png"
        w, h = asset["source_wh"]
        x, y, cw, ch = asset["crop_xywh"]
        entry = {key: asset[key] for key in ["id", "source", "source_sha256", "crop_xywh",
                 "canvas_wh", "pivot_xy", "content_scale", "content_anchor_xy", "body_reference_height",
                 "feet_source_xy", "alpha_threshold"]}
        entry.update(owner="raster", sheet_cell_xywh=[0, 0, w, h],
                     gutter_xy=[min(x, w - x - cw), min(y, h - y - ch)],
                     palette="tools/palette.py:COLOURS", animation=name, frame=0,
                     seconds=0.2, loop=False, output=output, output_sha256=asset["native_sha256"],
                     prompt=prompt, prompt_sha256=import_art.sha((ROOT / prompt).read_bytes()),
                     references=refs, tool="built-in ImageGen", generation_task="0006", revision=revision,
                     approval="Reviewed native/3x alpha, stable body/feet and distinct symbol; runtime gate recorded in review")
        if "bubble_xywh" in asset:
            entry["bubble_xywh"] = asset["bubble_xywh"]
        manifest["assets"].append(entry)
        by_output[output]["owner"] = "raster"
    owners["outputs"] = [by_output[o] for o in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    owner_path.write_text(json.dumps(owners, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Installed four south reaction frames and shared contact shadow")


if __name__ == "__main__":
    main()
