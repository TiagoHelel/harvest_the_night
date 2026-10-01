"""Measure generated alpha; preview deterministic native crops without painting."""
from collections import deque
from pathlib import Path
import json
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT / "implementation/sprites/reviews/0006"
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def components(mask):
    remaining = mask.copy()
    result = []
    for y, x in zip(*np.nonzero(mask)):
        if not remaining[y, x]:
            continue
        remaining[y, x] = False
        queue = deque([(int(x), int(y))])
        count, x0, y0, x1, y1 = 0, int(x), int(y), int(x), int(y)
        while queue:
            px, py = queue.popleft()
            count += 1
            x0, y0, x1, y1 = min(x0, px), min(y0, py), max(x1, px), max(y1, py)
            for ny in range(max(0, py - 1), min(mask.shape[0], py + 2)):
                for nx in range(max(0, px - 1), min(mask.shape[1], px + 2)):
                    if remaining[ny, nx]:
                        remaining[ny, nx] = False
                        queue.append((nx, ny))
        result.append((count, (x0, y0, x1 + 1, y1 + 1)))
    return sorted(result, reverse=True)


def checker(size):
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], 8):
        for x in range(0, size[0], 8):
            draw.rectangle((x, y, x + 7, y + 7), fill=(112, 104, 120, 255)
                           if (x // 8 + y // 8) % 2 else (184, 176, 184, 255))
    return image


def main():
    HERE.mkdir(parents=True, exist_ok=True)
    entries, natives = [], []
    for name in ["react_bang", "react_question", "react_note", "react_heart", "shadow"]:
        source = "assets/art_source/player/" + name + ".png"
        raw = Image.open(ROOT / source).convert("RGBA")
        mask = np.array(raw.getchannel("A")) >= 128
        parts = components(mask)
        body = parts[0][1]
        xs, ys = np.nonzero(mask)[1], np.nonzero(mask)[0]
        crop = [int(xs.min()), int(ys.min()), int(xs.max() - xs.min() + 1),
                int(ys.max() - ys.min() + 1)]
        body_height = body[3] - body[1]
        if name == "shadow":
            scale = 18.0 / (body[2] - body[0])
            canvas, pivot = [20, 8], [10, 4]
            anchor = [round(crop[2] * scale) // 2, round(crop[3] * scale) // 2]
            feet = None
        else:
            scale = 30.0 / body_height
            canvas, pivot = [48, 48], [24, 44]
            # The lower boot rows, excluding the separate floating symbol.
            lower = mask[body[3] - max(2, body_height // 20):body[3], body[0]:body[2]]
            boot_x = np.nonzero(lower)[1]
            feet = [body[0] + (int(boot_x.min()) + int(boot_x.max()) + 1) / 2, body[3]]
            anchor = [round((feet[0] - crop[0]) * scale), round((feet[1] - crop[1]) * scale)]
        entry = {"id": "actors/" + name + ("_0" if name != "shadow" else ""),
                 "name": name, "source": source, "source_sha256": import_art.sha((ROOT / source).read_bytes()),
                 "source_wh": list(raw.size), "crop_xywh": crop, "body_box_xyxy": list(body),
                 "body_reference_height": body_height, "feet_source_xy": feet,
                 "content_scale": scale, "content_anchor_xy": anchor,
                 "canvas_wh": canvas, "pivot_xy": pivot, "alpha_threshold": 128,
                 "components": [{"pixels": c, "box_xyxy": list(b)} for c, b in parts]}
        native = import_art.render_source(entry)
        if name != "shadow":
            native_parts = components(np.array(native.getchannel("A")) >= 128)
            glyphs = [box for _count, box in native_parts[1:]]
            gx, gy = min(b[0] for b in glyphs), min(b[1] for b in glyphs)
            gr, gb = max(b[2] for b in glyphs), max(b[3] for b in glyphs)
            entry["bubble_xywh"] = [gx, gy, gr - gx, gb - gy]
            # A view-only rectangular mask must never remove any body pixels.
            assert native_parts[0][1][3] == 44
            body_mask = np.array(native.getchannel("A")) >= 128
            region_count = int(body_mask[gy:gb, gx:gr].sum())
            assert region_count == sum(count for count, _box in native_parts[1:])
        entry["native_bounds_xyxy"] = list(native.getbbox())
        entry["native_sha256"] = import_art.sha(import_art.png(native))
        natives.append((name, native))
        entries.append(entry)
        # Source alpha on three backgrounds; the full original is also retained.
        preview = raw.resize((640, round(raw.height * 640 / raw.width)), Image.Resampling.NEAREST)
        page = Image.new("RGBA", (640, preview.height * 3), (232, 224, 207, 255))
        page.paste((38, 32, 47, 255), (0, preview.height, 640, preview.height * 2))
        page.paste(checker(preview.size), (0, preview.height * 2))
        for y in range(3):
            page.alpha_composite(preview, (0, preview.height * y))
        page.save(HERE / ("source-alpha-" + name + ".png"))
        print(name, "body", body, "canvas", canvas, "native", native.getbbox(), "parts", len(parts))
    (HERE / "measured-contract.json").write_text(json.dumps({"assets": entries}, indent=2) + "\n",
                                                 encoding="utf-8", newline="\n")
    natives.insert(0, ("idle reference", Image.open(ROOT / "sprites/actors/idle_south_0.png").convert("RGBA")))
    for kind, color in enumerate([(232, 224, 207, 255), (38, 32, 47, 255), None]):
        page = Image.new("RGBA", (336, 112), color) if color else checker((336, 112))
        draw = ImageDraw.Draw(page)
        for i, (name, native) in enumerate(natives):
            x = i * 56
            draw.text((x + 1, 4), name.replace("react_", ""), fill=(30, 24, 35, 255) if kind == 0 else "white")
            page.alpha_composite(native, (x + (56 - native.width) // 2, 30))
            draw.line((x + 1, 74, x + 54, 74), fill=(180, 138, 85, 255))
        page.save(HERE / ("alpha-%d.png" % kind))
        page.resize((1008, 336), Image.Resampling.NEAREST).save(HERE / ("alpha-%d-3x.png" % kind))


if __name__ == "__main__":
    main()
