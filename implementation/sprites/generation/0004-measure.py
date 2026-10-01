"""Measure alpha boxes and preview sources; production uses frozen manifest boxes."""
from pathlib import Path
import json
import sys
from statistics import median
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art
import cut_sheet

OUT = ROOT / "implementation/sprites/reviews/0004"
NAMES = ["idle_south", "walk_south", "idle_north", "walk_north", "idle_west", "walk_west"]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    contract = {"date": "2026-10-01", "canvas_wh": [48, 48], "pivot_xy": [24, 44], "animations": []}
    contact = Image.new("RGBA", (480, 396), (44, 39, 51, 255))
    draw = ImageDraw.Draw(contact)
    for row, name in enumerate(NAMES):
        source = "assets/art_source/player/" + name + ".png"
        with Image.open(ROOT / source) as raw:
            raw = raw.convert("RGBA")
            alpha = raw.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
            columns = [sum(alpha.getpixel((x, y)) != 0 for y in range(raw.height)) > 8 for x in range(raw.width)]
            runs = cut_sheet._runs(columns)
            boxes = []
            for x0, x1 in runs:
                if x1 - x0 < 20:
                    continue
                box = alpha.crop((x0, 0, x1, raw.height)).getbbox()
                boxes.append([x0 + box[0], box[1], box[2] - box[0], box[3] - box[1]])
            count = 3 if name.startswith("idle_") else 4
            if len(boxes) != count:
                raise ValueError((name, "expected complete strip", boxes))
            scale = 30.0 / median(b[3] for b in boxes)
            frames = []
            draw.text((4, row * 66 + 3), name, fill=(237, 225, 201, 255))
            for i, box in enumerate(boxes):
                entry = {"id": name + "_" + str(i), "source": source, "crop_xywh": box,
                         "canvas_wh": [48, 48], "pivot_xy": [24, 44], "content_scale": scale,
                         "alpha_threshold": 128}
                image = import_art.render_source(entry)
                frames.append(image)
                contact.alpha_composite(image, (136 + i * 64, row * 66 + 15))
                draw.line((132 + i * 64, row * 66 + 59, 188 + i * 64, row * 66 + 59), fill=(180, 138, 85, 255))
            print(name, raw.size, "alpha", raw.getchannel("A").getextrema(), "boxes", boxes,
                  "scale", scale, "unique native", len({f.tobytes() for f in frames}),
                  "native boxes", [f.getbbox() for f in frames])
            contract["animations"].append({"name": name, "source": source,
                "source_sha256": import_art.sha((ROOT / source).read_bytes()),
                "source_wh": list(raw.size), "content_scale": scale, "crop_xywh": boxes})
    (OUT / "measured-contract.json").write_text(json.dumps(contract, indent=2) + "\n", encoding="utf-8")
    (OUT / "native-frames.png").write_bytes(import_art.png(contact))
    (OUT / "native-frames-3x.png").write_bytes(import_art.png(contact.resize((1440, 1188), Image.Resampling.NEAREST)))


if __name__ == "__main__":
    main()
