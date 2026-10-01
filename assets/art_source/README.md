# Accepted art sources

`masters/` contains task 0001's accepted ImageGen identity/style references:
`farmer.png`, `house.png`, `tree.png`, `walker.png`, `style-day.png` and
`style-night.png`. Preserve these original generated pixels; regenerate variants
with the accepted master as a reference instead of repainting these files.

The masters are source references and are not yet selected by the live game's
rendering code. Task 0002 owns production import/ownership; task 0003 integrates
the playable pilot. Do not overwrite `sprites/` with these large raw images.

`masters/master-contract.json` records measured source crop boxes, native review
dimensions, pivots and SHA-256. Exact prompts, reference roles and hashes are
under `implementation/sprites/generation/0001-*`; source review evidence is in
`implementation/sprites/reviews/0001/`.

To regenerate the task 0001 native review/contact sheets:

```powershell
python implementation/sprites/reviews/0001/build_preview.py
```

This does nearest reduction, fixed-canvas placement, binary alpha and mapping
to `tools/palette.py`. It writes review images only; it does not replace runtime
assets or implement the production importer. The original owner sheet in
`docs/sprites_sem_fundo.png` remains unchanged.
