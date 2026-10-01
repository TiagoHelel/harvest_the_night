"""Compose source alpha and native/nearest crop QA; never paint runtime art."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
KINDS = ("wheat", "corn", "carrot")


def pair(im, name):
    im.save(HERE/(name+".png"))
    im.resize((im.width*3, im.height*3), Image.Resampling.NEAREST).save(HERE/(name+"-3x.png"))


def checker(size):
    im = Image.new("RGBA", size)
    draw = ImageDraw.Draw(im)
    for y in range(0, size[1], 8):
        for x in range(0, size[0], 8):
            draw.rectangle((x,y,x+7,y+7), fill="#e8e0cf" if (x//8+y//8)%2 else "#877e8a")
    return im


def main():
    soils = [Image.open(ROOT/("sprites/crops/"+n+".png")).convert("RGBA") for n in ("tilled", "tilled_wet")]
    for name, color in (("light", "#e8e0cf"), ("dark", "#241f2e"), ("checker", None)):
        sheet = Image.new("RGBA", (480,180), color) if color else checker((480,180))
        draw = ImageDraw.Draw(sheet)
        for row, kind in enumerate(KINDS):
            draw.text((2,row*56+26),kind,fill="#241f2e" if name=="light" else "#e8e0cf")
            for stage in range(4):
                crop = Image.open(ROOT/("sprites/crops/%s_%d.png"%(kind,stage))).convert("RGBA")
                pivot = (8,22) if kind=="corn" else (8,14)
                for wet in range(2):
                    x = 92+stage*92+wet*26
                    baseline = row*56+34
                    sheet.alpha_composite(soils[wet],(x-8,baseline-16))
                    sheet.alpha_composite(crop,(x-pivot[0],baseline-pivot[1]))
                draw.text((82+stage*92,row*56+39),str(stage)+" dry/wet",fill="#241f2e" if name=="light" else "#e8e0cf")
        pair(sheet,"growth-"+name)
    repeat = Image.new("RGBA",(288,160),"#241f2e")
    draw = ImageDraw.Draw(repeat)
    for i,soil in enumerate(soils):
        draw.text((i*144+3,3),("dry","wet")[i],fill="#e8e0cf")
        for y in range(8):
            for x in range(8):
                repeat.alpha_composite(soil,(i*144+x*16+8,y*16+24))
    pair(repeat,"soil-repeat")
    source_sheet = Image.new("RGBA", (960,480),"#241f2e")
    draw = ImageDraw.Draw(source_sheet)
    for i,name in enumerate((*KINDS,"tilled","tilled_wet")):
        raw = Image.open(ROOT/("assets/art_source/crops/"+name+".png")).convert("RGBA")
        draw.text((i*192+3,3),name+" alpha "+str(raw.getchannel("A").getextrema()),fill="#e8e0cf")
        raw.thumbnail((180,130),Image.Resampling.NEAREST)
        for row,color in enumerate(("#e8e0cf","#241f2e",None)):
            layer = Image.new("RGBA",(180,140),color) if color else checker((180,140))
            layer.alpha_composite(raw,((180-raw.width)//2,(140-raw.height)//2))
            source_sheet.paste(layer,(i*192+6,row*148+24))
    source_sheet.save(HERE/"source-alpha.png")
    folder = ROOT/"implementation/shots/sprites/0010"
    captures = sorted((folder/"crops").glob("*.png"))+sorted(folder.glob("*.png"))
    assert len(captures)==41,len(captures)
    for page in range((len(captures)+3)//4):
        sheet = Image.new("RGBA", (960,576),"#241f2e")
        draw = ImageDraw.Draw(sheet)
        for i,path in enumerate(captures[page*4:(page+1)*4]):
            x,y=i%2*480,i//2*288
            draw.text((x+3,y+2),path.stem,fill="#e8e0cf")
            im=Image.open(path).convert("RGBA")
            assert im.size==(480,270)
            sheet.paste(im,(x,y+18))
        pair(sheet,"captures-%02d"%page)
        enlarged=sheet.resize((2880,1728),Image.Resampling.NEAREST)
        # Split columns so the image viewer can deliver exact 3x without resizing.
        for side in range(2):
            enlarged.crop((side*1440,0,(side+1)*1440,1728)).save(HERE/("captures-%02d-3x-%d.png"%(page,side)))
    (HERE/"frame-review.json").write_text(json.dumps(dict(captures=[dict(path=p.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in captures],capture_pages=11,native_size=[480,270],nearest_scale=3),indent=2)+"\n",encoding="utf-8",newline="\n")
    compare=Image.new("RGBA",(960,864),"#241f2e")
    draw=ImageDraw.Draw(compare)
    for row,scenario in enumerate(("noon","dusk","wave")):
        for col,task in enumerate(("0009","0010")):
            draw.text((col*480+3,row*288+2),task+" / "+scenario,fill="#e8e0cf")
            compare.paste(Image.open(ROOT/("implementation/shots/sprites/"+task+"/"+scenario+".png")).convert("RGBA"),(col*480,row*288+18))
    pair(compare,"before-after")
    print("Saved 12-stage dry/wet matrices, soil repeats, five source alpha comparisons and 41 native/nearest3x captures")


if __name__=="__main__":main()
