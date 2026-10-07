# src/tools/

Scripts run by `tools/verify.py`, never by the game.

- `headless_check.gd` - the rules, asserted with no window (task 0004)
- `determinism.gd` - the scripted scenario behind the hash guard (task 0005)
- `input_check.gd` - real clicks and keys through the real UI (task 0011)
- `headless_v1.gd` / `input_v1.gd` - the same two suites for every task from
  0112 on; the old pair keeps tasks up to 0111 (task 0112)
- `suite_kit.gd` - plain helpers the suites share, moved rather than copied
  (task 0112)
- `autoplayer.gd` - plays the ten nights for balance data (task 0067)
- `shot.gd` - named screenshot scenarios (task 0082)

Excluded from both export presets: none of it ships.
