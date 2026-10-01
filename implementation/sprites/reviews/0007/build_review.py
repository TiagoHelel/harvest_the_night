"""Compose unmodified source/atlas pixels and actual Godot captures for QA."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent


def main():
    folder = ROOT / "implementation/shots/sprites/0007"
    captures = sorted((folder / "terrain").glob("*.png")) + sorted(folder.glob("*.png"))
    for page in range((len(captures) + 3) // 4):
        image = Image.new("RGBA", (960, 576), (36, 31, 46, 255))
        draw = ImageDraw.Draw(image)
        for i, path in enumerate(captures[page*4:(page+1)*4]):
            x, y = i%2*480, i//2*288
            draw.text((x+3, y+2), path.stem, fill=(237,225,201,255))
            with Image.open(path) as capture:
                assert capture.size == (480,270), path
                image.paste(capture.convert("RGBA"), (x, y+18))
        image.save(HERE / ("captures-%02d.png" % page))
        image.resize((2880,1728), Image.Resampling.NEAREST).save(HERE / ("captures-%02d-3x.png" % page))
    measured = json.loads((HERE / "measured-contract.json").read_text())
    raw_page = Image.new("RGBA", (640,360), (36,31,46,255))
    draw = ImageDraw.Draw(raw_page)
    for i, entry in enumerate(measured["assets"]):
        x,y = i%4*160, i//4*180
        with Image.open(ROOT / entry["source"]) as source:
            assert source.convert("RGBA").getchannel("A").getextrema() == (255,255)
            raw_page.paste(source.resize((144,144), Image.Resampling.NEAREST).convert("RGBA"), (x+8,y+23))
        draw.text((x+6,y+5), entry["name"] + " alpha 255", fill=(237,225,201,255))
    raw_page.save(HERE / "source-alpha.png")
    atlas = Image.open(ROOT / "sprites/terrain/atlas.png").convert("RGBA")
    atlas.save(HERE / "atlas.png")
    atlas.resize((768,240), Image.Resampling.NEAREST).save(HERE / "atlas-3x.png")
    comparison = Image.new("RGBA", (960,864), (36,31,46,255))
    draw = ImageDraw.Draw(comparison)
    for row, scenario in enumerate(["noon", "dusk", "wave"]):
        for column, task in enumerate(["0006", "0007"]):
            x,y = column*480,row*288
            draw.text((x+3,y+2), task + " / " + scenario, fill=(237,225,201,255))
            comparison.paste(Image.open(ROOT / ("implementation/shots/sprites/" + task + "/" + scenario + ".png")).convert("RGBA"), (x,y+18))
    comparison.save(HERE / "before-after.png")
    comparison.resize((2880,2592), Image.Resampling.NEAREST).save(HERE / "before-after-3x.png")
    (HERE / "frame-review.json").write_text(json.dumps({
        "assets": measured["assets"], "captures": [dict(path=p.relative_to(ROOT).as_posix(),
         sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in captures],
        "capture_pages": (len(captures)+3)//4}, indent=2)+"\n", encoding="utf-8", newline="\n")
    print("OK: %d actual Godot captures at native and nearest 3x; 8 opaque raw sources" % len(captures))


if __name__ == "__main__":
    main()
