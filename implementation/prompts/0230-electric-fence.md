# 0230 - The electric fence

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0196, 0132, 0176
- **Likely files:** src/core/game_data.gd, src/core/enemies.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

A barrier like the wooden fence, except whatever bites it is thrown back stunned for a moment - a winter answer that needs the generator running (plan section 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A042
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `electric_fence`: a barrier (`path_cost` and `hp` LEVERs, within `WIDEST_STEP` by `check_pathing`) with an `energy_draw`, a cost in copper (0176), with wood if it needs a frame, and `season` winter (0193's field). The shock is a stun, not `damage`, so no `Sfx.TOWER_SOUNDS` entry (`_task_0085_night_sounds` wants one exactly when a defence has `damage`; 0283 adds the zap)
- Stun in `Enemies._gnaw`: an enemy biting an electric fence is stunned for a LEVER of ticks (1-3 s) - a generic entity counter (any source may set it) read at the top of `Enemies._walk`, so a stunned enemy neither moves nor bites; 0233's farm bell writes the same counter. The bite still lands; decide whether bosses get a shorter stun or none. `check_defences` refuses a stun of zero ticks
- Needs power, degraded never dead: on a short farm the stun is scaled down by `Power.percent`, never to zero
- Joins like the fence: `WorldView.barrier_mask` joins only `wall` and `fence` today - add the electric fence (decide whether it meets a wooden one) and the placeholder road's `connected` flag, so the joins draw before the art arrives
- `Names.KEYS` `DEF_ELECTRIC_FENCE`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (fence-style modules for the 16 masks, whole/hurt, a wreck, a 3-frame zap) until A042 is integrated by 0241
- DATA moves (a new row); SIM moves only if the scenario meets one or a state key appears - record both numbers

## Done when

- [ ] `_task_0230_electric_fence` in `src/tools/headless_v1.gd` asserts a walker that bites it stands still for the stun and then bites again, a short farm shortens the stun without removing it, and the field prices it like a barrier
- [ ] The Deliverables table of `implementation/backlog/packs/A042-electric-fence.md` states the final geometry this task settled
- [ ] `python tools/shot.py 0230` captures of a joined run of electric fence, opened and looked at
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
