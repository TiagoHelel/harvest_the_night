# Image generation prompts

These are production briefs, not a promise that generated pixels will already
match the exact grid, palette, canvas or frame layout. Measure every accepted
source and import using PIPELINE.md. Never cut a sheet using coordinates inferred
only from this prompt. Prefer one master or one short animation strip per call.

## How to assemble a request

Combine BASE with one family section below. Replace every brace variable with
the actual asset contract, attach/open the relevant reference images and record
the full assembled text beside the accepted source. For a strip also add STRIP.
Use the built-in ImageGen tool; `transparent_background` is a tool argument.
Do not add API model/size/path fields that the built-in tool does not expose.

For an isolated asset/strip set `transparent_background=true`. For a scene
study or fully opaque terrain patch set it to false. A painted checkerboard or
solid color background is not transparency. Inspect alpha before import.

## BASE

```text
Use case: stylized-concept
Asset type: production raster sprite source for HARVEST THE NIGHT, a cozy farm
that becomes a fortress against zombies at night.
Primary request: {specific object or animation, asset ID, required states}.
Input images: {Image 1: approved style reference; Image 2: identity/shape master;
Image 3 if applicable: edit target. Specify each role explicitly.}
Style/medium: coherent hand-crafted pixel art with deliberate pixel clusters,
colored outlines, restrained texture, readable material planes and clean forms.
Composition/framing: orthographic three-quarter top-down view on a rectangular
grid; match the approved master camera and scale. Final native canvas is
{width}x{height} pixels with contact pivot {x},{y}; this is a downstream import
target, so the generated source must remain simple enough to survive reduction.
Lighting/mood: neutral warm daytime, highlights from upper left, darker underside;
runtime supplies dusk/night lighting. Keep emission in separate localized forms.
Color palette: match the approved project palette and master, warm timber and
terracotta, layered greens, cool water, violet/blue shadows; limited ramps.
Scene/backdrop: {true transparent background for isolated sprites, or fully
opaque edge-to-edge material for terrain}. No baked ground shadow for actors.
Constraints: complete unclipped object, consistent perspective and scale, clear
ground contact, generous tool/weapon clearance, no labels, text, watermark or UI.
Avoid: smooth painting, vector look, 3D render, anti-aliased halos, blur, gradients,
random pixel speckle, thick black boxes, diamond isometric tiles, duplicate parts,
new gameplay objects, tiny details that disappear at native size.
```

## STRIP

```text
Generate exactly {N} sequential frames of {animation} for the SAME approved
character/object, in one horizontal strip, ordered {exact ordered poses}.
Use equal-size cells with {clear gutter} between them. No labels or separators.
Keep feet/contact point on the same baseline and centered at the same position
in every cell. Same body height, hat size, clothing, face and camera throughout.
Do not individually enlarge a smaller pose to fill its cell. Tools and limbs
must not cross into the next cell. Frame 1 and final frame form {loop/recovery}.
Output is an animation source, not a collage of different character designs.
```

## STYLE

```text
Create a compact visual-direction study using the repository reference sheet's
farm materials and atmosphere. Show one farmhouse, a full-canopy tree, the
straw-hat farmer and a walker at consistent proportions over 16 px logical
ground cells. Warm grass/path/soil/water; house is a clear landmark. Keep the
farmer roughly 28–32 native pixels tall, with readable face and clothes.
Study material/scale relationships, not a giant fantasy village. No typography,
infographic boxes or extra gameplay systems. This is a style study, not an atlas.
```

## PLAYER_MASTER

```text
Create one neutral south-facing farmer identity master, preserving the owner's
reference character: straw hat, dark hair, blue work clothes, warm face and boots.
Reinterpret in the approved game's pixel art style. Comfortable working stance,
empty hands, readable face, about 28–32 pixels body height on a 48x48 target
canvas, feet (24,44). Keep space for later tools and reactions. No ground shadow.
No costume redesign, extra bags/weapons or painting-style facial detail.
```

## PLAYER_STRIP

```text
Use the accepted farmer master. Direction: {south/north/west}. Action:
{idle/walk}. Idle: 3 frames of subtle breathing without changing hat silhouette
or foot location. Walk: 4 frames, left step/contact, passing, right step/contact,
passing. Keep the same identity and pixel scale; show the correct back of the
hat/clothes for north. Side master faces west; east may be mirrored downstream.
```

## PLAYER_WORK

```text
Use the accepted farmer master, side-facing work pose. Produce one four-frame
action strip for {verb}, with ordered anticipation, contact/action, follow-through
and recovery. Tool: {axe/pickaxe/hoe/seed hand/watering can/fishing rod/harvest
bundle/hammer/production hand movement}. Keep the body/feet anchored and tool
entirely inside the frame. {Specify the exact target/contact direction.}
For fishing separate cast and reel; for repair hammer down at the work point.
No tree, building or crop baked into the strip; those are separate world sprites.
```

## PLAYER_REACTION

```text
Use the accepted farmer identity and one neutral south-facing pose. Add one
small readable reaction over the head: {exclamation/question/music note/heart}.
Match the world pixel scale and keep the same body/feet as idle_south. Bubble
has a clear silhouette under day and night light, no painted glow. If it needs
more headroom, supply a separate bubble asset rather than shrinking the farmer.
The glyph is the only intentional symbol; no words or captions.
```

## TERRAIN

```text
Create one fully opaque tileable material for {grass/soil/path/wood floor/natural
rock}, designed for 16x16 native tiles. Low contrast beneath characters, grouped
surface texture, no obvious centerpiece. Grass uses occasional small clusters
with calm open areas, not a dot in every few pixels. Rock is irregular layered
stone, not brickwork. Wood planks align to the approved jetty/floor orientation.
Make opposite borders seamless. Variants must share boundary colors and density.
No scene objects, shadows, borders, perspective block or transparency.
```

## WATER

```text
Produce {one water master / one three-frame water loop / one named bank edge}.
Water is cool blue with restrained bright ripple clusters, fully opaque within
water tiles; subtle slow motion. Opposite borders match within and across all
frames. Banks use warm earth, short grass fringe and coherent water contact;
the bank overlay has true transparency outside the edge. Edge direction/mask:
{north/east/south/west and desired corner combinations}. No shore sliding
between frames, foam noise, diagonal island perspective or baked jetty.
```

## TREE

```text
Create {full tree/stump}, broad lush canopy with distinct shaded lower lobes,
sunlit upper-left clusters and a visible warm trunk. Full tree target 40x48,
visible body 36x42, trunk contact (20,44), as accepted in task 0001. Stump must match
the same trunk species/width and show the cut surface. No ground tile, grass
patch or painted drop shadow. Variants retain the same contact and scale.
```

## RESOURCE_PROP

```text
Create {stone boulder/stone seam/iron ore}, compact natural resource prop with
recognizable material. Boulder has two or three readable angular masses. Stone
seam is natural layered rock; iron ore has restrained metallic mineral clusters.
Target {16x16 or 32x24} with stable ground contact and silhouette distinct from
tilled soil. No floating rock, gem fantasy crystal, grass base or background.
```

## ANIMAL

```text
Create {cow/chicken} in the same three-quarter farm style. Compact recognizable
body on a 24x24 target canvas, stable feet. Cow has clear muzzle, horns/ears and
appropriate light/dark markings; chicken has compact feathers, beak and comb.
Do not inflate into a mascot or add accessories. A short idle strip, if requested,
changes head posture subtly while body scale and contact remain identical.
```

## CROP

```text
Create one {wheat/corn/carrot} growth-stage strip with exactly four ordered stages:
planted seed indication, small sprout, growing plant, mature ready-to-harvest.
Same ground anchor and native scale in every frame. Wheat: golden grain heads;
corn: broad leaves, upright stalk and clear cobs; carrot: feathery green tops
with small orange shoulder at maturity. Transparent background, no baked soil.
Target 16x16; mature corn may extend to 16x24 under the approved anchor contract.
Keep neighboring crop rows readable. No random unrelated plants or mature
plant duplicated four times. Dry/wet tilled soil are separate opaque assets.
```

## HOUSE

```text
Create the farm's main house: compact warm timber farmhouse, terracotta gabled
roof, readable roof tile clusters, front door, small windows and chimney.
Match the accepted pilot. Target 64x64 over an existing 48x48 logical footprint;
overhanging roof is visual only. One coherent orthographic three-quarter
building, no diamond base tile, courtyard, ground, fence or extra structure.
Neutral day art. Keep window planes available for separate runtime amber glow.
State {whole/hurt}: damage preserves the identity and depicts structural wear,
not evenly distributed holes or a second unrelated house.
```

## PRODUCTION_BUILDING

```text
Create one {workshop/kitchen/oil press/generator} matching the farmhouse timber,
stone and metal palette. Function cues: {workbench and tools/oven and cookware/
screw press, lever and barrel/metal engine, coil and exhaust}. Target 48x48 over
the existing 32x32 footprint where applicable. One coherent full station with
stable base; no repeated miniature station per tile. State {idle/active/hurt},
maintaining geometry. Active frame moves only mechanism or localized furnace
light; no baked smoky scene or ground. No signage or text.
```

## SHOP_WELL

```text
Create one {shop/well} as a recognizable farm station. Shop: modest counter,
warm wooden structure and cloth awning, target 32x40. Well: circular stone rim,
simple timber support and bucket, target 24x32. Match the farmhouse perspective
and materials. Stable contact point over the existing logical fixture; no new
floor plan or expanded collision area. No NPC baked into art, letters or labels.
```

## TOWER

```text
Create one {gun tower/flame tower/mortar/automatic crossbow}, level {1/2/3},
state {whole/hurt/fire/wreck}, matching the approved family master. Gun: readable
barrel on timber/metal tower. Flame: fuel tank, pipe and short nozzle. Mortar:
low broad base and upward-tilted heavy tube. Crossbow: obvious limbs, string and
bolt rail. Target 32x48 common canvas, stable one-cell base and pivot. Level 2
adds reinforcement/mechanism; level 3 looks stronger through construction,
not vertical duplication. Hurt has deliberate broken boards/metal; wreck lies
at the same base. Fire adds a localized muzzle form at the actual weapon tip.
Do not change camera/pivot between levels or put a permanent flame on whole art.
```

## WALL_TRAP

```text
Create {timber fence/stone wall/barricade/mine} in {whole/hurt/wreck/armed/triggered}
state, orientation/join {horizontal/vertical/end/corner/junction}. Target
{16x24 or 16x32; mine 16x16}, logical cell base remains 16x16. Neighboring
segments align in height and spacing, including perpendicular turns. Fence has
clear posts/rails, wall solid masonry, barricade piled timber, mine small low
mechanical disc. Broken state has a visible structural gap. No letters, skull
label, blood puddle, separate ground base or extra blocked cells.
```

## WALKER

```text
Create one enemy identity master for {walker/runner/tank/breaker}. Target
32x40 canvas, about 24–32 visible body pixels, stable feet (16,36). All share
the approved world camera/material style, but have distinct black silhouettes:
walker slouched and uneven; runner thin and forward leaning; tank broad heavy
torso/shoulders; breaker large arms and prominent demolition stance. Rot greens,
muted worn clothes and selective cold highlights. Menacing but compatible with
the cozy farm, restrained gore. No all-white outline, background or ground shadow.
```

## ENEMY_STRIP

```text
Use the accepted {kind} master. Produce only {walk 4 frames/attack 3 frames/
death 4 frames} in one clear ordered strip. Walk has believable weight transfer
without row-shifting the whole body. Attack anticipates, contacts and recovers
toward {direction}. Death loses support and collapses once, ending low to ground;
it is not a looping dance. Keep mass, clothes, scale and pivot consistent.
No limb from one frame crosses another cell; no baked impact target or scenery.
```

## GIANT

```text
Create the approved game's Giant boss, a massive mutated zombie that is clearly
larger than the four ordinary enemies. Target 64x64, ground contact (32,60).
Large heavy arms/torso, readable broad silhouette and subdued rot/stone/cloth
ramps. Produce {master/walk 4 frames/wind-up 3 frames/slam 3 frames/death 5 frames}
with fixed size. Wind-up visibly raises and loads the striking arm before slam;
the threatening body shape must be readable at 480x270. No huge aura obscuring
the target ring, excessive gore, scenery or new attack type.
```

## FX

```text
Create one short pixel-art effect strip for {muzzle flash/impact/flame/smoke/
harvest dust/water splash/flare}, {frame count} ordered frames, target {canvas}.
Clear localized origin at {pivot}. Sparks/flame have small warm bright cores;
smoke/dust are subdued clustered forms. Expansion then dissipation, no looping
flash unless specifically declared. Transparent outside actual particles, no
full-image bloom, smooth photographic smoke or background gradient. Must remain
readable over the game's night grass without covering nearby actors.
```

## ICON

```text
Create ONE resource icon for {exact resource ID}. Match the actual world material
and approved icon master, target 16x16 with a clear shape and internal padding.
Represent {logs/stone/iron ingot/meal/fish/oil barrel/wheat head/corn cob/carrot/
meat/gunpowder/incendiary fuel/coins/energy/tech mechanism} as appropriate.
Readable at the actual small HUD scale, colored outline and 2–3 material planes.
No labels, numbers, enclosing panel, ground shadow or unrelated objects.
```

## UI_SURFACE

```text
Create a restrained pixel UI surface for {panel/button/tab/checkbox/slider},
state {normal/hover/pressed/disabled/focus/selected/on/off}. Target {canvas}.
Warm farm timber or subdued navy material according to the approved UI palette;
one clean readable border, calm center, nine-patch corner area {actual margins}.
Preserve stretchable edges. Focus/selected state visibly differs at native size.
No text, ornament covering content, fake controls or scene/background elements.
```

## LIGHTING_STUDY

```text
Use the approved completed-farm image as the edit target. Change only lighting
to a cool blue/violet night with deeper shadows, small amber window pools and
localized warm torch/fire cores. Preserve every object's position, identity,
scale, geometry and frame composition. Keep crop/cloth whites subdued, enemies
readable and paths distinct. No extra buildings, moon overlay, new zombies,
particles or redesign. This is a runtime lighting reference, not a second atlas.
```

## CORRECTION

```text
Edit the attached candidate. Change only {one concrete failed criterion}:
{precise requested correction}. Preserve identity, palette, camera, materials,
body scale, canvas composition, stable foot/contact anchor and all unaffected
poses. Keep true transparency. Do not invent new accessories or change frame
count. The failure was observed at {native preview/runtime capture}: {evidence}.
```

## Per-generation record

```text
Task/asset ID:
Tool used: built-in ImageGen
Reference roles and source paths/hashes:
Exact assembled prompt:
Candidate source path and SHA-256:
Revision number and one requested correction:
Accepted native canvas/pivot/crop boxes:
Reviewed: alpha, native silhouette, day/night, motion/joins, runtime capture:
Decision: accepted / rejected, with concrete reason:
Runtime outputs and manifest entry IDs:
```

Never label a whole sprite sheet accepted if some required frames were rejected.
For rejected generations record the cause; keep only accepted project sources
unless a rejected candidate is useful evidence. No production file may point to
an image that exists only in the generator's private output directory.
