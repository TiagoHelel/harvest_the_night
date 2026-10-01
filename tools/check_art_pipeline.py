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
        if any(e["animation"] == "repair" for e in data["assets"]):
            corrupt(ROOT / "sprites/actors/repair_3.png", "tools/import_art.py", missing=True)
            passed("Missing authored work recovery is rejected without borrowing another verb")
        corrupt(import_art.PLAYER_METADATA, "tools/import_art.py")
        passed("Tampered player count/canvas/pivot metadata is rejected")
        unmigrated = next(p for p, owner in sorted(art_ownership.registry().items())
                          if owner == "ascii" and p != "sprites/terrain/atlas.png")
        corrupt(ROOT / unmigrated, "tools/gen_sprites.py")
        passed("Tampered unmigrated ASCII output is still rejected")
        terrain = next((e for e in data["assets"] if e["id"] == "terrain/grass"), None)
        if terrain:
            corrupt(ROOT / terrain["source"], "tools/gen_sprites.py")
            passed("Atlas builder rejects changed accepted terrain source")
            corrupt(ROOT / terrain["source"], "tools/gen_sprites.py", missing=True)
            passed("Atlas builder rejects missing accepted terrain source without old ASCII fallback")
            corrupt(ROOT / terrain["output"], "tools/check_terrain_art.py")
            passed("Terrain checker rejects tampered migrated tile")
            corrupt(ROOT / "sprites/terrain/atlas.png", "tools/check_terrain_art.py")
            passed("Terrain checker rejects tampered composite atlas")
            from check_terrain_art import validate_tile
            for name, position, color in [
                    ("Terrain seam mismatch rejected", (0, 5), (0, 0, 0, 255)),
                    ("Transparent terrain hole rejected", (7, 7), (0, 0, 0, 0))]:
                broken = images["terrain/grass"].copy()
                broken.putpixel(position, color)
                try:
                    validate_tile(broken, "deliberate fault")
                except ValueError:
                    passed(name)
                else:
                    raise AssertionError(name)
        legacy_player = next((p for p, owner in art_ownership.registry().items() if owner == "player_sheet"), None)
        if legacy_player:
            corrupt(ROOT / legacy_player, "tools/cut_sheet.py")
            passed("Tampered unmigrated player output is still rejected")
        else:
            code, output = run("tools/cut_sheet.py", "--check")
            assert code == 0 and "0 player frames" in output, output
            passed("Fully migrated player has zero legacy writes and strict merged metadata checks")
        if any(e["animation"] == "react_bang" for e in data["assets"]):
            corrupt(ROOT / "sprites/actors/react_bang_0.png", "tools/import_art.py", missing=True)
            passed("Missing authored reaction is rejected without silently hiding the bubble")
            corrupt(ROOT / "sprites/actors/shadow.png", "tools/import_art.py", missing=True)
            passed("Missing shared contact shadow is rejected")

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
        invalid_manifest("Unknown material subset color rejected", lambda d: d["assets"][0].update(palette_keys=["invented color"]))
        invalid_manifest("Empty material palette subset rejected", lambda d: d["assets"][0].update(palette_keys=[]))
        invalid_manifest("Missing animation frame rejected", lambda d: d["assets"][0].update(frame=5))
        invalid_manifest("Per-frame canvas drift rejected", lambda d: d["assets"][0].update(canvas_wh=[49,48]))
        reaction = next((i for i, e in enumerate(data["assets"]) if "bubble_xywh" in e), None)
        if reaction is not None:
            invalid_manifest("Out-of-canvas reaction glyph rejected", lambda d: d["assets"][reaction].update(bubble_xywh=[47,0,3,2]))
            invalid_manifest("Reaction crop cannot erase body pixels", lambda d: d["assets"][reaction].update(bubble_xywh=[0,0,48,48]))
            invalid_manifest("Reaction crop cannot omit glyph pixels", lambda d: d["assets"][reaction].update(bubble_xywh=[0,0,1,1]))
        derived = next(i for i, entry in enumerate(data["assets"]) if "input" in entry)
        invalid_manifest("Missing derived input rejected", lambda d: d["assets"][derived].update(input="missing"))
        invalid_manifest("Derivation cycle rejected", lambda d: d["assets"][derived].update(input=d["assets"][derived]["id"]))
        water = next((i for i,e in enumerate(data["assets"]) if e["id"] == "terrain/water"), None)
        if water is not None:
            corrupt(ROOT / data["assets"][water]["source"], "tools/gen_sprites.py", missing=True)
            passed("Atlas rejects a missing water loop without old ASCII fallback")
            corrupt(ROOT / "sprites/terrain/water_b.png", "tools/check_terrain_art.py")
            passed("Standalone transition checker rejects a tampered water phase")
            corrupt(ROOT / "sprites/terrain/shore_corner_ne.png", "tools/check_terrain_art.py")
            passed("Standalone transition checker rejects a tampered derived corner")
            rotation = next(i for i,e in enumerate(data["assets"]) if e.get("operation") == "rotate")
            invalid_manifest("Invalid non-quarter rotation rejected", lambda d: d["assets"][rotation].update(quarter_turns=4))
            cap = next(i for i,e in enumerate(data["assets"]) if e.get("operation") == "slice_canvas")
            invalid_manifest("Clipped source endpoint cap rejected", lambda d: d["assets"][cap].update(paste_xy=[16,16]))
            from check_terrain_art import validate_side, validate_corner
            for label, validator, image in [
                    ("Swimming bank pixel rejected", lambda im: validate_side(im,"deliberate fault"), images["terrain/shore_n"].copy()),
                    ("Mismatched corner contact color rejected", lambda im: validate_corner(im,images["terrain/shore_n"],"deliberate fault"), images["terrain/shore_corner_nw"].copy())]:
                image.putpixel((0,8) if label.startswith("Swimming") else (0,0), (36,31,46,255))
                try:
                    validator(image)
                except ValueError:
                    passed(label)
                else:
                    raise AssertionError(label)

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
