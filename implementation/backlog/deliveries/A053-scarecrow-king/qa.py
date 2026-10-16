"""Native geometry, motion distinction, palette, and silhouette checks."""
from pathlib import Path
from PIL import Image, ImageChops
import itertools, sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
from check_enemy_art import silhouette
from palette import COLOURS

def check(images, plan):
    groups = {}
    for f in plan["files"]:
        groups.setdefault(f["anim"], []).append((f, images[f["output"]]))
    box = lambda im: im.getchannel("A").getbbox()
    height = lambda im: box(im)[3] - box(im)[1]
    master = groups["scarecrow_king"][0][1]
    mb = box(master)
    distances = {}
    sig = silhouette(master)
    for name in ("giant", "walker", "runner", "tank", "breaker"):
        ref = Image.open(ROOT / f"sprites/enemies/{name}.png").convert("RGBA")
        distances[f"scarecrow_king/{name}"] = sum(a != b for a, b in zip(sig, silhouette(ref)))
    walk = [im for f, im in groups["scarecrow_king_walk"]]
    cast = [im for f, im in groups["scarecrow_king_cast"]]
    attack = [im for f, im in groups["scarecrow_king_attack"]]
    death = [im for f, im in groups["scarecrow_king_death"]]
    icon = groups["head_scarecrow_king"][0][1]
    ib = box(icon)
    body = [im for key, fs in groups.items() if key != "head_scarecrow_king" for f, im in fs]
    body_colours = {p[:3] for im in body for p in im.get_flattened_data() if p[3]}
    head_colours = {p[:3] for p in icon.get_flattened_data() if p[3]}
    eye_colours = {COLOURS["bone"], COLOURS["bone_dark"]}
    heights = [height(im) for im in death]
    shifted_clone = False
    for a, b in itertools.combinations(walk, 2):
        if any(ImageChops.difference(a, ImageChops.offset(b, 0, dy)).getbbox() is None for dy in range(-2, 3)):
            shifted_clone = True
    return {
        "master_size_ok": 30 <= mb[2]-mb[0] <= 44 and 44 <= mb[3]-mb[1] <= 50,
        "boss_frames_grounded_and_clear": all(box(im) and box(im)[0] >= 1 and box(im)[1] >= 1 and box(im)[2] <= 79 and box(im)[3] == 60 for im in body),
        "all_motion_frames_distinct": all(len({im.tobytes() for f, im in fs}) == len(fs) for key, fs in groups.items() if key != "scarecrow_king" and key != "head_scarecrow_king"),
        "walk_not_shifted_clones": not shifted_clone,
        "cast_reaches_without_exceeding_58": height(cast[2]) >= 50 and height(cast[3]) >= 50 and max(map(height, cast)) <= 58,
        "death_heights": heights,
        "death_settles": all(a >= b for a,b in zip(heights, heights[1:])) and heights[-1] <= 20,
        "silhouette_distances": distances,
        "silhouette_distinct": min(distances.values()) >= 16,
        "dominates_ordinary_enemies": (mb[3]-mb[1]) > max(Image.open(ROOT / f"sprites/enemies/{n}.png").getbbox()[3]-Image.open(ROOT / f"sprites/enemies/{n}.png").getbbox()[1] for n in ("walker","runner","tank","breaker")),
        "icon_bounds_ok": ib[3] == 15 and 14 in (ib[2]-ib[0], ib[3]-ib[1]) and abs((ib[0]+ib[2])/2-8) <= 1 and ib[0] >= 1 and ib[1] >= 1 and ib[2] <= 15,
        "icon_body_palette_only": head_colours <= body_colours,
        "icon_eyes_bone_matte": bool(head_colours & eye_colours),
    }
