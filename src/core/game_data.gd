class_name GameData
extends RefCounted

## Every number a designer might want to turn, in one place.
##
## Task 0003 fills this out - crops, gathering, prices, recipes, buildings,
## towers, enemies, waves, rewards - and adds `validate()`. For now it holds the
## clock, which is the one thing task 0002 needs.
##
## `# LEVER` marks a balance dial: a number whose value is a design choice. A
## number without it is structural, and changing it breaks something rather than
## tuning it.


## Simulation rate, in ticks per second.
##
## Everything in the game advances at this rate: crop growth, tower fire, zombie
## walking, the headless tests, the double speed button and skipping a night are
## all the same code run a different number of times.
##
## **Not a lever.** Changing it rescales every duration in the game at once and
## invalidates the determinism hash. Tune durations, not the clock.
const TICK_HZ := 30

## Seconds of real time in one tick.
const TICK_SECONDS := 1.0 / float(TICK_HZ)

## The most ticks one frame may simulate before the rest is thrown away.
##
## A frame that stalls - alt-tab, a breakpoint, the first import, a laptop
## waking up - comes back owing whole seconds of simulation. Paying all of it in
## one frame makes the next frame stall too, and that is how a spiral starts.
## The cap means a long stall costs the player a moment of game time instead of
## a frozen window.
const MAX_CATCH_UP_TICKS := 8   # LEVER: 8 ticks is about a quarter of a second
