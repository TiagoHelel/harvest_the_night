"""Preserve the actual returned file and inspect a deterministic native candidate."""
from pathlib import Path
import argparse
import json
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
REVIEW = ROOT / "implementation/sprites/reviews/0009"
sys.path.insert(0, str(ROOT / "tools"))
import import_art


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("id")
    parser.add_argument("returned")
    parser.add_argument("--revision", type=int, default=0)
    parser.add_argument("--refs", nargs="+", required=True)
    args = parser.parse_args()
    source = ROOT / ("assets/art_source/props/" + args.id + ".png")
    source.parent.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    if source.exists():
        assert source.read_bytes() == Path(args.returned).read_bytes(), "Never overwrite an existing returned source"
    else:
        shutil.copyfile(args.returned, source)
    raw = Image.open(source).convert("RGBA")
    bbox = raw.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert bbox is not None
    width, height = bbox[2] - bbox[0], bbox[3] - bbox[1]
    kind = args.id.split("-r")[0]
    canvas, pivot, maximum = ([40,48],[20,44],[36,42]) if kind == "tree_b" else (([24,24],[12,22],[22,18]) if kind == "cow" else (([24,24],[12,22],[12,12]) if kind == "chicken" else ([16,16],[8,14],[14,10 if kind == "stump" else 12])))
    scale = min(maximum[0]/width, maximum[1]/height)
    entry = dict(id="props/"+kind,source=source.relative_to(ROOT).as_posix(),crop_xywh=[bbox[0],bbox[1],width,height],canvas_wh=canvas,pivot_xy=pivot,content_scale=scale,alpha_threshold=128)
    # Use the same approved pilot reduction scale for the tree variation.
    if kind == "tree_b":
        entry["content_scale"] = 42/1135
    elif kind.endswith("_b"):
        master = json.loads((HERE/("0009-"+kind.removesuffix("_b")+"-call.json")).read_text(encoding="utf-8"))
        entry["content_scale"] = master["measured_recipe"]["content_scale"]
    image = import_art.render_source(entry)
    image.save(REVIEW/(args.id+"-candidate.png"))
    image.resize((image.width*3,image.height*3),Image.Resampling.NEAREST).save(REVIEW/(args.id+"-candidate-3x.png"))
    prompt = HERE/("0009-"+args.id+".prompt.txt")
    call = dict(id=args.id,tool="built-in ImageGen",revision=args.revision,returned_file=args.returned,source=entry["source"],source_sha256=import_art.sha(source.read_bytes()),references=args.refs,prompt_text=prompt.read_text(encoding="utf-8").strip(),decision="Pending native and runtime review",source_wh=list(raw.size),source_alpha_range=raw.getchannel("A").getextrema(),measured_recipe=entry,native_bbox=image.getbbox())
    (HERE/("0009-"+args.id+"-call.json")).write_text(json.dumps(call,indent=2)+"\n",encoding="utf-8",newline="\n")
    print(json.dumps(dict(id=args.id,source_wh=raw.size,source_alpha=raw.getchannel("A").getextrema(),source_bbox=bbox,native_bbox=image.getbbox(),recipe=entry)))


if __name__ == "__main__":
    main()
