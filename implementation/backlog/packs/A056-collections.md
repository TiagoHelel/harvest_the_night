# A056 - The collection book, trophies and badges

- **Status:** todo
- **For game task:** 0288
- **Dressed by game tasks:** 0287
- **Spec after game task:** 0287
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 26 PNGs from 22 raw sources (default list): 1 book cover, 4 tab icons (2 cuts each), 4 boss trophies, 12 achievement badges, 1 page ornament

## What it is for

The collections screen (0287) is the reason to start Year 2: one book with tabs for
fish, crops, the bosses' trophies, "a year without losing the house" and the
achievements, kept in the profile across runs. It opens from the title menu and,
in a run, with its own key. This pack draws the book itself: its cover, the tab
icons, a mounted trophy for each boss, a medal for each achievement and an ornament
for the page headers. It is HUD art on the dark navy panel, never relit. Locked
trophies and badges are the same art dimmed by code, so there is no locked state.
No text anywhere: names and counts are code strings in both languages.

## Deliverables

The table is provisional: game task 0287 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

Every file: 1 frame, 1.0 s, static (`loop` false), direction `none`, `mirror:
"none"`, draw 1.0, runtime file `sprites/ui/<name>.png`. Every piece is centred on
its pivot (±1) with at least 1 transparent row and column on every side.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/collection_cover` | 48x64 | (24,32) | 1 / 1.0 / static | The closed collection book seen straight on: deep red-brown leather (`roof_dark`, `wood_dark`), `gold_dark` corner caps and a clasp, `bone` page edges on the right, an embossed emblem in the middle - the farmhouse roof (`roof`, `roof_light`) under a crescent moon (`gold_light`). The same book family as A023's `icon_book_fish`. Visible at most 46x62 |
| `ui/icon_book_crops`, `ui/hud_book_crops` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Crops tab: A023's small book with a green cover (`leaf`, `leaf_light`) and a `gold` wheat-ear emblem |
| `ui/icon_book_bosses`, `ui/hud_book_bosses` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Bosses tab: the book with a red cover (`roof_dark`, `roof`) and a cracked `bone` skull emblem |
| `ui/icon_book_year`, `ui/hud_book_year` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Year tab: the book with a gold cover (`gold_dark`, `gold`) and a small farmhouse emblem (`roof` roof, `bone` walls) |
| `ui/icon_book_achievements`, `ui/hud_book_achievements` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Achievements tab: the book with a night-blue cover (`night_light`, `ink_soft`, a `stone_light` top edge so it shows on the panel) and a `gold` medal emblem |
| `ui/trophy_giant` | 32x32 | (16,16) | 1 / 1.0 / static | The trophy plaque (below) with a slab of the stone armour that grows on the Giant's shoulder (`stone_dark`, `stone`, `rot` moss). Visible at most 30x30 |
| `ui/trophy_harvester` | 32x32 | (16,16) | 1 / 1.0 / static | The plaque with a bent cutting-reel blade with a broken tine from the Harvester's header (A052's rusted steel and red paint) |
| `ui/trophy_scarecrow_king` | 32x32 | (16,16) | 1 / 1.0 / static | The plaque with the Scarecrow King's twig crown (A053), slightly crooked |
| `ui/trophy_winter_lord` | 32x32 | (16,16) | 1 / 1.0 / static | The plaque with the Winter Lord's icicle crown (A054), cracked |
| `ui/badge_<achievement>` (12) | 24x24 | (12,12) | 1 / 1.0 / static | The medal (below) with the achievement's emblem on its face. Visible at most 22x22 |
| `ui/collection_ornament` | 64x12 | (32,6) | 1 / 1.0 / static | A page divider: a thin `gold_dark` vine line from end to end with small curling wheat ears and leaves (`gold`, `gold_light`, `grass_light`), a small crescent moon over a wheat ear in the middle; symmetric. Visible at most 62x10 |

- **The fish tab is not made here:** it is A023's `ui/icon_book_fish`/`hud_book_fish`
  (game task 0206 integrates it), and the four tabs above are the same book in other
  colours. 0287 may drop the achievements tab icon or add a tab; it then updates the
  table.
- **The trophy plaque:** a small shield-shaped plaque of dark wood (`wood_dark`,
  `wood`), a `gold_dark` rim and a gold nail at the top, seen straight on; the token
  is mounted across it and may overlap the rim. One trophy per `is_boss` enemy id:
  `giant`, `harvester`, `scarecrow_king`, `winter_lord`.
- **The medal:** a round bronze-gold medallion (`gold_dark` rim, `gold` face,
  `gold_light` highlight upper left) about 16 px across, hanging from a short
  `roof`/`roof_dark` ribbon at the top. Every badge shares it; only the emblem
  changes.
- **Badges, one per achievement id of 0287** (12 by default; 0287 writes the final
  ids, each with one emblem line). Examples of the form: `badge_first_dawn` (the
  farmhouse roof with a half sun rising behind it), `badge_full_moon_held` (a full
  moon over a short stone wall), `badge_legendary_landed` (a leaping golden fish),
  `badge_full_arsenal` (a tiny gun tower head), `badge_untouched_night` (an unbroken
  wooden shield), `badge_year_two` (a sprout with two leaves).
- **Recipe** (mode A, `content_anchor_xy` `(scaled_w // 2, scaled_h // 2)` for every
  piece, `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys`
  null unless a cut takes a colour from a ramp the piece does not have - then record
  the keys and why in review-log.txt):
  - cover: `content_scale` = min(46 / crop w, 62 / crop h);
  - tab icons: one crop for both cuts, 14 / max(crop w, h) and 8 / max(crop w, h);
    their books measure the same visible size as A023's `icon_book_fish` (±1);
  - trophies: one `content_scale` for all four = 30 / the largest side among their
    four crops, so the plaques are the same size;
  - badges: one `content_scale` for all = 22 / max(medal master crop w, h); each
    badge's crop is its own measured bounds, within ±2% of the master's;
  - ornament: min(62 / crop w, 10 / crop h).
- **Delivery paths:** `native/<name>/none/01.png`, e.g.
  `native/trophy_giant/none/01.png`, `native/icon_book_year/none/01.png`,
  `native/badge_year_two/none/01.png`.

## Match these

- **A023's approved `icon_book_fish`** (`implementation/backlog/deliveries/A023-fishing-gear/`,
  its raw and its `native/icon_book_fish` and `hud_book_fish`, or
  `sprites/ui/icon_book_fish.png` once integrated): the tab book family.
- **The bosses:** `sprites/enemies/giant_walk_0.png` (80x64, visible 46x41) and
  `assets/art_source/enemies/giant/master.png` (the stone shoulder armour); the
  approved masters of A052 `harvester`, A053 `scarecrow_king` and A054
  `winter_lord` (their delivery `native/<boss>/west/01.png` and raw master).
- A005's `icon_gun_tower` (for the arsenal badge) and A022's `golden_queen` (for the
  legendary badge) if approved; otherwise the emblem is drawn from the prompt alone.
- `sprites/ui/icon_wood.png`, `icon_money.png` and the style master
  `assets/art_source/ui/wood.png`: the icon family (outline, 2-3 planes, clusters).
- `sprites/ui/panel.png`, `tab.png`, `tab_selected.png` (`night` #1a1830,
  `night_light` #2e2a4e, `gold_dark`/`gold` borders): the screen's chrome, which the
  cover and the ornament must not compete with.
- `sprites/buildings/house.png` (64x64): the farmhouse the year emblem and the cover
  emblem stand for.
- `docs/reference-sheet.png` (style) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Check the inputs first.** Run `python implementation/backlog/assets.py status`
   for A023, A052, A053 and A054. Each must say `approved` or `integrated`: the tab
   book and the boss tokens are drawn from them. If one does not, ask the owner;
   without an answer,
   `python implementation/backlog/assets.py set A056 blocked "waiting for Axxx approval"`
   and stop.
2. **Prompts** from `implementation/sprites/generation/PROMPTS.md`: BASE with the
   row's canvas and pivot + ICON for the tab icons, trophies and badges (ICON's
   first line replaced by "Create ONE collection-book {tab icon / boss trophy /
   achievement medal}: ...") + the 0018 "Native contract" paragraph of
   `implementation/sprites/generation/0018-wood.prompt.txt` with the row's visible
   size (14 and 8, 30, or 22); BASE + UI_SURFACE ("one fixed piece, not a
   nine-patch") for the cover and the ornament.
3. **Tab icons:** an ImageGen edit of A023's accepted `book_fish` raw (edit target):
   "Change only the cover colour and the emblem: ... Keep the book's shape, size,
   angle and position."
4. **Trophies:** `trophy_giant` first (Image 1 `docs/reference-sheet.png` style,
   Image 2 the Giant's master as identity reference); accept it before the others.
   Then each other trophy as an edit of the accepted giant raw (edit target) with the
   boss's master attached as identity reference: "Replace only the token with ...;
   keep the plaque."
5. **Badges:** first a blank medal master (the medallion and ribbon, plain face), kept
   in `raw/` and listed in contract.json `references` with the role "medal master",
   never exported as a badge. Then each badge as an edit of the medal master (edit
   target): "Add only this emblem on the face: ...".
6. **Cover and ornament:** one call each; the cover with A023's `book_fish` raw
   attached as "the same book family; not an edit target".
7. One subject per call, one candidate per call, `transparent_background=true`.
   Inspect the raw alpha. At most 3 revisions per raw (CORRECTION).
8. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipes above. If an emblem or token is lost in the reduction, regenerate with a
   bolder, simpler shape. Never patch pixels.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- a mock collections screen at 1x and 4x on the panel colours: the cover, the five
  tab icons in a row (A023's fish book included) on `tab.png` and `tab_selected.png`,
  the ornament above a blank text block, the four trophies in a row and the badges
  in a grid; then the same with every trophy and badge dimmed to 40% brightness, as
  the locked state code will draw;
- every piece alone at 1x and 4x over flat `night` #1a1830, flat `night_light`
  #2e2a4e, light grey and checker; the tab icons' 10x10 cuts in a row;
- each trophy beside its boss's sprite, and the farmer frame with his feet on a 16 px
  grid line, at 1x and 4x;
- the night preview, labelled "world relight, for reference only: the HUD is not
  relit".

Questions for the owner:

1. "A capa, as abas e o enfeite parecem do mesmo livro, e cada troféu lembra o chefe que ele representa?"
2. "As medalhas de conquista se diferenciam entre si sem texto, inclusive apagadas (bloqueadas)?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly the files of the final table: by default 26 PNGs (1 cover, 4 `icon_book_*` + 4 `hud_book_*`, 4 trophies, 12 badges, 1 ornament), with its canvases and pivots; no `book_fish` file.
- [ ] Every piece centred on its pivot (±1) with at least 1 transparent row and column on every side; visible at most 46x62, 14 / 8, 30, 22 and 62x10 by kind.
- [ ] The tab icons match `icon_book_fish`'s visible size (±1); the four trophies share one `content_scale`; every badge shares one `content_scale` and the medal's rim and ribbon line up across badges (±1).
- [ ] Icon cuts: more than 24 / 7 opaque pixels, at least 2 colours; no two PNGs of one size byte-identical.
- [ ] Each badge stays distinct when dimmed: any two badges differ in at least 12 pixels.
- [ ] No text, letters, numbers, title or counts anywhere; binary alpha, only the 42 colours, `importer_recipe_matches` true; no shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A056-collections/` with the standard
  files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok`, `same_crop_per_pair`,
  `one_scale_trophies`, `one_scale_badges`, `tabs_match_book_fish` and
  `badges_distinct`.
- **The mapping lines** in `CLAUDE-A056-PROMPT.txt`, one per file, e.g.
  `native/collection_cover/none/01.png -> sprites/ui/collection_cover.png  48x64 pivot (24,32) draw 1.0  static`,
  `native/icon_book_bosses/none/01.png -> sprites/ui/icon_book_bosses.png  16x16 pivot (8,8)`,
  `native/trophy_winter_lord/none/01.png -> sprites/ui/trophy_winter_lord.png  32x32 pivot (16,16)`,
  `native/badge_year_two/none/01.png -> sprites/ui/badge_year_two.png  24x24 pivot (12,12)` and
  `native/collection_ornament/none/01.png -> sprites/ui/collection_ornament.png  64x12 pivot (32,6)`.
  The handoff says the fish tab is A023's `icon_book_fish`, and that A056 gets its
  own section and counts in `tools/check_ui_art.py`. They replace 0287's stand-ins
  for game task 0288.
- **Last step:** `python implementation/backlog/assets.py set A056 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
