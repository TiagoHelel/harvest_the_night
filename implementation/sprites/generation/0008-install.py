"""Install measured water/edge recipes and strictly source-derived rotations."""
from pathlib import Path
import json
import sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"tools"))
import import_art
def main():
    measured = json.loads((ROOT/"implementation/sprites/reviews/0008/measured-recipes.json").read_text())
    calls = {c["id"]:c for c in json.loads((ROOT/"implementation/sprites/generation/0008-generations.json").read_text())["attempts"]}
    manifest = json.loads(import_art.MANIFEST.read_text())
    owner_path = ROOT/"assets/art_source/ownership.json"
    owners = json.loads(owner_path.read_text())
    by_output = {o["output"]:o for o in owners["outputs"]}
    pending = []
    for entry in measured:
        name = entry["id"].split("/")[-1]
        call_id = "water" if name.startswith("water") else {"edge_n":"edge","shore_n":"shore-r1","shore_corner_nw":"shore-corner-r1"}[name]
        call = calls[call_id]
        prompt = "implementation/sprites/generation/0008-"+call_id+".prompt.txt"
        refs = [dict(path=p,sha256=import_art.sha((ROOT/p).read_bytes()),role="reference/edit target; exact role in the preserved prompt") for p in call["references"]]
        if call["revision"]:
            original_id = call_id.replace("-r1","")
            original = "implementation/sprites/generation/0008-"+original_id+".prompt.txt"
            refs.append(dict(path=original,sha256=import_art.sha((ROOT/original).read_bytes()),role="original full brief in revision chain"))
        animation = "terrain_water" if name.startswith("water") else "terrain_"+name
        frame = ["water","water_b","water_c"].index(name) if name.startswith("water") else 0
        source_size = list(Image.open(ROOT/entry["source"]).size)
        image = import_art.render_source(entry)
        entry.update(owner="raster",output="sprites/"+entry["id"]+".png",source_sha256=import_art.sha((ROOT/entry["source"]).read_bytes()),
                     output_sha256=import_art.sha(import_art.png(image)),palette="tools/palette.py:COLOURS",
                     animation=animation,frame=frame,seconds=0.55,loop=name.startswith("water"),
                     prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),references=refs,
                     sheet_cell_xywh=[0,0,*source_size],gutter_xy=[0,0],tool="built-in ImageGen",generation_task="0008",revision=call["revision"])
        pending.append((entry,image))
    north = {entry["id"]:image for entry,image in pending}
    for prefix in ["edge","shore"]:
        parent = "terrain/"+prefix+"_n"
        for turns,side in enumerate(["e","s","w"],1):
            base = next(e for e,im in pending if e["id"]==parent)
            image = north[parent].transpose({1:Image.Transpose.ROTATE_270,2:Image.Transpose.ROTATE_180,3:Image.Transpose.ROTATE_90}[turns])
            entry = {k:base[k] for k in ["owner","canvas_wh","pivot_xy","palette","seconds","loop","prompt","prompt_sha256","references","generation_task"]}
            entry.update(id="terrain/"+prefix+"_"+side,input=parent,operation="rotate",quarter_turns=turns,
                         animation="terrain_"+prefix+"_"+side,frame=0,output="sprites/terrain/"+prefix+"_"+side+".png",
                         output_sha256=import_art.sha(import_art.png(image)))
            pending.append((entry,image))
    # The grass endpoint is exactly one native pixel: cut it from the approved
    # fringe and place it on the same 16x16 canvas. No painted substitute.
    base = next(e for e,im in pending if e["id"]=="terrain/edge_n")
    cap = Image.new("RGBA",(16,16))
    cap.alpha_composite(north["terrain/edge_n"].crop((0,0,1,1)),(0,0))
    entry = {k:base[k] for k in ["owner","canvas_wh","pivot_xy","palette","seconds","loop","prompt","prompt_sha256","references","generation_task"]}
    entry.update(id="terrain/edge_corner_nw",input="terrain/edge_n",operation="slice_canvas",slice_xywh=[0,0,1,1],paste_xy=[0,0],
                 animation="terrain_edge_corner_nw",frame=0,output="sprites/terrain/edge_corner_nw.png",output_sha256=import_art.sha(import_art.png(cap)))
    pending.append((entry,cap))
    for prefix in ["edge","shore"]:
        parent = "terrain/"+prefix+"_corner_nw"
        base, image = next((e,im) for e,im in pending if e["id"]==parent)
        for turns,corner in enumerate(["ne","se","sw"],1):
            rotated = image.transpose({1:Image.Transpose.ROTATE_270,2:Image.Transpose.ROTATE_180,3:Image.Transpose.ROTATE_90}[turns])
            entry = {k:base[k] for k in ["owner","canvas_wh","pivot_xy","palette","seconds","loop","prompt","prompt_sha256","references","generation_task"]}
            entry.update(id="terrain/"+prefix+"_corner_"+corner,input=parent,operation="rotate",quarter_turns=turns,
                         animation="terrain_"+prefix+"_corner_"+corner,frame=0,output="sprites/terrain/"+prefix+"_corner_"+corner+".png",
                         output_sha256=import_art.sha(import_art.png(rotated)))
            pending.append((entry,rotated))
    ids = {e["id"] for e,im in pending}
    manifest["assets"] = [e for e in manifest["assets"] if e["id"] not in ids]+[e for e,im in pending]
    for entry,image in pending:
        by_output[entry["output"]] = dict(output=entry["output"],owner="raster")
    owners["outputs"] = [by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8",newline="\n")
    owner_path.write_text(json.dumps(owners,indent=2)+"\n",encoding="utf-8",newline="\n")
    print("Installed %d source-owned water/side/corner outputs" % len(pending))
if __name__ == "__main__":
    main()
