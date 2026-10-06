"""The farmer's selected detail density, shared by the walk and idle promoters.

The owner chose the "32px" farmer on 2026-10-06: about 32 art pixels tall,
each drawn 4x4 physical pixels at 1920x1080 - the density of the zombies, the
buildings and the rest of the world art. It is not a 32x32 cell, 32 colours or
a smaller screen. The approved 80x80 sources are sampled 80 -> 40 -> 80 NEAREST
by `tools/import_art.py` (the `detail_wh` recipe): exact source colours, binary
alpha, the same canvas, pivot (40, 72) and 0.5 draw scale, so the farmer stays
about 128 pixels tall. The full-detail sources stay as they are.

The review that chose it records every expected runtime output; the promoters
hold the game's frames to those pixels, so a rebuild cannot quietly bring back
the 64px detail of the sources or the 16px variant that lost the comparison.
"""
from functools import lru_cache
from pathlib import Path
import hashlib
import json

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
DETAIL_WH = [40, 40]
REVIEW_CONTRACT = ROOT / "implementation/fhd-enemies/pilots/2026-10-05/16px-review/contract.json"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def detailed(path):
    """A source frame at the selected density, as the importer renders it."""
    with Image.open(path) as image:
        full = image.convert("RGBA")
    return full.resize(tuple(DETAIL_WH), Image.Resampling.NEAREST).resize(full.size, Image.Resampling.NEAREST)


@lru_cache(maxsize=1)
def reviewed():
    """{source path: reviewed runtime-80 output} for the 72 selected frames."""
    contract = json.loads(REVIEW_CONTRACT.read_text(encoding="utf-8"))["farmer32"]
    assert contract["native_canvas_wh"] == DETAIL_WH and contract["runtime_pivot_xy"] == [40, 72] \
        and contract["runtime_draw_scale"] == 0.5, "the 32px review changed its geometry"
    out = {}
    for asset in contract["assets"]:
        assert sha(ROOT / asset["source"]) == asset["source_sha256"], ("reviewed source changed", asset["source"])
        out[asset["source"]] = asset["outputs"]["runtime-80"]
    assert len(out) == 72, len(out)
    return out


def references(source):
    """The manifest's link from a farmer frame to the review that chose its density."""
    review = reviewed()[source]
    return [
        {"path": review["path"], "sha256": review["sha256"],
         "role": "Selected 32px detail review frame; the runtime output is pixel-identical"},
        {"path": REVIEW_CONTRACT.relative_to(ROOT).as_posix(), "sha256": sha(REVIEW_CONTRACT),
         "role": "32px farmer review contract: 80->40->80 NEAREST, pivot (40,72), 0.5 draw scale"},
    ]


def check_runtime(entry):
    """The runtime frame is the reviewed 32px sample of its source, exactly."""
    assert entry.get("detail_wh") == DETAIL_WH, ("farmer frame lost its 32px density recipe", entry["id"])
    review = reviewed()[entry["source"]]
    assert sha(ROOT / review["path"]) == review["sha256"], ("reviewed 32px frame changed", review["path"])
    expected = detailed(ROOT / entry["source"]).tobytes()
    with Image.open(ROOT / review["path"]) as image:
        assert image.convert("RGBA").tobytes() == expected, ("reviewed 32px frame drifted", review["path"])
    with Image.open(ROOT / entry["output"]) as image:
        assert image.convert("RGBA").tobytes() == expected, ("runtime frame is not the 32px sample", entry["id"])
