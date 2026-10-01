"""Build task-0001 review images from accepted masters, not runtime sprites.

Uses measured crop boxes, explicit content size, fixed pivots, alpha threshold,
nearest resampling and the shared palette. This is a scoped scale/alpha review;
task 0002 still owns the production importer and output ownership migration.
"""
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
sys.path.insert(0, str(REPO / "tools"))
import gen_sprites
import palette


def samples(image):
    # Support the Pillow version used by the existing cutter and newer Pillow.
    return image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()


def encoded(image):
    image = image.convert("RGBA")
    pixels = list(samples(image))
    rows = [pixels[y * image.width:(y + 1) * image.width] for y in range(image.height)]
    return gen_sprites.png_bytes(image.width, image.height, rows)


def write(path, image):
    data = encoded(image)
    if not path.exists() or path.read_bytes() != data:
        path.write_bytes(data)
    return hashlib.sha256(data).hexdigest()


def native(entry):
    source = REPO / entry["source"]
    if hashlib.sha256(source.read_bytes()).hexdigest() != entry["source_sha256"]:
        raise ValueError("Source changed: " + entry["source"])
    with Image.open(source) as raw:
        crop = raw.convert("RGBA").crop(entry["crop_xyxy"])
        crop = crop.resize(tuple(entry["content_wh"]), Image.Resampling.NEAREST)
    colors = tuple(palette.COLOURS.values())
    cache = {}
    reduced = []
    for r, g, b, a in samples(crop):
        if a < 128:
            reduced.append((0, 0, 0, 0))
            continue
        rgb = (r, g, b)
        if rgb not in cache:
            cache[rgb] = min(colors, key=lambda c: sum((c[i] - rgb[i]) ** 2 for i in range(3)))
        reduced.append((*cache[rgb], 255))
    crop.putdata(reduced)
    canvas = Image.new("RGBA", tuple(entry["canvas_wh"]))
    px, py = entry["pivot_xy"]
    offset = (px - crop.width // 2, py - crop.height)
    if offset[0] < 0 or offset[1] < 0 or offset[0] + crop.width > canvas.width or py > canvas.height:
        raise ValueError("Content does not fit the approved canvas")
    canvas.alpha_composite(crop, offset)
    return canvas


def main():
    contract = json.loads((REPO / "assets/art_source/masters/master-contract.json").read_text())
    out = HERE / "native"
    out.mkdir(parents=True, exist_ok=True)
    frames = {}
    report = []
    for entry in contract["masters"]:
        image = native(entry)
        frames[entry["id"]] = image
        digest = write(out / (entry["id"] + ".png"), image)
        write(out / (entry["id"] + "-3x.png"), image.resize((image.width * 3, image.height * 3), Image.Resampling.NEAREST))
        opaque = [p for p in samples(image) if p[3]]
        assert opaque and all(p[:3] in palette.COLOURS.values() for p in opaque)
        assert set(samples(image.getchannel("A"))) <= {0, 255}
        report.append(dict(id=entry["id"], canvas_wh=list(image.size), bbox_xyxy=image.getbbox(),
                           pivot_xy=entry["pivot_xy"], colors=len(set(opaque)), sha256=digest))

    # Alpha review over white, charcoal, checker and real farm grass.
    sheet = Image.new("RGBA", (280, len(frames) * 84), (36, 31, 46, 255))
    draw = ImageDraw.Draw(sheet)
    for row, (name, image) in enumerate(frames.items()):
        draw.text((4, row * 84 + 2), name, fill=(232, 224, 207, 255))
        for column, color in enumerate(((244, 242, 235, 255), (20, 18, 30, 255), None, (*palette.COLOURS["grass"], 255))):
            x, y = column * 70 + 3, row * 84 + 17
            draw.rectangle((x, y, x + 63, y + 63), fill=color or (130, 125, 135, 255))
            if color is None:
                for cy in range(0, 64, 8):
                    for cx in range(0, 64, 8):
                        if (cx // 8 + cy // 8) % 2:
                            draw.rectangle((x + cx, y + cy, x + cx + 7, y + cy + 7), fill=(180, 175, 185, 255))
            sheet.alpha_composite(image, (x + (64 - image.width) // 2, y + 64 - image.height))
    write(HERE / "alpha-contact.png", sheet)
    write(HERE / "alpha-contact-3x.png", sheet.resize((sheet.width * 3, sheet.height * 3), Image.Resampling.NEAREST))

    if len(frames) == 4:
        scene = Image.new("RGBA", (240, 160), (*palette.COLOURS["grass"], 255))
        draw = ImageDraw.Draw(scene)
        for x in range(0, 240, 16):
            draw.line((x, 0, x, 159), fill=(*palette.COLOURS["grass_dark"], 255))
        for y in range(0, 160, 16):
            draw.line((0, y, 239, y), fill=(*palette.COLOURS["grass_dark"], 255))
        positions = {"house": (128, 80), "tree": (48, 80), "farmer": (96, 128), "walker": (160, 128)}
        for entry in sorted(contract["masters"], key=lambda e: positions[e["id"]][1]):
            x, y = positions[entry["id"]]
            px, py = entry["pivot_xy"]
            scene.alpha_composite(frames[entry["id"]], (x - px, y - py))
        write(HERE / "scale-grid.png", scene)
        write(HERE / "scale-grid-3x.png", scene.resize((720, 480), Image.Resampling.NEAREST))
        # A silhouette review preserves actual native shapes without recoloring source art.
        silhouettes = sheet.copy()
        for row, image in enumerate(frames.values()):
            black = Image.new("RGBA", image.size, (15, 12, 20, 255))
            black.putalpha(image.getchannel("A"))
            for column in range(4):
                x, y = column * 70 + 3, row * 84 + 17
                silhouettes.alpha_composite(black, (x + (64 - image.width) // 2, y + 64 - image.height))
        write(HERE / "silhouettes.png", silhouettes)
    (HERE / "native-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("PASS: native review generated for", ", ".join(frames))


if __name__ == "__main__":
    main()
