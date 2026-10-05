# HARVEST THE NIGHT

> A cozy farming game where your farm is also your fortress.
>
> By day, plant, fish, mine and produce. When you choose, switch reality: the
> same farm becomes the map you defend against the horde. Everything you make
> during the day decides what tonight can hold.
>
> **Build your farm. Build your defence. Find out if it survives.**

A Godot 4.7 game. `design.md` is the design document and the source of truth for
intent; `docs/reference-sheet.png` is the source of truth for the look.

---

## Status

The Godot project is playable and the original 110-task implementation backlog
is complete. The separate 20-task sprite queue is also complete, with
source-owned raster art, native animations and final visual review. See
[the art delivery catalogue](implementation/sprites/DELIVERY.md) for native sizes,
sources, animation coverage, reproduction commands and known limits.

```bash
python tools/task.py stats
python tools/task.py next
```

## Building it

The whole game is built by a loop that does one backlog task per invocation.
From the Claude Code desktop app:

```
/loop Read and execute implementation/prompts/00-RUNNER-LOOP.md
```

See [implementation/README.md](implementation/README.md) for the unattended
driver, the task lifecycle and the phase plan.

## Verifying it

```bash
python tools/verify.py
```

One command, every check, PASS or FAIL. Checks whose target the backlog has not
built yet print SKIP with the task number that will create them.

```bash
python tools/verify.py --fast      # skip the exports
python tools/verify.py --accept    # record a determinism hash that moved on purpose
```

Godot comes from `$GODOT`, defaulting to
`C:/Users/PC GAMER DA FAMILIA/Documents/Godot/Godot_v4.7.2-stable_win64_console.exe`.

## Running it

From the repository root, with Godot set in your environment:

```bash
"$GODOT" --path .
```

There is no zoom, as in Stardew Valley: at 1920x1080 a tile is 64 pixels and
the farmer is two tiles (128 pixels) tall. The camera follows the farmer
smoothly on both axes. The farmer walks in eight directions with the reviewed
blue walk; Shift plays the same walk faster.

The farm is Stardew Valley's Standard Farm size, 80x65 tiles. The previous
45x25 farm is its top left corner, unchanged; around it are a tree line, roads
out east and south, woods, a forest with a pond, an orchard, a second pond with
a jetty and open ground strewn with stones and saplings. Buildings reuse the
exterior art at twice its previous scale, and the 60 planting beds are where
they were. Saves from every earlier farm (40x18, 45x20, 45x25) keep crops,
inventory and production at the same coordinates.

During the day, stand at the farmhouse's front door and press Interact
(Space or Enter by default) to enter. Walk around the furnished room, then walk
through the southern doorway to return outside. The same pause controls work
indoors. Crops keep growing during visits; starting defence returns you
outside. Furniture is decorative with solid collision; sleep, storage and cooking
interactions inside the house are not implemented.

---

## The shape of the thing

| | |
|---|---|
| Engine | Godot 4.7, `gl_compatibility` so the Web export works |
| Resolution | 480x270 base, 16px tiles, integer scaling only |
| The farm | one 80x65 grid (5,200 cells, Stardew's Standard Farm), plus the enterable farmhouse room |
| Simulation | one fixed 30Hz `Sim.tick(state)` for day growth and night combat alike |
| Pathing | a flow field from the house, not A* per zombie |
| Language | English throughout; pt-BR is a translation file at task 0097 |

**`src/core/` is node-free and deterministic.** It advances only through
`Sim.tick(state)`: no nodes, no unseeded randomness, no clock reads, no
iterating an unordered Dictionary without sorting the keys. `src/ui/` draws and
reads input and owns no rules - nothing it does may be visible to the
determinism hash.

That one decision is what buys the headless tests, the balance autoplayer, the
"skip the night" button and the guarantee that the browser build plays
identically to the desktop one.

Every number a designer might want to turn lives in `src/core/game_data.gd` with
`# LEVER` on it. Art is generated from ASCII maps in `tools/gen_sprites.py` and
sound from `tools/gen_sfx.py`: nothing is hand-authored.

## The loop the game is

```
   FARM, DAY  ->  produce  ->  craft and sell  ->  build the defence
        ^                                                |
        |                                    SWITCH REALITY
        |                                                v
   improve  <-  rewards  <-  survive or lose  <-  FARM, NIGHT
```

The MVP asks one question, and task 0066 is where it gets answered: *after
surviving the first night, do you want to go back to the farm and improve your
defence to see what happens next?*
