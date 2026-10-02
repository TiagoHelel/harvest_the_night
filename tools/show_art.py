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
    script = "atmosphere_showcase.gd" if "--atmosphere" in args else "ui_art_showcase.gd" if "--ui" in args else "effect_showcase.gd" if "--effects" in args else "giant_showcase.gd" if "--giant" in args else "enemy_showcase.gd" if "--enemies" in args else "barrier_showcase.gd" if "--barriers" in args else "tower_showcase.gd" if "--towers" in args else "art_showcase.gd"
    command = [verify.GODOT, "--path", ".", "--fixed-fps", str(FIXED_FPS), *flags,
               "--script", "res://src/tools/" + script, "--", *args]
    code, output = verify.run(command, timeout=180)
    print(output)
    return code or (1 if re.search(r"SCRIPT ERROR:|^ERROR:", output, re.M) else 0)


if __name__ == "__main__":
    sys.exit(main())
