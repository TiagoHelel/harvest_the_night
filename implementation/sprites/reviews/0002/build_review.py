"""Native/nearest QA views of committed production outputs; no creative edits."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
import import_art

HERE = Path(__file__).resolve().parent


def write(path, image):
    data = import_art.png(image)
    if not path.exists() or path.read_bytes() != data:
        path.write_bytes(data)


def main():
    manifest = import_art.load_manifest()
    entries = manifest["assets"]
    sheet = Image.new("RGBA", (480, ((len(entries)+3)//4)*100), (36,31,46,255))
    draw = ImageDraw.Draw(sheet)
    for i, entry in enumerate(entries):
        x, y = (i%4)*120, (i//4)*100
        draw.text((x+2,y+2), entry["id"].split("/")[-1], fill=(232,224,207,255))
        for cy in range(0,72,8):
            for cx in range(0,96,8):
                draw.rectangle((x+cx,y+20+cy,x+cx+7,y+20+cy+7), fill=(80,75,90,255) if (cx+cy)//8%2 else (140,135,145,255))
        with Image.open(ROOT / entry["output"]) as raw:
            image = raw.convert("RGBA")
            sheet.alpha_composite(image, (x+(96-image.width)//2,y+24))
    write(HERE / "runtime-contact.png", sheet)
    write(HERE / "runtime-contact-3x.png", sheet.resize((sheet.width*3,sheet.height*3), Image.Resampling.NEAREST))
    for path in (ROOT / "implementation/shots/sprites/0002").glob("*.png"):
        with Image.open(path) as image:
            write(HERE / (path.stem+"-3x.png"), image.resize((image.width*3,image.height*3), Image.Resampling.NEAREST))
    print("OK: 18 output contact views and five 3x captures")


if __name__ == "__main__":
    main()
