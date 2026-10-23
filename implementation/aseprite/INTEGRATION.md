# Integrating an Aseprite batch (Claude, the game's chat)

The owner brings an approved batch with:

> Integra o lote Bxx do Aseprite: leia implementation/aseprite/INTEGRATION.md

One batch is one change: verified, journalled and committed like a backlog
task. The first time, add one integration task per batch to the backlog
(`tools/backlog/part*.py`, `python tools/gen_backlog.py`), so the loop's
procedure applies: `task.py doing`, verify, shots, journal, commit.

## 0. Before anything

- **Check the batch:**

  ```
  python implementation/aseprite/inventory.py check Bxx
  ```

  It must PASS. `APPROVAL.json` must exist, and its `approved_sha256` must
  match every `png/` file.
- **Read `HANDOFF.md`:**
  - the deviations and the owner's words;
  - the points;
  - what the owner asked of the game.
  
  A deviation that changes a frame count, a timing or a canvas is a game
  change, and needs the owner's call if it touches rules or tests.
- **B00 first.** Copy the approved palette to
  `assets/art_source/aseprite/palette.json`. It is the colour authority for
  every Aseprite source. Family checks that demand
  `tools/palette.py:COLOURS` learn to accept it for Aseprite-owned outputs.
  `tools/palette.py` itself does not change: the 42 colours are inside the
  new palette.

## 1. Promote the sources

Copy `png/` and `source/` into `assets/art_source/aseprite/<Bxx-slug>/`.
These are the versioned sources the manifest points at. Never edit them:
a change comes back from the Aseprite chat as a new approval.

## 2. Rewrite the manifest entries

For every row of `inventory/<Bxx-slug>.md`, rewrite the entries in
`assets/art_source/manifest.json` that produce its files.

- **The recipe:**
  - `source`: `assets/art_source/aseprite/<slug>/png/<file>`, plus its
    `source_sha256`;
  - `crop_xywh`: `[0, 0, w, h]`, the whole native canvas;
  - `content_scale`: 1.0;
  - `content_anchor_xy`: the native pivot;
  - `alpha_threshold`: 128;
  - `palette`: `"exact-source"`.
  
  Drop the ImageGen-only keys: `sheet_cell_xywh`, `gutter_xy`,
  `palette_keys`, `scale_reference`, `feet_source_xy`, `body_reference_height`.
- **Provenance:**
  - `prompt` is the Lua generator in `source/`, with its sha256;
  - `tool`: `"Aseprite 1.3.18 (procedural Lua)"`;
  - `generation_task`: `Bxx`;
  - `approval`: the owner's words;
  - `integration_task`: the task id.
- **Points:** take them from contract.json.
- **The farmer's 2x families** (B01-B06):
  - keep the runtime `canvas_wh` and `pivot_xy` (80x80 at (40,72), or 96x96
    at (48,88)), and `draw_scale` 0.5;
  - set `content_scale` to 2.0, `detail_wh` to the native size, and
    `content_anchor_xy` to the runtime pivot. That is an exact 2x NEAREST;
  - double the points;
  - B01's baked mirrors are delivered files. Bind them directly and never
    flip them again.
- **The five old 2x fixtures** (workshop, kitchen, press, generator, shop and
  `shop_closed`):
  - take the doubled canvas and pivot;
  - remove them from `ArtPlacement.visual_scale`, as task 0217 did for the
    house;
  - recompute `cell_offset_xy` and their points.
- **The new farmer animations** (B02-B06) are new entries. Their game tasks
  stop waiting on art:
  - 0123, 0124 and 0125 rename the poses;
  - 0143 and 0144 are the bed and the reactions;
  - 0207 and 0208 are fishing and care.
  
  Each deletes its `PlaceholderArt.POSES` lines. Run
  `python implementation/backlog/assets.py set Axxx integrated` for A001,
  A002, A007, A008, A009, A024 and A025 as they land.
- **Derived outputs** keep their recipes:
  - joins from the new modules;
  - rotations from the new `edge_n` and `shore_n`;
  - slices from the new full drawings;
  - aliases.
  
  Re-point their inputs if an id changed.
- **Components** (`sprites/components/`) whose consumer is now a direct
  source go: their manifest entries, their PNGs and their ownership rows.
- **`ownership.json`** follows every added or removed output.

## 3. Build and check

1. Run `python tools/import_art.py`, then `python tools/import_art.py --check`.
2. Update the family checks (`tools/check_*_art.py`, `show_art.py`) that
   hard-code old bytes or measurements.
   - Keep each rule: the geometry, the grounded rows, distinct silhouettes,
     binary alpha.
   - Change only the expected values, and journal each one.
3. Run `python tools/verify.py`. It must PASS, and the SIM and DATA hashes
   must not move: art is view-only, so a moved hash is a bug.
4. Take FHD shots by day and by night (`python tools/shot.py <task> --fhd`)
   and open them.

## 4. Close

1. Write `implementation/aseprite/deliveries/<Bxx-slug>/INTEGRATED.json`:
   `{"batch", "date", "task", "commit_subject"}`.
2. Journal in `implementation/PROGRESS.md` and run
   `python tools/devlog.py --check`.
3. Update `implementation/codex-claude/OPEN-WORK.md`.
4. Commit only the batch's paths. Never push.
