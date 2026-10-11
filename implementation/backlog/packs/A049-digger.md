# A049 - The digger

- **Status:** todo
- **For game task:** 0263
- **Dressed by game tasks:** 0250
- **Spec after game task:** 0250
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 24 PNGs: 1 master, 6 animations (22 frames), 1 forecast head

## What it is for

The digger is autumn's tunneller. It walks like a zombie on open ground, dives under fences and barricades, travels under them as a moving mound of soil, and comes up on the other side. Only a real wall stops it, and it gnaws walls like a walker. While it is underground, towers cannot target it. The player sees, at night:

- a hunched clawed zombie going down at a fence line;
- a mound crossing under the fence;
- the zombie bursting up behind it.

At 1x the mound must read as "something under the ground", not as a rock or a dirt prop, and the digger must not look like the breaker (big arms) at a glance.

## Deliverables

Final geometry settled by game task 0250. The rows stand as written: 64x48 standing on (32,44), the frames and seconds of the table. **How the game plays them:**
- **On open ground:** it walks at 16 ticks a tile, a little under two tiles a second, on the four `walk` frames at 0.125 s each, facing the way it moves. A wall or the house it gnaws as a walker does; until 0263 it does that on its walk frames, and `attack` waits for it.
- **Under a barrier it can dig under:** the fence, the barricade and the electric fence (every barrier's row says whether; the wall and the sandbag wall are not among them). For as long as it is on that cell it shows `mound_0..2` at 0.125 s each, with no shadow, and the barrier is drawn over it, so the posts cut across the mound as it slides under them. Nothing that hits reaches it there; the bell's peal still stuns it.
- **Burrow and emerge:** until 0263 tracks the dive and the climb, it goes straight from the walk to the mound and back. From 0263 `burrow_0..3` plays once going in and `emerge_0..3` once coming out, so `burrow_3` must match `mound_0` as the table says.
- **Death:** until 0263 the corpse is `digger_death_3`, squashed.
- **Night colours:** the relight takes the soil ramp down to the night ground's own tone, and a mound in mid soil disappeared into it. What reads is a body at the light end of the soil ramp under a dark top edge, with a pale crest. Keep the mound lighter than the ground it heaves under.

Until 0263 every frame but the mound stands in as the walker, tinted soil-brown (`PlaceholderArt`), and the mound is drawn in code (`DiggerArt`), both through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/digger` | 64x48 | (32,44) | 1 / 0.1 / static | Identity master, standing and hunched, facing `west`. Visible 20-26 wide x 25-27 tall: lower than the walker's 29. |
| `enemies/digger_walk_0..3` | 64x48 | (32,44) | 4 / 0.125 / loop | Facing `west`, mirrored at runtime. A low, knuckle-dragging shuffle with the claws swinging. |
| `enemies/digger_burrow_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | Facing `west`. (0) crouches and raises its claws, (1) dives head-first with clods thrown up, (2) only its back and legs are above a heap of soil, (3) only the soil heap is left. Frame 3 matches `mound_0` in size and shape (±1 px). |
| `enemies/digger_mound_0..2` | 64x48 | (32,44) | 3 / 0.125 / loop | Facing `west`. A low soil mound 14-18 wide x 5-7 tall, with a short trail of loose soil behind it (east, at most 8 px). The crest heaves west and the clods shift from frame to frame. These are drawn frames, not vertical shifts. No grass or ground tile. |
| `enemies/digger_emerge_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | Facing `west`. (0) the mound bulges and cracks, (1) the claws burst up, (2) the head and shoulders come out with clods, (3) it stands as in `walk_0`. |
| `enemies/digger_attack_0..2` | 64x48 | (32,44) | 3 / 0.1 / one-shot | A two-claw rake to the west: anticipation, contact, recovery. |
| `enemies/digger_death_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | Buckles, drops to its knees, falls forward, lies flat (at most 16 tall). |
| `ui/head_digger` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **Every frame, the mound included:**
  - the lowest opaque row is 43 (the pivot row is 44);
  - the body or mound is centred on x=32 (±1);
  - a 1 px clear border: only columns 1-62 and rows 1-43 hold pixels;
  - no two frames are identical;
  - one `content_scale` per strip.
- **One body scale:** a standing pose is 25-27 tall in the master, the walk, emerge frame 3 and attack frame 2.
- **The soil clods** in burrow, mound and emerge are the subject here (the creature's own spoil), not a baked ground patch. They use only the soil ramp.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 16 tall.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `digger` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `digger_walk_b` (= walk_2), `digger_attack` (= attack_1) and `digger_death` (= death_3). Do not deliver them.
- **Delivery paths:** `native/digger/west/01.png` and `native/digger_<walk,burrow,mound,emerge,attack,death>/west/01..NN.png`, plus `native/head_digger/none/01.png`.

## Match these

- `sprites/enemies/walker.png` and `walker_walk_0..3.png`, `walker_attack_0..2.png` and `walker_death_0..3.png`:
  - 64x48, pivot (32,44);
  - standing visible 15-19 x 28-29, feet on row 43;
  - the death ends 26x10.
  
  Match the scale, the outline, the rot palette and the contrast.
- `sprites/enemies/breaker.png` (visible 25x29, big arms): the digger must stay clearly different. It is lower, hunched and long-clawed, never broad-armed.
- `sprites/buildings/fence.png` (16x32, pivot (8,28), visible 4x13), `fence_join_10.png` and `sprites/buildings/barricade.png` (16x24, visible 14x9): what it tunnels under. The mound must read in front of and under these.
- `sprites/terrain/soil.png` and `sprites/crops/tilled.png` (16x16): the soil colours the mound must match. The mound is quieter than an actor but louder than terrain.
- `sprites/props/rock.png` (16x16): the mound must not read as a rock. It is soft, crumbly soil with clods, not a hard grey lump.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32).
- `assets/art_source/enemies/walker/master.png` and `walk-v2.png`: an accepted raw master and strip. `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER, with WALKER's old targets replaced by: 64x48 canvas, contact pivot (32,44), hunched standing body 26 px.
   - Add: "The digger: a hunched zombie miner, low and long, with a broken miner's helmet that has no lamp, soil caked on torn overalls, rot-green skin, and two long shovel-like claws of bone and broken nails. Side view facing west (left). Its back is bent nearly level, and the claws are the identity."
   - Attach `docs/reference-sheet.png` (style reference), `assets/art_source/enemies/walker/master.png` (same-world enemy) and `assets/art_source/enemies/breaker/master.png` (marked "a silhouette to avoid").
   - Make two candidates. Keep the one with the larger silhouette distance from the breaker.
2. **Strips.**
   - Prompt: BASE + ENEMY_STRIP + STRIP, one call per strip: walk, burrow, mound, emerge, attack, death.
   - Attach the accepted master raw as the identity master.
   - For the mound call, also attach the accepted burrow raw, so the mound continues the burrow's last heap. Add: "only a low mound of loose brown soil moving left, no creature visible, no grass, no ground tile".
3. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the broken helmet, the face and the tip of one claw at the shoulder".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/digger_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
4. **Tool argument:** `transparent_background=true` on every call.
5. **Export.**
   - One `content_scale` per strip. The body strips are scaled from their standing pose (26 px). The mound and burrow are scaled so that `burrow_3` and `mound_0` match.
   - Set the anchors so the lowest opaque row is 43 and the body or mound is centred on x=32.
   - Render through `import_art.render_source`.
   - The body strips use no `palette_keys`. The head follows A011's rule (above).
   - `digger_mound` uses `palette_keys` `["ink","ink_soft","soil_dark","soil","soil_light","wood_dark","stone_dark"]`, so the soil never borrows grass or rot green.

## Review with the owner

`index.html` follows contract 9.5. It shows every animation at 1x and 4x, playing and still, by day and in the night preview, next to the farmer and the walker. It also shows a scene on tiled `sprites/terrain/grass.png`, by day and at night, laid out on 16 px cells: a three-cell east-west fence run (`fence_join_2.png`, `fence_join_10.png`, `fence_join_8.png`).

The sequence plays in order:

1. the digger walks in from the east;
2. it burrows on the first fence cell;
3. the mound loop crosses the three cells;
4. it emerges one cell west of the run and walks on.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "O monte de terra se lê como algo passando por baixo da cerca, e não como uma pedra ou um monte de terra parado?"
2. "O escavador se distingue do destruidor a 1x, de dia e de noite?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 24 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every frame: lowest opaque row 43, centred on x=32 (±1), the 1 px clear border.
- [ ] No walk frame and no mound frame is another shifted vertically by 2 px or less.
- [ ] The walk and mound loops close.
- [ ] `burrow_3` and `mound_0` differ by at most 1 px in width and height. `emerge_3` stands at the master's height (±1).
- [ ] The mound is 14-18 wide and 5-7 tall (the trail excluded). It uses only the listed soil keys.
- [ ] The death never grows taller and ends at most 16 tall.
- [ ] `checks.json` `silhouette_distances` (the `silhouette()` of `tools/check_enemy_art.py`, master against `sprites/enemies/{walker,runner,tank,breaker}.png`) are each at least 16.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A049-digger/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `silhouette_distances`;
  - `silhouette_distinct`;
  - `burrow_meets_mound`;
  - `death_settles`;
  - `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A049-PROMPT.txt`:
  - `native/digger/west/01.png -> sprites/enemies/digger.png  64x48 pivot (32,44) draw 1.0`;
  - `native/digger_walk/west/01..04.png -> sprites/enemies/digger_walk_0..3.png  0.125 s loop`;
  - `native/digger_burrow/west/01..04.png -> sprites/enemies/digger_burrow_0..3.png  0.1 s one-shot`;
  - `native/digger_mound/west/01..03.png -> sprites/enemies/digger_mound_0..2.png  0.125 s loop`;
  - `native/digger_emerge/west/01..04.png -> sprites/enemies/digger_emerge_0..3.png  0.1 s one-shot`;
  - `native/digger_attack/west/01..03.png -> sprites/enemies/digger_attack_0..2.png  0.1 s one-shot`;
  - `native/digger_death/west/01..04.png -> sprites/enemies/digger_death_0..3.png  0.1 s one-shot`;
  - `native/head_digger/none/01.png -> sprites/ui/head_digger.png  16x16 pivot (8,8)`.
  
  The handoff also says:
  - burrow plays on the tick 0250 puts it underground;
  - the mound loops while it stays there;
  - emerge plays when it surfaces.
- **Last step:** `python implementation/backlog/assets.py set A049 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
