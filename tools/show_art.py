"""Capture deterministic native Godot art; --check is normally headless.

--tree-wind always renders, since its assertions compare actual trunk pixels.

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
    if "--visibility" in args:
        script = "visibility_showcase.gd"
    if "--house-visit" in args:
        script = "house_check.gd"
    if "--tree-wind" in args:
        script = "tree_wind_showcase.gd"
        flags = ["--position", WINDOW_AT]  # Pixel assertions require a real renderer.
    command = [verify.GODOT, "--path", verify.PROJECT_PATH, "--fixed-fps", str(FIXED_FPS), *flags,
               "--script", "res://src/tools/" + script, "--", *args]
    code, output = verify.run(command, timeout=180)
    print(output)
    return code or (1 if re.search(r"SCRIPT ERROR:|^ERROR:", output, re.M) else 0)


if __name__ == "__main__":
    sys.exit(main())
