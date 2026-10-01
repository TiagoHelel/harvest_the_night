"""Install reviewed work recipes and ownership; raw generated images remain intact."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT / "tools"))
import import_art


def reference(path,role):
    return {"path":path,"role":role,"sha256":import_art.sha((ROOT/path).read_bytes())}


def main():
    measured=json.loads((ROOT/"implementation/sprites/reviews/0005/measured-contract.json").read_text())
    manifest=json.loads(import_art.MANIFEST.read_text())
    owner_path=ROOT/"assets/art_source/ownership.json"
    owners=json.loads(owner_path.read_text())
    by_output={o["output"]:o for o in owners["outputs"]}
    names={a["name"] for a in measured["animations"]}
    manifest["assets"]=[e for e in manifest["assets"] if e["animation"] not in names]
    for animation in measured["animations"]:
        if animation["errors"] or animation["unique_native"] != 4:
            raise ValueError("Unaccepted work strip: "+animation["name"])
        name=animation["name"]
        revision=2 if name=="fish" else 0
        prompt="implementation/sprites/generation/0005-"+name+("-r2" if revision else "")+".prompt.txt"
        refs=[reference("assets/art_source/masters/farmer.png","approved identity and body scale reference"),
              reference("assets/art_source/player/idle_west.png","accepted west silhouette/clothing reference")]
        if revision:
            for i in range(2):
                refs.append(reference("assets/art_source/player/candidates/fish-r%d.png"%i,"preserved rejected edit target, revision %d"%i))
                refs.append(reference("implementation/sprites/generation/0005-fish"+("-r1" if i else "")+".prompt.txt","earlier complete prompt in compact-rod revision chain"))
        width,height=animation["source_wh"]
        poses=animation["poses"]
        for i,pose in enumerate(poses):
            x,y,w,h=pose["crop_xywh"]
            left=0 if i==0 else (poses[i-1]["crop_xywh"][0]+poses[i-1]["crop_xywh"][2]+x)//2
            right=width if i==3 else (x+w+poses[i+1]["crop_xywh"][0])//2
            output="sprites/actors/%s_%d.png"%(name,i)
            manifest["assets"].append({
                "id":"actors/%s_%d"%(name,i),"owner":"raster","source":animation["source"],
                "source_sha256":animation["source_sha256"],"crop_xywh":pose["crop_xywh"],
                "sheet_cell_xywh":[left,0,right-left,height],"gutter_xy":[min(x-left,right-x-w),min(y,height-y-h)],
                "canvas_wh":measured["canvas_wh"],"pivot_xy":measured["pivot_xy"],
                "content_scale":animation["content_scale"],"content_anchor_xy":pose["content_anchor_xy"],
                "feet_source_xy":pose["feet_source_xy"],"body_reference_height":poses[3]["body_height"],
                "alpha_threshold":128,"palette":"tools/palette.py:COLOURS","animation":name,"frame":i,
                "seconds":0.09,"loop":False,"output":output,"output_sha256":"0"*64,
                "prompt":prompt,"prompt_sha256":import_art.sha((ROOT/prompt).read_bytes()),"references":refs,
                "tool":"built-in ImageGen","generation_task":"0005","revision":revision,
                "approval":"Reviewed native/3x four-phase silhouette, tool clearance and boot contact"})
            if output not in by_output:
                by_output[output]={"output":output,"owner":"raster"}
            else:
                by_output[output]["owner"]="raster"
    owners["outputs"]=[by_output[o] for o in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8",newline="\n")
    owner_path.write_text(json.dumps(owners,indent=2)+"\n",encoding="utf-8",newline="\n")
    print("Installed thirteen four-frame work strips / 52 authored raster frames")


if __name__ == "__main__":
    main()
