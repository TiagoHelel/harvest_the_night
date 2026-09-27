# src/app/

Application services: the things that are neither game rules nor drawing.

Settings, saving, audio, the scene router, translations, crash reporting. They
are **nodes, they touch the filesystem and they are not deterministic**, which
is exactly why they are not in `src/core/`.

`src/core/` earns its guarantee by being narrow: node-free, clock-free,
advanced only by `Sim.tick()`. `verify.py` checks that with the **core is pure**
row. A settings file that reads the disk would break it, so it lives here.

Nothing in here may be read by `src/core/`. The dependency runs one way:
`app` and `ui` know about `core`, and `core` knows about neither.
