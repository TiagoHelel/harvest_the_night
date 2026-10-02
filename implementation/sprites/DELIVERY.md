# Sprite delivery catalogue

The game uses a **480x270 viewport**, 16px tiles and nearest filtering. Native
canvases below include transparent pose clearance; they do not describe the
visible body's size. Existing simulation, collision, map footprints, save formats
and balance are preserved. No completed sprites were regenerated for the final
lighting or catalogue tasks.

The final native review is complete. [Task 0020's review](reviews/0020/REVIEW.md)
records the visual criteria, all twenty original prompt requirements,
verification evidence and explicit animation limits.

## Files and reproducibility

All **468 runtime PNGs** have one registered owner: **447 raster outputs** and
**21 deterministic ASCII outputs**, with zero owner-sheet outputs remaining.
The [manifest](../../assets/art_source/manifest.json) preserves exact crops,
source and prompt SHA-256, nearest reduction scales, binary alpha threshold,
palette, native canvas, ground pivot, timing and derivations. Raw PNGs and original
identity/lighting masters are committed under [assets/art_source](../../assets/art_source/).
Exact ImageGen prompts, returned-source records, reference roles and revisions
remain in [generation](generation/). The owner's original player sheet and
[reference sheet](../../docs/reference-sheet.png) remain unchanged.

[catalogue.json](reviews/0020/catalogue.json) lists every output's hash, native
dimensions, visible bounds, pivot, animation, frame/duration, source lineage,
emission points and compatibility aliases. It covers source cuts, compositions,
slices, fixed rotations and exact copies. All sixteen enemy compatibility names
are verified byte-exact against their canonical authored frames; they are not
additional animation poses. Each source lineage resolves to committed masters
and exact prompts, with no dependency on an ImageGen private output folder.

The 21 ASCII-owned files are nineteen UI frame/control surfaces, the terrain
atlas assembled from accepted raster tiles, and one unused legacy
`actors/placeholder.png`. That old output has no reference in `src/` or `scenes/`;
it is preserved deliberately and is not used in normal actor playback.

```powershell
python tools/import_art.py
python tools/gen_sprites.py
python tools/cut_sheet.py
python tools/import_art.py --check
python tools/gen_sprites.py --check
python tools/cut_sheet.py --check
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
python tools/verify.py
```

[clean-rebuild.json](reviews/0020/clean-rebuild.json) proves two normal offline
rebuild cycles in a completely clean checkout of `c03c169`: 1,283 tracked art,
source and generated-metadata files retain identical bytes; both cycles write
zero outputs and leave Git completely clean. No ImageGen call is made by any
rebuild command. The temporary checkout is archived after testing.

## Native family contracts

| Family | Canvas and pivot | Playback / states | Sources and current evidence |
| --- | --- | --- | --- |
| Farmer idle / walk | 48x48; (24,44); about 30px standing body | South, north and west: 3 idle / 4 walk frames each; east mirrors west | [player](../../assets/art_source/player/), [locomotion captures](../shots/sprites/0020/locomotion/) |
| Farmer work | 48x48; (24,44) | Four authored frames for chop, mine, till, plant, water, fish, reel, harvest, collect, craft, trade, repair and delivery carry; all four gameplay facings exercised | [player sources](../../assets/art_source/player/), [work captures](../shots/sprites/0020/work/) |
| Reactions / shared shadow | Reactions 48x48; (24,44); shadow 20x8; (10,4) | Bang, question, note, heart are held source-owned poses; glyph clamp and work/movement suppression. Shadow is separate ground art | [reaction review](reviews/0006/), [final captures](../shots/sprites/0020/reactions/) |
| Ground / water / banks | 16x16; TileSet placement; atlas 256x80 | Eight quiet materials, three 550ms water phases, static cardinal edges and diagonal caps | [terrain sources](../../assets/art_source/terrain/), [final terrain](../shots/sprites/0020/terrain/), [water](../shots/sprites/0020/water/) |
| Props / livestock | Tree 40x48/(20,44); other contacts and exact canvases in catalogue | Static paired tree/rock/seam/ore variants; stump, cow and hen; actual gathering/removal/regrowth/production selection | [props](../../assets/art_source/props/), [final captures](../shots/sprites/0020/props/) |
| Crop growth / moisture | Wheat/carrot 16x16/(8,14); corn 16x24/(8,22); soil 16x16/(8,16) | Three species, four progressive authored stages each; dry/wet soil; no sway loop | [crops](../../assets/art_source/crops/), [dense beds / stages](../shots/sprites/0020/crops/) |
| House | 64x64/(32,60); logical 3x3 cells | Whole/hurt full drawings; eighteen exact compatibility slices; five measured windows, one chimney | [house](../../assets/art_source/buildings/house/), [final captures](../shots/sprites/0020/house/) |
| Farm stations | Production 48x48/(24,44); shop 32x40/(16,36); well 24x32/(12,30) | Four production families with idle/active/hurt; shop/well; real paid/stalled/fuel states, sixteen exact idle quarters | [buildings](../../assets/art_source/buildings/), [final states / overlap](../shots/sprites/0020/stations/) |
| Four tower families | 32x48/(16,44); one logical cell | Gun/flame/mortar/crossbow: 3 levels x whole/hurt/fire/wreck; 48 authored state cuts and measured launch points | [tower sources](../../assets/art_source/buildings/), [all levels / states](../shots/sprites/0020/towers/) |
| Joined walls / fences | 16x32/(8,28) | Sixteen cardinal neighbor masks, whole/hurt and low rubble; original occupied cells and route rules | [barrier sources](../../assets/art_source/buildings/), [joins / destruction](../shots/sprites/0020/barriers/) |
| Barricade / mine | 16x24/(8,20); 16x16/(8,14) | Whole/hurt/wreck; armed/triggered/spent one-shot mine cues | [final trap captures](../shots/sprites/0020/barriers/), exact source lineage in catalogue |
| Walker / runner / tank / breaker | 64x48/(32,44); about 29px standing bodies | Each: master, 4 walk, 3 attack, 4 death frames; horizontal mirroring and existing core-target/contact observations | [enemy sources](../../assets/art_source/enemies/), [mixed waves / motion](../shots/sprites/0020/enemies/) |
| Giant | 80x64/(40,60); master visible 43x42 | Master, 4 walk, 3 wind-up, 3 slam, 5 death; real warning/contact, bounded one-shot deaths | [Giant](../../assets/art_source/enemies/giant/), [final playback](../shots/sprites/0020/giant/) |
| Seven localized effect families | Muzzle/impact 12x12; flame/smoke 16x20; dust 16x12; splash 20x16; flare 24x24 | 25 one-shot frames; authored pivots/timing in catalogue; pool maximum 24 within existing shared particle budget | [effects](../../assets/art_source/effects/), [final contacts / a11y](../shots/sprites/0020/effects/) |
| Fifteen resource icons | 16x16/(8,8) inventory; 10x10/(5,5) HUD | Thirty static source cuts at native display size; localized names remain beside icons | [UI sources](../../assets/art_source/ui/), [final UI](../shots/sprites/0020/ui/) |
| UI surfaces | Exact individual dimensions in catalogue; top-left / three-pixel nine-patch | Button normal/hover/pressed/disabled/focus; tabs, checks and grips with distinct states | [deterministic maps](../../tools/ui_surfaces.py), [final menus](../shots/sprites/0020/) |
| Shared atmosphere | View-only; no duplicate night PNGs | Dawn/day/dusk/night; semantic fire layer, five local window cores; both transitions, reversal, lights off and accessibility | [final atmosphere](../shots/sprites/0020/atmosphere/), [accepted lighting review](reviews/0019/REVIEW.md) |

The [contact page index](reviews/0020/catalogue.json) maps all 468 outputs to
nineteen sheets, each saved at native pixels and exact nearest 3x. Labels and
checkerboards are review guides outside the native sprite; they do not alter
the accepted runtime PNGs. Frame order, fixed contacts and transparent clearance
can be compared directly across each strip.

## What animation is actually supplied

The October 2 follow-up adds canopy sway, hen pecking and cow head/tail movement
from the existing tree/animal textures, plus a brief farmer blink. Animals keep
their gameplay cells; this is ambient motion, not roaming. Banks and crop stages
remain static. See [native follow-up evidence](../reviews/world-visibility/REVIEW.md).
The [leaf-only wind correction](../reviews/tree-wind/REVIEW.md) keeps all exposed
wood fixed and gives trees individual, slow rhythms with subpixel leaf motion.
Water and farmer motion loop; timed work uses real anticipation/contact followed by short cosmetic
recovery. Instant water/reel/trade start at contact and return to ready.
North/south work deliberately uses the accepted side-on gesture, with west
authored and east mirrored. No four-direction work sheet is claimed.
Production activity and tower firing are authored state/event drawings, rather
than continuous mechanical loops. Ordinary enemies retain the last horizontal
facing during vertical movement; no four-direction enemy source family is claimed.
Deaths and localized effects finish once and expire, with bounded presentation
pools. Giant's larger transparent canvas admits the fist without changing its
standing scale or gameplay cell.

## Final review evidence and limits

[capture-index.json](reviews/0020/capture-index.json) inventories **890 fresh
480x270 renderer photographs** across every production family, the complete
work/facing matrix, dense crops, structure states, mixed enemies, Giant/deaths,
effects, menus, both locales/themes and accessibility. It identifies **242 exact
pixel matches** to previously accepted photographs and **648 new/changed views**
on 167 native/nearest-3x pages. Matching pixels permit reuse of the earlier
documented review; differing pages require a new visual decision.

[visual-review.json](reviews/0020/visual-review.json) records all 205 opened
pages: 167 capture pages and 38 native/3x contact pages.
[reused-review.json](reviews/0020/reused-review.json) proves the 242 exact pixel
matches resolve to unchanged committed captures and prior accepted review
journals. [completion-audit.json](reviews/0020/completion-audit.json) verifies
source/core preservation, complete coverage and native/nearest page pixels.
[verify.log](reviews/0020/verify.log) records **52 passed, zero skipped/failed**,
including Windows/Web exports, with unchanged sim/data hashes. Its 431s duration
exceeds the soft 300s target while runtime performance checks pass.

This remains a prototype art delivery:
the viewport limits facial detail; some pre-existing result/tech labels remain
untranslated. Native silhouettes, material identity, contacts and action timing
are the review criteria, not a claim that the reference illustration can retain
its original detail in a thirty-pixel actor.
