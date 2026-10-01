"""Validate complete source-owned prop species, variants, alpha and contacts."""
import sys
import art_ownership
import import_art

NAMES = ("tree", "tree_b", "stump", "rock", "rock_b", "seam", "seam_b", "ore", "ore_b", "cow", "chicken")


def validate_shape(image, name, canvas, pivot):
    if image.size != tuple(canvas) or image.getbbox() is None:
        raise ValueError("Missing prop silhouette/canvas: " + name)
    x0,y0,x1,y1 = image.getbbox()
    if x0 < 1 or y0 < 1 or x1 >= canvas[0] or y1 != pivot[1] or y1 >= canvas[1]:
        raise ValueError("Clipped or ungrounded prop: " + name)
    if {p[3] for p in import_art.samples(image)} != {0,255}:
        raise ValueError("Prop alpha must be clean binary transparency: " + name)
    lit = {(x,y) for y in range(image.height) for x in range(image.width) if image.getpixel((x,y))[3]}
    seen, active = {next(iter(lit))}, [next(iter(lit))]
    while active:
        x,y = active.pop()
        for dx in (-1,0,1):
            for dy in (-1,0,1):
                neighbor = x+dx,y+dy
                if neighbor in lit and neighbor not in seen:
                    seen.add(neighbor)
                    active.append(neighbor)
    if lit != seen:
        raise ValueError("Detached prop pixels: " + name)


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e["id"]:e for e in data["assets"]}
    owners = art_ownership.registry()
    for name in NAMES:
        key = "props/"+name
        entry = entries[key]
        if owners[entry["output"]] != "raster" or "source" not in entry:
            raise ValueError("Prop lacks its accepted raw species/material source: " + name)
        if (art_ownership.ROOT/entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Prop differs from the accepted source: " + name)
        canvas,pivot = ([40,48],[20,44]) if name.startswith("tree") else (([24,24],[12,22]) if name in ("cow","chicken") else ([16,16],[8,14]))
        if entry["canvas_wh"] != canvas or entry["pivot_xy"] != pivot:
            raise ValueError("Native prop contract drift: " + name)
        validate_shape(images[key],name,canvas,pivot)
    for kind in ("tree","rock","seam","ore"):
        a,b = entries["props/"+kind],entries["props/"+kind+"_b"]
        if a["content_scale"] != b["content_scale"] or images[a["id"]].tobytes() == images[b["id"]].tobytes():
            raise ValueError("Variant scale drift or duplicate shape: " + kind)
    print("OK: 11 source-owned props; 4 distinct same-scale variants; clean silhouettes and exact ground pivots")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyError,ValueError,OSError) as error:
        print("FAIL: " + str(error))
        sys.exit(1)
