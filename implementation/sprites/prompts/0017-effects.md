# 0017 - Combat and work effects in the same pixel language

- **Status:** done
- **Depends on:** 0014, 0016
- **Likely files:** assets/art_source/effects/; src/ui/particles.gd; src/ui/world_view.gd; src/ui/juice.gd; src/ui/lighting.gd
- **Generation briefs:** FX

## Goal and requirements

Create a small consistent set of muzzle flashes, impacts, flame/smoke, harvest dust, splashes and flare burst where raster forms improve readability. Keep effective low-cost procedural particles where they already match the style. Align emission to pivots/muzzles; share palette and bounded pools. Respect reduced motion/particle density. No new gameplay effects or damage changes.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Busy wave, simultaneous deaths and work actions remain readable without a screen of glare. Fire stays warm at night, smoke stays subdued. Accessibility settings work and density changes leave simulation identical. Runtime perf and verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
