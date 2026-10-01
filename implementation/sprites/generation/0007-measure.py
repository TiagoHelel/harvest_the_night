"""Measure source crops and compose unmodified terrain pixels for visual QA."""
from collections import Counter
from pathlib import Path
import json
import sys

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art

NAMES = ["grass", "grass_b", "grass_c", "grass_d", "soil", "path", "floor", "rock"]
# Measured crop phase keeps the revised source's three-cell clod under nearest
# reduction; the full-source sampling phase otherwise misses it entirely.
CROPS = {"soil": [46, 0, 1152, 1152], "path": [46, 46, 1152, 1152]}
HERE = ROOT / "implementation/sprites/reviews/0007"


def variant(x, y):
    value = abs((x * 73856093) ^ (y * 19349663)) % 32
    return 3 if value == 31 else 2 if value >= 25 else 1 if value >= 18 else 0


def main():
    HERE.mkdir(parents=True, exist_ok=True)
    measured, images = [], {}
    for name in NAMES:
        source = ROOT / ("assets/art_source/terrain/" + name + ".png")
        if not source.exists():
            continue
        raw = Image.open(source).convert("RGBA")
        side = min(raw.size)
        crop = CROPS.get(name, [(raw.width - side) // 2, (raw.height - side) // 2, side, side])
        entry = {
            "id": "terrain/" + name, "name": name,
            "source": source.relative_to(ROOT).as_posix(),
            "source_sha256": import_art.sha(source.read_bytes()),
            "source_wh": list(raw.size),
            "crop_xywh": crop,
            "content_scale": 16.0 / crop[2], "content_anchor_xy": [8, 16],
            "canvas_wh": [16, 16], "pivot_xy": [8, 16], "alpha_threshold": 128,
        }
        native = import_art.render_source(entry)
        pixels = list(import_art.samples(native))
        counts = Counter(pixels)
        seam_x = sum(native.getpixel((0, y)) != native.getpixel((15, y)) for y in range(16))
        seam_y = sum(native.getpixel((x, 0)) != native.getpixel((x, 15)) for x in range(16))
        entry.update(native_sha256=import_art.sha(import_art.png(native)),
                     native_colors=[{"rgba": list(c), "pixels": n} for c, n in counts.most_common()],
                     raw_alpha_range=list(raw.getchannel("A").getextrema()),
                     opposite_border_mismatches_xy=[seam_x, seam_y])
        measured.append(entry)
        images[name] = native
        patch = Image.new("RGBA", (128, 128))
        for y in range(8):
            for x in range(8):
                patch.paste(native, (x * 16, y * 16))
        patch.save(HERE / ("patch-" + name + ".png"))
        patch.resize((384, 384), Image.Resampling.NEAREST).save(HERE / ("patch-" + name + "-3x.png"))
        native.resize((192, 192), Image.Resampling.NEAREST).save(HERE / (name + "-12x.png"))
        print(name, raw.size, "base %", round(counts.most_common(1)[0][1] / 256 * 100, 1),
              "colors", len(counts), "border mismatches", seam_x, seam_y)
    if all(name in images for name in NAMES[:4]):
        mixed = Image.new("RGBA", (128, 128))
        for y in range(8):
            for x in range(8):
                mixed.paste(images[NAMES[variant(x, y)]], (x * 16, y * 16))
        mixed.save(HERE / "patch-grass-mixed.png")
        mixed.resize((384, 384), Image.Resampling.NEAREST).save(HERE / "patch-grass-mixed-3x.png")
    page = Image.new("RGBA", (256, 80), (36, 31, 46, 255))
    draw = ImageDraw.Draw(page)
    for i, (name, native) in enumerate(images.items()):
        x, y = i % 4 * 64, i // 4 * 40
        draw.text((x + 1, y + 1), name, fill=(232, 224, 207, 255))
        page.paste(native, (x + 24, y + 18))
    page.save(HERE / "native-materials.png")
    page.resize((768, 240), Image.Resampling.NEAREST).save(HERE / "native-materials-3x.png")
    (HERE / "measured-contract.json").write_text(json.dumps({"assets": measured}, indent=2) + "\n",
                                                 encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
