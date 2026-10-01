"""Capture the deterministic native Godot art showcase; --check is headless.

python tools/show_art.py --out=implementation/shots/sprites/0003/showcase
python tools/show_art.py --check
"""
import sys
import re
import verify
from shot import FIXED_FPS, WINDOW_AT


def main():
    args = sys.argv[1:]
    flags = ["--headless"] if "--check" in args else ["--position", WINDOW_AT]
    command = [verify.GODOT, "--path", ".", "--fixed-fps", str(FIXED_FPS), *flags,
               "--script", "res://src/tools/art_showcase.gd", "--", *args]
    code, output = verify.run(command, timeout=180)
    print(output)
    return code or (1 if re.search(r"SCRIPT ERROR:|^ERROR:", output, re.M) else 0)


if __name__ == "__main__":
    sys.exit(main())
