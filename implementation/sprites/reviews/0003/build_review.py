"""Contact pages of actual Godot captures at native and nearest 3x scale."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
from import_art import png

HERE = Path(__file__).resolve().parent


def write(path, image):
    data = png(image)
    if not path.exists() or path.read_bytes() != data:
        path.write_bytes(data)


def main():
    folder = ROOT / "implementation/shots/sprites/0003"
    paths = sorted(folder.glob("*.png")) + sorted((folder / "showcase").glob("*.png"))
    for page in range((len(paths)+3)//4):
        sheet = Image.new("RGBA", (960, 576), (36,31,46,255))
        draw = ImageDraw.Draw(sheet)
        for i, path in enumerate(paths[page*4:(page+1)*4]):
            x, y = (i%2)*480, (i//2)*288
            draw.text((x+3,y+2), path.stem, fill=(232,224,207,255))
            with Image.open(path) as image:
                sheet.paste(image.convert("RGBA"), (x,y+18))
        write(HERE / ("captures-%02d.png" % page), sheet)
        write(HERE / ("captures-%02d-3x.png" % page), sheet.resize((2880,1728), Image.Resampling.NEAREST))
    for name in ("noon", "dusk", "wave"):
        with Image.open(folder / (name+".png")) as image:
            write(HERE / (name+"-3x.png"), image.resize((1440,810), Image.Resampling.NEAREST))
    print("OK: %d captures across %d native/3x contact pages" % (len(paths), (len(paths)+3)//4))


if __name__ == "__main__":
    main()
