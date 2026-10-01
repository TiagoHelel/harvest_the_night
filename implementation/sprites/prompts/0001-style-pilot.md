# 0001 - Direction, scale and identity masters

- **Status:** done
- **Depends on:** nothing
- **Likely files:** docs/reference-sheet.png; docs/sprites_sem_fundo.png; tools/palette.py; assets/art_source/masters/
- **Generation briefs:** STYLE, PLAYER_MASTER, HOUSE, TREE, WALKER

## Goal and requirements

First resolve the pre-existing PNG byte-only baseline failures described in
AUDIT.md: compare decoded pixels, regenerate from unchanged sources deliberately,
review the encoding-only diff and obtain a full verifier PASS without changing
hash baselines or disabling checks.

Generate a compact neutral-day style board and a night lighting study. Produce identity masters for the farmer, house, tree and walker. Compare their visible body sizes in a shared composition over 16 px cells. Preserve the farmer's identity, establish materials/palette and record the chosen native dimensions and pivots. The proposed dimensions in ART_DIRECTION.md are the starting point. Sources are references at this stage; runtime integration belongs to 0003. Freeze the accepted style in ART_DIRECTION.md and record raw-source hashes.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Open baseline and reference next to the board. Farmer, house, tree and walker read as one game; no photoreal/painted character mismatch. Saved masters, source hashes, exact prompts and explicit scale decision exist. Mark art production done only after the masters actually exist.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
