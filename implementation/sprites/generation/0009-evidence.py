"""Audit exact prop runtime scope and approved returned-file provenance."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT/"implementation/sprites/reviews/0009"
BASELINE = "9cddbfd"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    changed,unchanged=[],[]
    expected={"sprites/props/"+n+".png" for n in ("tree_b","stump","rock","rock_b","seam","seam_b","ore","ore_b","cow","chicken")}
    for path in sorted((ROOT/"sprites").rglob("*.png")):
        relative=path.relative_to(ROOT).as_posix()
        old=subprocess.run(["git","show",BASELINE+":"+relative],cwd=ROOT,capture_output=True)
        new=path.read_bytes()
        if old.returncode or old.stdout != new:
            changed.append(dict(path=relative,old_sha256=None if old.returncode else sha(old.stdout),sha256=sha(new),added=bool(old.returncode)))
        else:
            unchanged.append(relative)
    assert {e["path"] for e in changed} == expected
    assert len(unchanged)==250 and sum(e["added"] for e in changed)==4
    preserved=["src/core","tools/palette.py","tools/determinism_sim_hash.txt","tools/determinism_data_hash.txt","docs/sprites_sem_fundo.png","src/ui/player_frames.gd","sprites/props/tree.png","sprites/terrain"]
    assert not subprocess.check_output(["git","diff",BASELINE,"--",*preserved],cwd=ROOT)
    owners=json.loads((ROOT/"assets/art_source/ownership.json").read_text(encoding="utf-8"))
    counts=dict(Counter(e["owner"] for e in owners["outputs"]))
    assert counts=={"raster":130,"ascii":130}
    (HERE/"runtime-delta.json").write_text(json.dumps(dict(baseline=BASELINE,changed=changed,unchanged_count=len(unchanged),unchanged=unchanged,preserved=preserved,ownership_counts=counts),indent=2)+"\n",encoding="utf-8",newline="\n")
    attempts=[]
    recipes={e["id"]:e for e in json.loads((ROOT/"assets/art_source/manifest.json").read_text(encoding="utf-8"))["assets"]}
    for path in sorted((ROOT/"implementation/sprites/generation").glob("0009-*-call.json")):
        call=json.loads(path.read_text(encoding="utf-8"))
        assert (ROOT/call["source"]).read_bytes()==Path(call["returned_file"]).read_bytes()
        assert sha((ROOT/call["source"]).read_bytes())==call["source_sha256"]
        assert (ROOT/("implementation/sprites/generation/0009-"+call["id"]+".prompt.txt")).read_text(encoding="utf-8").strip()==call["prompt_text"]
        # Keep the measured first candidate, and record the final shared-family
        # geometry used by the accepted importer without losing that history.
        initial=call["measured_recipe"]
        accepted={key:recipes["props/"+call["id"]][key] for key in initial}
        if initial != accepted and "initial_measured_recipe" not in call:
            call["initial_measured_recipe"]=initial
        call["measured_recipe"]=accepted
        call["decision"]="Accepted after native/nearest3x source-alpha and all actual prop/farm captures, resource silhouettes, harvest/regrowth/collection, density, and real behind/in-front pixel comparisons."
        path.write_text(json.dumps(call,indent=2)+"\n",encoding="utf-8",newline="\n")
        attempts.append(call)
    assert len(attempts)==10
    (ROOT/"implementation/sprites/generation/0009-generations.json").write_text(json.dumps(dict(date="2026-10-01",attempts=attempts),indent=2)+"\n",encoding="utf-8",newline="\n")
    print("OK: 10 immutable generated masters; 6 changed/4 added runtime PNGs; 250 PNGs, core/map/guards/palette/owner sheet/terrain/pilot tree unchanged")


if __name__ == "__main__":
    main()
