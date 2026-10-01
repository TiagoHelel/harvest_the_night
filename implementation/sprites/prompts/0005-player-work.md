# 0005 - Player farming, gathering and production actions

- **Status:** done
- **Depends on:** 0004
- **Likely files:** assets/art_source/player/; sprites/actors/; src/ui/player_art.gd; src/ui/player_frames.gd; src/ui/player_view.gd
- **Generation briefs:** PLAYER_WORK

## Goal and requirements

Produce separate short cycles for chop, mine, till, plant, water, fish/cast, reel, harvest, carry, craft, trade/collect and repair. Start with four frames per action and declare any deliberate alias; do not quietly retain a one-frame craft placeholder. Keep tools inside the common canvas and match contact timing to existing action state. Side-on work can remain a documented choice; don't claim four-direction action art unless generated. Update VERBS and metadata without changing core verbs/timers.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Each known verb triggers a purposeful matching animation in game. Axe/pick/tool contact is believable; fishing cast/reel and repair are distinguishable. Idle/walk interrupt correctly; action cancellation doesn't leave a tool pose stuck. Contact sheets cover every verb or explicitly reviewed alias; verify/hash guards pass.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
