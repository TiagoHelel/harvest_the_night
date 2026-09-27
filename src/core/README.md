# src/core/

The game rules. **Node-free and deterministic**: no nodes, no unseeded
randomness, no clock reads, no iterating an unordered Dictionary without sorting
the keys first. Everything advances through `Sim.tick(state)` at a fixed 30Hz.

The headless tests, the balance autoplayer, the skip-the-night button and the
guarantee that the browser build plays identically to the desktop one all
depend on that staying true.

Every number a designer might want to turn lives in `game_data.gd` with
`# LEVER` on it.
