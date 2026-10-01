# 0003 - Playable pilot, pivots and depth sorting

- **Status:** done
- **Depends on:** 0002
- **Likely files:** src/ui/world_view.gd; src/ui/player_view.gd; scenes/World.tscn; src/tools/shot.gd; new visual showcase scene/tool
- **Generation briefs:** Use 0001 masters

## Goal and requirements

Integrate the pilot farmer, house, tree and walker through manifest metadata. Move visual nodes to ground pivots, offset textures, audit nested Actors y-sorting and make multi-cell buildings render once per anchor or use validated overhang-aware slices. Make shadows, lamp positions, ghosts and highlights agree with unchanged logical cells. Add deterministic visual showcases for occlusion, bounds, silhouettes, crop stages, tower states and animation frames. Keep the unchanged farm playable while assets migrate.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Fresh noon/dusk/wave captures beat the baseline in consistency. Walk farmer and enemies in front of and behind tree/house; no sorting reversal or duplicate house. Ghost base matches the build cell. Roof overhang works at map/camera edges. Review pilot at 480x270 before producing all families; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
