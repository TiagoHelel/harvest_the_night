"""QA-only sheets from exact imported art and unmodified Godot captures."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
def save_pair(image, name):
    image.save(HERE/(name+".png"))
    image.resize((image.width*3,image.height*3),Image.Resampling.NEAREST).save(HERE/(name+"-3x.png"))
def main():
    folder = ROOT/"implementation/shots/sprites/0008"
    captures = sorted((folder/"water").glob("*.png"))+sorted(folder.glob("*.png"))
    for page in range((len(captures)+3)//4):
        image = Image.new("RGBA",(960,576),(36,31,46,255))
        draw = ImageDraw.Draw(image)
        for i,path in enumerate(captures[page*4:(page+1)*4]):
            x,y = i%2*480,i//2*288
            draw.text((x+3,y+2),path.stem,fill=(237,225,201,255))
            with Image.open(path) as capture:
                assert capture.size == (480,270)
                image.paste(capture.convert("RGBA"),(x,y+18))
        save_pair(image,"captures-%02d"%page)
    atlas = Image.open(ROOT/"sprites/terrain/atlas.png").convert("RGBA")
    save_pair(atlas,"atlas")
    sources = ["water-loop","edge-n","shore-n","shore-corner-nw"]
    alpha = Image.new("RGBA",(960,360),(36,31,46,255))
    draw = ImageDraw.Draw(alpha)
    for i,name in enumerate(sources):
        source = Image.open(ROOT/("assets/art_source/terrain/"+name+".png")).convert("RGBA")
        x=i*240
        draw.text((x+4,4),name+" / alpha"+str(source.getchannel("A").getextrema()),fill="#e8e0cf")
        thumb = source.resize((224,224) if source.width==source.height else (224,75),Image.Resampling.NEAREST)
        for background,y in [("#e8e0cf",24),("#241f2e",256)]:
            layer = Image.new("RGBA",thumb.size,background)
            layer.alpha_composite(thumb)
            alpha.paste(layer,(x+8,y))
    # Square source bottom checks use a smaller dark-background thumbnail.
    for i,name in enumerate(sources[1:],1):
        thumb = Image.open(ROOT/("assets/art_source/terrain/"+name+".png")).convert("RGBA").resize((96,96),Image.Resampling.NEAREST)
        layer = Image.new("RGBA",(96,96),"#241f2e")
        layer.alpha_composite(thumb)
        alpha.paste(layer,(i*240+8,256))
    alpha.save(HERE/"source-alpha.png")
    checker = Image.new("RGBA", (960,336), "#241f2e")
    checker_draw = ImageDraw.Draw(checker)
    for i,name in enumerate(sources):
        source = Image.open(ROOT/("assets/art_source/terrain/"+name+".png")).convert("RGBA")
        thumb = source.resize((224,224) if source.width == source.height else (224,75),Image.Resampling.NEAREST)
        layer = Image.new("RGBA",thumb.size)
        grid = ImageDraw.Draw(layer)
        for y in range(0,thumb.height,8):
            for x in range(0,thumb.width,8):
                grid.rectangle((x,y,x+7,y+7),fill="#e8e0cf" if (x//8+y//8)%2 else "#877e8a")
        layer.alpha_composite(thumb)
        checker.paste(layer,(i*240+8,24))
        checker_draw.text((i*240+4,4),name+" / actual alpha",fill="#e8e0cf")
        native = Image.open(ROOT/("sprites/terrain/"+{"water-loop":"water","edge-n":"edge_n","shore-n":"shore_n","shore-corner-nw":"shore_corner_nw"}[name]+".png")).convert("RGBA").resize((48,48),Image.Resampling.NEAREST)
        ground = Image.new("RGBA",(48,48))
        grid = ImageDraw.Draw(ground)
        for y in range(0,48,6):
            for x in range(0,48,6):
                grid.rectangle((x,y,x+5,y+5),fill="#e8e0cf" if (x//6+y//6)%2 else "#877e8a")
        ground.alpha_composite(native)
        checker.paste(ground,(i*240+8,280))
        checker_draw.text((i*240+4,256),"native / nearest 3x",fill="#e8e0cf")
    checker.save(HERE/"source-alpha-checker.png")
    sheet = Image.new("RGBA",(256,128),"#241f2e")
    draw = ImageDraw.Draw(sheet)
    for row,prefix in enumerate(["edge","shore"]):
        for mask in range(16):
            tile = atlas.crop((mask*16,(3+row)*16,(mask+1)*16,(4+row)*16))
            base = Image.open(ROOT/("sprites/terrain/"+("soil" if row==0 else "water")+".png")).convert("RGBA")
            base.alpha_composite(tile)
            sheet.paste(base,(mask*16,row*32+8))
        draw.text((1,row*32),"N1 E2 S4 W8 / 0-15",fill="#e8e0cf")
    for i,name in enumerate(["edge_n","edge_e","edge_s","edge_w","shore_n","shore_e","shore_s","shore_w"]):
        tile = Image.open(ROOT/("sprites/terrain/"+name+".png")).convert("RGBA")
        sheet.alpha_composite(tile,(i*32,76))
    for i,name in enumerate(["edge_corner_nw","edge_corner_ne","edge_corner_se","edge_corner_sw","shore_corner_nw","shore_corner_ne","shore_corner_se","shore_corner_sw"]):
        tile = Image.open(ROOT/("sprites/terrain/"+name+".png")).convert("RGBA")
        sheet.alpha_composite(tile,(i*32,106))
    save_pair(sheet,"native-transitions")
    phases = [Image.open(ROOT/("sprites/terrain/"+name+".png")).convert("RGBA") for name in ["water","water_b","water_c"]]
    patch_frames = []
    for frame in phases:
        patch = Image.new("RGBA",(128,128))
        for y in range(8):
            for x in range(8):
                patch.paste(frame,(x*16,y*16))
        patch_frames.append(patch)
    for i,patch in enumerate(patch_frames):
        save_pair(patch,"water-patch-%d"%i)
    patch_frames[0].save(HERE/"water-loop.gif",save_all=True,append_images=patch_frames[1:],duration=[550]*3,loop=0,disposal=2)
    # Before/after at the actual native farm size; no camera recropping.
    compare = Image.new("RGBA",(960,864),"#241f2e")
    draw = ImageDraw.Draw(compare)
    for row,scenario in enumerate(["noon","dusk","wave"]):
        for col,task in enumerate(["0007","0008"]):
            draw.text((col*480+3,row*288+2),task+" / "+scenario,fill="#e8e0cf")
            path=ROOT/("implementation/shots/sprites/"+task+"/"+scenario+".png")
            compare.paste(Image.open(path).convert("RGBA"),(col*480,row*288+18))
    save_pair(compare,"before-after")
    (HERE/"frame-review.json").write_text(json.dumps({"captures":[{"path":p.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in captures],"capture_pages":(len(captures)+3)//4,"native_size":[480,270],"nearest_scale":3},indent=2)+"\n",encoding="utf-8",newline="\n")
    print("OK: %d actual Godot captures, native/nearest3x; all masks/caps; raw alpha; repeated water loop" % len(captures))
if __name__ == "__main__":
    main()
