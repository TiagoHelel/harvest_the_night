"""Validate A003's porch guardian (task 0145): four states on its fixed post.

Twelve frames on 32x48 standing on (16,44), drawn at 1.0: `day` (one, still),
`wake` (four, once), `night` (four, round and round) and `point` (three, once).
Every one is A003's approved composition promoted as one - parts of its
component DAG, at most five a node, no source of its own - and decodes to its
approved native export. The post's foot is on the pivot row and the post below
the shirt never moves; the eyes are lit from the wake's second frame on, two
`flame_hot` pixels exactly on that frame's `lights_xy` (the first its
`light_xy`), and nothing else on the scarecrow is that hot.
"""
import hashlib
from pathlib import Path
import import_art
import palette

STATES = {"guardian_day": (1, 1, False), "guardian_wake": (4, 0.12, False),
          "guardian_night": (4, 0.25, True), "guardian_point": (3, 0.1, False)}
CANVAS, PIVOT = [32, 48], [16, 44]
## The rows under the shirt: the post and its foot, the same on every frame.
POST_ROWS = range(32, 48)


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    by_id = {e["id"]: e for e in data["assets"]}
    hot = palette.COLOURS["flame_hot"]
    post = None
    lit = 0
    for name, (count, seconds, loop) in STATES.items():
        frames = sorted((e for e in data["assets"] if e["id"].rsplit("_", 1)[0] == "props/" + name), key=lambda e: e["frame"])
        if [e["frame"] for e in frames] != list(range(count)):
            raise ValueError("Missing guardian frame: " + name)
        for e in frames:
            if e.get("generation_task") != "A003" or e.get("integration_task") != "0145" \
                    or e["canvas_wh"] != CANVAS or e["pivot_xy"] != PIVOT or e.get("draw_scale", 1) != 1 \
                    or e["seconds"] != seconds or e["loop"] is not loop:
                raise ValueError("Guardian frame drift: " + e["id"])
            if e.get("operation") != "compose" or "source" in e or not 1 <= len(e["parts"]) <= 5:
                raise ValueError("A layered frame not promoted as its composition: " + e["id"])
            for part in e["parts"]:
                if by_id[part["input"]].get("assembly_component_of") != "A003":
                    raise ValueError("A part from outside A003's assembly: " + e["id"])
            native = next(r for r in e["references"] if r["path"].endswith(".png"))
            if hashlib.sha256(Path(import_art.ROOT / native["path"]).read_bytes()).hexdigest() != native["sha256"]:
                raise ValueError("Approved export changed: " + native["path"])
            image = images[e["id"]]
            if image.getbbox()[3] != PIVOT[1]:
                raise ValueError("Not standing on its post's foot: " + e["id"])
            rows = image.crop((0, POST_ROWS[0], CANVAS[0], POST_ROWS[-1] + 1)).tobytes()
            if post is None:
                post = rows
            elif rows != post:
                raise ValueError("The post moved: " + e["id"])
            awake = not (name == "guardian_day" or (name == "guardian_wake" and e["frame"] == 0))
            points = e.get("lights_xy", [])
            glowing = [(x, y) for y in range(CANVAS[1]) for x in range(CANVAS[0])
                       if image.getpixel((x, y))[3] and image.getpixel((x, y))[:3] == hot]
            if awake != bool(points) or ("light_xy" in e) != awake:
                raise ValueError("Eyes lit on the wrong frame: " + e["id"])
            if awake and (len(points) != 2 or e["light_xy"] != points[0] or points[0][0] >= points[1][0]
                          or sorted(map(tuple, points)) != sorted(glowing)):
                raise ValueError("The eyes are not the frame's two hot pixels: " + e["id"])
            if not awake and glowing:
                raise ValueError("A hot pixel on an unlit frame: " + e["id"])
            if (import_art.ROOT / e["output"]).read_bytes() != files[e["output"]]:
                raise ValueError("Runtime frame out of date: " + e["output"])
            lit += awake
    components = [e for e in data["assets"] if e.get("assembly_component_of") == "A003"]
    print("OK: 12 guardian frames in four states, %d lit with two eye points each; fixed post; "
          "%d assembly components, every frame its approved composition" % (lit, len(components)))


if __name__ == "__main__":
    main()
