"""Copy actual built-in outputs and preserve exact prompts and source hashes."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    attempts = []
    for path in sorted(HERE.glob("0006-*-call.json")):
        attempt = json.loads(path.read_text(encoding="utf-8"))
        returned = Path(attempt["returned_file"])
        source = ROOT / attempt["source"]
        source.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            shutil.copyfile(returned, source)
        assert source.read_bytes() == returned.read_bytes(), str(source)
        attempt["source_sha256"] = hashlib.sha256(source.read_bytes()).hexdigest()
        prompt = HERE / ("0006-" + attempt["id"] + ".prompt.txt")
        assert prompt.read_text(encoding="utf-8").strip() == attempt["prompt_text"]
        attempts.append(attempt)
    (HERE / "0006-generations.json").write_text(
        json.dumps({"date": "2026-10-01", "attempts": attempts}, indent=2) + "\n",
        encoding="utf-8", newline="\n")
    print("Saved %d actual tool outputs and exact prompt records" % len(attempts))


if __name__ == "__main__":
    main()
