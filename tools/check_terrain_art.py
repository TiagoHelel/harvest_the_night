"""Verify accepted ground sources, seamless native tiles and every atlas cell."""
import sys
from PIL import Image
import art_ownership
import import_art
import gen_sprites

NAMES = ("grass", "grass_b", "grass_c", "grass_d", "soil", "path", "floor", "rock")
WATER = ("water", "water_b", "water_c")


def validate_side(image, name):
    # Inspect north masters before their exact clockwise rotations.
    if image.size != (16, 16) or image.getbbox() is None or image.getbbox()[0] != 0 or image.getbbox()[1] != 0 or image.getbbox()[2] != 16 or image.getbbox()[3] > 4:
        raise ValueError("Edge must be a shallow top-attached full-width band: " + name)
    left, right, top, bottom = borders(image)
    if left != right or any(p[3] != 255 for p in top) or any(p[3] for p in bottom):
        raise ValueError("Edge endpoints/boundary do not join: " + name)
    lit = {(x, y) for y in range(16) for x in range(16) if image.getpixel((x,y))[3]}
    seen, active = {(0,0)}, [(0,0)]
    while active:
        x,y = active.pop()
        for neighbor in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if neighbor in lit and neighbor not in seen:
                seen.add(neighbor)
                active.append(neighbor)
    if lit != seen:
        raise ValueError("Detached swimming edge pixels: " + name)


def validate_corner(image, side, name):
    # Incoming boundaries must be the exact same profile as the straight bank.
    profile = borders(side)[0]
    if image.size != (16,16) or borders(image)[0] != profile or borders(image)[2] != profile:
        raise ValueError("Corner incoming profiles differ from its source-owned edge: " + name)
    if image.getbbox() is None or image.getbbox()[0:2] != (0,0) or max(image.getbbox()[2:]) > 4:
        raise ValueError("Corner is missing, detached or too large: " + name)


def borders(image):
    return (tuple(image.getpixel((0, y)) for y in range(16)),
            tuple(image.getpixel((15, y)) for y in range(16)),
            tuple(image.getpixel((x, 0)) for x in range(16)),
            tuple(image.getpixel((x, 15)) for x in range(16)))


def validate_tile(image, name):
    if image.size != (16, 16) or image.getchannel("A").getextrema() != (255, 255):
        raise ValueError("Terrain must be fully opaque 16x16: " + name)
    left, right, top, bottom = borders(image)
    if left != right or top != bottom:
        raise ValueError("Opposite terrain borders differ: " + name)


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e["id"]: e for e in data["assets"]}
    owners = art_ownership.registry()
    for entry in data["assets"]:
        if entry.get("generation_task") == "0008" and (art_ownership.ROOT / entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Runtime water/transition differs from its accepted source: " + entry["id"])
    for name in NAMES:
        key = "terrain/" + name
        entry = entries[key]
        if "source" not in entry or owners[entry["output"]] != "raster":
            raise ValueError("Material lacks accepted raw source ownership: " + key)
        validate_tile(images[key], name)
        if (art_ownership.ROOT / entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Runtime tile differs from accepted source: " + key)
    if len({images["terrain/" + n].tobytes() for n in NAMES}) != len(NAMES):
        raise ValueError("Materials/grass variations must remain distinct")
    base = borders(images["terrain/grass"])
    if any(borders(images["terrain/" + n]) != base for n in NAMES[1:4]):
        raise ValueError("Mixed grass variations have different boundary colors")
    for name in WATER:
        entry = entries["terrain/" + name]
        if "source" not in entry or owners[entry["output"]] != "raster":
            raise ValueError("Water lacks an accepted raw source: " + name)
        image = images["terrain/" + name]
        validate_tile(image, name)
        if borders(image) != borders(images["terrain/water"]):
            raise ValueError("Water frame borders differ")
        base_color = image.getpixel((0,0))
        if sum(p == base_color for p in import_art.samples(image)) < 240:
            raise ValueError("Water ripples overwhelm the calm native surface")
    if len({images["terrain/" + n].tobytes() for n in WATER}) != 3:
        raise ValueError("Water requires three distinct restrained native phases")
    for prefix in ("edge", "shore"):
        north = images["terrain/" + prefix + "_n"]
        validate_side(north, prefix)
        cap = images["terrain/" + prefix + "_corner_nw"]
        validate_corner(cap, north, prefix)
        for turns, suffix in enumerate(("e", "s", "w"),1):
            image = images["terrain/" + prefix + "_" + suffix]
            expected = north.transpose({1:Image.Transpose.ROTATE_270,2:Image.Transpose.ROTATE_180,3:Image.Transpose.ROTATE_90}[turns])
            if image.tobytes() != expected.tobytes():
                raise ValueError("Cardinal side rotation drift: " + prefix + suffix)
        for turns, suffix in enumerate(("ne", "se", "sw"),1):
            expected = cap.transpose({1:Image.Transpose.ROTATE_270,2:Image.Transpose.ROTATE_180,3:Image.Transpose.ROTATE_90}[turns])
            if images["terrain/" + prefix + "_corner_" + suffix].tobytes() != expected.tobytes():
                raise ValueError("Corner rotation drift: " + prefix + suffix)
    if gen_sprites.ATLAS_ROWS != [["grass", "soil", "water", "rock", "path", "floor"],
                                  ["water", "water_b", "water_c"], list(NAMES[:4])]:
        raise ValueError("Terrain enum/animation/variation row contract moved")
    width, height, pixels = gen_sprites.build_atlas()
    expected = gen_sprites.png_bytes(width, height, pixels)
    path = art_ownership.ROOT / "sprites/terrain/atlas.png"
    if (width, height) != (256, 80) or path.read_bytes() != expected:
        raise ValueError("Terrain atlas is missing/stale/tampered")
    with Image.open(path) as atlas:
        atlas = atlas.convert("RGBA")
        contributed = 0
        for row, names in enumerate(gen_sprites.ATLAS_ROWS):
            for column, name in enumerate(names):
                if name in NAMES + WATER:
                    tile = atlas.crop((column*16, row*16, column*16+16, row*16+16))
                    if tile.tobytes() != images["terrain/" + name].tobytes():
                        raise ValueError("Atlas cell differs from raw source: " + name)
                    contributed += 1
        for prefix, start in gen_sprites.CORNER_START.items():
            for index, corner in enumerate(gen_sprites.CORNER_ORDER):
                tile = atlas.crop(((start+index)*16,0,(start+index+1)*16,16))
                if tile.tobytes() != images["terrain/"+prefix+"_corner_"+corner].tobytes():
                    raise ValueError("Atlas corner differs from source-owned cap")
                contributed += 1
    if contributed != 21:
        raise ValueError("Migrated terrain atlas contribution count moved")
    print("OK: 8 seamless materials; 3 distinct water phases; 8 static sides; 8 exact corner caps; 21 raster atlas cells; all 80 cells source-exact")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print("FAIL: " + str(error))
        sys.exit(1)
