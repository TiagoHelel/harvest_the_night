# A028 - The dog

- **Status:** integrated
- **For game task:** 0245
- **Dressed by game tasks:** 0185
- **Spec after game task:** 0233
- **Family:** animals
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 7 animations, 20 frames (side view, west only)

## What it is for

The farm dog is a pet from day 1 (task 0185).

- **By day** it follows the farmer, sits when he stops, and wags when he pets it. It barks now and then.
- **At night** it sleeps by the porch.
- **From autumn**, the "call the dog" power (0233) sends it running across the dark farm to bite the zombie nearest the cursor, and then back. This is the only time it is seen in action at night.

At 1080p it must read as a friendly medium-sized farm dog next to the 32px farmer: smaller than a sheep, bigger than a hen. At night it must stay clearly a dog and clearly not a zombie, against dark grass and beside a walker.

## Deliverables

Final geometry settled by game task 0233. The rows stand as written: one 40x32 canvas on (20,30) for every animation, drawn at 1.0 - a large animal beside the 32 px farmer, smaller than a sheep and bigger than a hen. **How the game plays the night ones:** "call the dog" (unlocked in autumn) sends it off the porch at a run - `dog_run`, 3 ticks a tile (ten tiles a second), straight at the zombie nearest the cell the cursor aimed, or at the cell when there is none - to bite it there: `dog_bite` plays once over the bite's 9 ticks (0.3 s, its three frames at 0.1), standing beside the zombie's feet on the side it came from, facing it; then it runs back to the porch and sleeps. The run and the bite are the view's: the rules only know when the bite lands (the run's length by Manhattan, three ticks a tile) and on whom. `bite_xy` places the existing `impact` effect once the art lands; until then the bite is lined up 10 px from the zombie's feet. Until 0245 every dog animation, these two included, is the farm's cow small and brown through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `dog_sit_0..1` | 40x32 | (20,30) | 2 / 0.5 / loop | The day idle. 0 = the master pose: sitting, head up, facing west. 1 = an ear flick or a head tilt, with the same body. |
| `dog_wag_0..1` | 40x32 | (20,30) | 2 / 0.12 / loop | Standing and looking up and west, with the tail high in 0 and low in 1. The body and paws are identical. Plays while petted (A025's pet pose). |
| `dog_walk_0..3` | 40x32 | (20,30) | 4 / 0.15 / loop | The follow walk: contact, passing, opposite contact, opposite passing. |
| `dog_bark_0..2` | 40x32 | (20,30) | 3 / 0.1 / one-shot | Standing: head drawn back with the mouth closed, head forward with the mouth open, then the mouth closing. No sound lines. |
| `dog_sleep_0..1` | 40x32 | (20,30) | 2 / 0.6 / loop | Curled on the ground, head on its paws, eyes closed. 1 = back 1 px higher (a breath). Seen at night by the porch. |
| `dog_run_0..3` | 40x32 | (20,30) | 4 / 0.08 / loop | The night run: front paws landing, gathered, hind paws pushing off with the front reaching, stretched. At least one paw on row 29 in every frame (no airborne frame). |
| `dog_bite_0..2` | 40x32 | (20,30) | 3 / 0.1 / one-shot | Crouch with the weight back; lunge with the jaws open at a zombie's shin height, front paws allowed off the ground; recover with the mouth closed and all paws down. Frame 1 carries `bite_xy`. No zombie, blood or impact drawn. |

Rules for every row:

- **Direction and files.**
  - Every animation faces `west` only (head on the left). East is the runtime mirror, so never deliver it: `mirror: "runtime"` and `mirror_pairs: {}`.
  - The dog follows the farmer north and south with these side frames. There are no up or down cycles.
  - Files are `native/<anim>/west/01..NN.png`, and `01.png` is frame 0.
  - Claude writes them to `sprites/props/<runtime name>.png`.
- **Canvas.** The dog is a large animal (contract 2.2): 40x32 with pivot (20,30) and draw scale 1.0. This overrides the "24x24 / (12,22) unless the pack says otherwise" line in game task 0245.
- **Grounding.**
  - The lowest opaque row is 29 in every frame.
  - The visible bounds of `dog_sit_0` are centred on x=20 (±1).
  - The torso keeps one position per animation, apart from the run and the bite lunge.
  - The dog keeps one body size across every animation, within 1 px of the standing torso.
- **Visible targets** in native px. The farmer is 16x32.

  | Pose | Width | Height | Reads as |
  |---|---|---|---|
  | Standing | 20-22 | 15-17 | Ear tips at the farmer's hip |
  | Sitting | 13-15 | 17-19 | |
  | Running, stretched | 24-28 | 12-15 | |
  | Curled asleep | 16-20 | 8-10 | |
- **`bite_xy`.**
  - It is on `dog_bite_1` only: the front-most opaque pixel of the open jaw. Expect it near x 4-9, y 17-22; measure it, and it must be opaque.
  - Code uses it to line the bite up with the target and to place the existing `impact` effect.
- **Colours.** The default is a caramel farm dog of collie-shepherd type.
  - The back, ears and tail are `wood_light`, `wood` and `wood_dark`.
  - The muzzle, chest, paws and tail tip are cream (`bone_dark`, with `bone` highlights). These carry the night read.
  - The nose and eye are `ink_soft`, and the tongue is `roof_light`, shown only when barking or biting.
  - Ears are upright with folded tips, and the tail is bushy.
  - No collar or accessories.
- **`palette_keys`**: `ink, ink_soft, wood_dark, wood, wood_light, soil_dark, bone_dark, bone, roof_light`. A change is recorded and applies to every frame.

## Match these

- **The animal family.** A026's and A027's approved deliveries set the style, outline, camera and scale: `implementation/backlog/deliveries/A026-farm-animals/native/sheep_idle/west/01.png` and `.../A027-cow-chicken/native/cow_idle/west/01.png`. If either is not `approved`, ask the owner before you start.
- **The farmer.** `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/left/01.png` (side view, visible 17x31) and the contract's `.../walk/down/01.png`.
- **The zombie.** `sprites/enemies/walker_walk_0.png` (64x48, pivot (32,44), visible 18x29) is the bite target's height and the night contrast to beat. `sprites/enemies/walker_death_3.png` shows how low a body ends.
- **The look.** `assets/art_source/masters/style-night.png` and `docs/reference-sheet.png` show the farm by night and by day.
- **Effects.** `sprites/actors/shadow.png` and `sprites/effects/impact_0.png` are drawn by code. Never bake either.

## How to make it

1. **Prompt.** Build it as contract section 8 says: BASE + ANIMAL + STRIP, + CORRECTION for revisions.
   - In ANIMAL, set the species to dog, use "40x32 target canvas, contact pivot (20,30)", and replace the cow/chicken sentence with this species line: "a friendly medium farm dog, collie-shepherd type, caramel back with cream muzzle, chest, paws and tail tip, upright ears with folded tips, bushy tail; no collar, no snarl, not a wolf, not a mascot."
   - Add: "Side view facing WEST (head on the left), three-quarter top-down camera, top of the back lit."
   - For the bite, add: "an eager working-dog lunge, not a vicious attack."
2. **Tool.** Built-in ImageGen with `transparent_background=true` on every call, one subject per call. Attach:
   - A026's sheep master (role: family style and scale reference);
   - the farmer side-view frame (role: scale reference);
   - `sprites/enemies/walker_walk_0.png` (role: bite-height reference only, never drawn into the strip);
   - after the master is accepted, the master (role: identity master, or edit target).
3. **Order.**
   1. Generate a standing master (west, all four paws down). Reduce it and check it beside the farmer and the walker before anything else.
   2. Make `dog_sit_0` as an edit of the standing master, and `dog_sit_1` from `dog_sit_0`.
   3. Make `dog_wag_0` and `dog_wag_1` as edits of the standing master that change only the tail.
   4. Make `dog_sleep_0` as an edit of the master, and `dog_sleep_1` from `dog_sleep_0`.
   5. Make `walk`, `bark`, `run` and `bite` as one STRIP call each, with the master attached.
   
   Run at most 3 CORRECTION revisions per asset.
4. **Reduce** with the mode A recipe (`render_source`, imported read-only).
   - **Master.**
     - `crop_xywh` is the measured visible box.
     - Pick `content_scale` so the standing dog is 15-17 tall.
     - The default anchor puts the paws on row 29.
   - **Edits.** Reuse the master's crop and scale when the framing held. Otherwise revise the edit.
   - **Strips.**
     - Use same-size measured cell boxes, with the bottom edge on the strip's paw baseline.
     - Use one `content_scale` per strip, matched to the master's torso (±1 px).
     - A per-frame vertical crop offset is allowed only to land the contact row, and it is recorded.
   - If reduction erases the eye, the nose, the open jaw or the cream chest, regenerate. Never patch native pixels.

## Review with the owner

The page follows contract 9.5 and shows:

- every animation at 1x and 4x, playing and as a still strip, by day and in the night preview;
- the dog with the farmer (`walk/down/01.png` and `walk/left/01.png`), A026's sheep and A027's hen on one ground line;
- `dog_bite_1` beside `walker_walk_0.png` by day and at night, with `bite_xy` on a separate overlay;
- `dog_sleep` over tiled grass in the night preview;
- an east preview made by flipping, as a preview only;
- an onion skin of every frame over the standing master.

Ask the owner:

1. "O tamanho do cachorro ao lado do fazendeiro, e do zumbi na mordida, está certo?"
2. "A cor padrão é caramelo com focinho, peito e patas creme. Prefere assim ou preto e branco?"
3. "Na prévia noturna, a corrida e a mordida leem bem contra a grama escura e o zumbi?"

## Acceptance

- [ ] There are 20 frames, the exact count per row, every one 40x32 with pivot (20,30), all facing west, and no east files.
- [ ] The lowest opaque row is 29 in every frame (no airborne run frame), and `dog_sit_0` is centred on x=20 (±1). The paws do not slide in sit, wag, bark or sleep, and the wag moves only the tail.
- [ ] The body size matches across animations in the onion skin, and each strip has one `content_scale`. Walk and run frame 3 leads back to 0, and bark and bite end.
- [ ] `bite_xy` sits on an opaque jaw pixel of `dog_bite_1`, and `points_on_opaque` is true.
- [ ] Alpha is binary on a true transparent background. There is no shadow, zombie, blood, impact, bowl, sound lines or text.
- [ ] Only the 42 colours are used, within `palette_keys`, and `importer_recipe_matches` holds.
- [ ] Sizes are inside the targets. At night the cream patches keep the dog readable and distinct from the walker.
- [ ] `build.py` twice gives identical bytes, `--check` passes, and checks.json is all `true`.

## Delivery

Deliver to `implementation/backlog/deliveries/A028-dog/` with `raw/`, `native/`, `preview/`, `rejected/`, contract.json, checks.json, build.py, index.html and review-log.txt (contract 9.1-9.6). This pack has no `runtime/`.

contract.json has:

- `palette_mode: "A"` and `palette_keys`;
- for every animation, `dir: "west"`, `mirror: "runtime"` and `draw_scale: 1.0`;
- `points: {"bite_xy": [x, y]}` on the `dog_bite` animation and on its frame 1 file entry.

After the owner approves, write APPROVAL.json (9.7) and CLAUDE-A028-PROMPT.txt (9.8).

- The prompt maps every animation, for example `native/dog_run/west/01..04.png -> sprites/props/dog_run_0..3.png  40x32 pivot (20,30) draw 1.0  0.08 s loop`.
- It says these replace 0185's day stand-in and the night dog stand-in of 0233's `call_dog` power.
- It says the canvas is 40x32, not 24x24.

The last step is `python implementation/backlog/assets.py set A028 approved`, and only after the owner approves in words recorded in APPROVAL.json.
