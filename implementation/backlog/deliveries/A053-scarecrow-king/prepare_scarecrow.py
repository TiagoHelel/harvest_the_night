"""Assemble recorded ImageGen exports into a diagnostic candidate plan."""
from pathlib import Path
import json, shutil
import sys

D = Path(__file__).resolve().parent
ROOT = D.parents[3]
RAW = D / "raw"
sys.path.insert(0, str(ROOT / "tools"))
from import_art import render_source
from palette import COLOURS

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def write(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

mapping = [
    ("scarecrow_king", "west", "scarecrow-master-r1", 1, .1, False, False),
    ("scarecrow_king_walk", "west", "scarecrow-walk-r2", 4, .14, True, False),
    ("scarecrow_king_cast", "west", "scarecrow-cast-r3", 4, .1, False, False),
    ("scarecrow_king_attack", "west", "scarecrow-attack-r2", 3, .1, False, False),
    ("scarecrow_king_death", "west", "scarecrow-death-r3", 5, .12, False, False),
    ("head_scarecrow_king", "none", "head-scarecrow-king-r3", 1, 1., False, True),
]
files = []
decisions = {}
body_rgb = set()
for anim, direction, stem, count, seconds, loop, icon in mapping:
    recipes_path = RAW / (stem + (".recipe.json" if anim == "scarecrow_king" else ".recipes.json"))
    recipes = read(recipes_path)
    if anim == "scarecrow_king":
        recipes = [{"recipe": recipes}]
    decisions[stem] = {"decision": "selected as diagnostic candidate for owner review; not approved"}
    call_path = RAW / (stem + ".call.json")
    call = read(call_path)
    call["decision"] = "selected as diagnostic candidate for owner review; not approved"
    write(call_path, call)
    for i, item in enumerate(recipes):
        recipe = item["recipe"]
        if not icon:
            body_rgb.update(px[:3] for px in render_source(recipe).get_flattened_data() if px[3])
        output = f"native/{anim}/{direction}/{i+1:02d}.png"
        files.append({
            "anim": anim, "dir": direction, "frame": i,
            "pose": f"{anim}_{i}", "output": output,
            "source": f"raw/{stem}.png", "prompt": f"raw/{stem}.prompt.txt", "call": f"raw/{stem}.call.json",
            "recipe": recipe, "canvas_wh": [16,16] if icon else [80,64],
            "pivot_xy": [8,8] if icon else [40,60], "draw_scale": 1,
            "seconds": seconds, "loop": loop,
            "mirror": "none" if icon else "runtime",
            "grounded": not icon,
        })
body_keys = [key for key, rgb in COLOURS.items() if rgb in body_rgb]
for f in files:
    if f["anim"] == "head_scarecrow_king":
        f["recipe"]["palette_keys"] = body_keys
plan = {
    "title": "The Scarecrow King", "date": "2026-10-14", "status": "blocked",
    "palette_mode": "A", "expected_files": 18, "files": files,
    "comparison": [{"path": "sprites/enemies/giant.png", "pivot_xy": [40,60], "draw_scale": 1.0}],
    "deviations": ["The forecast mark misses the matte bone/bone_dark eye-pixel requirement after three ImageGen attempts. No fourth attempt was made."],
    "supersedes": [],
}
write(RAW / "export-plan.json", plan)
write(RAW / "selection.json", {
    "status": "blocked", "issues": plan["deviations"],
    "files": {f"{f['anim']}/{f['dir']}/{f['frame']}": {"stem": f["source"][4:-4], "index": f["frame"]} for f in files},
    "rejected": {
        "scarecrow-master-r2": "At the required shared 48px body height its silhouette is only about 21px wide; cannot meet the 30-44px body width without breaking the single body scale.",
        "scarecrow-walk-r1": "Adjacent figures overlap; no measurable full-height gutters for an unambiguous crop.",
        "scarecrow-cast-r1": "Adjacent arms bridge frames; only two empty vertical gaps for four poses.",
        "scarecrow-cast-r2": "Adjacent arms bridge frames; only two empty vertical gaps for four poses.",
        "scarecrow-attack-r1": "Figures touch; fewer than two measurable vertical gaps.",
        "scarecrow-death-r1": "Silhouette grows from frame 0 to frame 1 (48px to 50px).",
        "scarecrow-death-r2": "Figures touch; only three measurable gutters for five poses.",
        "head-scarecrow-king-r1": "No matte bone/bone_dark eye pixels after native palette reduction.",
        "head-scarecrow-king-r2": "The edit lightened teeth rather than both eye pixels; no bone/bone_dark eye pixels after native palette reduction.",
    },
    "decisions": decisions,
})
write(D / "review-log.json", {"date":"2026-10-14", "status":"blocked", "selected_candidate_files":18, "approved":False, "issue":"The selected head mark has no matte bone/bone_dark eye pixels after native reduction. All three head ImageGen attempts were used."})
shutil.copyfile(ROOT / "implementation/backlog/deliveries/A052-harvester/build.py", D / "build.py")
(D / "review-log.txt").write_text("2026-10-14: 18 diagnostic candidate frames assembled from recorded built-in ImageGen sources. The mark misses the bone/bone_dark eye rule after three attempts; package blocked, no production export. Rejected cuts, silhouettes, and revisions are listed in raw/selection.json. No approval inferred.\n", encoding="utf-8")
print(f"Prepared {len(files)} candidate files; status={plan['status']}")
