"""Single output ownership, shared by every sprite writer and checker."""
import json
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "assets/art_source/ownership.json"
OWNERS = {"ascii", "player_sheet", "raster"}


def project_path(value, prefix=None):
    if not isinstance(value, str):
        raise ValueError("Project path must be a string")
    path = PurePosixPath(value)
    if "\\" in value or path.is_absolute() \
            or ".." in path.parts or ":" in value or str(path) != value:
        raise ValueError("Invalid project path: %r" % value)
    if prefix and not value.startswith(prefix + "/"):
        raise ValueError("Path must be inside %s: %s" % (prefix, value))
    return ROOT / value


def registry():
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    if data.get("version") != 1:
        raise ValueError("Unsupported ownership version")
    result = {}
    for entry in data["outputs"]:
        output, owner = entry["output"], entry["owner"]
        project_path(output, "sprites")
        if output in result or owner not in OWNERS:
            raise ValueError("Duplicate or invalid owner: " + output)
        result[output] = owner
    return result


def owned(files, owner, prefix="sprites"):
    owners = registry()
    result = {}
    for path, data in files.items():
        full = prefix + "/" + path
        if full not in owners:
            raise ValueError("Unregistered sprite: " + full)
        if owners[full] == owner:
            result[path] = data
    return result
