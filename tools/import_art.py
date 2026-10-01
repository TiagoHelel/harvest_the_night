"""Build accepted raster art offline; --check validates sources AND exact output.

Raw sources are immutable approvals. If they change, explicitly approve their
new hash in the manifest before rebuilding. PNGs and view metadata are generated.
"""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path
import sys

from PIL import Image
import art_ownership
import palette

ROOT = art_ownership.ROOT
MANIFEST = ROOT / "assets/art_source/manifest.json"
METADATA = ROOT / "src/ui/raster_art.gd"
PLAYER_METADATA = ROOT / "src/ui/player_frames.gd"
VERSION = 1


def sha(data):
    return hashlib.sha256(data).hexdigest()


def samples(image):
    return image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()


def png(image):
    # Imported lazily to keep ownership dispatch free of circular imports.
    from gen_sprites import png_bytes
    pixels = list(samples(image.convert("RGBA")))
    rows = [pixels[y * image.width:(y + 1) * image.width] for y in range(image.height)]
    return png_bytes(image.width, image.height, rows)


def integers(value, length, label, minimum=0):
    if not isinstance(value, list) or len(value) != length \
            or any(type(n) is not int or n < minimum for n in value):
        raise ValueError("Invalid " + label)
    return value


def rect(value, size, label):
    x, y, w, h = integers(value, 4, label)
    if w < 1 or h < 1 or x + w > size[0] or y + h > size[1]:
        raise ValueError("Out-of-bounds " + label)
    return x, y, x + w, y + h


def hashed_file(path, expected, prefix=None):
    if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise ValueError("Invalid SHA-256 for " + path)
    full = art_ownership.project_path(path, prefix)
    if not full.is_file():
        raise ValueError("Missing source/reference/prompt: " + path)
    if sha(full.read_bytes()) != expected:
        raise ValueError("Unapproved source/reference/prompt change: " + path)
    return full


def load_manifest(path=MANIFEST):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if data.get("version") != VERSION or data.get("recipe") != "nearest-palette-alpha-v1":
        raise ValueError("Unsupported manifest/recipe version")
    ids, outputs, animations = set(), set(), {}
    owners = art_ownership.registry()
    if not isinstance(data.get("assets"), list) or not data["assets"]:
        raise ValueError("Manifest needs nonempty assets")
    for entry in data["assets"]:
        ident, output = entry["id"], entry["output"]
        if not isinstance(ident, str) or not ident or not isinstance(entry["animation"], str) or not entry["animation"]:
            raise ValueError("Missing asset/animation ID")
        art_ownership.project_path(output, "sprites")
        if not output.endswith(".png") or ("source" in entry) == ("input" in entry):
            raise ValueError("Asset needs PNG output and exactly one source or input")
        if ident in ids or output in outputs or entry["owner"] != "raster" \
                or owners.get(output) != "raster":
            raise ValueError("Duplicate ID/output or owner mismatch: " + ident)
        ids.add(ident)
        outputs.add(output)
        canvas = integers(entry["canvas_wh"], 2, "canvas", 1)
        pivot = integers(entry["pivot_xy"], 2, "pivot")
        if any(pivot[i] > canvas[i] for i in range(2)):
            raise ValueError("Out-of-range pivot: " + ident)
        if entry["palette"] != "tools/palette.py:COLOURS":
            raise ValueError("Unknown palette: " + ident)
        if type(entry["frame"]) is not int or entry["frame"] < 0 \
                or type(entry["loop"]) is not bool \
                or type(entry["seconds"]) not in (int, float) \
                or not math.isfinite(entry["seconds"]) or entry["seconds"] <= 0:
            raise ValueError("Invalid animation metadata: " + ident)
        if not isinstance(entry["output_sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", entry["output_sha256"]):
            raise ValueError("Invalid output hash: " + ident)
        hashed_file(entry["prompt"], entry["prompt_sha256"])
        for reference in entry["references"]:
            if not reference.get("role"):
                raise ValueError("Reference must declare its role")
            hashed_file(reference["path"], reference["sha256"])
        if "source" in entry:
            source = hashed_file(entry["source"], entry["source_sha256"], "assets/art_source")
            with Image.open(source) as image:
                rect(entry["crop_xywh"], image.size, "source crop: " + ident)
                if "sheet_cell_xywh" in entry:
                    cell = rect(entry["sheet_cell_xywh"], image.size, "sheet cell")
                    box = rect(entry["crop_xywh"], image.size, "source crop")
                    if box[0] < cell[0] or box[1] < cell[1] or box[2] > cell[2] or box[3] > cell[3]:
                        raise ValueError("Crop crosses its sheet cell: " + ident)
                    integers(entry["gutter_xy"], 2, "gutter")
            scale = entry["content_scale"]
            if type(scale) not in (int, float) or not math.isfinite(scale) or scale <= 0:
                raise ValueError("Invalid scale: " + ident)
            if type(entry["alpha_threshold"]) is not int or not 1 <= entry["alpha_threshold"] <= 255:
                raise ValueError("Invalid alpha threshold: " + ident)
        elif "input" not in entry or entry.get("operation") not in {"copy", "slice", "legacy_bob", "legacy_lunge", "legacy_fall"}:
            raise ValueError("Missing source/valid derivation: " + ident)
        key = entry["animation"]
        animations.setdefault(key, []).append(entry)
    if outputs != {p for p, owner in owners.items() if owner == "raster"}:
        raise ValueError("Manifest does not cover every raster-owned output")
    for name, frames in animations.items():
        indices = sorted(e["frame"] for e in frames)
        if indices != list(range(len(frames))):
            raise ValueError("Missing/duplicate runtime frame: " + name)
        for field in ("canvas_wh", "pivot_xy", "seconds", "loop"):
            if any(e[field] != frames[0][field] for e in frames):
                raise ValueError("Inconsistent animation " + field + ": " + name)
        scales = {e["content_scale"] for e in frames if "source" in e}
        if len(scales) > 1:
            raise ValueError("Per-frame scale drift: " + name)
    return data


def render_source(entry):
    with Image.open(ROOT / entry["source"]) as raw:
        crop = raw.convert("RGBA").crop(rect(entry["crop_xywh"], raw.size, "crop"))
        scale = entry["content_scale"]
        size = tuple(max(1, round(n * scale)) for n in crop.size)
        crop = crop.resize(size, Image.Resampling.NEAREST)
    colors, cache, reduced = tuple(palette.COLOURS.values()), {}, []
    for r, g, b, a in samples(crop):
        if a < entry["alpha_threshold"]:
            reduced.append((0, 0, 0, 0))
        else:
            rgb = (r, g, b)
            if rgb not in cache:
                cache[rgb] = min(colors, key=lambda c: sum((c[i] - rgb[i]) ** 2 for i in range(3)))
            reduced.append((*cache[rgb], 255))
    crop.putdata(reduced)
    canvas = Image.new("RGBA", tuple(entry["canvas_wh"]))
    anchor = integers(entry.get("content_anchor_xy", [crop.width // 2, crop.height]), 2, "content anchor")
    offset = tuple(entry["pivot_xy"][i] - anchor[i] for i in range(2))
    if any(offset[i] < 0 or offset[i] + size[i] > canvas.size[i] for i in range(2)):
        raise ValueError("Content clips canvas: " + entry["id"])
    canvas.alpha_composite(crop, offset)
    return canvas


def build(data):
    by_id = {e["id"]: e for e in data["assets"]}
    images, active = {}, set()

    def resolve(ident):
        if ident in images:
            return images[ident]
        if ident not in by_id or ident in active:
            raise ValueError("Missing/cyclic raster derivation: " + ident)
        entry = by_id[ident]
        active.add(ident)
        if "source" in entry:
            image = render_source(entry)
        else:
            parent = resolve(entry["input"])
            operation = entry["operation"]
            if operation == "copy":
                image = parent.copy()
            elif operation == "slice":
                image = parent.crop(rect(entry["slice_xywh"], parent.size, "slice"))
            else:
                # Transitional legacy motion, explicitly identified; authored strips
                # replace these in task 0015. They derive from the NEW raster master.
                from gen_sprites import bobbed, lunging, fallen
                pixels = list(samples(parent))
                rows = [pixels[y * parent.width:(y + 1) * parent.width] for y in range(parent.height)]
                rows = {"legacy_bob": bobbed, "legacy_lunge": lunging, "legacy_fall": fallen}[operation](rows)
                image = Image.new("RGBA", (len(rows[0]), len(rows)))
                image.putdata([p for row in rows for p in row])
        if list(image.size) != entry["canvas_wh"]:
            raise ValueError("Derived canvas mismatch: " + ident)
        opaque = [p for p in samples(image) if p[3]]
        if not opaque or any(p[3] != 255 or p[:3] not in palette.COLOURS.values() for p in opaque):
            raise ValueError("Empty frame, nonbinary alpha or unknown color: " + ident)
        images[ident] = image
        active.remove(ident)
        return image

    files = {}
    for ident in sorted(by_id):
        files[by_id[ident]["output"]] = png(resolve(ident))
    return files, images


def metadata(data):
    lines = ["class_name RasterArt", "extends RefCounted", "",
             "## Generated by tools/import_art.py. Do not edit.", "const FRAMES := {"]
    for entry in sorted(data["assets"], key=lambda e: e["output"]):
        w, h = entry["canvas_wh"]
        x, y = entry["pivot_xy"]
        offset = entry.get("cell_offset_xy", [0, 0])
        lines.append('\t"res://%s": {"canvas": Vector2i(%d, %d), "pivot": Vector2i(%d, %d), "cell_offset": Vector2i(%d, %d), "seconds": %s, "loop": %s},' %
                     (entry["output"], w, h, x, y, *offset, entry["seconds"], str(entry["loop"]).lower()))
        for field in ("light", "smoke"):
            if field + "_xy" in entry:
                point = integers(entry[field + "_xy"], 2, field + " point")
                if any(point[i] > entry["canvas_wh"][i] for i in range(2)):
                    raise ValueError("Emission point outside canvas")
                lines[-1] = lines[-1][:-2] + ', "%s": Vector2i(%d, %d)},' % (field, *point)
    lines.extend(["}", ""])
    return "\n".join(lines).encode("utf-8")


def validate_coverage(data):
    import gen_sprites
    import cut_sheet
    owners = art_ownership.registry()
    ascii_paths = {"sprites/" + p for p in gen_sprites.everything(dispatch=False)}
    player_paths = {"sprites/actors/" + p for p in cut_sheet.paths(cut_sheet.cut())}
    for output, owner in owners.items():
        if owner == "ascii" and output not in ascii_paths or owner == "player_sheet" and output not in player_paths:
            raise ValueError("Owner has no recipe for: " + output)
    expected = set(owners)
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "sprites").rglob("*.png")}
    if actual != expected:
        raise ValueError("Missing/unregistered runtime sprites: " + str(sorted(actual ^ expected)))
    for path in ascii_paths | player_paths:
        if path not in owners:
            raise ValueError("Legacy runtime frame lost its owner: " + path)
    # All derived legacy outputs must move with their raster parent.
    for base in gen_sprites.SPRITES:
        prefix = "sprites/" + base
        if owners.get(prefix + ".png") == "raster":
            for path in ascii_paths:
                if path.startswith(prefix + "_") and owners[path] != "raster":
                    raise ValueError("Stale legacy derivative: " + path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    args = parser.parse_args()
    try:
        data = load_manifest(args.manifest)
        files, _ = build(data)
        if args.check:
            validate_coverage(data)
        bad = []
        for entry in data["assets"]:
            content = files[entry["output"]]
            if args.check and entry["output_sha256"] != sha(content):
                bad.append(entry["output"] + " recipe/output hash changed")
            entry["output_sha256"] = sha(content)
        files[METADATA.relative_to(ROOT).as_posix()] = metadata(data)
        import cut_sheet
        files[PLAYER_METADATA.relative_to(ROOT).as_posix()] = cut_sheet.frames_gd(cut_sheet.cut(), data)
        written = 0
        for path, content in files.items():
            full = ROOT / path
            if not full.is_file() or full.read_bytes() != content:
                if args.check:
                    bad.append(path + " missing/stale/tampered")
                else:
                    full.parent.mkdir(parents=True, exist_ok=True)
                    full.write_bytes(content)
                    written += 1
        if bad:
            raise ValueError("; ".join(bad))
        if not args.check:
            content = json.dumps(data, indent=2) + "\n"
            if args.manifest.read_text(encoding="utf-8") != content:
                args.manifest.write_text(content, encoding="utf-8", newline="\n")
        print("OK: %d raster outputs, metadata verified, %d written" % (len(data["assets"]), written))
        return 0
    except (ValueError, KeyError, OSError, TypeError) as error:
        print("FAIL: " + str(error))
        return 1


if __name__ == "__main__":
    sys.exit(main())
