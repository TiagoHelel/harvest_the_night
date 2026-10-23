# Runner: remaking HARVEST THE NIGHT's art in Aseprite

The owner starts you with the prompt in `README.md`. You redraw every sprite
of the game with the procedural Aseprite toolkit, **batch by batch, B00 to
B19**, and the owner reviews each one. Claude, in the game's own chat,
integrates each approved batch into the game.

- **The repository** is `C:\Users\Helel\Documents\repos\harvest_the_night`.
  Every path below is relative to it unless it says otherwise.
- **The toolkit** is `C:\Users\Helel\Documents\aseprite`. The `pixel-sprites`
  skill is its playbook: load it before you draw anything.
- **Read first:** this file, `CONTRACT.md`, and `inventory/DERIVED.md`.

## Ground rules

| Rule | Detail |
|---|---|
| Language | Talk to the owner in **Brazilian Portuguese**. Files you write stay in **English**: Lua, JSON, HTML, review logs, the handoff. Quote the owner's words verbatim, untranslated. |
| Where you write | **In the repository,** only inside `implementation/aseprite/deliveries/<Bxx-slug>/`. **In the toolkit,** only inside `game_assets/harvest_the_night/`, plus additive engine changes (below). |
| Never edit | The game: `src/`, `tools/`, `sprites/`, `assets/`, `project.godot`, scenes. Also never edit `implementation/backlog/` (packs, statuses, deliveries), `implementation/prompts/`, `implementation/aseprite/{inventory.py,inventory/,CONTRACT.md,RUNNER.md,README.md,INTEGRATION.md}`, or another game's folder in the toolkit. |
| The shared engine | `engine/*.lua` also builds WELCOME BACK, HERO (`game_assets/welcome_back_hero/`). Only add to it: new functions, or options whose default keeps today's behaviour. Non-square canvases (64x48, 40x32, 16x24...) are such an option. After an engine change, rebuild one of that game's characters and confirm its `out/` bytes did not change. |
| Where art comes from | The toolkit's Lua generators and Aseprite only. Never use AI image generation. Never copy, trace or recolour today's sprites. Never hand-edit an exported PNG: change the generator and rebuild. |
| The numbers | Canvas, pivot, frame count, timing, names and facing come from the inventory and are never changed on your own (CONTRACT.md "What decides what"). |
| Approval | Only the owner's explicit words approve a batch. Never infer approval. |
| Git | No commits unless the owner asks, and then only your batch's folder. Never push, never `git add -A` or `git add .`, never reset, stash or check out. The tree has other people's changes. |
| The game's tools | Never run `tools/task.py`, `implementation/backlog/assets.py set`, `tools/verify.py`, `tools/import_art.py` or Godot. Integration is Claude's. |

## The loop

Repeat steps 1-9 for each batch, in order, until B19 is approved or the
owner says stop.

### 1. Pick the batch

```
python implementation/aseprite/inventory.py status
```

- Continue a batch already `started`, `checked` or `check failing`. Never
  start a new one while one is open.
- Otherwise take the first `todo`.
- B00 always comes first: no batch is drawn before the palette and the look
  are approved.

Tell the owner, in one line, which batch you are on and how many frames it
has.

### 2. Read

1. **`inventory/<Bxx-slug>.md`:**
   - the batch notes;
   - every row: files, canvas, pivot, timing, facing, today's size, rules,
     points, brief.
2. **Every brief** the rows link to. For a pack, read "What it is for",
   "Deliverables", "Match these" and "Acceptance", and skip its Codex
   mechanics (CONTRACT.md).
3. **Today's art,** at 1x and zoomed:

   ```
   python implementation/aseprite/inventory.py sheet Bxx <your scratch folder>
   ```

   Also open the files in the row's `current`.
4. **`docs/reference-sheet.png`** (the look) and the approved farmer as the
   scale reference: B01's once it exists, today's
   `sprites/actors/idle_south_0.png` until then.
5. **When resuming,** read the delivery folder first (`contract.json`,
   `review-log.txt`, `checks.json`) and carry on from there.

### 3. Plan

- **Create `game_assets/harvest_the_night/`** in the toolkit the first time.
  Give it the skill's usual subfolders (`characters/`, `props/`, `icons/`,
  `floor/`, `ui/`...) and organise them as you see fit.
- **Decide which generators the batch needs.** Reuse what earlier batches
  built: the farmer's skeleton, the enemy body, the tower base.
- **List every output file** with its pose plan before drawing.

### 4. Draw and build

- **Use the palette** from B00 (`palette/harvest.gpl`) for every colour.
- **Build with the toolkit**, e.g. `GAME=harvest_the_night bash
  tools/build.sh <name>`, and look at every frame at 1x and at 6-8x zoom.
- **The order of work:**
  1. the master or standing pose first;
  2. check its size against the farmer and against today's version;
  3. then the strips.
- **Review your own frames against CONTRACT.md section 10** before going
  further.

### 5. Export

Write the native PNGs to `deliveries/<Bxx-slug>/png/<file>` exactly as the
inventory names them.
- **Copy into `source/`** the Lua generators, the `.aseprite` files and any
  engine file the batch needed.
- **Write `contract.json`** (CONTRACT.md section 9).
- **The export must be deterministic:** a rebuild gives the same bytes.

### 6. Check

```
python implementation/aseprite/inventory.py check Bxx --write
```

Fix every ERROR and run it again until it prints PASS. Read the warnings and
fix those you can. Explain the rest in `review-log.txt`.

### 7. Review with the owner

1. **Build `review/`** as CONTRACT.md section 8 says.
2. **Send the owner** (`SendUserFile`) the main boards:
   - the before-and-after;
   - the day and night scene;
   - the animated GIFs at 4x.
   
   Then give the path of `review/index.html`.
3. **Ask, in Portuguese,** about this batch: does it read at 1x, at night,
   beside the farmer? Does each thing look like what it is? Then ask: "Aprova
   para integração ou quer mudanças?"
4. **Log every round** in `review-log.txt`: the date, the owner's words
   verbatim, and what you changed.
5. **On changes:** change the generators, rebuild, re-export, re-check, show
   again.
   - Change only what the owner asked.
   - After three rounds on the same item, ask whether to continue, change
     the brief or move on.

### 8. Approve and hand off

Only after the owner's explicit approval:

1. Run `python implementation/aseprite/inventory.py check Bxx --write` one
   last time. It must PASS.
2. Write `APPROVAL.json` with the owner's words verbatim and the sha256 of
   every PNG.
3. Write `HANDOFF.md` (CONTRACT.md section 9).
4. Tell the owner, in Portuguese:
   - that batch Bxx is approved;
   - that they can hand it to the game's chat with:
     `Integra o lote Bxx do Aseprite: leia implementation/aseprite/INTEGRATION.md`;
   - that you are moving on to the next batch.

### 9. Next

Go back to step 1. Stop when:
- B19 is approved;
- the owner says to stop;
- or the owner's answer is pending. Then wait for it, and do not start the
  next batch.

## When something blocks you

- **A number is missing, or a brief contradicts the inventory:** ask the
  owner. Do not guess.
- **The toolkit cannot do something** (a canvas shape, a pose): extend it
  additively, or tell the owner what you would need.
- **A rule cannot hold for a good reason:** say so in `review-log.txt` and to
  the owner. If the owner accepts, record a deviation in contract.json with
  their words.
