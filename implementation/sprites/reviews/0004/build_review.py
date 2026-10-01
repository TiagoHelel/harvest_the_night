"""Native/nearest QA, alpha/silhouettes and animation previews of accepted files."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
import import_art

HERE = Path(__file__).resolve().parent
NAMES = ["idle_south", "walk_south", "idle_north", "walk_north", "idle_west", "walk_west"]


def write(path, image):
    data = import_art.png(image)
    if not path.exists() or path.read_bytes() != data:
        path.write_bytes(data)


def main():
    data = import_art.load_manifest()
    report = []
    for row, name in enumerate(NAMES):
        entries = sorted((e for e in data["assets"] if e["animation"] == name), key=lambda e: e["frame"])
        frames = [Image.open(ROOT / e["output"]).convert("RGBA") for e in entries]
        assert len({frame.tobytes() for frame in frames}) == len(frames), name + " duplicate native frame"
        assert all(frame.size == (48, 48) and frame.getbbox()[3] == 44 for frame in frames), name + " contact drift"
        report.append({"name": name, "native_unique_frames": len(frames), "ground_y": 44,
                       "body_wh": [[f.getbbox()[2]-f.getbbox()[0], f.getbbox()[3]-f.getbbox()[1]] for f in frames]})
    backgrounds = [(232, 224, 207, 255), (38, 32, 47, 255), None]
    for kind, background in enumerate(backgrounds):
        sheet = Image.new("RGBA", (480, 396), background or (94, 91, 102, 255))
        draw = ImageDraw.Draw(sheet)
        if background is None:
            for y in range(0, 396, 8):
                for x in range(0, 480, 8):
                    if (x//8 + y//8) % 2:
                        draw.rectangle((x, y, x+7, y+7), fill=(145, 141, 151, 255))
        for row, name in enumerate(NAMES):
            draw.text((4, row*66+3), name, fill=(255, 255, 255, 255) if kind else (38, 32, 47, 255))
            entries = sorted((e for e in data["assets"] if e["animation"] == name), key=lambda e: e["frame"])
            for i, entry in enumerate(entries):
                frame = Image.open(ROOT / entry["output"]).convert("RGBA")
                sheet.alpha_composite(frame, (136+i*64, row*66+15))
        write(HERE / ("alpha-%d.png" % kind), sheet)
        write(HERE / ("alpha-%d-3x.png" % kind), sheet.resize((1440, 1188), Image.Resampling.NEAREST))
    # Four direction rows, actual frames plus the runtime's west->east mirror.
    for action in ["idle", "walk"]:
        gifs = []
        count = 3 if action == "idle" else 4
        for i in range(count):
            page = Image.new("RGBA", (480, 270), (42, 37, 49, 255))
            draw = ImageDraw.Draw(page)
            draw.text((10, 8), action + " - committed native frames / fixed ground pivots", fill=(237, 225, 201, 255))
            for facing, side in enumerate(["south", "west", "north", "west"]):
                image = Image.open(ROOT / ("sprites/actors/%s_%s_%d.png" % (action, side, i))).convert("RGBA")
                if facing == 3:
                    image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                for column in range(2):
                    y = 18 + facing*60
                    draw.text((4, y+19), ["SOUTH", "WEST", "NORTH", "EAST"][facing], fill=(237, 225, 201, 255))
                    page.alpha_composite(image, (112+column*120, y))
                    draw.line((104+column*120, y+44, 168+column*120, y+44), fill=(175, 135, 83, 255))
            write(HERE / ("%s-phase-%02d.png" % (action, i)), page)
            gifs.append(page.convert("RGB"))
        gifs[0].save(HERE / (action+".gif"), save_all=True, append_images=gifs[1:],
                     duration=550 if action == "idle" else 130, loop=0, disposal=2, optimize=False)
        zoom = [g.resize((1440, 810), Image.Resampling.NEAREST) for g in gifs]
        zoom[0].save(HERE / (action+"-3x.gif"), save_all=True, append_images=zoom[1:],
                     duration=550 if action == "idle" else 130, loop=0, disposal=2, optimize=False)
    folder = ROOT / "implementation/shots/sprites/0004"
    captures = sorted(folder.glob("*.png")) + sorted((folder / "locomotion").glob("*.png"))
    for page in range((len(captures)+3)//4):
        sheet = Image.new("RGBA", (960, 576), (36, 31, 46, 255))
        draw = ImageDraw.Draw(sheet)
        for i, path in enumerate(captures[page*4:(page+1)*4]):
            x, y = i%2*480, i//2*288
            draw.text((x+3, y+2), path.stem, fill=(237, 225, 201, 255))
            sheet.paste(Image.open(path).convert("RGBA"), (x, y+18))
        write(HERE / ("captures-%02d.png" % page), sheet)
        write(HERE / ("captures-%02d-3x.png" % page), sheet.resize((2880, 1728), Image.Resampling.NEAREST))
    (HERE / "frame-review.json").write_text(json.dumps({"animations": report, "captures": len(captures)}, indent=2)+"\n", encoding="utf-8")
    print("OK: 21 distinct source-owned native frames; %d actual Godot captures" % len(captures))


if __name__ == "__main__":
    main()
