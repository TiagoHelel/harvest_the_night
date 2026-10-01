"""Install complete prop masters with measured, shared family scales."""
from pathlib import Path
import json
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
REVIEW = ROOT / "implementation/sprites/reviews/0009"
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def main():
    calls = {c["id"]:c for c in (json.loads(p.read_text(encoding="utf-8")) for p in HERE.glob("0009-*-call.json"))}
    assert set(calls) == {"tree_b","stump","rock","rock_b","seam","seam_b","ore","ore_b","cow","chicken"}
    # Static contour variants share one family scale, even when their source
    # bounds differ. This is never per-pose fitting or silhouette repainting.
    for kind in ("rock","seam","ore"):
        pair = [calls[kind]["measured_recipe"],calls[kind+"_b"]["measured_recipe"]]
        scale = min(14/max(e["crop_xywh"][2] for e in pair),12/max(e["crop_xywh"][3] for e in pair))
        for entry in pair:
            entry["content_scale"] = scale
    manifest = json.loads(import_art.MANIFEST.read_text(encoding="utf-8"))
    owners_path = ROOT / "assets/art_source/ownership.json"
    owners = json.loads(owners_path.read_text(encoding="utf-8"))
    by_output = {e["output"]:e for e in owners["outputs"]}
    new_entries, measurements = [], []
    for ident,call in sorted(calls.items()):
        entry = dict(call["measured_recipe"])
        image = import_art.render_source(entry)
        assert image.getbbox() is not None
        prompt = "implementation/sprites/generation/0009-"+ident+".prompt.txt"
        assert (ROOT/entry["source"]).read_bytes() == Path(call["returned_file"]).read_bytes()
        assert (ROOT/prompt).read_text(encoding="utf-8").strip() == call["prompt_text"]
        entry.update(owner="raster",source_sha256=call["source_sha256"],output="sprites/props/"+ident+".png",output_sha256=import_art.sha(import_art.png(image)),palette="tools/palette.py:COLOURS",animation="props/"+ident,frame=0,seconds=0.55,loop=False,prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),references=[dict(path=p,sha256=import_art.sha((ROOT/p).read_bytes()),role="edit target/style/material reference; exact indexed role in preserved prompt") for p in call["references"]],sheet_cell_xywh=[0,0,*call["source_wh"]],gutter_xy=[0,0],tool="built-in ImageGen",generation_task="0009",revision=call["revision"])
        if ident.endswith("_b"):
            entry["variant_of"] = "props/"+ident.removesuffix("_b")
        new_entries.append(entry)
        by_output[entry["output"]] = dict(output=entry["output"],owner="raster")
        image.save(REVIEW/(ident+"-native.png"))
        image.resize((image.width*3,image.height*3),Image.Resampling.NEAREST).save(REVIEW/(ident+"-native-3x.png"))
        measurements.append(dict(recipe=entry,native_bbox=image.getbbox(),native_alpha_range=image.getchannel("A").getextrema(),native_rgba_sha256=import_art.sha(image.tobytes()),source_wh=call["source_wh"],source_alpha_range=call["source_alpha_range"]))
    ids = {e["id"] for e in new_entries}
    manifest["assets"] = [e for e in manifest["assets"] if e["id"] not in ids]+new_entries
    owners["outputs"] = [by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8",newline="\n")
    owners_path.write_text(json.dumps(owners,indent=2)+"\n",encoding="utf-8",newline="\n")
    (REVIEW/"measured-contract.json").write_text(json.dumps(dict(contracts=measurements,retained_tree=next(e for e in manifest["assets"] if e["id"]=="props/tree")),indent=2)+"\n",encoding="utf-8",newline="\n")
    (HERE/"0009-generations.json").write_text(json.dumps(dict(date="2026-10-01",attempts=list(calls.values())),indent=2)+"\n",encoding="utf-8",newline="\n")
    print("Installed 10 raw-source prop recipes; retained the accepted pilot tree; shared scales for every material variant")


if __name__ == "__main__":
    main()
