# src/ui/

Drawing and input. **Owns no rules.** It reads the core state and never writes
to it.

Shake, particles, lighting, damage numbers and transitions all live here, and
none of them may be visible to the determinism hash. A task in this directory
that moves the hash is a bug, not a new baseline.

## Art that has not arrived (task 0120)

New things go on screen before Codex has drawn them, through **one road**:

- **The registry**, `placeholder_art.gd` (`PlaceholderArt.POSES`): one line per
  runtime animation drawn before its pack is integrated - the pack id, frames,
  seconds and loop from the pack's Deliverables table, the stand-in it plays
  meanwhile, the stand-in's own geometry and the pack's final one.
- **The lookup**, `PlaceholderArt.frame(path)`: the only reader of
  `RasterArt.FRAMES` in this directory. It answers from the real art first and
  the registry second; `PlaceholderArt.texture_path(path)` says which file to
  load. The farmer's door is `PlayerArt.animation(name)` and
  `PlayerArt.texture_path(name, frame)`, which fall back on the registry when
  `PlayerFrames` has no such name.
- **A stand-in is never a hand-painted PNG**: an existing texture (reused,
  tinted, scaled or mirrored), an ASCII map built by `tools/gen_sprites.py`, or a
  code-drawn shape, at the canvas and pivot the real art will have.
- **Adding**: a line in `POSES` (keep it on one line). **Deleting**: when the
  pack's raster outputs land at the same paths, its leaf deletes the line and
  no view code changes. `python tools/placeholders.py` lists what is still on
  stand-ins; `--check` (in verify) fails on an entry for a pack already
  integrated, a missing pack, or a path that is already raster-owned.
