class_name PerfNames

## Which systems the benchmark times, in the order the sim ticks them.
##
## Its own file because two scripts need the same list and neither should
## own it: `src/tools/perf_check.gd` walks it to produce a row per system,
## and `src/tools/headless_check.gd` compares it against what `Sim.tick()`
## actually calls. Kept as a written-down list rather than discovered from
## the source, so that a system leaving the benchmark is a line somebody
## deleted on purpose rather than a row that stopped appearing.


## Every system `Sim.tick()` calls during a night, in call order.
const NIGHT: Array = [
	&"Power", &"Waves", &"Ability", &"Enemies", &"Traps", &"Towers",
	&"Combat", &"Building", &"Player", &"Reactions",
]

## And during a day.
const DAY: Array = [
	&"Power", &"Building", &"Farming", &"Gathering", &"Livestock",
	&"Tutorial", &"Crafting", &"Player", &"Reactions",
]
