# src/tools/

Scripts run by `tools/verify.py`, never by the game.

- `headless_check.gd` - the rules, asserted with no window (task 0004)
- `determinism.gd` - the scripted scenario behind the hash guard (task 0005)
- `input_check.gd` - real clicks and keys through the real UI (task 0011)
- `autoplayer.gd` - plays the ten nights for balance data (task 0067)
- `shot.gd` - named screenshot scenarios (task 0082)

Excluded from both export presets: none of it ships.
