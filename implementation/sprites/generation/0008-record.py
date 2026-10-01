"""Preserve returned ImageGen files and exact provenance without creative edits."""
from pathlib import Path
import hashlib
import json
import shutil
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
def main():
    calls = []
    for path in sorted(HERE.glob("0008-*-call.json")):
        call = json.loads(path.read_text(encoding="utf-8"))
        source, returned = ROOT / call["source"], Path(call["returned_file"])
        source.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            shutil.copyfile(returned, source)
        assert source.read_bytes() == returned.read_bytes(), source
        call["source_sha256"] = hashlib.sha256(source.read_bytes()).hexdigest()
        prompt = HERE / ("0008-" + call["id"] + ".prompt.txt")
        assert prompt.read_text(encoding="utf-8").strip() == call["prompt_text"]
        calls.append(call)
    (HERE / "0008-generations.json").write_text(json.dumps({"date":"2026-10-01","attempts":calls},indent=2)+"\n",encoding="utf-8",newline="\n")
    print("OK: %d immutable sources and exact prompts preserved" % len(calls))
if __name__ == "__main__":
    main()
