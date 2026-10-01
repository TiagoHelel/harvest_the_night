"""Measure raw sources through the actual nearest/palette/alpha recipe; QA only."""
from pathlib import Path
import json
import sys
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art
from PIL import Image
OUT = ROOT / "implementation/sprites/reviews/0008"
OUT.mkdir(parents=True, exist_ok=True)
def recipe(name, source, box):
    return dict(id="terrain/"+name,source=source,crop_xywh=box,canvas_wh=[16,16],pivot_xy=[8,16],content_anchor_xy=[8,16],content_scale=16/box[2],alpha_threshold=128)
def main():
    items = []
    for i,name in enumerate(["water","water_b","water_c"]):
        entry = recipe(name,"assets/art_source/terrain/water-loop.png",[i*724,0,724,724])
        entry["palette_keys"] = ["water_dark","water","water_light","cloth"]
        items.append(entry)
    for name in ["edge_n","shore_n"]:
        items.append(recipe(name,"assets/art_source/terrain/"+name.replace("_","-")+".png",[0,0,1254,1254]))
    items.append(recipe("shore_corner_nw","assets/art_source/terrain/shore-corner-nw.png",[14,14,720,720]))
    items[-1]["palette_keys"] = ["leaf_light","wood_light"]
    page = Image.new("RGBA",(len(items)*32,48),"#e8e0cf")
    native = {}
    for i,entry in enumerate(items):
        raw = Image.open(ROOT / entry["source"]).convert("RGBA")
        image = import_art.render_source(entry)
        name = entry["id"].split("/")[-1]
        native[name] = image
        pixels = list(import_art.samples(image))
        left = [image.getpixel((0,y)) for y in range(16)]
        right = [image.getpixel((15,y)) for y in range(16)]
        print(name, "raw",raw.size, "alpha",raw.getchannel("A").getextrema(), "native alpha bbox",image.getbbox(), "colors",len(set(pixels)), "L/R mismatch",sum(a!=b for a,b in zip(left,right)), "sha",import_art.sha(image.tobytes())[:12])
        for y in range(0,48,8):
            for x in range(i*32,i*32+32,8):
                if (x//8+y//8)%2:
                    page.paste("#24212e",(x,y,x+8,y+8))
        page.alpha_composite(image,(i*32+8,8))
        page.alpha_composite(image,(i*32+8,24))
        image.save(OUT / (name+"-native.png"))
    page.save(OUT/"initial-native.png")
    page.resize((page.width*8,page.height*8),Image.Resampling.NEAREST).save(OUT/"initial-8x.png")
    print("distinct water frames",len({native[n].tobytes() for n in ["water","water_b","water_c"]}))
    (OUT/"measured-recipes.json").write_text(json.dumps(items,indent=2)+"\n")
if __name__ == "__main__":
    main()
