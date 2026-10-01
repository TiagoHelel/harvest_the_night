"""Assemble exact family briefs and preserve source/reference roles."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BRIEFS = (HERE / "PROMPTS.md").read_text(encoding="utf-8")


def section(name):
    return re.search(r"## " + name + r"\n\n```text\n(.*?)\n```", BRIEFS, re.S)[1]


def prompt(ident, family, primary, wh, pivot, references, detail):
    base = section("BASE")
    substitutions = [primary, references, str(wh[0]), str(wh[1]), str(pivot[0]), str(pivot[1]), "genuinely transparent background for this isolated sprite"]
    for value in substitutions:
        base = re.sub(r"\{[^{}]*\}", lambda _: value, base, count=1)
    if family == "TREE":
        brief = section(family).replace("{full tree/stump}", "a full tree variation" if ident == "tree_b" else "a cut stump")
    elif family == "ANIMAL":
        brief = section(family).replace("{cow/chicken}", ident)
    else:
        material = {"rock":"stone boulder", "seam":"stone seam", "ore":"iron ore"}[ident.removesuffix("_b")]
        brief = section(family).replace("{stone boulder/stone seam/iron ore}", material).replace("{16x16 or 32x24}", "16x16")
    text = base + "\n\n" + family + " brief:\n" + brief + "\n\nExact asset contract:\n" + detail + "\n"
    assert "{" not in text
    (HERE / ("0009-" + ident + ".prompt.txt")).write_text(text, encoding="utf-8", newline="\n")


def main():
    style = "Image 1: approved neutral-day scene for material/camera reference only."
    prompt("tree_b", "TREE", "props/tree_b, a second full-canopy variation of the approved tree; edit Image 1", [40,48], [20,44], "Image 1: approved full tree, EDIT TARGET and identity/scale master; Image 2: neutral-day scene, style reference only.", "Change only the broad canopy lobe arrangement into a slightly rounder, asymmetrical crown with two grouped upper-left highlights. Preserve the same deciduous species, original warm branching trunk and roots, trunk width, exact root contact and object scale. Same broad lush green canopy and 36x42 native visible body, 40x48 canvas, contact (20,44). Keep all bark/root pixels below the lowest leaves unchanged. Neutral upper-left daylight, darker lower-right foliage. Preserve true alpha; remove no roots, add no ground shadow, grass, fruit or flowers. Keep the complete tree, camera, original canvas size and margin; do not zoom or add another tree. The different crown must remain visible after reduction to 36x42 pixels; avoid microleaf noise.")
    prompt("stump", "TREE", "props/stump, one low cut stump matching the approved tree trunk; create a new isolated object", [16,16], [8,14], "Image 1: approved full tree, reference for exact bark species/root color and trunk width only; Image 2: neutral-day scene for camera/material reference. Neither is an edit target.", "One low cut stump with the same ochre/brown trunk bark and four compact splayed roots as the tree. Cut the trunk below its branching fork, showing an elliptical pale warm wood top with ONE broad curved ring and one short dark notch, no detailed tiny rings. Downstream visible bounds about 14x10 native pixels, fitting a 16x16 canvas with contact (8,14). Trunk thickness should match the approved tree's lower trunk, about 5 native pixels, with roots spanning about 14 pixels. Full object centered, no leaves, axe, logs, detached chips, ground, shadow or grass. Its roots rest on one common baseline.")
    for material in ("rock", "seam", "ore"):
        details = {
            "rock":"A loose low BOULDER: two joined rounded angular gray masses, a broad light upper-left face and darker lower-right plane. About 14x11 visible native pixels. Asymmetric rounded contour; no horizontal stratification, mineral vein or loose scattered pebbles.",
            "seam":"A low naturally layered STONE SEAM embedded in the rock face: one wider flat irregular outcrop with TWO broad horizontal gray strata and a stepped low contour. About 14x12 visible native pixels. No square brick/tile framing, masonry, golden flecks, mound or fantasy crystal. The strata, not tiny surface grain, distinguish it from loose boulders.",
            "ore":"A compact IRON ORE node: a dark angular gray host rock with exactly TWO chunky restrained ochre metallic mineral veins on its visible front/top planes, clearly readable after native reduction. About 14x12 visible native pixels. Mineral colors #a8742c/#c49646/#d6ba60 against stone #52505c/#6e6c78/#8c8a96. No luminous gold glow, gem crystal spikes, white glitter, scattered tiny dots or horizontal stone strata. The warm joined mineral clusters distinguish iron from stone without a label."
        }
        common = " Native canvas 16x16, contact (8,14); complete isolated centered object with clear two-pixel empty margin where possible. Restrained gray stone #52505c/#6e6c78/#8c8a96, colored dark underside outline #241f2e. Upper-left neutral light. Genuinely transparent outside the silhouette, no baked shadow, backdrop, ground plate, grass or other objects. Broad deliberate joined pixel clusters, no texture noise."
        prompt(material,"RESOURCE_PROP","props/"+material+", one distinct natural resource master",[16,16],[8,14],style+" Image 2: accepted quiet natural rock terrain for gray palette/material contrast only. Neither is an edit target.",details[material]+common)
        prompt(material+"_b","RESOURCE_PROP","props/"+material+"_b, second controlled visual variation of the same resource",[16,16],[8,14],"Image 1: accepted "+material+" master, EDIT TARGET; Image 2: approved neutral-day style reference. Preserve the existing material, camera and lighting.","Change only the contour and arrangement of the same identifying masses/strata/veins into a second asymmetrical shape. Keep the species/material and the same body size, ground baseline, camera, upper-left light, limited palette, transparent canvas and broad readable clusters. "+details[material]+common+" Do not mirror lighting, zoom, shrink or add ground; no new resource type.")
    prompt("cow","ANIMAL","props/cow, one recognizable standing farm cow",[24,24],[12,22],style+" Image 2: repository reference sheet for the existing cow's species/markings only; not an edit target.","One compact realistic farm cow, side-on three-quarter top-down camera, head facing LEFT; body length about 22 native pixels and height about 17-18 including hooves on a 24x24 target canvas, contact (12,22). Cream-white stocky horizontal torso with TWO broad dark brown/near-black patches, small clear muzzle, two short horns/ears, four ordinary short legs (far legs visible only partly), compact udder and one tail. Broad grouped shading. Neutral upper-left daylight, colored outlines, no glow or baked ground shadow. Keep normal cattle proportions: long body, small head, no huge mascot eyes, accessories, bell, collar, grass or backdrop. Hooves share one baseline; all parts unclipped. Isolated centered complete cow on true transparent alpha.")
    prompt("chicken","ANIMAL","props/chicken, one recognizable standing farm hen",[24,24],[12,22],style+" Image 2: repository reference sheet for existing chicken's species only; not an edit target.","One compact cream-white hen, three-quarter top-down camera, head facing LEFT. Visible body about 12x12 native pixels including thin ochre legs, on a 24x24 canvas with contact (12,22): much smaller than the cow. Rounded feathers, a clear tiny ochre beak, red comb and wattle, one dark eye, simple raised fan tail and TWO ordinary thin legs on the same baseline. Broad off-white feather clusters with a light brown underside; colored dark outline. No rooster's long tail, wing pose, egg, chick, accessories, big mascot head, grass, ground shadow or backdrop. Complete isolated centered hen on true transparent alpha, neutral upper-left daylight. These identifying forms must survive 12x12 reduction.")
    (HERE / "0009-plan.json").write_text(json.dumps(dict(date="2026-10-01",task="0009",baseline="9cddbfd",preserved_tree="assets/art_source/masters/tree.png",generated=["tree_b","stump","rock","rock_b","seam","seam_b","ore","ore_b","cow","chicken"],variants="tree/rock/seam/ore: fixed cell hash only; no simulation RNG",no_decorative_animation=True),indent=2)+"\n",encoding="utf-8",newline="\n")
    print("Saved 10 exact prompts and the task contract")


if __name__ == "__main__":
    main()
