# 0013 - Four tower families at three authored levels

- **Status:** done
- **Depends on:** 0012
- **Likely files:** assets/art_source/defences/; sprites/buildings/gun_tower*,flame_tower*,mortar*,auto_crossbow*; tools/gen_sprites.py; src/ui/world_view.gd; src/ui/lighting.gd
- **Generation briefs:** TOWER

## Goal and requirements

Produce gun, flame, mortar and automatic crossbow with level 1/2/3, hurt and fire states plus wrecks. The mine is handled in 0014. Levels change base reinforcement, mechanism and weapon form, not merely repeat post pixels. Keep common canvas/pivot per family; author muzzle positions as metadata. Disable legacy band-growth/flash/damage derivations only for migrated families with complete replacements. Existing mechanics and placement stay unchanged.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Show each family/level/state in the showcase. L1 and L3 instantly distinguishable; functions differ in silhouette. Firing/damaged state paths resolve, projectile/glow origin matches muzzle, ghost base matches one cell. Mixed-defence night capture and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
