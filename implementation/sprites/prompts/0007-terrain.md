# 0007 - Quiet ground, paths and natural rock terrain

- **Status:** todo
- **Depends on:** 0003
- **Likely files:** assets/art_source/terrain/; sprites/terrain/; tools/gen_sprites.py; src/ui/world_view.gd
- **Generation briefs:** TERRAIN

## Goal and requirements

Replace grass and its four variants, soil, path, floor and rock terrain. Reduce repetitive speckles and brick-like rock pattern. Keep 16 px exact tiles, terrain enum order and atlas row contract or migrate generator and view together. Do not alter FARM_MAP or use decorative variants to change walkability. Keep low contrast under actors.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Repeated 8x8 patches and full farm have no obvious seams or distracting tiling. Each material reads under day/dusk/night. Atlas check verifies every migrated tile and includes accepted sources. Native captures show actors clearly; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
