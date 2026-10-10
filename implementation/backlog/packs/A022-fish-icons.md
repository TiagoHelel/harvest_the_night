# A022 - Fish

- **Status:** todo
- **For game task:** 0205
- **Dressed by game tasks:** 0179, 0182
- **Spec after game task:** 0179
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 16 species from 16 raw sources, each cut three times (48 PNGs: 16 portraits, 16 icons, 16 HUD icons)

## What it is for

Fishing becomes a hunt by pond, season and hour (0179): about twelve species, plus
four legendaries, one per season (0182). Each catch shows its icon in the catch
line, the inventory and the stall (16x16) and the HUD's compact rows (10x10), and
the fish book (0182) gives each species a page with a 32x32 portrait; an unknown
species is shown as its black silhouette (code). At 1x on the dark navy panel each
fish must be told from the others by shape and colour alone, and a legendary must
look special without a baked glow. The HUD and the book are not relit at night.

## Deliverables

Final list settled by game task 0179. There are twelve species under the ids below, in this order: `carp`, `perch`, `catfish`, `tilapia`, `sunfish`, `bream` (the commons); `trout`, `pike`, `eel` (the middling three); and `dorado`, `salmon`, `sturgeon` (the rare three). The four legendaries are 0182's, under the ids below; game task 0182 settled them as `old_catfish` (spring), `golden_queen` (summer), `ghost_pike` (autumn) and `ice_sturgeon` (winter). The fish book (0182, the ledger's last tab) draws `portrait_<id>` at 1x beside the species' name, rarity and hint, and an unknown species as the same portrait drawn black; until 0205 every portrait is the species' tinted `icon_fish` stand-in at twice the size. Each species has three static cuts: the 32x32 portrait at (16,16), the 16x16 icon at (8,8) and the 10x10 HUD icon at (5,5). Until 0205, the icon and HUD cuts are drawn as tinted `icon_fish`/`hud_fish` stand-ins. `icon_fish` itself stays, as the icon of "any fish", the group a recipe names. Start only when `python implementation/backlog/assets.py next` offers this pack.

Every species: one raw source, three cuts from the same crop. Each file is 1 frame,
1.0 s, static (`loop` false), direction `none`, `mirror: "none"`, draw 1.0, runtime
file `sprites/ui/<name>.png`. Every fish is in side profile **facing west**: head
and mouth at the left, tail at the right, belly down, one eye showing, like
`sprites/ui/icon_fish.png`.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/portrait_<id>` | 32x32 | (16,16) | 1 / 1.0 / static | Book portrait. Visible at most 30x30, centred |
| `ui/icon_<id>` | 16x16 | (8,8) | 1 / 1.0 / static | Visible at most 14x14, centred |
| `ui/hud_<id>` | 10x10 | (5,5) | 1 / 1.0 / static | Visible at most 8x8, centred |

**The species** (ids as 0179 and 0182 will use them; 0179 writes the final list
here):

| Id | Shape | Colours |
|---|---|---|
| `carp` | Deep body, big scales, two short barbels at the mouth | Bronze-gold (`gold_dark`, `gold`), `roof_light` fins |
| `perch` | Spiny raised front dorsal fin | Green-gold (`grass`, `gold_light`) with 4-5 dark vertical bars (`leaf_dark`), `roof`/`flame` lower fins |
| `catfish` | Flat broad head, four long whiskers, smooth body | Grey-brown (`stone_dark`, `soil`), `bone_dark` belly |
| `tilapia` | Compact oval, long spiny dorsal fin | Blue-grey (`stone`, `water_light`) with faint stripes, `roof_light` tail edge |
| `trout` | Streamlined | Olive back (`grass_dark`), `roof_light` side band, dark speckles, `bone` belly |
| `pike` | Long torpedo body, duck-bill snout, dorsal fin far back | Green (`leaf`, `leaf_light`) with pale spots (`grass_light`) |
| `eel` | Long snake body in an S-curve (so it stays readable at 10x10), one continuous back fin | Dark olive-brown (`rot_dark`, `soil_dark`), `gold_light` belly |
| `dorado` | Muscular, steep forehead, big forked tail | Golden (`gold`, `gold_light`), `flame` tail, fine dark scale lines |
| `salmon` | Hooked jaw | Silver-pink (`bone_dark`, `roof_light`), `stone_dark` back, small spots |
| `sturgeon` | Long shark-like body, a row of bony plates on the side, pointed snout with barbels below, upper tail lobe longer | Grey (`stone`, `stone_dark`), `bone_dark` plates |
| `sunfish` | Round, almost a disc | `water`/`grass` body, `flame` belly, an `ink` ear spot behind the gill |
| `bream` | Very deep and flat, small head, high back, forked tail | Silvery bronze (`bone_dark`, `gold_dark`) |
| `old_catfish` (legendary) | The catfish's shape, bigger in presence: very long whiskers, a scarred lip with an old hook still in it (`stone_light`) | Mossy (`rot_dark`, `rot`, `stone_dark`) |
| `golden_queen` (legendary) | A carp-like body with a tall crown-like spiky dorsal fin and a long flowing veil tail | `gold_light`, `gold`, `flame_hot` glints, `flame` veil |
| `ghost_pike` (legendary) | The pike's shape, gaunt, a dark hollow eye (`ink`) | Washed-out pale (`bone`, `bone_dark`, `moon`), fins `stone_light`. Drawn opaque; no halo, no see-through |
| `ice_sturgeon` (legendary) | The sturgeon's shape with frosted plates and icicle-tipped fins | Ice blue (`water_light`, `moon`, `bone`) |

The colours are the target ramps for the prompt; the reduction picks the final
pixels. Today's `icon_fish` stays as it is and is not redrawn here.

**Recipe** (contract section 3, mode A):

- `crop_xywh`: the fish's measured alpha bounds in its raw; one crop for all three
  cuts.
- `content_scale`: portrait = 30 / max(crop w, h); icon = 14 / max(crop w, h);
  HUD = 8 / max(crop w, h). A fish is longer than it is tall, so its length is 30,
  14 and 8.
- `content_anchor_xy`: `(scaled_w // 2, scaled_h // 2)`, the centre, as in
  `ui/icon_fish` (crop 766x432, scale 14/766, anchor (7,4)).
- `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys` null.
  Set a subset for a species (all three cuts) only when a cut takes a colour from a
  ramp the fish does not have, and record the keys and the reason in review-log.txt.
- **Delivery paths:** `native/portrait_<id>/none/01.png`, `native/icon_<id>/none/01.png`
  and `native/hud_<id>/none/01.png`.

## Match these

- `sprites/ui/icon_fish.png` (16x16, visible 14x8) and `hud_fish.png`, raw
  `assets/art_source/ui/fish.png` (1254x1254): the fish icon family - side profile
  facing west, the outline, the planes, the light. Its eye is lost at 16x16: give
  every new fish an eye large enough to be a 2x2 cluster in the 30 px portrait.
- `assets/art_source/ui/wood.png`: the icon style master.
- `sprites/ui/panel.png` (centre `night` #1a1830) and `button_normal.png` (centre
  `night_light` #2e2a4e): the background of the catch line, the inventory and the
  book.
- `sprites/terrain/water.png`, `water_b.png`, `water_c.png`: the ponds' blues; the
  fish must not melt into them in the catch scene.
- `docs/reference-sheet.png` (style; the PEIXE icon) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Prompt:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, with ICON's `{exact resource ID}`
   set to the id and "Represent ..." set to the species' shape and colours above,
   plus the last paragraph of `implementation/sprites/generation/0018-fish.prompt.txt`
   ("Native contract: ...") with the visible sizes changed to "30 for the book
   portrait, 14 for the icon, 8 for the compact HUD". Add: "Side profile facing
   left (west), head left, tail right, belly down, one large clear eye. The same
   source is reduced to 30, 14 and 8 pixels long: a bold silhouette with the
   species' one distinctive feature large enough to survive at 8."
2. **Inputs:** Image 1 `assets/art_source/ui/fish.png` (family master: camera,
   facing, outline; not the species); Image 2 `assets/art_source/ui/wood.png` (icon
   style master); Image 3 `docs/reference-sheet.png` (style).
3. **Order:** `carp` first, in two calls; keep the candidate whose three cuts read
   best. It is the master for the set: attach its accepted raw as Image 4 ("same
   camera, outline weight and light; a different species") to every later call.
   Then the commons, then each legendary with its common's accepted raw attached as
   "the ordinary species this legendary is a special version of": `old_catfish` with
   `catfish`, `ghost_pike` with `pike`, `ice_sturgeon` with `sturgeon`,
   `golden_queen` with `carp`.
4. One call per species, one candidate per call, `transparent_background=true`.
   Inspect the raw alpha before accepting. At most 3 revisions per raw (CORRECTION).
5. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipe above. If the 10x10 cut of two species looks the same, regenerate the
   weaker raw with its distinctive feature larger. Never patch pixels and never
   draw a cut separately.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- a grid of all 16 species, each with its three cuts at 1x and 4x, over flat
  `night` #1a1830, flat `night_light` #2e2a4e, tiled `sprites/ui/panel.png`, light
  grey and checker;
- the silhouettes: each portrait as a black alpha mask on the panel, as the book
  shows an unknown species;
- confusion pairs at 1x, 10x10 and 16x16: pike / eel / ghost_pike, carp / bream /
  golden_queen / dorado, catfish / old_catfish, sturgeon / ice_sturgeon, perch /
  sunfish / tilapia, trout / salmon;
- a mock book page (the 32x32 portrait on the panel beside a blank text block) and a
  mock HUD row of 10x10 cuts;
- today's `icon_fish` and the farmer frame with his feet on a 16 px grid line, at 1x
  and 4x;
- the night preview, labelled "world relight, for reference only: the HUD and the
  book are not relit".

Questions for the owner:

1. "Cada peixe se reconhece no 10x10 só pela forma e pela cor? Algum par se confunde (lúcio e enguia, carpa e brema, perca e peixe-sol)?"
2. "Os quatro lendários parecem especiais o bastante, sem brilho pintado, e os retratos 32x32 do livro têm o detalhe que você quer?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 48 PNGs for the 16 ids of the final table: `portrait_` 32x32 pivot (16,16), `icon_` 16x16 pivot (8,8), `hud_` 10x10 pivot (5,5).
- [ ] The three cuts of a species come from one raw with one crop, at 30, 14 and 8 / max(crop w, h).
- [ ] Visible at most 30, 14 and 8 in both dimensions, centred on the pivot (±1), at least 1 transparent row and column on every side (`icon_bounds_ok`, `icon_margin_ok`).
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each; no two PNGs of one size byte-identical, and none identical to `icon_fish`/`hud_fish`.
- [ ] `silhouettes_distinct`: any two 32x32 alpha masks differ in at least 24 pixels.
- [ ] Every fish faces west, belly down, with its eye visible in the portrait and the icon.
- [ ] Legendaries carry no halo, glow or translucency; binary alpha, only the 42 colours, `importer_recipe_matches` true; no text, numbers, frame, panel, water or shadow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A022-fish-icons/` with the standard
  files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok`, `same_crop_per_species`
  and `silhouettes_distinct`.
- **The mapping lines** in `CLAUDE-A022-PROMPT.txt`, one per file (48), e.g.
  `native/portrait_pike/none/01.png -> sprites/ui/portrait_pike.png  32x32 pivot (16,16) draw 1.0  static`,
  `native/icon_pike/none/01.png -> sprites/ui/icon_pike.png  16x16 pivot (8,8)` and
  `native/hud_pike/none/01.png -> sprites/ui/hud_pike.png  10x10 pivot (5,5)`;
  manifest `display_role` `inventory`, `compact_hud` and `book_portrait`. The
  portraits are a family of their own in `tools/check_ui_art.py`. They replace the
  tinted `icon_fish` stand-ins of 0179 and 0182 for game task 0205.
- **Last step:** `python implementation/backlog/assets.py set A022 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
