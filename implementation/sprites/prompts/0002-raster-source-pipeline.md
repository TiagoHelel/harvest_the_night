# 0002 - Raster source ownership and deterministic importer

- **Status:** done
- **Depends on:** 0001
- **Likely files:** tools/gen_sprites.py; tools/cut_sheet.py; tools/verify.py; assets/art_source/manifest.json; tools/import_art.py (new)
- **Generation briefs:** Use approved 0001 masters; no new generation required

## Goal and requirements

Implement the PIPELINE.md manifest, source validation, explicit crop boxes, shared scaling, palette/alpha conversion, pivots and deterministic PNG output with --check. Add single-owner dispatch to legacy writers/checks and verification. Migrate the pilot assets and ALL affected derivatives together. Old terrain atlas, fixture slices and player cutter must not overwrite migrated art. Keep legacy checks for every unmigrated output. Generate matching view metadata instead of hand-copying dimensions. Preserve original source sheets.

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

Rebuild twice with identical bytes. A changed accepted source fails --check until regenerated. A tampered migrated output fails; a tampered legacy output still fails. Missing source, duplicate owner, invalid crop and missing runtime frame fail. Restore deliberate corruption before closing. Full verify passes, sim/data hashes unchanged.

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
