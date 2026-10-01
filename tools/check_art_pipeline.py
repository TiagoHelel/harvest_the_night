"""Integration fault probes for raster/legacy ownership. Always restore corruption.

Run outside a concurrent verify/import/editor build. The finally blocks restore
all touched files byte for byte, including on an assertion failure.
"""
import copy
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile

import art_ownership
import import_art

ROOT = art_ownership.ROOT


def run(script, *args):
    process = subprocess.run([sys.executable, str(ROOT / script), *args], cwd=ROOT,
                             capture_output=True, text=True, timeout=90)
    return process.returncode, process.stdout + process.stderr


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="implementation/sprites/reviews/0002/fault-probes.json")
    args = parser.parse_args()
    data = import_art.load_manifest()
    results = []
    def passed(name):
        results.append(name)
        print("PASS: " + name)

    files, images = import_art.build(data)
    assert files == import_art.build(data)[0]
    passed("Two in-memory rebuilds are byte-identical")
    saved = {ROOT / path: (ROOT / path).read_bytes() for path in files}
    saved[import_art.MANIFEST] = import_art.MANIFEST.read_bytes()
    saved[import_art.METADATA] = import_art.METADATA.read_bytes()
    saved[import_art.PLAYER_METADATA] = import_art.PLAYER_METADATA.read_bytes()
    try:
        for _ in range(2):
            code, output = run("tools/import_art.py")
            assert code == 0 and "0 written" in output, output
        assert all(path.read_bytes() == content for path, content in saved.items())
        passed("Two on-disk rebuilds change zero bytes")
        for script in ("tools/gen_sprites.py", "tools/cut_sheet.py"):
            code, output = run(script)
            assert code == 0, output
        assert all(path.read_bytes() == content for path, content in saved.items())
        passed("Legacy writers cannot overwrite any of %d migrated files" % len(files))

        def corrupt(path, script, missing=False):
            original = path.read_bytes()
            try:
                if missing:
                    path.unlink()
                else:
                    path.write_bytes(original + b"deliberate fault probe")
                code, output = run(script, "--check")
                assert code != 0, output
            finally:
                path.write_bytes(original)

        corrupt(ROOT / data["assets"][0]["source"], "tools/import_art.py")
        passed("Changed accepted source is rejected")
        corrupt(ROOT / data["assets"][0]["source"], "tools/import_art.py", missing=True)
        passed("Missing accepted source is rejected")
        corrupt(ROOT / data["assets"][0]["output"], "tools/import_art.py")
        passed("Tampered migrated output is rejected")
        corrupt(ROOT / data["assets"][0]["output"], "tools/import_art.py", missing=True)
        passed("Missing runtime frame is rejected")
        if any(e["animation"] == "walk_south" for e in data["assets"]):
            corrupt(ROOT / "sprites/actors/walk_south_2.png", "tools/import_art.py", missing=True)
            passed("Missing authored locomotion frame cannot fall back to idle")
        corrupt(import_art.PLAYER_METADATA, "tools/import_art.py")
        passed("Tampered player count/canvas/pivot metadata is rejected")
        corrupt(ROOT / "sprites/terrain/grass.png", "tools/gen_sprites.py")
        passed("Tampered unmigrated ASCII output is still rejected")
        corrupt(ROOT / "sprites/actors/chop_0.png", "tools/cut_sheet.py")
        passed("Tampered unmigrated player output is still rejected")

        def invalid_manifest(name, mutate):
            candidate = copy.deepcopy(data)
            mutate(candidate)
            with tempfile.TemporaryDirectory(prefix="harvest-art-probe-") as folder:
                path = Path(folder) / "manifest.json"
                path.write_text(json.dumps(candidate), encoding="utf-8")
                try:
                    loaded = import_art.load_manifest(path)
                    import_art.build(loaded)
                except (ValueError, KeyError):
                    passed(name)
                else:
                    raise AssertionError("Accepted invalid manifest: " + name)

        invalid_manifest("Duplicate manifest output rejected", lambda d: d["assets"].append(copy.deepcopy(d["assets"][0])))
        invalid_manifest("Invalid crop rejected", lambda d: d["assets"][0].update(crop_xywh=[0,0,999999,2]))
        invalid_manifest("Out-of-range pivot rejected", lambda d: d["assets"][0].update(pivot_xy=[500,500]))
        invalid_manifest("Unknown palette rejected", lambda d: d["assets"][0].update(palette="other palette"))
        invalid_manifest("Missing animation frame rejected", lambda d: d["assets"][0].update(frame=5))
        invalid_manifest("Per-frame canvas drift rejected", lambda d: d["assets"][0].update(canvas_wh=[49,48]))
        derived = next(i for i, entry in enumerate(data["assets"]) if "input" in entry)
        invalid_manifest("Missing derived input rejected", lambda d: d["assets"][derived].update(input="missing"))
        invalid_manifest("Derivation cycle rejected", lambda d: d["assets"][derived].update(input=d["assets"][derived]["id"]))

        original_owners = art_ownership.REGISTRY.read_bytes()
        try:
            owners = json.loads(original_owners)
            owners["outputs"].append(owners["outputs"][0])
            art_ownership.REGISTRY.write_text(json.dumps(owners), encoding="utf-8")
            try:
                art_ownership.registry()
            except ValueError:
                passed("Duplicate output owner rejected")
            else:
                raise AssertionError("Duplicate owner accepted")
        finally:
            art_ownership.REGISTRY.write_bytes(original_owners)

        # Every house pixel belongs to one slice, with offsets preserving the
        # 64x64 whole over its unchanged 48x48 logical footprint.
        from PIL import Image
        whole = images["buildings/house"]
        assembled = Image.new("RGBA", whole.size)
        area = 0
        for entry in data["assets"]:
            if entry.get("input") == "buildings/house":
                x,y,w,h = entry["slice_xywh"]
                assembled.paste(images[entry["id"]], (x,y))
                area += w*h
        assert area == 64*64 and assembled.tobytes() == whole.tobytes()
        passed("House's nine slices reconstruct the full roof without lost pixels")
    finally:
        for path, content in saved.items():
            path.write_bytes(content)
    code, output = run("tools/import_art.py", "--check")
    assert code == 0, output
    report = dict(tests=results, count=len(results), restored=True)
    destination = art_ownership.project_path(args.out, "implementation")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8", newline="\n")
    print("OK: %d fault/rebuild probes; all deliberate corruption restored" % len(results))


if __name__ == "__main__":
    main()
