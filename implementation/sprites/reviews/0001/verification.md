# Task 0001 baseline verification

Date: 2026-10-01. Godot:
`C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe`.

Baseline normalization regenerated 99 PNG files from their unchanged existing
sources after comparing image size and every decoded RGBA pixel. All changes
were encoding only, recorded with old/new SHA-256 in `normalization.json`.
No generator logic, owner sheet, simulation or balance baseline was changed.

The full `python tools/verify.py` run after normalization printed **PASS**:
23 passed, 0 skipped, 0 failed in 164 seconds. Godot imported successfully and
parsed 101 scripts with 0 failures. Headless checks passed 6417 assertions;
input checks passed 980 cases. Windows/Web exports passed. Performance passed.
Simulation hash remained `1961000123`; data hash remained `407837701`.

This establishes the verified starting point for producing the style sources.
Final source QA and screenshots will be recorded separately after generation.

## Final verification after source generation and palette extension

The final full run printed **PASS**, 23 passed, 0 skipped, 0 failed in 166
seconds. All 101 scripts parsed. Headless checks passed 6417 assertions, input
checks passed 980 cases and both Windows/Web exports passed. Simulation/data
hashes remained `1961000123` / `407837701`. Full output: `verify-full.log`.

All six source/prompt/reference SHA-256 records were rechecked. The scoped
native-review builder regenerated every native/contact/grid image byte-identically
on a second run; its palette and binary-alpha assertions passed. All art-loop
Python sources compiled. No production raster importer exists yet; that is 0002.

The existing screenshot tool wrote all five scenarios into
`implementation/shots/sprites/0001/`, with 5 written, 0 failed. Noon, dusk,
wave, result and tech were opened for review. Noon/dusk/wave were also compared
to the archived baseline, with identical decoded RGBA pixels. The new identity
masters are deliberately not substituted into gameplay until the following
source-ownership and playable-integration tasks.
