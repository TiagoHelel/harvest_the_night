# 0020 - Whole-game visual review and deliverable catalogue

- **Status:** todo
- **Depends on:** 0019
- **Likely files:** implementation/sprites/PROGRESS.md; implementation/sprites/DELIVERY.md (new); src/tools/shot.gd; docs/PLAYTEST.md
- **Generation briefs:** CORRECTION only for assets failing review

## Goal and requirements

Review the final farm, dense crop beds, all work verbs/facings, every structure/level/state, mixed waves, Giant, death playback, menus and accessibility settings. Fix remaining missing/fallback assets within the art scope. Check source-to-output ownership coverage and regenerate from a clean working tree without calling ImageGen. Produce a catalogue/contact sheets with native canvases, pivots, animation coverage, source links and known limits. Do not claim shipping based on one nice farm shot.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Full python tools/verify.py including Windows/Web exports passes or documented environmental blockers remain blocked. Sim/data hashes unchanged from planning baseline. All visual contract criteria have concrete capture evidence. Final source regeneration changes no bytes; no required placeholders/missing textures or unreviewed aliases; delivery catalogue exists.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
