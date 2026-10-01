"""Verify accepted ground sources, seamless native tiles and every atlas cell."""
import sys
from PIL import Image
import art_ownership
import import_art
import gen_sprites

NAMES = ("grass", "grass_b", "grass_c", "grass_d", "soil", "path", "floor", "rock")


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
                if name in NAMES:
                    tile = atlas.crop((column*16, row*16, column*16+16, row*16+16))
                    if tile.tobytes() != images["terrain/" + name].tobytes():
                        raise ValueError("Atlas cell differs from raw source: " + name)
                    contributed += 1
    if contributed != 9:
        raise ValueError("Migrated terrain atlas contribution count moved")
    print("OK: 8 accepted seamless materials; 9 raster atlas cells; all 80 cells source-exact; mixed grass borders match")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print("FAIL: " + str(error))
        sys.exit(1)
