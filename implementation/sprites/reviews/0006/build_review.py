"""Compose actual captures at native/nearest-3x, never editing source pixels."""
from pathlib import Path
import json

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent


def main():
    folder = ROOT / "implementation/shots/sprites/0006"
    # Keep reviewed reaction pages stable when the final base captures arrive.
    captures = sorted((folder / "reactions").glob("*.png")) + sorted(folder.glob("*.png"))
    for page in range((len(captures) + 3) // 4):
        image = Image.new("RGBA", (960, 576), (36, 31, 46, 255))
        draw = ImageDraw.Draw(image)
        for i, path in enumerate(captures[page * 4:(page + 1) * 4]):
            x, y = i % 2 * 480, i // 2 * 288
            draw.text((x + 3, y + 2), path.stem, fill=(237, 225, 201, 255))
            capture = Image.open(path).convert("RGBA")
            assert capture.size == (480, 270), path
            image.paste(capture, (x, y + 18))
        image.save(HERE / ("captures-%02d.png" % page))
        image.resize((2880, 1728), Image.Resampling.NEAREST).save(HERE / ("captures-%02d-3x.png" % page))
    measured = json.loads((HERE / "measured-contract.json").read_text())
    (HERE / "frame-review.json").write_text(json.dumps({
        "assets": measured["assets"],
        "captures": [p.relative_to(ROOT).as_posix() for p in captures],
        "capture_pages": (len(captures) + 3) // 4}, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("OK: %d actual Godot captures at native and nearest 3x" % len(captures))


if __name__ == "__main__":
    main()
