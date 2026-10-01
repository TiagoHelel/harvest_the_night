"""Compose actual native runtime/capture bytes for visual QA, never paint sprites."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/"tools"))
import import_art

HERE=Path(__file__).resolve().parent
NAMES="chop mine till plant water fish reel harvest carry craft trade collect repair".split()


def write(path,image):
    content=import_art.png(image)
    if not path.exists() or path.read_bytes()!=content:
        path.write_bytes(content)


def checker(size):
    result=Image.new("RGBA",size,(94,91,102,255))
    draw=ImageDraw.Draw(result)
    for y in range(0,size[1],8):
        for x in range(0,size[0],8):
            if (x//8+y//8)%2:
                draw.rectangle((x,y,x+7,y+7),fill=(145,141,151,255))
    return result


def main():
    data=import_art.load_manifest()
    measured=json.loads((HERE/"measured-contract.json").read_text())
    report=[]
    frames_by_name={}
    for animation in measured["animations"]:
        name=animation["name"]
        entries=sorted((e for e in data["assets"] if e["animation"]==name),key=lambda e:e["frame"])
        frames=[Image.open(ROOT/e["output"]).convert("RGBA") for e in entries]
        assert len(frames)==4 and len({f.tobytes() for f in frames})==4,name
        assert all(f.size==(48,48) for f in frames),name
        assert not animation["errors"] and round(animation["poses"][3]["body_height"]*animation["content_scale"])==30,name
        frames_by_name[name]=frames
        source=Image.open(ROOT/animation["source"]).convert("RGBA")
        assert source.getchannel("A").getextrema()==(0,255),name
        # All raw frames on light/dark/checker expose matte/shadow/edge defects.
        thumbnail=source.resize((960,round(source.height*960/source.width)),Image.Resampling.NEAREST)
        raw_page=Image.new("RGBA",(960,thumbnail.height*3),(232,224,207,255))
        raw_page.paste((38,32,47,255),(0,thumbnail.height,960,thumbnail.height*2))
        raw_page.paste(checker(thumbnail.size),(0,thumbnail.height*2))
        for y in range(3):
            raw_page.alpha_composite(thumbnail,(0,y*thumbnail.height))
        write(HERE/("source-alpha-"+name+".png"),raw_page)
        report.append({"name":name,"unique_frames":4,"standing_reference_height":30,
                       "canvas":[48,48],"feet":[24,44],"native_boxes":[list(f.getbbox()) for f in frames]})
    for page in range(2):
        names=NAMES[page*7:(page+1)*7]
        for kind,color in enumerate([(232,224,207,255),(38,32,47,255),None]):
            sheet=Image.new("RGBA",(480,64*len(names)),color) if color else checker((480,64*len(names)))
            draw=ImageDraw.Draw(sheet)
            for row,name in enumerate(names):
                draw.text((4,row*64+3),name,fill=(38,32,47,255) if kind==0 else (255,255,255,255))
                for i,frame in enumerate(frames_by_name[name]):
                    sheet.alpha_composite(frame,(136+i*64,row*64+12))
            write(HERE/("alpha-%d-%d.png"%(page,kind)),sheet)
            write(HERE/("alpha-%d-%d-3x.png"%(page,kind)),sheet.resize((1440,sheet.height*3),Image.Resampling.NEAREST))
        phases=[]
        for frame in range(4):
            sheet=Image.new("RGBA",(480,64*len(names)),(38,32,47,255))
            draw=ImageDraw.Draw(sheet)
            for row,name in enumerate(names):
                draw.text((4,row*64+3),name,fill=(255,255,255,255))
                image=frames_by_name[name][frame]
                sheet.alpha_composite(image,(144,row*64+12))
                sheet.alpha_composite(image.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(280,row*64+12))
                draw.line((130,row*64+56,338,row*64+56),fill=(180,138,85,255))
            write(HERE/("work-phase-%d-%d.png"%(page,frame)),sheet)
            write(HERE/("work-phase-%d-%d-3x.png"%(page,frame)),sheet.resize((1440,sheet.height*3),Image.Resampling.NEAREST))
            phases.append(sheet.convert("RGB"))
        phases[0].save(HERE/("work-%d.gif"%page),save_all=True,append_images=phases[1:],duration=90,loop=0,disposal=2,optimize=False)
        zoom=[p.resize((1440,p.height*3),Image.Resampling.NEAREST) for p in phases]
        zoom[0].save(HERE/("work-%d-3x.gif"%page),save_all=True,append_images=zoom[1:],duration=90,loop=0,disposal=2,optimize=False)
    folder=ROOT/"implementation/shots/sprites/0005"
    captures=sorted(folder.glob("*.png"))+sorted((folder/"work").glob("*.png"))
    for page in range((len(captures)+3)//4):
        sheet=Image.new("RGBA",(960,576),(36,31,46,255))
        draw=ImageDraw.Draw(sheet)
        for i,path in enumerate(captures[page*4:(page+1)*4]):
            x,y=i%2*480,i//2*288
            draw.text((x+3,y+2),path.stem,fill=(237,225,201,255))
            sheet.paste(Image.open(path).convert("RGBA"),(x,y+18))
        write(HERE/("captures-%02d.png"%page),sheet)
        write(HERE/("captures-%02d-3x.png"%page),sheet.resize((2880,1728),Image.Resampling.NEAREST))
    (HERE/"frame-review.json").write_text(json.dumps({"animations":report,"captures":[p.relative_to(ROOT).as_posix() for p in captures]},indent=2)+"\n",encoding="utf-8")
    print("OK: 52 distinct native work frames, %d actual Godot captures"%len(captures))


if __name__=="__main__":
    main()
