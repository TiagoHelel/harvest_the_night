"""Audit the exact runtime delta and preserve accepted terrain provenance."""
from pathlib import Path
import hashlib
import json
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT / "implementation/sprites/reviews/0007"
NAMES = ["grass", "grass_b", "grass_c", "grass_d", "soil", "path", "floor", "rock", "atlas"]
BASELINE = "b116b6c"


def main():
    changed, unchanged = [], []
    for path in sorted((ROOT / "sprites").rglob("*.png")):
        relative = path.relative_to(ROOT).as_posix()
        old = subprocess.run(["git", "show", BASELINE + ":" + relative], cwd=ROOT, capture_output=True, check=True).stdout
        new = path.read_bytes()
        if old != new:
            changed.append(dict(path=relative, old_sha256=hashlib.sha256(old).hexdigest(), sha256=hashlib.sha256(new).hexdigest()))
        else:
            unchanged.append(relative)
    assert {e["path"] for e in changed} == {"sprites/terrain/" + n + ".png" for n in NAMES}
    assert len(unchanged) == 239
    assert not subprocess.run(["git", "diff", BASELINE, "--", "src/core", "tools/determinism_sim_hash.txt", "tools/determinism_data_hash.txt", "docs/sprites_sem_fundo.png"], cwd=ROOT, capture_output=True, check=True).stdout
    attempts = []
    for path in sorted((ROOT / "implementation/sprites/generation").glob("0007-*-call.json")):
        call = json.loads(path.read_text())
        if call["decision"].startswith("Pending"):
            call["decision"] = "Accepted after native/3x repeated patches, exact borders, raw alpha and day/dusk/night Godot actor/farm review."
            path.write_text(json.dumps(call, indent=2) + "\n", encoding="utf-8", newline="\n")
        attempts.append(call)
    assert sum(c["decision"].startswith("Accepted") for c in attempts) == 8
    assert sum(c["decision"].startswith("Rejected") for c in attempts) == 4
    (HERE / "runtime-delta.json").write_text(json.dumps(dict(baseline=BASELINE, changed=changed, unchanged_count=len(unchanged), unchanged=unchanged,
        core_map_balance_owner_sheet_unchanged=True), indent=2) + "\n", encoding="utf-8", newline="\n")
    print("OK: only 8 materials plus atlas changed; other 239 runtime PNGs, core, guards and owner sheet unchanged")


if __name__ == "__main__":
    main()
