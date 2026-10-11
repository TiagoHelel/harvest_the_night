"""Copy ImageGen return byte-for-byte and preserve exact request provenance."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

HERE=Path(__file__).resolve().parent
stem,returned,revision=sys.argv[1:4]
source=Path(returned)
output=HERE/f"raw/{stem}.png"
assert not output.exists()
shutil.copyfile(source,output)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(source)==sha(output)
arguments=json.loads((HERE/f"raw/{stem}.request.json").read_text())
def role(path):
    if "edit" in path: return "Exact complete-canvas pixel edit target"
    if "identity" in path or "idle" in path: return "Approved farmer identity and scale"
    if "guide" in path: return "Placement guide only; annotations never drawn"
    if "sleep-strip" in path: return "Accepted sleeping style, scale and continuity"
    if "death" in path: return "Low lying-body proportions only; never identity"
    return "Accepted pose style and scale reference"
call={"tool":"built-in ImageGen","arguments":arguments,
      "input_images":[{"path":p,"sha256":sha(p),"role":role(p)} for p in arguments["referenced_image_paths"]],
      "returned_file_path":str(source),"copied_raw_path":f"raw/{stem}.png","raw_sha256":sha(output),
      "date":"2026-10-07","revision":int(revision),"decision":"inspection pending"}
(HERE/f"raw/{stem}.call.json").write_text(json.dumps(call,indent=2)+"\n",encoding="utf-8")
from PIL import Image
im=Image.open(output)
print(json.dumps({"raw":str(output),"size":im.size,"mode":im.mode,"sha256":sha(output)}))
