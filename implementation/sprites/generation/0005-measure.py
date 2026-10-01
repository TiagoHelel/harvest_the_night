"""Measure generated work strips and preview frozen native cuts; never paint art."""
from pathlib import Path
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import import_art
import cut_sheet

OUT = ROOT / "implementation/sprites/reviews/0005"
NAMES = "chop mine till plant water fish reel harvest carry craft trade collect repair".split()


def measure(name):
    source = "assets/art_source/player/" + name + ".png"
    raw = Image.open(ROOT / source).convert("RGBA")
    rgba = np.asarray(raw).astype(int)
    opaque = rgba[:, :, 3] >= 128
    detected = [r for r in cut_sheet._runs(list(opaque.sum(axis=0) > 8)) if r[1]-r[0] > 20]
    breaks = set(sorted(range(1,len(detected)), key=lambda i:detected[i][0]-detected[i-1][1], reverse=True)[:3])
    runs = []
    for ri,r in enumerate(detected):
        if runs and ri not in breaks:
            runs[-1] = (runs[-1][0],r[1])
        else:
            runs.append(r)
    if len(runs) != 4:
        raise ValueError((name, "expected four complete cells", runs))
    poses = []
    for x0, x1 in runs:
        ys, xs = np.where(opaque[:, x0:x1])
        box = [x0+int(xs.min()), int(ys.min()), int(xs.max()-xs.min()+1), int(ys.max()-ys.min()+1)]
        # The lower blue overall legs identify the farmer, excluding the tool.
        region = rgba[:, x0:x1]
        blue = (region[:, :, 2]-region[:, :, 0] > 20) & (region[:, :, 2]-region[:, :, 1] > 10) & (region[:, :, 2] > 65) & opaque[:, x0:x1]
        blue[:int(raw.height*.62)] = False
        peak = int(blue.sum(axis=0).argmax())
        blue[:, :max(0,peak-90)] = False
        blue[:, min(blue.shape[1],peak+90):] = False
        blue[blue.sum(axis=1)<8] = False
        by, bx = np.where(blue)
        cx = x0+int(np.median(bx[by>np.quantile(by,.65)]))
        radius = 120
        bottom = opaque[int(by.max()):, max(x0,cx-radius):min(x1,cx+radius)]
        fy = int(by.max()) + int(np.where(bottom)[0].max()) + 1
        boot_runs = [r for r in cut_sheet._runs(list(opaque[fy-50:fy,x0:x1].sum(axis=0)>12)) if r[1]-r[0]>35]
        chosen = sorted(boot_runs,key=lambda r:abs((r[0]+r[1])/2-peak))[:2]
        cx = x0+round((min(r[0] for r in chosen)+max(r[1] for r in chosen))/2)
        # Ground-level hoe, wheat and pail overlap the boot scan in contact poses.
        # These reviewed source coordinates anchor boots rather than carried props.
        reviewed = {("till",1):907,("harvest",1):914,("collect",1):898}
        cx = reviewed.get((name,len(poses)),cx)
        # Dense golden hat clusters give a body reference independent of raised tools.
        hat = (region[:, :, 0] > 170) & (region[:, :, 1] > 120) & (region[:, :, 2] < 110) & opaque[:, x0:x1]
        hat[int(raw.height*.5):] = False
        hat_rows = hat[:, max(0,cx-x0-radius):min(x1-x0,cx-x0+radius)].sum(axis=1)
        hy = int(np.where(hat_rows > 45)[0].min())
        # Include the outline above the bright hat, measured within the farmer's center.
        center = opaque[max(0,hy-35):hy+1, cx-20:cx+21]
        if center.any():
            hy = max(0,hy-35)+int(np.where(center)[0].min())
        poses.append({"crop_xywh": box, "feet_source_xy": [cx,fy], "hat_source_y": hy,
                      "body_height": fy-hy})
    scale = 30.0 / poses[3]["body_height"]
    frames, errors = [], []
    for i,p in enumerate(poses):
        x,y,w,h = p["crop_xywh"]
        anchor = [round((p["feet_source_xy"][0]-x)*scale),round((p["feet_source_xy"][1]-y)*scale)]
        p["content_anchor_xy"] = anchor
        recipe = {"id": name+"_"+str(i), "source": source, "crop_xywh": p["crop_xywh"],
                  "canvas_wh": [48,48], "pivot_xy": [24,44], "content_scale": scale,
                  "content_anchor_xy": anchor, "alpha_threshold": 128}
        try:
            frames.append(import_art.render_source(recipe))
        except ValueError as e:
            errors.append(str(e))
            frames.append(Image.new("RGBA",(48,48)))
    result = {"name": name, "source": source, "source_sha256": import_art.sha((ROOT/source).read_bytes()),
              "source_wh": list(raw.size), "content_scale": scale, "poses": poses,
              "unique_native": len({f.tobytes() for f in frames}), "errors": errors}
    print(name, "alpha",raw.getchannel("A").getextrema(), "scale",round(scale,6),
          "body heights",[p["body_height"] for p in poses], "feet",[p["feet_source_xy"] for p in poses],
          "unique",result["unique_native"], "errors",errors)
    return result,frames


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    contract={"date":"2026-10-01","canvas_wh":[48,48],"pivot_xy":[24,44],"animations":[]}
    for page in range(2):
        names=NAMES[page*7:(page+1)*7]
        contact=Image.new("RGBA",(480,len(names)*64),(44,39,51,255))
        draw=ImageDraw.Draw(contact)
        for row,name in enumerate(names):
            measured,frames=measure(name)
            contract["animations"].append(measured)
            draw.text((4,row*64+3),name,fill=(237,225,201,255))
            for i,frame in enumerate(frames):
                contact.alpha_composite(frame,(136+i*64,row*64+12))
                draw.line((132+i*64,row*64+56,188+i*64,row*64+56),fill=(180,138,85,255))
        (OUT/("native-frames-%d.png"%page)).write_bytes(import_art.png(contact))
        (OUT/("native-frames-%d-3x.png"%page)).write_bytes(import_art.png(contact.resize((1440,contact.height*3),Image.Resampling.NEAREST)))
    (OUT/"measured-contract.json").write_text(json.dumps(contract,indent=2)+"\n",encoding="utf-8")


if __name__ == "__main__":
    main()
