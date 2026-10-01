"""Explicitly capture current sprite inventory and read-only generator comparisons.

Run from the repo root during an audit. This writes only inventory.json and
baseline-check.json in this planning folder; it never regenerates runtime art.
The historical screenshot baseline is untouched. Requires the existing Pillow
dependency already used by the owner's player cutter.
"""
import hashlib
import io
import json
from pathlib import Path
import struct
import sys
import zlib

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "tools"))

import cut_sheet
import gen_font
import gen_icon
import gen_logo
import gen_sprites
from PIL import Image


def sha(data):
    return hashlib.sha256(data).hexdigest()


def decoded(data):
    with Image.open(io.BytesIO(data)) as source:
        rgba = source.convert("RGBA")
        return rgba.size, rgba.tobytes()


def main():
    generated = gen_sprites.everything()
    player = cut_sheet.paths(cut_sheet.cut())
    comparisons = []
    groups = [
        ("sprites", REPO / "sprites", generated),
        ("player art", REPO / "sprites/actors", player),
        ("font", REPO / "assets/fonts", gen_font.everything()[0]),
        ("logo", REPO / "assets", gen_logo.everything()),
        ("icon", REPO / "assets", gen_icon.everything()),
    ]
    for name, folder, outputs in groups:
        byte_mismatches, pixel_mismatches = [], []
        for filename, expected in outputs.items():
            if not filename.endswith(".png"):
                continue
            path = folder / filename
            if not path.exists():
                byte_mismatches.append(filename)
                pixel_mismatches.append(filename)
                continue
            actual = path.read_bytes()
            if actual != expected:
                byte_mismatches.append(filename)
                if decoded(actual) != decoded(expected):
                    pixel_mismatches.append(filename)
        comparisons.append(dict(check=name, png_byte_mismatch_count=len(byte_mismatches),
                                png_pixel_mismatch_count=len(pixel_mismatches),
                                byte_mismatches=byte_mismatches, pixel_mismatches=pixel_mismatches))
    assets = []
    for path in sorted((REPO / "sprites").rglob("*.png")):
        data = path.read_bytes()
        key = path.relative_to(REPO / "sprites").as_posix()
        owner = "tools/gen_sprites.py" if key in generated else (
            "tools/cut_sheet.py" if key.startswith("actors/") and path.name in player else "unclassified")
        width, height = struct.unpack(">II", data[16:24])
        assets.append(dict(path=path.relative_to(REPO).as_posix(), width=width, height=height,
                           owner=owner, bytes=len(data), sha256=sha(data),
                           rgba_sha256=sha(decoded(data)[1])))
    counts = {}
    for asset in assets:
        group = asset["path"].split("/")[1]
        counts[group] = counts.get(group, 0) + 1
    inventory = dict(captured_date="2026-10-01", purpose="pre-production sprite baseline",
                     total=len(assets), counts_by_family=counts, assets=assets)
    report = dict(captured_date="2026-10-01", zlib_build=zlib.ZLIB_VERSION,
                  zlib_runtime=zlib.ZLIB_RUNTIME_VERSION, comparisons=comparisons,
                  note="Read-only comparison. Equal decoded pixels with different PNG bytes is an encoding discrepancy; exact historical cause is unverified.")
    for filename, value in (("inventory.json", inventory), ("baseline-check.json", report)):
        (HERE / filename).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Inventory: {len(assets)} PNGs; families {counts}")
    for check in comparisons:
        print(f"{check['check']}: {check['png_byte_mismatch_count']} byte mismatches, {check['png_pixel_mismatch_count']} pixel mismatches")


if __name__ == "__main__":
    main()
