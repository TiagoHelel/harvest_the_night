# Thirteen corrected deliveries: final artwork review pending

> Historical review notes. Superseded on 2026-10-15 by the owner's explicit
> approval of all thirteen packs. Read CLAUDE-RETRY-APPROVED.md and the per-pack
> APPROVAL.json / CLAUDE-Axxx-PROMPT.txt for current integration authorization.

Date: 2026-10-14. This is a new correction pass on the older quality-blocked
deliveries, separate from the 21-pack / 422-PNG batch already approved by the owner.

All thirteen deliveries now contain their complete native exports: **182 PNGs**.
All statuses are `review`, not `approved`. There is no APPROVAL.json for this
correction batch. Do not integrate these new candidates until the owner explicitly
approves the final review and that approval is recorded against the exact hashes.

Unified owner review: `retry-final-review.html` in this folder.
Exact inventory: `retry-final-inventory.json`. The inventory identifies every
authoritative delivery folder and its native outputs, hashes and runtime names.
Each folder's `index.html` has the detailed animation, scale and source review.

## Scope and integration tasks

| Pack | Delivery folder under implementation/backlog/deliveries | PNGs | Game task |
|---|---|---:|---|
| A003 | A003-guardian | 12 | 0145 |
| A004 | A004-cursor | 14 | 0146 |
| A017 | A017-autumn-crops | 27 | 0200 |
| A018 | A018-sprinklers | 21 | 0201 |
| A023 | A023-fishing-gear | 20 | 0206 |
| A026 | A026-farm-animals | 23 | 0209 |
| A027 | A027-cow-chicken | 20 | 0210 |
| A030 | A030-coop-barn | 6 | 0212 |
| A033 | A033-shipping-bin | 4 | 0215 |
| A034 | A034-peddler | 15 | 0216 |
| A035 | A035-house-tiers | 6 | 0217 |
| A036 | A036-night-loot | 13 | 0235 |
| A057 | A057-morning-report | 1 | 0289 (optional) |

The authoritative runtime mapping is each `contract.json` file entry's
`runtime_name`. Animation order is `frame`, with 01.png representing frame 0.
Canvas, pivot, draw scale, timing, loops, mirrors and per-state metadata are
recorded in the file and animation entries. Do not infer them from previews.

## Owner-authorized method

Owner words, verbatim: **"Sim, autorizar composição com recortes do ImageGen"**.

The question explained that composition was previously limited to barriers and
asked to reuse generated body, base and planted-foot parts in other families.
The exact question and answer are in each layered delivery's `authorization.json`
and `contract.json` deviations. This authorizes the method, not the finished art.

Every artwork pixel comes from actual ImageGen raster sources, with their exact
prompts, tool calls, image hashes and reference hashes. Recorded conversions are
crop, nearest scale, alpha threshold, palette reduction, exact rotation/mirror and
source-part composition. No artwork was drawn, traced or repainted in code.

Previously rejected raw candidates were requalified only for explicitly measured
crops or parts. `raw/recovered-*` files are byte-identical copies; their history
remains preserved. The recorded source recipes and assembly DAG identify the
actual accepted parts. Old `rejected/`, historical previews and
`retry-before-20261014/` snapshots are never integration sources.

## What changed

- A003: a readable generated face with closed day eyes, two source-owned warm eye
  pixels, a fixed supporting post, stable torso and articulated sleeve crops.
  Wake joins the night pose. Both eyes are in `lights_xy`, with `light_xy` also
  identifying the first eye.
- A004: symmetric generated L-bracket parts, exact clockwise rotations, seven
  color/glyph states, a one-pixel inward pulse, fixed corner glyphs and the exact
  3x3 aim plus. The top-right glyph region takes precedence where it overlaps the
  otherwise empty centre. Actual cursor presentation is unlit above night relight.
- A017: new grape strip with one species scale, measured stage heights and
  adequate soil visibility. Other crop outputs retained.
- A018: fixed sprinkler feet/base rows and an exact two-pixel nozzle lift. Spray
  attachment points remain metadata, not baked water scenes.
- A023: a measured 90x6 blue track and an opaque 8x6 sweet zone assembled from
  actual generated rails, caps and fill crops. Existing fishing items retained.
- A026/A027: fixed torso/hoof parts for quiet poses, generated head and leg cycles,
  grounded support feet and small source-owned back movement for sleep. The wrong
  hen returned for one cow source was excluded. Facing west; east is runtime flip.
- A030: the corrected front-facing coop master, centered entrances, fixed bottom
  footing rows, localized source-owned damage and cool glass with at least two pale
  glint pixels per pane. Whole/hurt points match; wrecks emit no window/lamp light.
- A033: a 19px-wide bin body assembled from its original center timber strips;
  bottom body pixels stay identical while the generated lid opens.
- A034: fixed idle body, localized blink and talk motion. The stall keeps its
  original pixels outside the shutter opening. Peddler art uses mode B; the
  legacy closed stall is explicitly mode A at draw scale 2.0. Do not treat the
  whole mixed pack as one palette or one draw scale.
- A035: all six house states share the actual entry, 24px stoop, chimney and left
  glass; lowest row 119. Tier construction remains distinct. Native glass is cool
  and unlit; panes have separate measured lighting metadata. House uses full
  density, 128x128 at draw scale 1.0; remove the legacy house scale 2.0 on integration.
- A036: fertilised dry/wet tiles retain original furrows and the same six powder
  cluster locations; wet is darker. Existing loot and moon shimmer retained.
- A057: measured dawn crop and corrected sky palette. Optional UI header, unlit.

## Promotion of layered mode-A files

**Do not import a composed final file as its primary raw-source crop.** Its
`source`, `prompt` and `recipe` also identify provenance, while `parts` and
`components` define the authoritative assembly.

1. Verify final hashes against contract.json and, after approval, APPROVAL.json.
2. Traverse the component DAG from each final file's `parts`. Every part names an
   input, an exact `slice_xywh` and integer `paste_xy`. Preserve order. Each node
   has at most five parts, compatible with the existing raster importer.
3. Promote versioned raw sources and exact prompts with provenance. Mode-A render
   leaves use the recorded crop, scale, anchor, palette subset and threshold with
   `tools/import_art.py:render_source`.
4. Exact-reference leaves retain their original ImageGen manifest provenance.
   Mode-B ramp outputs and baked-mirror intermediates are available as hashed
   `components/*.png` and can be promoted byte-exact as source leaves with
   `palette: exact-source`, full-canvas crop and scale 1.0. Do not repaint,
   resample or re-quantize these approved intermediates.
5. Derived compose entries use `operation: compose`, the recorded parts, and
   `input` set to the first part's input. Do not leave a `source` field in a derived
   importer entry: the importer prioritizes `source` and would bypass composition.
   Exact quarter-turn nodes use the existing `rotate` operation. Baked horizontal
   mirrors can use the already hashed exact component leaves.
6. Namespace support nodes separately from runtime frames. Supporting component
   PNGs are assembly inputs, not extra animations. Only the 182 inventory outputs
   are final deliverables. Do not import GIFs, screenshots, mock lighting, grids,
   rejected candidates or preview PNGs.

`check_pipeline_replay.py` demonstrates the DAG mapping read-only and replays all
182 final outputs through **the existing `tools/import_art.py:build`**, with
pixel-exact equality. Per-pack results are `pipeline-replay-check.json`.
This replay writes no manifest, ownership record, game source or runtime sprite.

## Verification and next step

Every delivery's `retry-validation.json` records two byte-identical builds and a
successful `build.py --check`. Every measured boolean in checks.json is true.
Alpha, canvas, palette, output count, source hashes, exact prompts/reference hashes
and composition provenance pass. `assets.py check` reports 57 packs, zero problems.

The owner reviews the single final HTML next. After explicit artwork approval,
Codex records the owner words and exact approved hashes and creates the approved
per-pack handoffs. Claude then promotes through the raster pipeline, updates
ownership/hard-coded family checks, verifies game behavior and FHD day/night
captures, and marks integrated only after successful game integration. Claude owns
game-task state and `assets.py unblock`.

No game code, runtime art, art-source manifest, ownership file, deferred farmer
pack, cancelled run pack, commit or push was changed by this correction delivery.
