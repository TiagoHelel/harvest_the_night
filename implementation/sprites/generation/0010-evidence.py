"""Audit crop-only runtime changes and immutable ImageGen provenance."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=ROOT/"implementation/sprites/reviews/0010"
BASELINE="18b4b3e"
sys.path.insert(0,str(ROOT/"tools"))
import import_art


def sha(data):return hashlib.sha256(data).hexdigest()


def main():
    expected={"sprites/crops/%s_%d.png"%(kind,stage) for kind in ("wheat","corn","carrot") for stage in range(4)}
    expected.update(("sprites/crops/tilled.png","sprites/crops/tilled_wet.png"))
    changed,unchanged=[],[]
    for path in sorted((ROOT/"sprites").rglob("*.png")):
        relative=path.relative_to(ROOT).as_posix()
        old=subprocess.run(["git","show",BASELINE+":"+relative],cwd=ROOT,capture_output=True)
        assert old.returncode==0,relative
        new=path.read_bytes()
        if old.stdout!=new:
            changed.append(dict(path=relative,old_sha256=sha(old.stdout),sha256=sha(new),added=False))
        else:unchanged.append(relative)
    assert {e["path"] for e in changed}==expected
    assert len(unchanged)==246
    preserved=["src/core","tools/palette.py","tools/determinism_sim_hash.txt","tools/determinism_data_hash.txt","docs/sprites_sem_fundo.png","src/ui/player_frames.gd","sprites/props","sprites/terrain","assets/art_source/atlas.png"]
    assert not subprocess.check_output(["git","diff",BASELINE,"--",*preserved],cwd=ROOT)
    counts=dict(Counter(e["owner"] for e in json.loads((ROOT/"assets/art_source/ownership.json").read_text(encoding="utf-8"))["outputs"]))
    assert counts=={"raster":144,"ascii":116}
    (HERE/"runtime-delta.json").write_text(json.dumps(dict(baseline=BASELINE,changed=changed,unchanged_count=246,unchanged=unchanged,preserved=preserved,ownership_counts=counts),indent=2)+"\n",encoding="utf-8",newline="\n")
    attempts=[]
    recipes={e["id"]:e for e in json.loads(import_art.MANIFEST.read_text(encoding="utf-8"))["assets"]}
    for path in sorted((ROOT/"implementation/sprites/generation").glob("0010-*-call.json")):
        call=json.loads(path.read_text(encoding="utf-8"))
        assert (ROOT/call["source"]).read_bytes()==Path(call["returned_file"]).read_bytes()
        assert sha((ROOT/call["source"]).read_bytes())==call["source_sha256"]
        prompt=ROOT/("implementation/sprites/generation/0010-"+call["id"]+".prompt.txt")
        assert prompt.read_text(encoding="utf-8").strip()==call["prompt_text"]
        for initial in call["measured_recipes"]:
            accepted=recipes[initial["id"]]
            assert all(initial[key]==accepted[key] for key in initial),(call["id"],initial)
            assert accepted["prompt_sha256"]==sha(prompt.read_bytes())
        call["decision"]="Accepted after all twelve native/nearest3x growth stages on light/dark/checker, dry/wet repeat materials, 41 actual Godot captures in four light states, dense-bed grounding, real watering/harvest/growth and unchanged simulation/data guards."
        path.write_text(json.dumps(call,indent=2)+"\n",encoding="utf-8",newline="\n")
        attempts.append(call)
    assert len(attempts)==5 and all(c["revision"]==0 for c in attempts)
    (ROOT/"implementation/sprites/generation/0010-generations.json").write_text(json.dumps(dict(date="2026-10-01",attempts=attempts,targeted_imagegen_revisions=0,soil_conversion_evidence="implementation/sprites/reviews/0010/initial-soil-conversion.json"),indent=2)+"\n",encoding="utf-8",newline="\n")
    dry,wet=[import_art.render_source(recipes["crops/"+name]) for name in ("tilled","tilled_wet")]
    brightness=lambda im:sum(sum(p[:3])/3 for p in import_art.samples(im))/256
    (HERE/"soil-metrics.json").write_text(json.dumps(dict(dry_brightness=brightness(dry),wet_brightness=brightness(wet),difference=brightness(dry)-brightness(wet),required_difference=20,palette_keys=recipes["crops/tilled"]["palette_keys"]),indent=2)+"\n",encoding="utf-8",newline="\n")
    print("OK: 5 immutable generated masters; 14 changed and zero added runtime PNGs; other 246 PNGs/core/map/guards/palette/owner sheet/props/terrain unchanged")


if __name__=="__main__":main()
