"""Cut source-owned idle/walk/run assets and encode a real Godot playback GIF.

No artwork is painted here. Sources are measured, cut, uniformly reduced using
the existing palette/alpha recipe and anchored to a shared ground contact.
"""
from pathlib import Path
import argparse
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
ART = ROOT / "assets/art_source/player-fhd/approved"
OUT = ART / "frames"
sys.path.insert(0, str(ROOT / "tools"))
import import_art

FAMILIES = [
    ("idle_south", "idle_south.png", 3, 1, 3, .55),
    ("walk_south", "walk_south_8-r1.png", 4, 2, 8, .12),
    ("run_south", "run_south_8.png", 4, 2, 8, .08),
]
KEYS = ["ink", "ink_soft", "soil_dark", "wood_dark", "wood", "wood_light",
        "gold_dark", "gold", "gold_light", "skin_dark", "skin", "skin_light",
        "bone", "bone_dark", "cloth_dark", "cloth", "cloth_light"]


def recipes():
    entries = []
    for name, filename, columns, rows, count, seconds in FAMILIES:
        path = ART / filename
        raw = Image.open(path).convert("RGBA")
        pixels = np.array(raw)
        measured = []
        for frame in range(count):
            col, row = frame % columns, frame // columns
            left, right = round(raw.width * col / columns), round(raw.width * (col + 1) / columns)
            top, bottom = round(raw.height * row / rows), round(raw.height * (row + 1) / rows)
            alpha = pixels[top:bottom, left:right, 3] >= 128
            ys, xs = np.nonzero(alpha)
            assert len(xs), (name, frame, "empty source cell")
            x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
            # Hat center is stable across the stride. Centering on the lowest
            # single support boot would move the entire farmer left/right.
            hat = alpha[y0:y0 + round((y1 - y0) * .36)]
            hx = np.nonzero(hat)[1]
            center_x = left + (int(hx.min()) + int(hx.max()) + 1) / 2
            measured.append({"crop": [left + x0, top + y0, x1 - x0, y1 - y0],
                             "center_x": center_x, "row": row, "top": top,
                             "local_hat_y": y0, "local_bottom": y1,
                             "cell": [left, top, right - left, bottom - top]})
        baselines = {row: max(m["local_bottom"] for m in measured if m["row"] == row) for row in range(rows)}
        height = max(baselines[m["row"]] - m["local_hat_y"] for m in measured)
        scale = 60 / height
        for frame, m in enumerate(measured):
            box = m["crop"]
            ground = m["top"] + baselines[m["row"]]
            anchor = [round((m["center_x"] - box[0]) * scale), round((ground - box[1]) * scale)]
            prompt = "idle_south" if name == "idle_south" else "walk_south_8-r1" if name == "walk_south" else "run_south_8"
            entry = {"id": name + "_" + str(frame), "source": path.relative_to(ROOT).as_posix(),
                     "source_sha256": import_art.sha(path.read_bytes()), "crop_xywh": box,
                     "sheet_cell_xywh": m["cell"], "canvas_wh": [96, 96], "pivot_xy": [48, 88],
                     "content_scale": scale, "content_anchor_xy": anchor, "alpha_threshold": 128,
                     "palette": "tools/palette.py:COLOURS", "palette_keys": KEYS,
                     "animation": name, "frame": frame, "seconds": seconds, "loop": True,
                     "draw_scale": .5, "body_reference_height": height,
                     "feet_source_xy": [m["center_x"], ground],
                     "output": (OUT / (name + "_" + str(frame) + ".png")).relative_to(ROOT).as_posix(),
                     "prompt": "implementation/fhd-player/approved-prompts/" + prompt + ".prompt.txt"}
            entry["prompt_sha256"] = import_art.sha((ROOT / entry["prompt"]).read_bytes())
            entries.append(entry)
    return entries


def build(check=False):
    OUT.mkdir(parents=True, exist_ok=True)
    entries = recipes()
    seen = {}
    for entry in entries:
        image = import_art.render_source(entry)
        content = import_art.png(image)
        entry["output_sha256"] = import_art.sha(content)
        path = ROOT / entry["output"]
        if check:
            assert path.read_bytes() == content, path
        else:
            path.write_bytes(content)
        assert image.getchannel("A").getextrema() == (0, 255)
        seen.setdefault(entry["animation"], []).append(entry["output_sha256"])
    for animation, hashes in seen.items():
        assert len(hashes) == (3 if animation == "idle_south" else 8)
        if animation != "idle_south":
            assert len(set(hashes)) == 8, (animation, "duplicated native animation drawing")
            # Different hats or pixel noise do not prove different leg motion.
            lower = [Image.open(ROOT / e["output"]).crop((22, 67, 74, 92))
                     for e in entries if e["animation"] == animation]
            assert len({import_art.sha(im.tobytes()) for im in lower}) == 8, \
                (animation, "duplicated lower-body phase")
    manifest = {"recipe": "nearest-palette-alpha-v1", "canvas_wh": [96, 96],
                "pivot_xy": [48, 88], "draw_scale": .5,
                "fhd_physical_body_height": 120, "frames": entries,
                "scope": "source-owned front-facing animation assets and review playback; gameplay unchanged"}
    data = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    target = HERE / "locomotion-contract.json"
    if check:
        assert target.read_bytes() == data, "measurement recipe changed"
    else:
        target.write_bytes(data)
    print("Source check:", len(entries), "frames; eight unique lower-body phases per cycle; shared scale per strip; binary alpha")
    return entries


def contacts(entries):
    for name in ["idle_south", "walk_south", "run_south"]:
        group = [e for e in entries if e["animation"] == name]
        page = Image.new("RGB", (len(group) * 196, 224), (54, 49, 61))
        draw = ImageDraw.Draw(page)
        for i, entry in enumerate(group):
            image = Image.open(ROOT / entry["output"]).convert("RGBA").resize((192, 192), Image.Resampling.NEAREST)
            page.paste(image, (i * 196 + 2, 24), image)
            draw.text((i * 196 + 10, 6), name + " " + str(i), fill=(232, 224, 207))
            draw.line((i * 196 + 35, 200, i * 196 + 157, 200), fill=(112, 96, 76))
        page.save(HERE / (name + "-contact.png"))


def encode():
    paths = sorted((HERE / "locomotion-playback").glob("frame-*.png"))
    assert len(paths) == 192, "Expected 7.68 seconds at 25 fps from the actual Godot renderer"
    frames = [Image.open(path).convert("RGB") for path in paths]
    assert all(frame.size == (660, 240) for frame in frames)
    assert len({import_art.sha(frame.tobytes()) for frame in frames}) > 40
    # Sample every animation phase for one stable shared GIF palette.
    samples = Image.new("RGB", (660, 240 * 24))
    for i in range(24):
        samples.paste(frames[i * 8], (0, i * 240))
    palette = samples.quantize(colors=128, dither=Image.Dither.NONE)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    target = HERE / "idle-walk-run-horizontal.gif"
    indexed[0].save(target, save_all=True, append_images=indexed[1:], duration=40,
                    loop=0, disposal=2, optimize=False)
    with Image.open(target) as gif:
        duration = 0
        for frame in range(gif.n_frames):
            gif.seek(frame)
            duration += gif.info["duration"]
        assert duration == 7680
        print("Playback:", target, gif.size, gif.n_frames, "encoded frames", duration, "ms")


if __name__ == "__main__":
    args = argparse.ArgumentParser()
    args.add_argument("--check", action="store_true")
    args.add_argument("--encode", action="store_true")
    flags = args.parse_args()
    entries = build(flags.check)
    if not flags.check:
        contacts(entries)
    if flags.encode:
        encode()
