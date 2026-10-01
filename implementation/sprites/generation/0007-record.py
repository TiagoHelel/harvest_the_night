"""Preserve actual built-in terrain sources and exact prompt provenance."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    attempts = []
    for path in sorted(HERE.glob("0007-*-call.json")):
        attempt = json.loads(path.read_text(encoding="utf-8"))
        returned, source = Path(attempt["returned_file"]), ROOT / attempt["source"]
        source.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            shutil.copyfile(returned, source)
        assert source.read_bytes() == returned.read_bytes(), source
        attempt["source_sha256"] = hashlib.sha256(source.read_bytes()).hexdigest()
        prompt = HERE / ("0007-" + attempt["id"] + ".prompt.txt")
        assert prompt.read_text(encoding="utf-8").strip() == attempt["prompt_text"]
        attempts.append(attempt)
    (HERE / "0007-generations.json").write_text(json.dumps({
        "date": "2026-10-01", "attempts": attempts}, indent=2) + "\n",
        encoding="utf-8", newline="\n")
    print("OK: %d actual built-in sources and exact prompts preserved" % len(attempts))


if __name__ == "__main__":
    main()
