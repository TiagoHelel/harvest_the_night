# -*- coding: utf-8 -*-
"""The Aseprite remake of HARVEST THE NIGHT's art: what to draw, batch by batch.

    python implementation/aseprite/inventory.py build            write inventory/ from the manifest
    python implementation/aseprite/inventory.py build --check    fail if inventory/ is stale
    python implementation/aseprite/inventory.py status           every batch and how far it got
    python implementation/aseprite/inventory.py check B07        check a delivery against the inventory
    python implementation/aseprite/inventory.py check B07 --write   ... and write its checks.json
    python implementation/aseprite/inventory.py sheet B07 OUT    today's art of a batch, 4x, as OUT/B07-current.png

`build` reads `assets/art_source/manifest.json` - every raster sprite the game
loads, with its canvas, pivot, timing and metadata points - and the farmer
packs in `implementation/backlog/packs/` whose sprites were never drawn, and
sorts every sprite to draw into exactly one batch. It writes only
`inventory/`. `check` and `status` read `deliveries/`; `check --write` writes
the one `checks.json` of the delivery it checks; `sheet` writes one PNG into
the folder it is given. Python 3 and Pillow only, no clock, no randomness: two
runs of `build` give the same bytes.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = ROOT / "assets" / "art_source" / "manifest.json"
OWNERSHIP = ROOT / "assets" / "art_source" / "ownership.json"
PACKS = ROOT / "implementation" / "backlog" / "packs"
INVENTORY = HERE / "inventory"
DELIVERIES = HERE / "deliveries"

sys.path.insert(0, str(ROOT / "tools"))
import palette  # noqa: E402  - the 42 project colours, read only

# ------------------------------------------------------------------ batches

FARMER_BATCHES = ("B01", "B02", "B03", "B04", "B05", "B06")

BATCHES = [
    ("B00", "palette-and-pilot", "The palette and a style pilot", """\
Make the game's palette and prove the look before anything else is drawn.

- **Deliver** `palette/harvest.gpl` and `palette/harvest.json` (CONTRACT.md
  section 4).
- **The style pilot:** draft versions of:
  - the farmer's `idle_south` (3 frames) and `walk_south` (8);
  - the walker's master and walk (4);
  - the oak (`props/tree`) and the grass tile (`terrain/grass`);
  - the level-1 gun tower and the wood icon pair.
- **One board,** `review/pilot-board.png`: all of them together on tiled grass,
  at 1x and 4x, by day and in the night preview, beside today's versions.
- **What gets integrated:** only the palette. The pilot sprites are drawn for
  real in their own batches, so B00 has no `png/`.
- **This is where the owner settles the look:**
  - the farmer's identity;
  - the outline style;
  - how many tones per material;
  - how dark the night reads."""),
    ("B01", "farmer-walk-idle", "The farmer: walk, idle and shadow", """\
The farmer is the scale reference for everything after this batch.

- **His body is 16 wide x 32 tall**, on a 40x40 canvas standing on (20,36).
- **His identity:** straw hat with a brown band, dark hair, warm skin, blue
  work clothes, brown boots - unless the owner changed it in B00.
- **Directions:** author `south`, `north`, `east`, `south_west` and
  `north_east`.
  - Deliver `west`, `south_east` and `north_west` as exact whole-canvas
    horizontal flips of `east`, `south_west` and `north_east`.
  - The game binds those three as they are and never flips them again.
- **Walk:** 8 frames at 0.1 s, a loop.
- **Idle:** 3 frames at 0.55 s, a loop. It is one grounded pose breathing,
  never a lifted walk frame.
- **The shadow** (20x8) is one flat shape the game draws under every actor.
  Nobody bakes a shadow into a sprite.
- **Native size only.** Claude makes the 80x80 runtime copies (an exact 2x)."""),
    ("B02", "farmer-field-work", "The farmer: tilling, planting, watering, harvesting (A007)", """\
- **Each row's brief is its pack.** It gives every pose, the timing and the
  `contact_xy` point. Skip its Codex mechanics: ImageGen, raw/, build.py,
  palette mode B, `tool_rects_xywh`, `tool_ramp_reserved`.
- **Canvas 48x48, standing on (24,44),** with the same 16x32 body as the walk.
  The extra room is for the tools.
- **Directions:** `south`, `north` and `west`. East is the game's mirror of
  west and is not delivered.
- **The boots never move** inside a strip.
- **No crop, soil, splash or particle** is drawn into a work frame.
- **`current`** is today's single west-facing strip at an older 30 px body. It
  shows the verb, not the size.
- **Native size only.** Claude makes the 96x96 runtime copies."""),
    ("B03", "farmer-gather-work", "The farmer: chopping, mining, collecting, carrying (A008)", """\
The same rules as B02. The pack is the brief.
- The axe and the pick give `contact_xy` on frame 1.
- No tree, rock, chip or particle is drawn into a work frame."""),
    ("B04", "farmer-make-work", "The farmer: crafting, trading, repairing (A009)", """\
The same rules as B02. The pack is the brief.
- The hammer gives `contact_xy` on frame 1.
- No bench, coin, goods, nail or spark is drawn into a work frame."""),
    ("B05", "farmer-fishing-care", "The farmer: fishing and tending animals (A024, A025)", """\
The same rules as B02. The packs are the briefs.
- **The bobber, the line and the caught fish are drawn by code,** never in
  these frames. The packs name the points the code needs (`rod_tip_xy`,
  `line_xy`, `catch_xy`).
- **The catch** faces the viewer whatever his facing.
- **`tend`** is one gesture for every animal job. **`pet_dog`** is the dog's
  pat."""),
    ("B06", "farmer-night", "The farmer: going to bed, reactions and Zzz (A001, A002)", """\
- **`bed_in` and `bed_sleep` happen on the bed** (`interior/bed`, drawn in
  B12). The A001 pack gives where he lies and the covers over him.
- **The owner retired A001's waking and pass-out** on 2026-10-08: he wakes on
  his feet and a pass-out is a black screen. Do not draw them.
- **The reactions** (`!`, `?`, a note, a heart) and the **Zzz** are glyphs
  over his head. Each frame is his idle south body plus the glyph, on 48x48
  standing on (24,44).
  - The glyph stays at least 1 transparent pixel away from the body,
    diagonals included.
  - `bubble_xywh` covers every glyph pixel and no body pixel."""),
    ("B07", "terrain", "Terrain and tilled soil", """\
- **Tiles are 16x16.** A ground tile is fully opaque and seamless:
  - opposite borders match;
  - variants share their boundary colours and texture density.
- **Water** is 3 phases at 0.55 s, a loop, with a 2 px calm margin.
- **Edges and shores:** draw `edge_n`, `shore_n` and `shore_corner_nw`, and
  their winter versions.
  - They are overlays, transparent outside their band.
  - The game rotates them for east, south and west (DERIVED.md).
- **`tilled*`** are the soil the crops sit on. They are opaque, and wet is at
  least 20 RGB brightness darker than dry.
- **Terrain is the quietest contrast in the game:** grouped texture, no
  centrepiece. Claude builds the atlas."""),
    ("B08", "crops", "Crops", """\
- **Four stages:** planted, sprout, growing, ripe, as frames 0..3. They are
  static: the game picks the stage.
- **Canvases:**
  - most crops are 16x16 standing on (8,14);
  - corn is 16x24 on (8,22);
  - sunflower and grape are 16x32 on (8,30).
- **One scale per species.**
- **`_regrow`** is the stage a regrowing crop goes back to after a harvest.
  **`trampled`** and **`withered`** are the night's damage.
- **Ripe crops must not look lit** at night."""),
    ("B09", "nature-resources", "Trees, rocks, ore, resources and sprinklers", """\
- **Trees** are 40x48 standing on (20,44), about 36x42 visible.
  - The seasonal versions keep the same trunk, base and silhouette.
  - A `_b` variant shares canvas, pivot and palette with its master.
- **Small nodes** are 16x16 on (8,14); the 2x2 ones are 32x32 on (16,30).
- **`_snow` versions** put snow on the same shape. `snow_cap` is the cap alone.
- **Sprinklers:** an idle frame and a 4-frame spray each, with `spray_xy` where
  the water leaves.
- **`bone_pile`, `moon_stone` and `truffle_spot`** are things on the ground the
  farmer picks up."""),
    ("B10", "animals", "Farm animals and the dog", """\
- **Side view facing west.** The game mirrors them to face east.
- **Canvases:** cow, sheep, pig and dog are 40x32 standing on (20,30); the
  chicken is 24x24 on (12,22).
- **Animations:**
  - idle 2 at 0.5 s, a loop;
  - walk 4 at 0.15 s, a loop;
  - eat 2 and sleep 2, loops;
  - the pig's dig and the dog's bark and bite are 3-frame one-shots.
- **`bite_xy`** is on the dog's bite.
- **`props/cow` and `props/chicken`** are older single poses the game still
  loads. Draw them as the new animals' standing pose."""),
    ("B11", "farm-buildings", "The house, farm buildings and machines", """\
- **Full density.** A building W tiles wide is about W*16 art px.
- **The house is the landmark:** three tiers at 128x128 standing on (64,120),
  each whole and hurt. The coop is 64x64 and the barn 96x100.
- **Machines** (keg, preserves jar, dairy, loom, mill) have idle, active, hurt
  and wreck.
  - Active moves only the mechanism or a local furnace.
  - An idle building never looks active.
- **Glass panes stay separate shapes.** The game lights them at night
  (`windows_xy`, `window_rects_xywh`, `light_xy`, `smoke_xy`), so never bake
  a glow.
- **Workshop, kitchen, press, generator and the shop** (with `shop_closed`)
  were drawn at half density and doubled by the game.
  - Draw them at full density on a canvas twice as big: 96x96 on (48,88); the
    shop 64x80 on (32,72).
  - At integration Claude sets their draw scale to 1.0, as task 0217 did for
    the house.
  - Their quarters (`workshop_0_0`...) are cut by Claude."""),
    ("B12", "people-interior", "The peddler, the porch guardian and the house interior", """\
- **The peddler** follows the NPC rules: 40x40 standing on (20,36).
  - Idle and talk face south.
  - The walk is a side view facing west, mirrored by the game.
- **The porch guardian** is a scarecrow, 32x48 on (16,44).
  - Its poses: day (asleep), wake, night idle and point.
  - Its eyes are `lights_xy`; the game makes them glow.
- **The interior** is the farmhouse room the farmer sleeps in. Each piece
  stands on its bottom centre, at its canvas.
  - The bed (48x64) is where B06's `bed_in` and `bed_sleep` lie."""),
    ("B13", "towers", "Towers", """\
- **One cell:** 32x48 standing on (16,44).
- **Levels change the construction:** footing, armour, mechanism, barrels.
  Never stack copies, and never add level pips or coloured bands.
- **States:**
  - `_hurt` shows deliberate damage;
  - `_wreck` collapses onto the same base;
  - `_fire` adds only a small local muzzle form at the real weapon tip.
- **Points, per level,** on whole, hurt and fire: `muzzle_xy`, `muzzles_xy`
  (1-2 points) and `muzzle_region_xywh`. The searchlight gives `light_xy`
  instead, because its beam is code.
- **Levels:** the beehive and the searchlight have 2, the catapult 3."""),
    ("B14", "barriers-traps", "Walls, fences, traps, decoys and tarps", """\
- **Barriers are modules,** 16x32 standing on (8,28): `post`, `horizontal` and
  `vertical`, each whole and hurt, plus one `wreck`.
  - Claude composes the 16 join masks per state with the recipe in
    `implementation/backlog/ART-CONTRACT.md` 2.3.
  - The post and the horizontal span stand on row 20. The vertical slice runs
    rows 8-27.
  - Open today's modules before drawing.
- **The barricade** is 16x24 on (8,20). **The mine** is 16x16 on (8,14),
  with triggered and spent states.
- **The decoy** is 16x32 on (8,28), with a 3-frame sway when hit.
- **The garlic braid** is 16x24 on (8,20).
- **Tarps cover the defences by day:** tower 32x48, tall 16x32 and short
  16x24. Each has whole, hurt and a 2-frame unveil."""),
    ("B15", "enemies", "Enemies and their forecast heads", """\
- **Side view facing west.** The game mirrors them to face east.
- **Ordinary enemies** are 64x48 standing on (32,44). The body is about 18x29,
  with the feet on row 43 centred on x=32.
- **Animations:**
  - walk 4 at 0.125 s, a loop;
  - attack 3 at 0.1 s, a one-shot;
  - death 4 at 0.1 s, a one-shot ending low on the ground (at most 16 tall).
  - The master is the standing pose.
  - The extra moves and odd canvases are in each brief: the digger's burrow,
    mound and emerge; the crow's fly, land and peck; the rat on 24x16.
- **The look:** rot greens and muted worn clothes, menacing but at home on a
  cozy farm, with restrained gore. Every silhouette must differ at 1x.
- **Forecast heads** (`ui/head_<kind>`, 16x16 on (8,8)): as the owner asked
  for A011, crop each head from your own walk frame 0 into the box.
  - A bust, lowest row 14, centred on x=8.
- **Aliases:** Claude makes `_walk_b`, `_attack` and `_death`."""),
    ("B16", "bosses", "Bosses and their forecast heads", """\
- **Side view facing west**, on 80x64 standing on (40,60). The Giant stands
  about 46x41, and every boss is at least the Giant's size.
- **Animations:**
  - walk 4 at 0.14 s;
  - windup 3, slam, charge, crush or attack 3-4, and cast 4, all at 0.1 s;
  - death 5 at 0.12 s, a one-shot.
  - The master is the standing pose.
- **Each boss is its season's face:** the Giant (spring), the Harvester
  (summer), the Scarecrow King (autumn) and the Winter Lord (winter).
- **Heads** are cut as in B15."""),
    ("B17", "effects", "Effects", """\
- **Canvases:**
  - bursts 12x12 centred on (6,6);
  - rising effects (flame, smoke) 16x20 on (8,18);
  - dust 16x12;
  - splashes 20x16;
  - flares 24x24;
  - projectiles 8x8 on (4,4).
- **One-shots of 3-4 frames,** with a peak visible size of 8-18 px and a 1 px
  clear border.
- **Effects are the only sprites that may look bright.** The light they cast
  is code."""),
    ("B18", "item-icons", "Item icons and fish portraits", """\
- **Two sizes of every item:**
  - the inventory icon, 16x16 centred on (8,8), at most 14x14 visible;
  - the HUD icon, 10x10 on (5,5), at most 8x8 visible.
- **Same item, same colours.** Pixel the 10x10 as its own drawing, not a
  resample: it must still read at that size.
- **No text, numbers, panels or drop shadows.**
- **Fish portraits** are 32x32 centred on (16,16), for the fishing book."""),
    ("B19", "hud-menus", "HUD icons, cursor, fishing bar, collection book and report", """\
- **Icons:** the night hotbar's defences and powers, the calendar and moons,
  the events, and the books. They follow the icon rules of B18, and each must
  match the thing it stands for (B13, B14).
- **The cursor** is the guardian's pointer over the farm: 7 states, each a
  2-frame pulse at 0.4 s, 16x16 on (8,8).
- **The fishing bar:**
  - `fishbar_frame` is a 100x16 frame whose inner track is `track_xywh`;
  - `fishbar_zone` (8x6) is a nine-patch with `patch_margins_lrtb`;
  - `fishbar_marker` is 5x12;
  - hit and miss are 3-frame bursts.
- **The collection book:** its cover (48x64) and ornament (64x12), trophies
  (32x32) and badges (24x24).
- **`report_header`** (206x40) heads the morning report.
- **The panel and button kit is code-owned.** Do not draw it."""),
]
BATCH_IDS = [b[0] for b in BATCHES]
SLUGS = {b[0]: "%s-%s" % (b[0], b[1]) for b in BATCHES}

# What the game derives from the drawn sprites (DERIVED.md).
DERIVED_NOTES = {
    "components": "Pieces the importer cut out of ImageGen sheets and pasted "
                  "together. The game never loads them. Draw the finished "
                  "sprite instead.",
    "joins": "Barrier join masks. Claude composes all 16 per state from your "
             "post, horizontal and vertical modules (B14).",
    "aliases": "Byte copies of another frame, e.g. `walker_walk_b` = "
               "`walker_walk_2`. Claude makes them.",
    "rotations": "Terrain edges, shores and corners for the other sides, "
                 "rotated from your north and north-west versions (B07).",
    "slices": "Old compatibility cuts: a building's quarters, and the "
              "terrain's north-west edge corner cut from `edge_n`. Claude cuts "
              "them from your full drawing.",
    "replaced": "The farmer's old single-direction work strips and reactions. "
                "B02-B06 replace them with the packs' per-direction strips.",
}

LEGACY_FARMER = {"chop", "mine", "till", "plant", "water", "fish", "reel", "harvest",
                 "carry", "craft", "trade", "collect", "repair",
                 "react_bang", "react_question", "react_note", "react_heart"}
BOSSES = ("giant", "harvester", "scarecrow_king", "winter_lord")
TOWERS = ("gun_tower", "flame_tower", "mortar", "auto_crossbow", "beehive", "catapult",
          "searchlight")
ANIMALS = ("cow", "chicken", "sheep", "pig", "dog")
FARM_BUILDINGS = ("house", "coop", "barn", "workshop", "kitchen", "keg", "preserves_jar",
                  "dairy", "loom", "mill")
FARM_PROPS = ("press", "generator", "shop", "well", "shipping_bin")
HUD_PACKS = {"A004", "A005", "A010", "A045", "A055", "A056", "A057"}
LEGACY_2X = {"shop", "workshop", "kitchen", "press", "generator"}
NOT_POINTS = {"crop_xywh", "sheet_cell_xywh", "gutter_xy", "pivot_xy", "content_anchor_xy",
              "cell_offset_xy", "feet_source_xy", "slice_xywh", "paste_xy"}
# Points that mark where code draws something, not a pixel of the sprite.
FREE_POINTS = {"catch_xy"}
MIRRORS = {"west": "east", "south_east": "south_west", "north_west": "north_east"}
DIRS = ("south", "north", "east", "west", "south_east", "south_west", "north_east",
        "north_west")


def rel(path):
    return path[len("sprites/"):] if path.startswith("sprites/") else path


def pack_file(pack):
    found = sorted(PACKS.glob(pack + "-*.md"))
    return found[0].relative_to(ROOT).as_posix() if found else ""


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


# ------------------------------------------------------------ the manifest

def derived_reason(entry, by_id):
    out = entry["output"]
    if out.startswith("sprites/components/"):
        return "components"
    op = entry.get("operation")
    if op == "compose" and any(by_id[p["input"]]["output"].startswith("sprites/buildings/modules/")
                               for p in entry.get("parts", [])):
        return "joins"
    if op == "copy":
        return "aliases"
    if op == "rotate":
        return "rotations"
    if op in ("slice", "slice_canvas"):
        return "slices"
    if out.startswith("sprites/actors/") and entry["animation"] in LEGACY_FARMER:
        return "replaced"
    return None


def batch_of(path, pack):
    folder, name = path.split("/")[1], Path(path).stem
    first = name.split("_")[0]
    if folder == "terrain":
        return "B07"
    if folder == "crops":
        return "B07" if name.startswith("tilled") else "B08"
    if folder == "actors":
        if name.startswith(("walk_", "idle_")) or name == "shadow":
            return "B01"
        if name.startswith("peddler"):
            return "B12"
    if folder == "interior":
        return "B12"
    if folder == "props":
        if name.startswith("guardian"):
            return "B12"
        if first in ANIMALS:
            return "B10"
        if name.startswith(FARM_PROPS):
            return "B11"
        return "B09"
    if folder == "buildings":
        if name.startswith(TOWERS):
            return "B13"
        if name.startswith(FARM_BUILDINGS):
            return "B11"
        return "B14"
    if folder == "enemies":
        return "B16" if name.startswith(BOSSES) else "B15"
    if folder == "effects":
        return "B17"
    if folder == "ui":
        if name.startswith("head_"):
            return "B16" if name[5:].startswith(BOSSES) else "B15"
        if name.startswith(("cursor_", "fishbar_", "collection_", "trophy_", "badge_",
                            "report_")):
            return "B19"
        if name.startswith(("icon_", "hud_")):
            return "B19" if pack in HUD_PACKS or name.endswith("book_fish") else "B18"
        if name.startswith("portrait_"):
            return "B18"
    raise SystemExit("no batch for " + path)


def geometry(entry):
    """The native canvas and pivot to draw on, and how the game gets there."""
    canvas, pivot = list(entry["canvas_wh"]), list(entry["pivot_xy"])
    folder, name = entry["output"].split("/")[1], Path(entry["output"]).stem
    if entry.get("draw_scale") == 0.5 and "detail_wh" in entry:
        k = canvas[0] // entry["detail_wh"][0]
        assert all(v % k == 0 for v in canvas + pivot), entry["output"]
        return ([v // k for v in canvas], [v // k for v in pivot],
                {"canvas_wh": canvas, "pivot_xy": pivot, "draw_scale": 0.5}, None, 1.0 / k)
    if folder in ("buildings", "props") and name.split("_")[0] in LEGACY_2X:
        return ([v * 2 for v in canvas], [v * 2 for v in pivot], None,
                {"canvas_wh": canvas, "pivot_xy": pivot, "draw_scale": 2.0}, 2.0)
    return canvas, pivot, None, None, 1.0


def measure(path, scale):
    """Today's art in native pixels: visible box, lowest opaque row, opaque."""
    with Image.open(ROOT / path) as im:
        alpha = im.convert("RGBA").getchannel("A")
    box = alpha.getbbox()
    if box is None:
        return None
    return {"visible_wh": [round((box[2] - box[0]) * scale), round((box[3] - box[1]) * scale)],
            "lowest_row": int(box[3] * scale) - 1,
            "opaque": alpha.getextrema() == (255, 255)}


def scaled_points(entry, scale):
    points = {}
    for key in sorted(entry):
        if key in NOT_POINTS or not (key.endswith("_xy") or key.endswith("_xywh")
                                     or key == "patch_margins_lrtb"):
            continue
        value = entry[key]
        if value is None:
            continue
        points[key] = _scale_value(value, scale) if key != "patch_margins_lrtb" else value
    return points


def _scale_value(value, scale):
    if isinstance(value, list):
        return [_scale_value(v, scale) for v in value]
    return round(value * scale) if isinstance(value, (int, float)) else value


def anim_key(files, fallback):
    if len(files) == 1:
        return files[0][:-4]
    stems = set()
    for i, f in enumerate(files):
        m = re.match(r"^(.*)_(\d+)\.png$", f)
        if not m or int(m.group(2)) != i:
            return fallback
        stems.add(m.group(1))
    return stems.pop() if len(stems) == 1 else fallback


def facing(batch, key):
    folder, name = key.split("/", 1)
    if batch in FARMER_BATCHES:
        for d in sorted(DIRS, key=len, reverse=True):
            if name.endswith("_" + d):
                return d
        return "south" if name.startswith(("bed_", "react_")) else "none"
    if folder == "enemies":
        return "west"
    if folder == "props" and name.split("_")[0] in ANIMALS:
        return "west"
    if name.startswith("peddler_walk"):
        return "west"
    if name.startswith("peddler_"):
        return "south"
    return "none"


def from_manifest(assets):
    by_id = {e["id"]: e for e in assets}
    groups, derived = {}, {k: [] for k in DERIVED_NOTES}
    for e in assets:
        reason = derived_reason(e, by_id)
        if reason:
            derived[reason].append(e["output"])
            continue
        groups.setdefault(e["animation"], []).append(e)
    rows = []
    for anim, frames in groups.items():
        frames.sort(key=lambda e: e["frame"])
        first = frames[0]
        files = [rel(e["output"]) for e in frames]
        pack = first.get("generation_task") or ""
        pack = pack if re.match(r"^A\d{3}$", pack) else ""
        batch = batch_of(first["output"], pack)
        key = anim_key(files, rel(first["output"]).rsplit("/", 1)[0] + "/" + anim.split("/")[-1])
        canvas, pivot, runtime, doubled, scale = geometry(first)
        measures = [measure(e["output"], scale) for e in frames]
        points = [scaled_points(e, scale) for e in frames]
        same_points = all(p == points[0] for p in points)
        rules = {"grounded": all(m and m["lowest_row"] == pivot[1] - 1 for m in measures),
                 "opaque": all(m and m["opaque"] for m in measures)}
        row = {
            "batch": batch, "anim": key, "files": files, "frames": len(frames),
            "canvas_wh": canvas, "pivot_xy": pivot,
            "seconds": first["seconds"], "loop": bool(first["loop"]) and len(frames) > 1,
            "facing": facing(batch, key), "mirror_of": None,
            "runtime": runtime, "doubled_from": doubled, "rules": rules,
            "current": [e["output"] for e in frames],
            "current_visible_wh": [max(m["visible_wh"][i] for m in measures if m) for i in (0, 1)]
            if any(measures) else None,
            "points": points[0] if same_points else {"per_frame": points},
            "points_hint": "",
            "brief": pack_file(pack) if pack else first.get("prompt", ""),
            "pack": pack or None,
            "note": "",
        }
        if key.startswith("actors/walk_") or key.startswith("actors/idle_"):
            d = row["facing"]
            if d in MIRRORS:
                row["mirror_of"] = key[: -len(d)] + MIRRORS[d]
        rows.append(row)
    return rows, derived


# ------------------------------------------------ the farmer's undrawn packs

WORK_FRAME = ([48, 48], [24, 44], {"canvas_wh": [96, 96], "pivot_xy": [48, 88], "draw_scale": 0.5})
WALK_FRAME = ([40, 40], [20, 36], {"canvas_wh": [80, 80], "pivot_xy": [40, 72], "draw_scale": 0.5})
CONTACT = {"till", "water", "chop", "mine", "repair"}


def farmer_rows(assets):
    legacy = {}
    for e in assets:
        if e["output"].startswith("sprites/actors/") and e["animation"] in LEGACY_FARMER:
            legacy.setdefault(e["animation"], []).append(e)
    for frames in legacy.values():
        frames.sort(key=lambda e: e["frame"])

    rows = []

    def add(batch, pack, name, frames, seconds, loop, geo, current, hint, note=""):
        canvas, pivot, runtime = geo
        cur = [e["output"] for e in legacy.get(current, [])]
        rows.append({
            "batch": batch, "anim": "actors/" + name,
            "files": ["actors/%s_%d.png" % (name, i) for i in range(frames)],
            "frames": frames, "canvas_wh": canvas, "pivot_xy": pivot,
            "seconds": seconds, "loop": loop, "facing": facing(batch, "actors/" + name),
            "mirror_of": None, "runtime": runtime, "doubled_from": None,
            "rules": {"grounded": True, "opaque": False},
            "current": cur,
            "current_visible_wh": None, "points": {}, "points_hint": hint,
            "brief": pack_file(pack), "pack": pack, "note": note,
        })

    for batch, pack, verbs in (("B02", "A007", ("till", "plant", "water", "harvest")),
                               ("B03", "A008", ("chop", "mine", "collect", "carry")),
                               ("B04", "A009", ("craft", "trade", "repair"))):
        for verb in verbs:
            for d in ("south", "north", "west"):
                add(batch, pack, "%s_%s" % (verb, d), 4, 0.09, False, WORK_FRAME, verb,
                    "contact_xy on frame 1" if verb in CONTACT else "")
    for d in ("south", "north", "west"):
        add("B05", "A024", "fish_cast_" + d, 4, 0.09, False, WORK_FRAME, "fish",
            "rod_tip_xy, line_xy (pack)")
        add("B05", "A024", "fish_wait_" + d, 2, 0.6, True, WORK_FRAME, "fish", "rod_tip_xy (pack)")
        add("B05", "A024", "fish_strike_" + d, 3, 0.08, False, WORK_FRAME, "reel",
            "rod_tip_xy (pack)")
        add("B05", "A024", "fish_reel_" + d, 4, 0.1, True, WORK_FRAME, "reel", "rod_tip_xy (pack)")
    add("B05", "A024", "fish_catch_south", 2, 0.3, False, WORK_FRAME, "",
        "catch_xy on frame 1", "frame 1 is held")
    for d in ("south", "north", "west"):
        add("B05", "A025", "tend_" + d, 4, 0.09, False, WORK_FRAME, "collect", "")
        add("B05", "A025", "pet_dog_" + d, 4, 0.15, False, WORK_FRAME, "",
            "", "played 0,1,2,1,2,3")
    add("B06", "A001", "bed_in", 4, 0.2, False, WALK_FRAME, "", "see the pack",
        "on the bed; frame 3 = bed_sleep frame 0")
    add("B06", "A001", "bed_sleep", 2, 0.8, True, WALK_FRAME, "", "see the pack",
        "only the chest moves")
    for kind in ("bang", "question", "note", "heart"):
        add("B06", "A002", "react_" + kind, 1, 0.2, False, WORK_FRAME, "react_" + kind,
            "bubble_xywh")
    add("B06", "A002", "react_zzz", 3, 0.4, True, WORK_FRAME, "react_note", "bubble_xywh",
        "letters already shown never move")
    for row in rows:
        if row["anim"].startswith("actors/bed_"):
            row["rules"]["grounded"] = False      # he lies on the bed, not on the ground
    return rows


# ----------------------------------------------------------------- build

def code_owned():
    data = json.load(open(OWNERSHIP, encoding="utf-8"))
    return sorted(r["output"] for r in data["outputs"] if r["owner"] != "raster")


def inventory():
    assets = json.load(open(MANIFEST, encoding="utf-8"))["assets"]
    rows, derived = from_manifest(assets)
    rows += farmer_rows(assets)
    seen = {}
    for row in rows:
        for f in row["files"]:
            if f in seen:
                raise SystemExit("drawn twice: %s (%s, %s)" % (f, seen[f], row["anim"]))
            seen[f] = row["anim"]
    # The old reactions keep their names: B06 redraws them, so they are not
    # "replaced".
    derived["replaced"] = [o for o in derived["replaced"] if rel(o) not in seen]
    order = {b: i for i, b in enumerate(BATCH_IDS)}
    rows.sort(key=lambda r: (order[r["batch"]], r["anim"]))
    batches = []
    for bid, slug, title, notes in BATCHES:
        mine = [r for r in rows if r["batch"] == bid]
        frames = sum(r["frames"] for r in mine)
        mirrored = sum(r["frames"] for r in mine if r["mirror_of"])
        batches.append({"id": bid, "slug": SLUGS[bid], "title": title, "notes": notes,
                        "frames": frames, "mirrored_frames": mirrored,
                        "animations": mine})
    return {
        "version": 1,
        "manifest": "assets/art_source/manifest.json",
        "manifest_sha256": sha256(MANIFEST),
        "frames": sum(b["frames"] for b in batches),
        "batches": batches,
        "derived": {k: sorted(v) for k, v in derived.items()},
        "code_owned": code_owned(),
    }


def files_cell(files):
    if len(files) == 1:
        return "`%s`" % files[0]
    m = re.match(r"^(.*)_0\.png$", files[0])
    return "`%s_0..%d.png`" % (m.group(1), len(files) - 1) if m else \
        ", ".join("`%s`" % f for f in files)


def timing_cell(row):
    if row["frames"] == 1:
        return "static"
    return "%g s %s" % (row["seconds"], "loop" if row["loop"] else "once")


def points_cell(row):
    if row["points_hint"]:
        return row["points_hint"]
    pts = row["points"]
    if not pts:
        return ""
    if "per_frame" in pts:
        keys = sorted({k for p in pts["per_frame"] for k in p})
        return ", ".join("`%s`" % k for k in keys) + " (per frame)"
    return ", ".join("`%s` %s" % (k, json.dumps(v, separators=(",", ":"))) for k, v in pts.items())


def rules_cell(row):
    out = []
    if row["rules"]["grounded"]:
        out.append("lowest row %d" % (row["pivot_xy"][1] - 1))
    if row["rules"]["opaque"]:
        out.append("opaque")
    if row["mirror_of"]:
        out.append("exact flip of `%s`" % row["mirror_of"])
    if row["runtime"]:
        out.append("runtime %dx%d x2 by Claude" % tuple(row["runtime"]["canvas_wh"]))
    if row["doubled_from"]:
        out.append("was %dx%d at 2x" % tuple(row["doubled_from"]["canvas_wh"]))
    if row["note"]:
        out.append(row["note"])
    return "; ".join(out)


def batch_markdown(b):
    lines = ["# %s - %s" % (b["slug"], b["title"]), "",
             "Generated by `python implementation/aseprite/inventory.py build`. Do not edit.", ""]
    if b["frames"]:
        lines.append("**%d frames** in %d animations%s. Deliver them as "
                     "`deliveries/%s/png/<file>`." % (
                         b["frames"], len(b["animations"]),
                         ", %d of them exact flips" % b["mirrored_frames"] if b["mirrored_frames"] else "",
                         b["slug"]))
        lines.append("")
    lines += [b["notes"], ""]
    if not b["animations"]:
        return "\n".join(lines) + "\n"
    lines += [
        "Columns:",
        "- **Draw on:** the native canvas and the pivot (the ground contact), in "
        "the pixels you draw.",
        "- **Facing:** `west` means a side view facing west, which the game mirrors "
        "to face east.",
        "- **Today:** the visible size of today's art in native pixels, a guide "
        "for scale. `current` in `inventory.json` lists its files.",
        "- **Rules:** what the check enforces.",
        "- **Points:** today's values, for reference. Give the points of your own "
        "art in contract.json.",
        "",
        "| Files | Draw on | Timing | Facing | Today | Rules | Points | Brief |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for r in b["animations"]:
        today = "%dx%d" % tuple(r["current_visible_wh"]) if r["current_visible_wh"] else \
            ("old strip" if r["current"] else "new")
        brief = r["brief"]
        brief_cell = "[%s](../../../%s)" % (Path(brief).name, brief) if brief else ""
        lines.append("| %s | %dx%d (%d,%d) | %s | %s | %s | %s | %s | %s |" % (
            files_cell(r["files"]), r["canvas_wh"][0], r["canvas_wh"][1],
            r["pivot_xy"][0], r["pivot_xy"][1], timing_cell(r), r["facing"], today,
            rules_cell(r), points_cell(r), brief_cell))
    return "\n".join(lines) + "\n"


def derived_markdown(inv):
    lines = ["# What not to draw", "",
             "Generated by `python implementation/aseprite/inventory.py build`. Do not edit.", "",
             "The game loads these files, but they are made from what you draw, or "
             "they are code. Never deliver them.", ""]
    for key, note in DERIVED_NOTES.items():
        files = inv["derived"][key]
        lines += ["## %s (%d)" % (key, len(files)), "", note, ""]
        shown = files[:12]
        lines += ["- `%s`" % f for f in shown]
        if len(files) > len(shown):
            lines.append("- ... and %d more (`inventory.json` lists them all)" % (len(files) - len(shown)))
        lines.append("")
    lines += ["## code-owned (%d)" % len(inv["code_owned"]), "",
              "Drawn by code from ASCII maps, or built by Claude from your tiles:",
              "- the panel and button nine-patch kit;",
              "- the terrain atlas;",
              "- the actor placeholder.", ""]
    lines += ["- `%s`" % f for f in inv["code_owned"]]
    lines += ["", "## Not art of this game", "",
              "- `assets/studio/` is the studio ident, carried byte for byte.",
              "- `assets/fonts/` comes from `tools/gen_font.py`.",
              "- `assets/icon*.png` and `assets/logo.png` come from `tools/gen_icon.py` and "
              "`tools/gen_logo.py`. Redrawing them is a separate request from the owner.", ""]
    return "\n".join(lines)


def outputs(inv):
    files = {"inventory.json": json.dumps(inv, indent=1, ensure_ascii=False) + "\n",
             "DERIVED.md": derived_markdown(inv)}
    for b in inv["batches"]:
        files["%s.md" % b["slug"]] = batch_markdown(b)
    return files


def build(check_only):
    stale = []
    for name, text in outputs(inventory()).items():
        path = INVENTORY / name
        old = path.read_text(encoding="utf-8") if path.exists() else None
        if old != text:
            stale.append(name)
            if not check_only:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(text.encode("utf-8"))
    if check_only and stale:
        print("stale: " + ", ".join(stale))
        return 1
    print("inventory/ %s (%s)" % ("is current" if not stale else "written",
                                  ", ".join(stale) if stale else "no change"))
    return 0


# ------------------------------------------------------- status and check

def load_inventory():
    return json.load(open(INVENTORY / "inventory.json", encoding="utf-8"))


def delivery_dir(arg):
    p = Path(arg)
    if p.is_dir():
        return p
    if arg in SLUGS:
        return DELIVERIES / SLUGS[arg]
    raise SystemExit("unknown batch " + arg)


def status():
    inv = load_inventory()
    print("%-26s %6s  %s" % ("batch", "frames", "state"))
    for b in inv["batches"]:
        d = DELIVERIES / b["slug"]
        state = "todo"
        if d.is_dir():
            state = "started"
            if (d / "checks.json").exists():
                ok = json.load(open(d / "checks.json", encoding="utf-8")).get("ok")
                state = "checked" if ok else "check failing"
            if (d / "APPROVAL.json").exists():
                state = "approved"
            if (d / "INTEGRATED.json").exists():
                state = "integrated"
        print("%-26s %6d  %s" % (b["slug"], b["frames"], state))
    print("%d frames in %d batches" % (inv["frames"], len(inv["batches"])))
    return 0


def palette_rgbs(root, warnings):
    """The B00 palette next to the delivery being checked, as RGB triples."""
    path = root / SLUGS["B00"] / "palette" / "harvest.json"
    if not path.exists():
        warnings.append("no palette yet (B00): colours not checked")
        return None
    if not (root / SLUGS["B00"] / "APPROVAL.json").exists():
        warnings.append("the palette is not approved yet (B00)")
    data = json.load(open(path, encoding="utf-8"))
    rgbs = set()
    for c in data["colours"]:
        h = c["hex"].lstrip("#")
        rgbs.add(tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)))
    return rgbs, data


def check_palette(root, errors, warnings):
    got = palette_rgbs(root, warnings)
    if got is None:
        errors.append("B00 must deliver palette/harvest.json and palette/harvest.gpl")
        return
    rgbs, data = got
    names = {c.get("name"): c["hex"].lower() for c in data["colours"]}
    for name, rgb in palette.COLOURS.items():
        want = "#%02x%02x%02x" % rgb
        if names.get(name) != want:
            errors.append("palette: project colour %s %s missing or changed" % (name, want))
    if len(rgbs) != len(data["colours"]):
        errors.append("palette: duplicate colours")
    if len(rgbs) > 64:
        warnings.append("palette: %d colours (target 64; above needs the owner's yes)" % len(rgbs))
    if not (root / SLUGS["B00"] / "palette" / "harvest.gpl").exists():
        errors.append("palette: harvest.gpl missing")
    if not list((root / SLUGS["B00"] / "review").glob("pilot-board*.png")):
        errors.append("review/pilot-board.png missing")


def is_point(v):
    return isinstance(v, list) and len(v) == 2 and all(isinstance(n, int) for n in v)


def is_rect(v):
    return isinstance(v, list) and len(v) == 4 and all(isinstance(n, int) for n in v)


def check_points(name, points, im, errors):
    w, h = im.size
    alpha = im.getchannel("A").load()
    for key, value in sorted(points.items()):
        if key.endswith("_xy"):
            pts = [value] if is_point(value) else value
            for p in pts:
                if not is_point(p) or not (0 <= p[0] < w and 0 <= p[1] < h):
                    errors.append("%s: %s %s is off the canvas" % (name, key, p))
                elif key not in FREE_POINTS and alpha[p[0], p[1]] != 255:
                    errors.append("%s: %s %s is not on an opaque pixel" % (name, key, p))
        elif key.endswith("_xywh"):
            rects = [value] if is_rect(value) else value
            for r in rects:
                if not is_rect(r) or r[0] < 0 or r[1] < 0 or r[0] + r[2] > w or r[1] + r[3] > h:
                    errors.append("%s: %s %s leaves the canvas" % (name, key, r))


def check(arg, write):
    inv = load_inventory()
    folder = delivery_dir(arg)
    bid = folder.name.split("-")[0]
    batch = next((b for b in inv["batches"] if b["id"] == bid), None)
    if batch is None:
        raise SystemExit("%s is not a batch folder" % folder)
    errors, warnings = [], []
    if not folder.is_dir():
        raise SystemExit("no delivery yet: %s" % folder)

    if bid == "B00":
        check_palette(folder.parent, errors, warnings)
        return report(folder, bid, errors, warnings, 0, write)

    contract_path = folder / "contract.json"
    contract = json.load(open(contract_path, encoding="utf-8")) if contract_path.exists() else None
    if contract is None:
        errors.append("contract.json missing")
    by_png = {f["png"]: f for f in (contract or {}).get("files", [])}
    deviated = {d.get("anim") for d in (contract or {}).get("deviations", [])}
    got = palette_rgbs(folder.parent, warnings)
    rgbs = got[0] if got else None

    expected = set()
    checked = 0
    for row in batch["animations"]:
        images = []
        for i, f in enumerate(row["files"]):
            png = "png/" + f
            expected.add(png)
            path = folder / png
            if not path.exists():
                errors.append("missing " + png)
                images.append(None)
                continue
            checked += 1
            im = Image.open(path)
            if im.mode != "RGBA":
                errors.append("%s: mode %s, not RGBA" % (png, im.mode))
            im = im.convert("RGBA")
            images.append(im)
            if list(im.size) != row["canvas_wh"]:
                errors.append("%s: %dx%d, the inventory says %dx%d" % (
                    png, im.size[0], im.size[1], row["canvas_wh"][0], row["canvas_wh"][1]))
                continue
            alpha = im.getchannel("A")
            lo, hi = alpha.getextrema()
            if hi == 0:
                errors.append(png + ": empty frame")
                continue
            if sum(alpha.histogram()[1:255]):
                errors.append(png + ": alpha is not binary (0 or 255 only)")
            if row["rules"]["opaque"] and lo != 255:
                errors.append(png + ": must be fully opaque")
            box = alpha.getbbox()
            if row["rules"]["grounded"] and box[3] - 1 != row["pivot_xy"][1] - 1:
                errors.append("%s: lowest opaque row %d, must be %d (the pivot row %d minus 1)" % (
                    png, box[3] - 1, row["pivot_xy"][1] - 1, row["pivot_xy"][1]))
            if rgbs is not None:
                stray = {c[:3] for _, c in im.getcolors(1 << 24) if c[3] == 255} - rgbs
                if stray:
                    errors.append("%s: %d colours outside the palette, e.g. #%02x%02x%02x" % (
                        (png, len(stray)) + tuple(sorted(stray)[0])))
            entry = by_png.get(png)
            if contract is not None:
                if entry is None:
                    errors.append("%s: not in contract.json" % png)
                else:
                    if entry.get("sha256") != sha256(path):
                        errors.append("%s: sha256 differs from contract.json" % png)
                    if row["anim"] not in deviated:
                        for key in ("seconds", "loop"):
                            if key in entry and entry[key] != row[key]:
                                errors.append("%s: %s %s, the inventory says %s" % (
                                    png, key, entry[key], row[key]))
                    check_points(png, entry.get("points", {}), im, errors)
        if row["mirror_of"]:
            pair = next(r for r in batch["animations"] if r["anim"] == row["mirror_of"])
            for f, g in zip(row["files"], pair["files"]):
                a, b = folder / ("png/" + f), folder / ("png/" + g)
                if a.exists() and b.exists():
                    flipped = Image.open(b).convert("RGBA").transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                    if flipped.tobytes() != Image.open(a).convert("RGBA").tobytes():
                        errors.append("%s is not an exact flip of %s" % (f, g))
        live = [im for im in images if im is not None and list(im.size) == row["canvas_wh"]]
        if len(live) > 1 and len({im.tobytes() for im in live}) < len(live):
            warnings.append("%s: two frames are identical" % row["anim"])
        if row["current_visible_wh"] and live:
            boxes = [im.getchannel("A").getbbox() for im in live]
            heights = [b[3] - b[1] for b in boxes if b]
            old = row["current_visible_wh"][1]
            if heights and abs(max(heights) - old) > max(2, round(old * 0.15)):
                warnings.append("%s: visible height %d, today's is %d" % (row["anim"], max(heights), old))
    pngs = {p.relative_to(folder).as_posix() for p in (folder / "png").rglob("*.png")} \
        if (folder / "png").is_dir() else set()
    for extra in sorted(pngs - expected):
        errors.append("not in this batch: " + extra)
    for src in (contract or {}).get("sources", []):
        p = folder / src.get("path", "")
        if not p.exists():
            errors.append("contract.json source missing: %s" % src.get("path"))
        elif src.get("sha256") != sha256(p):
            errors.append("contract.json source sha256 differs: %s" % src.get("path"))
    if contract is not None and not contract.get("sources"):
        errors.append("contract.json lists no sources (the Lua and .aseprite files)")
    return report(folder, bid, errors, warnings, checked, write)


def report(folder, bid, errors, warnings, checked, write):
    for w in warnings:
        print("warning: " + w)
    for e in errors:
        print("ERROR: " + e)
    ok = not errors
    print("%s: %s - %d frames checked, %d errors, %d warnings" % (
        folder.name, "PASS" if ok else "FAIL", checked, len(errors), len(warnings)))
    if write:
        (folder / "checks.json").write_text(json.dumps(
            {"batch": bid, "ok": ok, "frames_checked": checked,
             "errors": errors, "warnings": warnings}, indent=1) + "\n", encoding="utf-8")
    return 0 if ok else 1


# ----------------------------------------------------------------- sheet

def sheet(bid, out_dir):
    inv = load_inventory()
    batch = next(b for b in inv["batches"] if b["id"] == bid)
    font = ImageFont.load_default()
    zoom, pad, width = 4, 8, 1600
    blocks = []
    for row in batch["animations"]:
        frames = []
        for path in row["current"]:
            with Image.open(ROOT / path) as im:
                im = im.convert("RGBA")
                frames.append(im.resize((im.width * zoom, im.height * zoom), Image.Resampling.NEAREST))
        label = "%s  %dx%d (%d,%d)" % (row["anim"], row["canvas_wh"][0], row["canvas_wh"][1],
                                       row["pivot_xy"][0], row["pivot_xy"][1])
        if not frames:
            label += "  (new: no art today)"
        fw = sum(f.width + 4 for f in frames)
        fh = max([f.height for f in frames] + [0])
        blocks.append((label, frames, max(fw, 8 * len(label)), fh + 16))
    rows, x, y, line_h = [], pad, pad, 0
    for label, frames, w, h in blocks:
        if x + w > width and x > pad:
            x, y, line_h = pad, y + line_h + pad, 0
        rows.append((x, y, label, frames))
        x += w + pad
        line_h = max(line_h, h)
    canvas = Image.new("RGBA", (width + pad, y + line_h + pad), (92, 92, 104, 255))
    draw = ImageDraw.Draw(canvas)
    for x, y, label, frames in rows:
        draw.text((x, y), label, fill=(255, 255, 255, 255), font=font)
        fx = x
        for f in frames:
            canvas.alpha_composite(f, (fx, y + 14))
            fx += f.width + 4
    out = Path(out_dir) / ("%s-current.png" % bid)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    print(out)
    return 0


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "build":
        return build("--check" in argv)
    if cmd == "status":
        return status()
    if cmd == "check" and len(argv) >= 2:
        return check(argv[1], "--write" in argv)
    if cmd == "sheet" and len(argv) >= 3:
        return sheet(argv[1], argv[2])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
