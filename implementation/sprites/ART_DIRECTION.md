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

Task 0007 accepts the four existing grass choices and soil/path/floor/rock at
16x16. Grass keeps the weighted distribution and shared olive boundary color,
with only 2.0-6.2 percent interior clustered texture. Soil/path stay dark/light
brown, with 1.2/0.8 percent joined surface marks. Horizontal timber plank joins
survive reduction and continue across adjacent dock tiles. Natural gray rock
has sparse irregular flecks, replacing the old rectangular masonry. These
materials deliberately stay calm below actors; no decorative flower or extra
walkability variant is introduced. Exact measurements and runtime lighting
reviews are in `reviews/0007/`. Water and transitions remain task 0008.

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

Task 0008's accepted water is a quiet flat blue field with two restrained
horizontal ripple clusters: 98.0-98.4% native base coverage, one-pixel horizontal
motion and a dim returning phase at 550 ms per frame. Keep the outer two native
pixels calm in every phase. Banks are static, narrow green/earth bands with
matching endpoint colors; grass fringes remain one row with a small attached
tuft. Corner caps continue these exact profiles. Timber planks must stay readable
across water without foam, bright borders or moving bank pixels.

Task 0009 keeps the pilot's broad full-canopy tree and introduces a rounder
second crown on the same scale/ground pivot. The canopy's measured visible
height varies by one native pixel (42/43) while its source reduction scale stays
identical. Stumps match its warm bark, roots and a single readable cut ring.
Loose stone has rounded angular masses; stone seams are lower layered shelves;
iron has joined restrained ochre mineral veins. These cues survive 16px output.
The cow has a long cream body with dark patches, muzzle and short legs; the
smaller hen has compact feathers, comb and beak. Preserve normal silhouettes,
transparent margins, shared upper-left light and stable feet. Static variation
is cosmetic and selected by cell; tree/animal movement remains optional.

Task 0010 gives each species four progressively larger authored stages on the
same native scale. Planted kernels remain small; sprouts never fill a mature
canvas. Wheat ripens into a slim golden head cluster; corn has the tallest
upright stalk, broad separated leaves, cobs and tassel; carrot stays low with
feathery foliage and visible orange shoulders. The growth frame is selected by
existing Farming.stage, with no decorative sway in this task.

Keep dry/wet soil as the same joined furrow material with a clearly darker wet
shadow ramp. Both must remain visible beneath foliage. Wheat/carrot contacts
are (8,14) on 16x16; every corn stage uses (8,22) on 16x24, allowing a four-pixel
upper overhang while preserving side margins and neighboring row visibility.
Plants remain on the existing walkable ground layer beneath actors. Their
distinct ready shapes must survive the production night shader; shared night
palette/emission unification remains task 0019.

Task 0011 refines the full farmhouse into one terracotta/timber landmark.
Its whole and independently authored damaged states share the 64x64 canvas,
(32,60) contact and one source reduction scale over the unchanged 3x3 logical
footprint. Roof loss concentrates on the left slope with exposed rafters and
local facade wear. Keep the right chimney, front steps and five warm panes
recognizable in both states. Native visible bounds are 56x55, larger than the
30px farmer and 42/43px trees. Five localized night glows follow the actual
glass rather than lighting the center of the entire roof.

Task 0012 extends those materials to six recognizable farm stations. Workshop
shows its tools/bench and right furnace; kitchen has cookware and a broad
front oven; press is an open timber screw/lever machine; generator is a low
metal engine with flywheel, exhaust and blue indicator. Shop has a blue/cream
awning and open counter; well has a round stone rim, timber hoist and bucket.
The four production stations use 48x48/(24,44), shop 32x40/(16,36), well
24x32/(12,30). They remain subordinate to the 64x64 farmhouse landmark.

Independent idle/active/hurt drawings share one source reduction scale per
production family. Existing paid-job/fuel state selects an authored working
pose; this is bounded state feedback, not a continuous multi-frame loop.
Structural damage takes precedence over that pose. Real working furnace
glows/exhaust can still communicate activity on a damaged station. Idle and
stalled jobs must never acquire active art, smoke or a false working glow.
Keep native glow/exhaust points on the actual accepted furnace/indicator and
chimney pixels. Full station drawings replace repeated quarter miniatures,
while compatibility quarters remain exact slices of their complete idle form.

Task 0013 replaces all four tower families at three levels. Gun progresses
from open timber trestle to a joined stone footing/heavier receiver and then
a solid stone/iron pedestal with two separate barrels. Flame progresses from
upright tank/pipe to a geared reinforced base and a broad horizontal copper
tank. Mortar stays a low, upward-angled tube with increasingly heavy collar,
brace and geared carriage. Crossbow retains curved limbs/string/rail while
gaining an automatic feed and reinforced pedestal. Levels change construction;
they never repeat old post bands or colored level pips.

All 48 whole/hurt/fire/wreck drawings use 32x48/(16,44) over one logical cell.
Each level shares one fixed source scale across its four independent poses.
Fire cues stay small: two gun mouths at L3, a short flame jet, mortar mouth
flash and released crossbow string/tiny bolt. Muzzle metadata follows the actual
opaque fire pose. Local glow/sparks and the visual launch use that same point.
Wear changes braces/armor/mechanisms; wrecks collapse onto the ground. Existing
fire-over-wear priority remains. These are authored event/state poses, not a
continuous recoil animation. Final atmosphere tuning remains task 0019.

Task 0014 connects grey masonry and iron-banded timber from actual occupied
neighbors. Taller posts establish ground contacts; front spans show joined
stone courses or two timber rails. North/south spans use the narrow top/side
projection and overlap only the connected cells. Each material shares one
physical scale across all selected raw modules and damage states. All sixteen
cardinal masks share 16x32/(8,28), with no post in an unoccupied neighbor.

Broken states chip posts, expose a displaced stone and snap the far-side rail;
the center post must not conceal the entire break. Ruins are low piles on the
actual destroyed cells and never create decorative blocking. Barricades remain
rough timber braces on 16x24/(8,20). The 16x16/(8,14) mine is a low steel disc
with a restrained red pressure plate, a short source-authored trigger spark
and a split spent casing. Plot foliage may coexist under the disc by the
original placement rules; every actor's boots remain above it. Source alpha
conversion removes low-opacity edge haze, not creative source features.

These are authored join/damage/outcome states. Mines have a short one-shot
presentation cue; no continuous barrier or trap animation is claimed. The
normal enemy family remains 0015, Giant/death playback 0016 and common final
night atmosphere 0019.

Task 0015 gives walker, runner, tank and breaker authored 4/3/4 motion on
64x48 canvases with pivot (32,44). Their visible standing bodies remain about
29 pixels high, near the owner's farmer. Transparent pose clearance is not
body size. Preserve these finished sources and drawings during later tuning.

Task 0016 gives Giant a 43x42 visible master, oversized fists, bare mottled
skin, asymmetric shoulder growth and ragged shorts. Four steps, three raised
arm preparations, three contact/recovery poses and five collapse poses share
80x64/(40,60). The extra sixteen transparent columns beyond the planned 64x64
envelope accommodate the contact fist while keeping the feet on the same
ground pivot; they do not enlarge the standing body or change its map cell.
Scale stays fixed within each strip. Wind-up grows from 39 to 48 to 55 visible
pixels as the arm rises. Death collapses from 39 to 16 visible pixels.

The existing target ring belongs above the boss and house roof so neither
can conceal a real warning. Its target and timing still come from core.
Death uses the last observed position, once, with a hard cap of 24 cosmetic
sprites; it never preserves a dead entity or changes hits/pathing. Ordinary
death drawings come unchanged from 0015. Shared night tuning remains 0019
and should use the accepted art rather than regenerate completed families.
