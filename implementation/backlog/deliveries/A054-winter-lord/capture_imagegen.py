"""Archive a built-in ImageGen return without altering its bytes."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil
import sys

D = Path(__file__).resolve().parent
request_path = D / sys.argv[1]
request = json.loads(request_path.read_text(encoding="utf-8"))
name = request_path.name.removesuffix(".request.json")
source = Path(request["returned_path"])
output = D / "raw" / (name + ".png")
if output.exists():
    assert output.read_bytes() == source.read_bytes(), "Existing source differs"
else:
    shutil.copy2(source, output)
(D / "raw" / (name + ".prompt.txt")).write_text(request["arguments"]["prompt"], encoding="utf-8")
refs = [{"path": path, "sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest(), "role": role}
        for path, role in zip(request["arguments"]["referenced_image_paths"], request["roles"])]
im = Image.open(output).convert("RGBA")
mask = im.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
bounds = mask.getbbox()
receipt = {**request, "input_images": refs, "copied_path": output.relative_to(D).as_posix(),
           "sha256": hashlib.sha256(output.read_bytes()).hexdigest(), "decision": "pending inspection",
           "inspection": {"canvas_wh": list(im.size), "alpha_extrema": list(im.getchannel("A").getextrema()),
                          "alpha_threshold_128_bounds": list(bounds) if bounds else None}}
(D / "raw" / (name + ".call.json")).write_text(json.dumps(receipt, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps(receipt["inspection"]))
