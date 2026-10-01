"""Install measured, visually accepted locomotion recipes; never edits raw pixels."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def reference(path, role):
    return {"path": path, "role": role, "sha256": import_art.sha((ROOT / path).read_bytes())}


def main():
    measured = json.loads((ROOT / "implementation/sprites/reviews/0004/measured-contract.json").read_text())
    manifest = json.loads(import_art.MANIFEST.read_text())
    owners = json.loads((ROOT / "assets/art_source/ownership.json").read_text())
    names = {a["name"] for a in measured["animations"]}
    manifest["assets"] = [e for e in manifest["assets"] if e["animation"] not in names]
    for animation in measured["animations"]:
        name = animation["name"]
        revision = {"walk_south": 1, "walk_north": 1, "walk_west": 2}.get(name, 0)
        prompt = "implementation/sprites/generation/0004-" + name + ("-r%d" % revision if revision else "") + ".prompt.txt"
        refs = [reference("assets/art_source/masters/farmer.png", "approved identity and body-scale master")]
        if revision:
            refs.append(reference("assets/art_source/player/candidates/" + name + "-r%d.png" % (revision - 1), "edit target for accepted revision"))
            refs.append(reference("implementation/sprites/generation/0004-" + name + ".prompt.txt", "original complete strip prompt"))
        if name == "walk_north":
            refs.append(reference("assets/art_source/player/idle_north.png", "accepted back-view clothing reference"))
        if revision == 2:
            refs.append(reference("assets/art_source/player/candidates/" + name + "-r0.png", "preserved first candidate in revision chain"))
            refs.append(reference("implementation/sprites/generation/0004-" + name + "-r1.prompt.txt", "first targeted revision prompt"))
        boxes = animation["crop_xywh"]
        width, height = animation["source_wh"]
        for i, box in enumerate(boxes):
            x, y, w, h = box
            left = 0 if i == 0 else (boxes[i-1][0] + boxes[i-1][2] + x) // 2
            right = width if i == len(boxes)-1 else (x + w + boxes[i+1][0]) // 2
            output = "sprites/actors/%s_%d.png" % (name, i)
            manifest["assets"].append({
                "id": "actors/%s_%d" % (name, i), "owner": "raster",
                "source": animation["source"], "source_sha256": animation["source_sha256"],
                "crop_xywh": box, "sheet_cell_xywh": [left, 0, right-left, height],
                "gutter_xy": [min(x-left, right-x-w), min(y, height-y-h)],
                "canvas_wh": measured["canvas_wh"], "pivot_xy": measured["pivot_xy"],
                "content_scale": animation["content_scale"], "alpha_threshold": 128,
                "palette": "tools/palette.py:COLOURS", "animation": name, "frame": i,
                "seconds": 0.55 if name.startswith("idle_") else 0.13, "loop": True,
                "output": output, "output_sha256": "0"*64,
                "prompt": prompt, "prompt_sha256": import_art.sha((ROOT / prompt).read_bytes()),
                "references": refs, "tool": "built-in ImageGen", "generation_task": "0004",
                "revision": revision, "approval": "Native/3x strip review before runtime promotion"
            })
            for owner in owners["outputs"]:
                if owner["output"] == output:
                    owner["owner"] = "raster"
                    break
            else:
                raise ValueError("Missing prior runtime owner: " + output)
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")
    (ROOT / "assets/art_source/ownership.json").write_text(json.dumps(owners, indent=2)+"\n", encoding="utf-8", newline="\n")
    print("Installed six measured strips / 21 raster locomotion frames")


if __name__ == "__main__":
    main()
