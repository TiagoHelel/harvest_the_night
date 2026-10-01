"""Compose native/nearest QA without painting source or runtime art."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
NAMES = ["tree","tree_b","stump","rock","rock_b","seam","seam_b","ore","ore_b","cow","chicken"]


def pair(image, name):
    image.save(HERE/(name+".png"))
    image.resize((image.width*3,image.height*3),Image.Resampling.NEAREST).save(HERE/(name+"-3x.png"))


def checker(size):
    image = Image.new("RGBA",size)
    draw = ImageDraw.Draw(image)
    for y in range(0,size[1],8):
        for x in range(0,size[0],8):
            draw.rectangle((x,y,x+7,y+7),fill="#e8e0cf" if (x//8+y//8)%2 else "#877e8a")
    return image


def captures_only():
    folder=ROOT/"implementation/shots/sprites/0009"
    captures=sorted((folder/"props").glob("*.png"))+sorted(folder.glob("*.png"))
    for page in range((len(captures)+3)//4):
        sheet=Image.new("RGBA",(960,576),"#241f2e")
        draw=ImageDraw.Draw(sheet)
        for i,path in enumerate(captures[page*4:(page+1)*4]):
            x,y=i%2*480,i//2*288
            draw.text((x+3,y+2),path.stem,fill="#e8e0cf")
            capture=Image.open(path).convert("RGBA")
            assert capture.size == (480,270)
            sheet.paste(capture,(x,y+18))
        pair(sheet,"captures-%02d"%page)
    (HERE/"frame-review.json").write_text(json.dumps(dict(captures=[dict(path=p.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in captures],capture_pages=(len(captures)+3)//4,native_size=[480,270],nearest_scale=3),indent=2)+"\n",encoding="utf-8",newline="\n")
    return captures


def main():
    if "--captures-only" in sys.argv:
        print("Saved %d actual native/nearest3x captures"%len(captures_only()))
        return
    names = NAMES
    # Three alpha backgrounds; native body placement and common ground line.
    for background,color in [("light","#e8e0cf"),("dark","#241f2e"),("checker",None)]:
        sheet = Image.new("RGBA",(480,80),color) if color else checker((480,80))
        draw = ImageDraw.Draw(sheet)
        for i,name in enumerate(names):
            tile = Image.open(ROOT/("sprites/props/"+name+".png")).convert("RGBA")
            pivot = (20,44) if name.startswith("tree") else ((12,22) if name in ("cow","chicken") else (8,14))
            x = i*43+21
            sheet.alpha_composite(tile,(x-pivot[0],62-pivot[1]))
            draw.line((x-12,63,x+12,63),fill="#be6363")
            draw.text((i*43+2,66),name,fill="#241f2e" if background=="light" else "#e8e0cf")
        pair(sheet,"native-"+background)
    for page in range(2):
        selected = names[page*6:(page+1)*6]
        sheet = Image.new("RGBA",(960,384),"#241f2e")
        draw = ImageDraw.Draw(sheet)
        for i,name in enumerate(selected):
            source = ROOT/("assets/art_source/masters/tree.png" if name == "tree" else "assets/art_source/props/"+name+".png")
            raw = Image.open(source).convert("RGBA")
            x=i*160
            draw.text((x+2,4),name,fill="#e8e0cf")
            draw.text((x+2,16),"alpha "+str(raw.getchannel("A").getextrema()),fill="#e8e0cf")
            raw.thumbnail((112,112),Image.Resampling.NEAREST)
            for row,color in enumerate(("#e8e0cf","#241f2e",None)):
                layer=Image.new("RGBA",raw.size,color) if color else checker(raw.size)
                layer.alpha_composite(raw)
                sheet.paste(layer,(x+8,32+row*116))
        sheet.save(HERE/("source-alpha-%d.png"%page))
    captures=captures_only()
    compare=Image.new("RGBA",(960,864),"#241f2e")
    draw=ImageDraw.Draw(compare)
    for row,scenario in enumerate(("noon","dusk","wave")):
        for col,task in enumerate(("0008","0009")):
            draw.text((col*480+3,row*288+2),task+" / "+scenario,fill="#e8e0cf")
            compare.paste(Image.open(ROOT/("implementation/shots/sprites/"+task+"/"+scenario+".png")).convert("RGBA"),(col*480,row*288+18))
    pair(compare,"before-after")
    print("Saved 11 complete native props, raw alpha checks and %d actual native/3x Godot captures"%len(captures))


if __name__ == "__main__":
    main()
