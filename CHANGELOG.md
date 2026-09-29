# CHANGELOG

What changed, in sentences a player would recognise. Newest first.

The version here and `VERSION` in `src/core/build_info.gd` move together;
`headless_check` fails if this file has no section for the one the build
says it is.

## 0.1.0 - prototype - unreleased

The first build that is worth putting in front of anybody.

### The game

- **Ten nights.** Farm by day, defend the same tiles by night, and the night
  starts when you send for it rather than on a timer.
- Sixteen crops, animals, fishing, a workshop, a press and a kitchen.
- Towers, walls, traps and a flare, powered by a generator that browns out
  when you ask too much of it.
- A tech tree of twelve upgrades across three branches.
- A stall that buys what you grow and sells what you have not built yet.
- Losing a night costs you a day and a share of the stock, never the run.

### Around it

- Seven tutorial lines that appear when they are relevant and go when they
  are done.
- English and Portuguese, switchable in the options without restarting.
- Every key rebindable, with the controls screen to do it on.
- High contrast, reduced flashing, a slower clock, and a picture scale for
  people who want the pixels bigger.
- A crash writes a folder you can read and send, and nothing is ever sent
  by the game itself.
- Your run is saved when you quit and survives an update.

### Fixed before it ever shipped

- **"Steady hands" and "a name at market" did nothing.** Both tech nodes were
  in the tree with a sentence about what they do, and nothing in the game
  read either one. Found by the release checklist the first time it was run,
  which is what a checklist is for.
