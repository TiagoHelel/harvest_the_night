"""The farmer's selected detail density, shared by the walk and idle promoters.

The owner chose the "32px" farmer on 2026-10-06: about 32 art pixels tall,
each drawn 4x4 physical pixels at 1920x1080 - the density of the zombies, the
buildings and the rest of the world art. It is not a 32x32 cell, 32 colours or
a smaller screen. `tools/import_art.py` holds every farmer frame to it with the
`detail_wh` recipe, 80 -> 40 -> 80 NEAREST: exact source colours, binary
alpha, the same canvas, pivot (40, 72) and 0.5 draw scale, so the farmer stays
about 128 pixels tall.

* The grounded idle poses are sampled from their full-detail sources, and the
  review that chose the density (farmer32) records every expected frame.
* The walk comes from the approved 2026-10-06 pack, already at this detail; on
  it the recipe changes nothing, and the walk promoter names the approved
  frame each output must equal.

Either way a rebuild cannot quietly bring back 64px detail, the 16px variant
that lost the comparison, or a walk older than the approved one.
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
    """{source path: reviewed runtime-80 output} for the 72 farmer32 frames."""
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
    """The manifest's link from a farmer32 frame to the review that chose its density."""
    review = reviewed()[source]
    return [
        {"path": review["path"], "sha256": review["sha256"],
         "role": "Selected 32px detail review frame; the runtime output is pixel-identical"},
        {"path": REVIEW_CONTRACT.relative_to(ROOT).as_posix(), "sha256": sha(REVIEW_CONTRACT),
         "role": "32px farmer review contract: 80->40->80 NEAREST, pivot (40,72), 0.5 draw scale"},
    ]


def check_runtime(entry, approved=None):
    """The runtime frame is its approved 32px frame and the 32px sample of its
    source, exactly. `approved` defaults to the farmer32 review's frame."""
    assert entry.get("detail_wh") == DETAIL_WH, ("farmer frame lost its 32px density recipe", entry["id"])
    if approved is None:
        review = reviewed()[entry["source"]]
        assert sha(ROOT / review["path"]) == review["sha256"], ("reviewed 32px frame changed", review["path"])
        approved = ROOT / review["path"]
    expected = detailed(ROOT / entry["source"]).tobytes()
    with Image.open(approved) as image:
        assert image.convert("RGBA").tobytes() == expected, ("approved 32px frame drifted", str(approved))
    with Image.open(ROOT / entry["output"]) as image:
        assert image.convert("RGBA").tobytes() == expected, ("runtime frame is not its approved 32px frame", entry["id"])
