# Art direction and review contract

## Direction

Detailed but readable pixel art: a small working farm, warm timber, terracotta
roofs, full foliage and cool water. At night the same forms become blue/violet
with localized amber windows and fire. Use `docs/reference-sheet.png` for
composition and materials; preserve the farmer's straw hat, work clothes and
recognizable identity from `docs/sprites_sem_fundo.png`.

One orthographic three-quarter top-down camera, showing roofs and front faces.
No diamond-shaped isometric grid. Light comes from upper left in the neutral
day art. Use clustered highlights and colored outlines, with darker outlines
on underside/contact areas. Avoid uniform black boxes, random one-pixel noise,
smooth painted gradients, blur and enlarged single-pixel placeholders.

## Scale contract — accepted source previews in 0001 and playable pilot in 0003

Keep 16x16 terrain cells, 40x18 world and 480x270 viewport with nearest filtering
and integer scaling. Do not raise the game resolution to accommodate generated
art. These are final native canvas targets, not claimed ImageGen output sizes.

| Family | Proposed native canvas | Placement |
|---|---|---|
| Ground and edge tiles | 16x16 | Exact cell, seamless edges |
| Farmer | 48x48, body about 28–32 px high | Feet at (24,44); tool clearance in remaining canvas |
| Standard enemies | 32x40, body about 24–32 px high | Feet at (16,36); tank/breaker silhouette varies |
| Giant | 64x64 | Feet at (32,60), distinct wind-up silhouette |
| Trees | 40x48 | Trunk contact at (20,44), one existing logical cell; 36x42 visible body |
| Rocks, stumps, ore | 16x16 or 32x24 | Anchor from manifest, keep logical footprint |
| Crops | 16x16, tall mature corn up to 16x24 | Ground base at cell bottom; review neighbor overlap |
| Animals | 24x24 | Feet/contact point, current logical cell |
| House | 64x64 | Existing 3x3 footprint (48x48); roof may overhang |
| Workshop/kitchen/press/generator | 48x48 | Existing 2x2 footprint (32x32) where applicable |
| Shop/well | 32x40 / 24x32 | Existing fixture footprint; no new collision cells |
| Towers | 32x48, same canvas for three levels | Existing one-cell base; barrels and overhang cosmetic |
| Walls/fences/barricades | 16x24 or 16x32 | Existing footprint with matched horizontal/vertical joins |
| Resource icons | 16x16, inspect at actual HUD display size | Clear main shape and generous interior spacing |

A transparent canvas is not the object's size. Compare visible body bounds and
feet, not only image width/height. Freeze final accepted anchors in the manifest
after the pilot. If 32 px actors obscure the field, adjust the shared scale in
the pilot before generating all animation families.

Task 0001 source review, 2026-10-01: farmer 20x30 visible pixels on 48x48,
house 56x55 on 64x64, tree 36x42 on 40x48, walker 16x29 on 32x40. The tree
canvas was widened from 32 to 40 to preserve the broad canopy's aspect ratio
without clipping or distortion. The 16 px logical footprint remains unchanged.
Exact accepted crops, native sizes, contact pivots and source hashes are in
`assets/art_source/masters/master-contract.json`. All animations of each
family must reuse its accepted body scale and canvas rather than refitting each
pose independently. Task 0003 accepts these proportions in the actual 480x270
farm, including farmer/walker overlap with both landmarks. The remaining 43
owner-sheet player poses are recut to the same 30 px body reference, 48x48
canvas and (24,44) contact while authored strips replace them in 0004–0006.
The house ground pivot is (32,60); its visual starts at (-8,-12) relative to
the unchanged 3x3 footprint. Trees and actors sort by ground contact. These
accepted canvases/pivots apply to future families; animation must not grow the
body or shift the planted feet to fill individual frame bounds.

Task 0004 accepts authored idle/walk for south/north/west, with east mirroring
west. Their visible height stays 30 px; width is 20–22 px across directions
and strides versus the static pilot's 20 px. This allows the hat and extended
limbs without changing canvas, contact, grid or collision. One measured scale
per strip applies to every frame; no pose is individually resized. Twenty-five
owner-sheet work/reaction frames remain at the pilot scale for 0005–0006.

Task 0005 accepts thirteen west work strips with four distinct frames each.
East mirrors west; north/south work intentionally uses the west side-on art.
No work verb borrows another gesture. The farmer's standing reference remains
30 px on 48x48 with feet (24,44); crouches bend naturally without per-pose resizing.
Tools, droplets and lines fit the common canvas. Source boot coordinates and
native anchors are measured separately from the complete silhouette bounds;
two rejected fishing candidates preserve the compact-rod revision history.
Carry is a brief visual response to a nearby real production delivery, not an
added carrying mechanic. Four original reaction poses remain for task 0006.

Task 0006 accepts four single south-facing reaction poses matching the same
30 px standing body, 48x48 canvas and feet (24,44). Bang, question, note and
heart remain the four existing kinds; heart is available art without adding
a gameplay trigger. Compact warm symbols float above/right of the crown.
Reaction selection and duration still belong to Reactions; the view suppresses
them during movement, work and work recovery. Source-owned glyph crops are
drawn separately only to keep them inside the viewport. The body's feet and
depth sorting do not change; its duplicate glyph is masked rather than drawn
twice. At a map edge the body can retain its existing natural viewport clip,
while the complete glyph stays inside a two-pixel margin.

The separate shared contact shadow uses 20x8 with a measured 18x3 opaque
silhouette, one palette color and binary alpha. It is intentionally shallow
under the 20–22 px farmer body, not stretched to the prompt's approximate 4 px
height. Existing 0.42 modulate, centered placement and -1 px ground offset stay
unchanged for player, trees and enemies. No body source contains a second shadow.

The four transparent identity masters and neutral-day/night scene studies live
in `assets/art_source/masters/`. The studies establish materials and lighting;
their illustrative object sizes are not authoritative runtime measurements.
Use the native `reviews/0001/scale-grid.png` and master contract for scale.
The scene studies are references, never a background replacement for the farm.
Future terrain should be quieter than the study's textured grass so actors and
interactive shapes remain prominent at 480x270.

The shared palette now has 42 colors: the original 36 unchanged, plus three
skin colors and three cloth-blue colors. This keeps the farmer's identity after
palette mapping while preserving existing world colors and light ramps.

## Palette and surface rules

Start from `tools/palette.py`: ink, grass, soil, water, stone, wood, leaf,
roof, gold, flame, bone, rot and night ramps. Task 0001 may refine the palette
as visual-only data. Use one approved runtime palette; do not change a ramp
inside `game_data.gd` or introduce a second independent palette table.

AI output does not guarantee exact colors or pixel lattice. Preserve the source
and use the import recipe to reduce to native resolution and approved palette.
Review the result before promoting it. Palette reduction must not erase a face,
crop stage, weapon barrel or silhouette. If it does, regenerate the source.

Ground has the lowest contrast, props next, interactive forms/actors highest.
The house is the farm's landmark. Fire, windows and muzzle cores are localized
warm highlights; crops must not become emissive under the night shader.

## Animation

Use fixed cell canvases, constant body scale and a stable foot anchor. Generate
one character identity master, then each direction/action as its own small
strip. Do not request the entire player and all work verbs on one enormous
sheet. Start with idle (3 frames) and walk (4 frames) for south/north/west;
east may mirror west if tool handedness remains coherent. Work cycles normally
use 4 frames: anticipation, contact, follow-through, recovery. Match existing
state-driven action timing; cosmetic durations live in the view layer.

Work anticipation holds while the existing action timer runs; contact starts
on its completion tick. Follow-through and recovery expire in the view. Their
maximum duration is 90 ms per frame, shortened to one quarter of a work cycle
for fast repeating repair. Instant water/reel/trade begin at contact, continue
through follow-through/recovery and return to ready. A movement/cancel removes
the cue immediately. At accelerated/catch-up speeds the render may sample fewer
frames than the simulation runs; observers still see every fixed tick and do
not change the core rates, durations, payloads or state.

Single-shot deaths finish and expire rather than looping forever. Enemy death
art requires view playback because the core removes the enemy immediately.

## Review gate for every family

- Inspect actual 480x270 game screenshots and a nearest-neighbor 3x preview.
- Check neutral day, dusk and night; the same farm must remain recognizable.
- Inspect source, alpha over light/dark/checkered ground and native output.
- Confirm consistent scale, perspective, outline and light with the pilot.
- Check every required state/level/verb; no missing texture or fallback.
- Check behind/in-front overlap and build preview versus actual footprint.
- Confirm animation doesn't move the feet or change body size.
- Confirm sprites communicate function without requiring text or health bars.

Record pass/fail and a concrete reason for each criterion. A visually poor
result is not done because the scripts passed. Allow at most three targeted
generation revisions per asset in one task; if still wrong, keep the existing
runtime art and record the specific unresolved cause before blocking the task.
