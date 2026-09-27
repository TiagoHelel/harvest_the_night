class_name GameData
extends RefCounted

## Every number a designer might want to turn, in one place.
##
## Nothing in here branches, calls a node or computes anything: it is data, and
## `validate()` at the bottom is the only function. A rule that needs a number
## reads it from here; a number that appears anywhere else in `src/core/` is a
## bug waiting for a balance pass to find it.
##
## `# LEVER` marks a balance dial - a number whose value is a design choice,
## with its unit and a sane range beside it. A number without `# LEVER` is
## structural: changing it breaks something rather than tuning it.
##
## **Durations are in ticks**, at `TICK_HZ` to the second, because the rules
## never see real seconds. `SECONDS` at the bottom converts for readability at
## the point of writing, not at runtime.
##
## The reference sheet, `docs/reference-sheet.png`, is where the resource,
## tower and enemy line-ups come from. `design.md` is where the scope comes
## from: ten nights, one boss, no more.


# ============================================================ time and the tick

## Simulation rate, in ticks per second.
##
## Everything advances at this rate: crop growth, tower fire, zombie walking,
## the headless tests, the double speed button and skipping a night are all the
## same code run a different number of times.
##
## **Not a lever.** Changing it rescales every duration below at once and
## invalidates the determinism hash. Tune durations, not the clock.
const TICK_HZ := 30

## Seconds of real time in one tick.
const TICK_SECONDS := 1.0 / float(TICK_HZ)

## Ticks in a second, for writing durations readably: `4 * SECONDS`.
const SECONDS := TICK_HZ

## The most ticks one frame may simulate before the rest is thrown away.
##
## A frame that stalls - alt-tab, a breakpoint, a laptop waking up - comes back
## owing whole seconds. Paying all of it in one frame makes the next frame stall
## too, and that is how a spiral starts. The cap costs the player a moment of
## game time instead of a frozen window.
const MAX_CATCH_UP_TICKS := 8           # LEVER: ticks, 4-16

## How long a day runs before dusk.
##
## The day does not end on its own: `design.md` promises the player switches
## reality when they want to. Past dusk the night button starts asking, and that
## is all it does.
const DAY_TICKS := 240 * SECONDS        # LEVER: ticks, 120-480 seconds worth
const DUSK_AT_TICK := 192 * SECONDS     # LEVER: ticks, 0.7-0.9 of DAY_TICKS

## The build window between pressing the night button and the first spawn.
const PREPARATION_TICKS := 20 * SECONDS # LEVER: ticks, 10-45 seconds worth


# ===================================================================== the farm

## The whole world, in tiles. About 1.3 screens wide and just over one tall at
## 480x270, which is what `design.md` asks for.
const GRID_WIDTH := 40
const GRID_HEIGHT := 18
const TILE_SIZE := 16

## What the farmhouse can take before the night is lost.
const HOUSE_HP := 100                   # LEVER: hit points, 60-200

## How fast the player walks, in `Player.SUBTILE` units per tick.
##
## 64 units is a tile and there are 30 ticks a second, so 6 is 2.8 tiles a
## second - brisk enough to cross the farm without the day feeling like a
## commute, slow enough that the farm feels like a place rather than a menu.
const PLAYER_SPEED := 6                 # LEVER: subtile units per tick, 3-12


# ================================================================== resources

const WOOD := &"wood"
const STONE := &"stone"
const IRON := &"iron"
const FOOD := &"food"
const FISH := &"fish"
const OIL := &"oil"
const WHEAT := &"wheat"
const CORN := &"corn"
const CARROT := &"carrot"
const MEAT := &"meat"
const GUNPOWDER := &"gunpowder"
const MONEY := &"money"
const ENERGY := &"energy"

## Every resource the ledger knows about, in the order the reference sheet
## lays them out.
const RESOURCES: Array = [
	WOOD, STONE, IRON, FOOD, FISH, OIL,
	WHEAT, CORN, CARROT, MEAT, GUNPOWDER, MONEY, ENERGY,
]

## What the shop will buy, and for how much.
##
## `design.md` sets wood, stone, iron, wheat, fish and oil; the rest follow the
## same scale. Money is not here because money does not sell for money, and
## neither does energy, which is a rate rather than a stock (task 0033).
const SELL_PRICE: Dictionary = {        # LEVER: money each, 1-30
	WOOD: 2,
	STONE: 3,
	IRON: 7,
	FOOD: 12,
	FISH: 8,
	OIL: 10,
	WHEAT: 4,
	CORN: 5,
	CARROT: 3,
	MEAT: 9,
	GUNPOWDER: 14,
}

## What the shop charges, as a multiple of what it pays.
##
## Above 1 by design and by a wide margin: buying a material must always be
## worse than going and getting it, or money quietly replaces playing the game.
const BUY_MARKUP := 2.5                 # LEVER: multiplier, 1.8-3.5

## How much of a structure's cost comes back when it is sold.
const SELL_BACK_FRACTION := 0.6         # LEVER: fraction, 0.4-0.8

## What the player wakes up on day 1 with.
##
## `design.md` section 5: a small amount. Small enough that day 1 is about
## going and getting things, large enough to buy the first seeds and put up the
## first fence without standing around. Deliberately no iron: the first tower
## has to be earned at the rock face, which is the lesson day 1 teaches.
const STARTING_RESOURCES: Dictionary = {   # LEVER: units each, 0-40
	MONEY: 25,
	WOOD: 12,
	STONE: 6,
}


# ===================================================================== crops

## The three crops of `design.md`, each with a different reason to plant it.
##
## ## Money, attention, capital - pick two
##
## Per plot across a 240 second day, with the seed paid for:
##
##     carrot  60s   seed $1   net  5  x 4 harvests  = 20     four visits
##     wheat   90s   seed $2   net  6  x 2 harvests  = 12     two visits
##     corn   180s   seed $4   net 11  x 1 harvest   = 11     one visit
##
## Carrot pays the most and costs the least to start - and wants you standing in
## the field all day. Corn pays the least and asks for one visit and four
## dollars, so it is what you plant before going down the mine. Wheat is neither
## and beats each of them at something: more money than corn, half the walking
## of carrot.
##
## **No crop is better than another on money, visits and seed cost at once** -
## `check_crops()` enforces that, so a later balance pass cannot quietly flatten
## the choice. Before this was tuned it was flat: wheat paid 10 a day to
## carrot's 8 for half the walking and a cheaper seed, which is not a choice,
## it is a trap.
##
## The **seed costs** are what carry the balance; the sale prices are
## `design.md` section 6 and stay where the document put them.
##
## On top of the money each one feeds something the others do not: wheat is the
## money crop, corn is the industry crop - oil and gunpowder come out of it -
## and carrot is the food crop, which is what repairs a wall at three in the
## morning. Which is why corn stays worth planting even on the arithmetic
## above: the day you need gunpowder, corn is the only crop that makes any.
const CROPS: Dictionary = {
	WHEAT: {
		"seed_cost": 2,                 # LEVER: money, 1-8
		"growth_ticks": 90 * SECONDS,   # LEVER: ticks, 30-180 seconds worth
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,
	},
	CORN: {
		"seed_cost": 4,                 # LEVER: money, 1-10
		"growth_ticks": 180 * SECONDS,  # LEVER: ticks, 90-300 seconds worth
		"yield": 3,                     # LEVER: units per harvest, 2-5
		"stages": 4,
	},
	CARROT: {
		"seed_cost": 1,                 # LEVER: money, 1-8
		"growth_ticks": 60 * SECONDS,   # LEVER: ticks, 30-120 seconds worth
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,
	},
}

## How much faster a watered tile grows, and how long the watering lasts.
##
## Unwatered is slower, never dead: this is a cozy game and a missed chore is
## not a punishment. Thirty-five percent brings carrot in at forty-four seconds
## instead of sixty - far enough apart to see across a field, not so far that
## forgetting ruins a day.
##
## **A percentage, not a fraction.** This was `0.35` from the day the table was
## laid out, and nothing ever read it. A float in `src/core/` is a desync
## waiting for a machine that rounds differently, so it became an integer the
## moment something needed it: `Farming.tick()` banks it in hundredths of a
## tick and pays out whole ticks, which is exact for any percentage.
const WATER_GROWTH_BONUS := 35          # LEVER: percent faster, 10-60
const WATER_LASTS_UNTIL_NIGHT := true

## How many tiles one canful waters.
##
## The field is forty-eight plots, so watering all of it is six trips to the
## water. That is the chore: worth doing, never required, and the reason the
## well is somewhere you have to walk to.
const WATER_CAN_CAPACITY := 8           # LEVER: tiles per fill, 3-20


# ================================================================== gathering

## Trees, rocks and ore: how long a hit takes, what it gives, how long until it
## comes back. Nothing on the farm can be exhausted permanently.
const GATHERING: Dictionary = {
	&"tree": {
		"work_ticks": 1 * SECONDS,      # LEVER: ticks per swing, 15-90
		"hits": 3,                      # LEVER: swings to fell it, 1-6
		"yield": {WOOD: 3},             # LEVER: units, all on the last swing
		"regrow_ticks": 120 * SECONDS,  # LEVER: ticks, 60-240 seconds worth
		"leaves": &"stump",
	},
	# A boulder sitting on the lawn. **It does not come back**, and that is
	# the reward for clearing one: the cell underneath becomes build space for
	# good. The farm still cannot be stripped, because stone comes out of the
	# rock face for ever - see `seam` below.
	&"rock": {
		"work_ticks": 2 * SECONDS,      # LEVER: ticks per swing, 20-120
		"hits": 2,                      # LEVER: swings, 1-4
		"yield": {STONE: 2},            # LEVER: units, 1-4
		"regrow_ticks": 0,              # 0 means gone for good, not a lever
	},
	# The rock face, which `design.md` section 5 says gives stone and iron.
	# Five seams at 3 stone, back every 90 seconds: about 39 stone across a
	# 240 second day of nothing but mining, against 10 for a wall.
	&"seam": {
		"work_ticks": 2 * SECONDS,      # LEVER: ticks per swing, 20-120
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {STONE: 3},            # LEVER: units, 2-5
		"regrow_ticks": 90 * SECONDS,   # LEVER: ticks, 45-180 seconds worth
	},
	&"ore": {
		# Iron is the thing you are always slightly short of, and that is
		# deliberate: it gates every tower. A node has to come back inside a day
		# or the whole rock face yields one iron per node per day, and a 15 iron
		# tower would take three days of nothing but mining. Six nodes, remined
		# four times, is about 24 iron a day for 144 seconds of a 240 second day
		# spent at the rock face - one tower, and a real cost.
		"work_ticks": 2 * SECONDS,      # LEVER: ticks per swing, 20-120
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {IRON: 1},             # LEVER: units, 1-2
		"regrow_ticks": 60 * SECONDS,   # LEVER: ticks, 30-120 seconds worth
	},
}

## Fishing: how long the wait is, how long you have to react, how often it is
## the good one. The pond pays the most per action and costs attention rather
## than resources.
const FISHING: Dictionary = {
	"bite_min_ticks": 2 * SECONDS,      # LEVER: ticks, 1-4 seconds worth
	"bite_max_ticks": 10 * SECONDS,     # LEVER: ticks, 5-20 seconds worth
	"window_ticks": 45,                 # LEVER: ticks to react, 20-60
	"rare_in": 6,                       # LEVER: 1 in N is the rare one, 4-12
	"common_yield": {FISH: 1},
	"rare_yield": {FISH: 3},
}


# ==================================================================== recipes

## What turns into what, and how long it takes.
##
## The bridge the whole game rests on: everything here takes something the day
## produced and makes something the night needs.
const RECIPES: Dictionary = {
	# **A kit is the structure's cost, paid in advance.** The inputs below are
	# the same numbers as the `cost` in DEFENCES, and `check_recipes()` refuses
	# a build where they have drifted apart - they were already 4 wood against
	# 3 the day this was noticed.
	&"barricade_kit": {
		"station": &"workshop",
		"inputs": {WOOD: 3, STONE: 2},
		"output": {&"barricade": 1},
		"ticks": 6 * SECONDS,           # LEVER: ticks, 3-15 seconds worth
	},
	&"fence_kit": {
		"station": &"workshop",
		"inputs": {WOOD: 5},
		"output": {&"fence": 1},
		"ticks": 5 * SECONDS,           # LEVER: ticks, 3-12 seconds worth
	},
	&"wall_kit": {
		"station": &"workshop",
		"inputs": {STONE: 10},
		"output": {&"wall": 1},
		"ticks": 10 * SECONDS,          # LEVER: ticks, 5-20 seconds worth
	},
	&"press_oil": {
		"station": &"press",
		"inputs": {CORN: 4},
		"output": {OIL: 1},
		"ticks": 20 * SECONDS,          # LEVER: ticks, 10-40 seconds worth
	},
	&"make_gunpowder": {
		"station": &"workshop",
		"inputs": {CORN: 2, OIL: 1},
		"output": {GUNPOWDER: 2},
		"ticks": 15 * SECONDS,          # LEVER: ticks, 8-30 seconds worth
	},
	&"cook_meal": {
		"station": &"kitchen",
		"inputs": {CARROT: 2, WHEAT: 1},
		"output": {FOOD: 2},
		"ticks": 12 * SECONDS,          # LEVER: ticks, 6-25 seconds worth
	},
	&"cook_fish": {
		"station": &"kitchen",
		"inputs": {FISH: 1, CARROT: 1},
		"output": {FOOD: 3},
		"ticks": 15 * SECONDS,          # LEVER: ticks, 8-30 seconds worth
	},
	&"cook_roast": {
		"station": &"kitchen",
		"inputs": {MEAT: 1, CORN: 1},
		"output": {FOOD: 4},
		"ticks": 18 * SECONDS,          # LEVER: ticks, 10-35 seconds worth
	},
}

## How many items a production building may have queued at once.
const QUEUE_LENGTH := 5                 # LEVER: items, 3-10


# ================================================================== buildings

## The production side of the farm. Energy draw is what task 0033 turns into a
## reason to care where the generator is.
const BUILDINGS: Dictionary = {
	&"workshop": {
		"cost": {WOOD: 20, STONE: 10},
		"energy_draw": 0,
		"size": Vector2i(2, 2),
	},
	&"press": {
		"cost": {WOOD: 25, IRON: 5},
		"energy_draw": 2,               # LEVER: energy per tick, 1-5
		"size": Vector2i(2, 2),
	},
	&"kitchen": {
		"cost": {WOOD: 15, STONE: 15},
		"energy_draw": 1,               # LEVER: energy per tick, 0-3
		"size": Vector2i(2, 2),
	},
	&"generator": {
		"cost": {IRON: 20, STONE: 10},
		"energy_draw": 0,
		"energy_output": 10,            # LEVER: energy per tick, 5-20
		"fuel": {OIL: 1},
		"fuel_every_ticks": 30 * SECONDS,   # LEVER: ticks, 15-60 seconds worth
		"size": Vector2i(2, 2),
	},
}

## What a structure runs at when the farm is drawing more energy than it makes.
##
## Degraded, never dead: a brown-out should slow the defence and let the night
## resolve, not switch the towers off and end it.
const BROWNOUT_RATE := 0.5              # LEVER: fraction of normal, 0.25-0.8


# =================================================================== defences

const DAMAGE_IMPACT := &"impact"
const DAMAGE_FIRE := &"fire"
const DAMAGE_EXPLOSIVE := &"explosive"

## The six things from the reference sheet that go on the farm at night.
##
## `range` and `min_range` are in tiles. `reload_ticks` is the gap between
## shots. Task 0042 turns these entries into declarative behaviour so the combat
## code stops growing a branch per tower.
const DEFENCES: Dictionary = {
	&"gun_tower": {
		"cost": {WOOD: 10, IRON: 15},
		"hp": 60,                       # LEVER: hit points, 30-120
		"damage": 6,                    # LEVER: per shot, 3-12
		"damage_type": DAMAGE_IMPACT,
		"range": 5,                     # LEVER: tiles, 3-8
		"reload_ticks": 1 * SECONDS,    # LEVER: ticks, 15-60
		"projectile_tiles_per_second": 14,
		"energy_draw": 1,               # LEVER: energy per tick, 0-3
		"targets": 1,
	},
	&"flame_tower": {
		"cost": {WOOD: 20, IRON: 25, OIL: 10},
		"hp": 70,                       # LEVER: hit points, 40-140
		"damage": 3,                    # LEVER: per tick in the cone, 1-6
		"damage_type": DAMAGE_FIRE,
		"range": 3,                     # LEVER: tiles, 2-5
		"cone_degrees": 60,             # LEVER: degrees, 30-90
		"burn_ticks": 3 * SECONDS,      # LEVER: ticks, 1-6 seconds worth
		"burn_damage": 2,               # LEVER: per second burning, 1-5
		"ammo": {OIL: 1},
		"ammo_every_ticks": 2 * SECONDS,
		"energy_draw": 2,
	},
	&"mortar": {
		"cost": {STONE: 30, IRON: 35, GUNPOWDER: 15},
		"hp": 55,                       # LEVER: hit points, 30-100
		"damage": 40,                   # LEVER: at the centre, 20-70
		"damage_type": DAMAGE_EXPLOSIVE,
		"range": 12,                    # LEVER: tiles, 8-16
		# A minimum range is what makes placing a mortar a decision rather than
		# a purchase: it cannot defend itself.
		"min_range": 4,                 # LEVER: tiles, 2-6
		"splash_tiles": 2,              # LEVER: tiles, 1-3
		"splash_falloff": 0.5,          # LEVER: fraction at the edge, 0.2-0.8
		"reload_ticks": 5 * SECONDS,    # LEVER: ticks, 3-8 seconds worth
		"flight_ticks": 45,             # LEVER: ticks in the air, 20-75
		"ammo": {GUNPOWDER: 1},
		"energy_draw": 1,
	},
	&"auto_crossbow": {
		"cost": {WOOD: 15, IRON: 20},
		"hp": 50,                       # LEVER: hit points, 30-90
		"damage": 3,                    # LEVER: per bolt, 1-6
		"damage_type": DAMAGE_IMPACT,
		"range": 7,                     # LEVER: tiles, 5-10
		"reload_ticks": 15,             # LEVER: ticks, 8-30
		"projectile_tiles_per_second": 22,
		"pierce": 5,                    # LEVER: targets in the line, 2-8
		"pierce_falloff": 0.4,          # LEVER: fraction lost each, 0.2-0.6
		"energy_draw": 3,               # hungry: the reason to build a generator
	},
	&"mine": {
		"cost": {IRON: 5, GUNPOWDER: 8},
		"hp": 1,
		"damage": 60,                   # LEVER: on trigger, 30-100
		"damage_type": DAMAGE_EXPLOSIVE,
		"splash_tiles": 1,              # LEVER: tiles, 1-2
		"one_shot": true,
		"energy_draw": 0,
	},
	&"fence": {
		"cost": {WOOD: 5},
		"hp": 30,                       # LEVER: hit points, 15-60
		"path_cost": 6,                 # LEVER: tiles-equivalent detour, 3-12
		"energy_draw": 0,
	},
	&"wall": {
		"cost": {STONE: 10},
		"hp": 120,                      # LEVER: hit points, 60-250
		"path_cost": 20,                # LEVER: tiles-equivalent detour, 10-40
		"energy_draw": 0,
	},
	&"barricade": {
		"cost": {WOOD: 3, STONE: 2},
		"hp": 20,                       # LEVER: hit points, 10-40
		"path_cost": 4,                 # LEVER: tiles-equivalent detour, 2-8
		# It may go down mid-wave, which nothing else may - and it expires, so
		# it cannot quietly become a cheaper wall.
		"placeable_at_night": true,
		"lifetime_ticks": 60 * SECONDS, # LEVER: ticks, 30-120 seconds worth
		"per_night_limit": 5,           # LEVER: how many, 2-10
		"energy_draw": 0,
	},
}

## What repairing costs, per hit point put back.
const REPAIR_COST_PER_HP: Dictionary = {FOOD: 1, WOOD: 1}
const REPAIR_TICKS_PER_HP := 3          # LEVER: ticks, 1-8
const HOUSE_REPAIR_PENALTY := 2.0       # LEVER: multiplier, 1.5-3.0

## The one button the player has during a night.
const ABILITY: Dictionary = {
	"damage": 25,                       # LEVER: in the area, 10-50
	"radius_tiles": 3,                  # LEVER: tiles, 2-5
	"slow_fraction": 0.5,               # LEVER: fraction of speed, 0.2-0.8
	"slow_ticks": 5 * SECONDS,          # LEVER: ticks, 2-10 seconds worth
	"cooldown_ticks": 45 * SECONDS,     # LEVER: ticks, 20-90 seconds worth
}

## How long something stays lit after it is hit.
##
## Long enough to read at 30 ticks a second, short enough that a crowd being
## shot does not become a wall of white.
const HURT_TICKS := 5                   # LEVER: ticks, 2-12

## Speeds the night may be watched at. Ticks per tick, never a changed rate.
const SPEEDS: Array = [1, 2, 4]


# ==================================================================== enemies

## The four of `design.md` plus the one boss.
##
## Speed is **ticks to cross one tile**, so it stays an integer and two machines
## cannot disagree about where a zombie is. Lower is faster.
const ENEMIES: Dictionary = {
	&"walker": {
		# **Ten, not five.** Twelve of them is night one, and at five damage a
		# farm with nothing built on it survived the tutorial night with forty
		# hit points to spare - so the one night whose job is to teach that you
		# have to build taught the opposite. At ten, twelve walkers are 120
		# against a house of 100: undefended loses, one tower holds it with
		# room. Task 0068 sweeps the rest of this table against the autoplayer.
		"hp": 20,                       # LEVER: hit points, 10-40
		"ticks_per_tile": 20,           # LEVER: ticks, 12-30 (lower is faster)
		"damage": 10,                   # LEVER: to the house, 4-16
		"reward": 3,                    # LEVER: money, 1-6
		"armour": 0,
	},
	&"runner": {
		# Fast and fragile: it arrives before a mortar can reload, which is what
		# makes a defence of only slow expensive towers wrong.
		"hp": 10,                       # LEVER: hit points, 6-20
		"ticks_per_tile": 9,            # LEVER: ticks, 6-14
		"damage": 3,                    # LEVER: to the house, 1-6
		"reward": 4,                    # LEVER: money, 2-8
		"armour": 0,
	},
	&"tank": {
		# Armour is flat and applies per hit, so many small hits are worse than
		# a few big ones. That is the reason the mortar exists.
		"hp": 120,                      # LEVER: hit points, 70-220
		"ticks_per_tile": 38,           # LEVER: ticks, 30-50
		"damage": 15,                   # LEVER: to the house, 8-25
		"reward": 12,                   # LEVER: money, 6-20
		"armour": 3,                    # LEVER: damage off each hit, 1-6
	},
	&"breaker": {
		# It goes for what you built rather than what you live in, which makes
		# an uncovered tower line a liability.
		"hp": 45,                       # LEVER: hit points, 25-80
		"ticks_per_tile": 21,           # LEVER: ticks, 15-30
		"damage": 8,                    # LEVER: to the house, 4-14
		"structure_damage_multiplier": 3.0,   # LEVER: multiplier, 2.0-5.0
		"targets_structures": true,
		"reward": 8,                    # LEVER: money, 4-14
		"armour": 1,
	},
	&"giant": {
		"hp": 900,                      # LEVER: hit points, 500-1600
		"ticks_per_tile": 50,           # LEVER: ticks, 40-70
		"damage": 40,                   # LEVER: to the house, 25-60
		"structure_damage_multiplier": 4.0,
		"targets_structures": false,
		"telegraph_ticks": 1 * SECONDS, # LEVER: ticks before the heavy hit
		"reward": 120,                  # LEVER: money, 60-200
		"armour": 6,                    # LEVER: damage off each hit, 3-10
		"is_boss": true,
	},
}


# ====================================================================== nights

## The ten nights of `design.md`, section 10.
##
## A night is a list of waves; a wave is `[enemy, count, spawn, delay_ticks]`,
## where `delay_ticks` is the gap after the previous wave. Task 0059 formalises
## this into a validated table and task 0060 tunes the curve - what is here is
## the shape, so that the first playable build of task 0027 has three waves to
## fight and the rest has somewhere to grow.
const WAVE_GAP_TICKS := 15 * SECONDS    # LEVER: ticks, 8-30 seconds worth

## How long between two members of the same wave.
##
## Eight zombies materialising on one tick is a magic trick; eight walking out
## of the dark in a line is a wave, and it gives the towers something to do
## while the player watches.
const SPAWN_INTERVAL_TICKS := 20        # LEVER: ticks, 8-45

const NIGHTS: Array = [
	# 1 - the tutorial night: winnable with the one tower the first day buys.
	[[&"walker", 3, 0, 0], [&"walker", 4, 0, WAVE_GAP_TICKS],
	 [&"walker", 5, 0, WAVE_GAP_TICKS]],
	# 2 - more of the same, from two sides.
	[[&"walker", 6, 0, 0], [&"walker", 5, 1, WAVE_GAP_TICKS],
	 [&"walker", 8, 0, WAVE_GAP_TICKS]],
	# 3 - the first runner.
	[[&"walker", 6, 0, 0], [&"runner", 3, 1, WAVE_GAP_TICKS],
	 [&"walker", 8, 0, WAVE_GAP_TICKS], [&"runner", 5, 1, WAVE_GAP_TICKS]],
	# 4 - a bigger version of what night 3 taught.
	[[&"walker", 10, 0, 0], [&"runner", 6, 1, WAVE_GAP_TICKS],
	 [&"walker", 12, 0, WAVE_GAP_TICKS]],
	# 5 - the first tank.
	[[&"walker", 8, 0, 0], [&"tank", 1, 0, WAVE_GAP_TICKS],
	 [&"runner", 6, 1, WAVE_GAP_TICKS], [&"tank", 2, 0, WAVE_GAP_TICKS]],
	# 6 - everything so far, mixed.
	[[&"walker", 12, 0, 0], [&"runner", 8, 1, WAVE_GAP_TICKS],
	 [&"tank", 3, 0, WAVE_GAP_TICKS], [&"walker", 14, 1, WAVE_GAP_TICKS]],
	# 7 - the breakers arrive and go for the towers.
	[[&"walker", 10, 0, 0], [&"breaker", 4, 1, WAVE_GAP_TICKS],
	 [&"runner", 8, 0, WAVE_GAP_TICKS], [&"breaker", 6, 1, WAVE_GAP_TICKS]],
	# 8 - a large night.
	[[&"walker", 18, 0, 0], [&"runner", 10, 1, WAVE_GAP_TICKS],
	 [&"breaker", 6, 0, WAVE_GAP_TICKS], [&"tank", 4, 1, WAVE_GAP_TICKS]],
	# 9 - the heavy mix, and the dress rehearsal for the Giant.
	[[&"walker", 20, 0, 0], [&"breaker", 8, 1, WAVE_GAP_TICKS],
	 [&"tank", 5, 0, WAVE_GAP_TICKS], [&"runner", 14, 1, WAVE_GAP_TICKS],
	 [&"tank", 3, 0, WAVE_GAP_TICKS]],
	# 10 - the Giant, with company so it cannot be focused down alone.
	[[&"walker", 14, 0, 0], [&"giant", 1, 0, WAVE_GAP_TICKS],
	 [&"walker", 16, 1, WAVE_GAP_TICKS], [&"breaker", 8, 1, WAVE_GAP_TICKS]],
]

## How many nights the MVP has. Past this, task 0070 generates them.
const MVP_NIGHTS := 10

## Where the horde comes in, as `[[x, y], ...]` per spawn point.
##
## The wave tables above name these by index: `0` is the east edge, which is
## the open ground the farm was drawn to have, and `1` is the south, across the
## bottom of the map. A cell that is not walkable or cannot reach the house is
## skipped at spawn time rather than being kept in step by hand here.
##
## **Two sides, not four.** A farm attacked from every direction at once cannot
## be defended with the handful of towers a first night affords, and the reason
## to choose where a wall goes disappears with it.
const SPAWNS: Array = [
	# 0 - the east edge, down the open right-hand side.
	[[39, 4], [39, 5], [39, 6], [39, 7], [39, 8], [39, 9],
	 [39, 10], [39, 11], [39, 12], [39, 13]],
	# 1 - the south, along the bottom of the open ground.
	[[26, 14], [28, 14], [30, 14], [32, 14], [34, 14],
	 [24, 13], [36, 13]],
]


# ===================================================================== rewards

## What a night pays, and what losing one costs.
const REWARDS: Dictionary = {
	# Paid for finishing the night at all, growing with the night number.
	"base_money": 30,                   # LEVER: money, 15-60
	"money_per_night": 15,              # LEVER: money added per night, 5-30
	"resources": {WOOD: 10, STONE: 8, IRON: 4},
	"resources_per_night": {WOOD: 4, STONE: 3, IRON: 2},
	# Defending well should pay more than barely holding.
	"intact_structure_bonus": 4,        # LEVER: money each, 1-10
	"house_untouched_bonus": 25,        # LEVER: money, 10-50
	"tech_points": 1,                   # LEVER: per night survived, 1-2
}

## Losing a night takes a share of the stock. It must hurt enough to matter and
## little enough to keep playing: `design.md` is explicit that a loss costs a
## day, never the run.
const DEFEAT_RESOURCE_LOSS := 0.25      # LEVER: fraction, 0.1-0.4
const DEFEAT_KEEPS_MONEY := true
const DEFEAT_KEEPS_TECH := true


# ====================================================================== the map

## The farm, as one 40x18 picture.
##
## **The whole world is this map**, by day and by night alike: `design.md`
## pillar 1 is that there is one farm and it is everything, and pillar 2 is that
## the night is the same tiles doing a different job. Two maps would be two
## things to keep in step, and they would drift the first week.
##
## Regions are not coordinates written down somewhere else - they are what the
## characters say. Move the pond by editing the pond.
##
##     .  grass          s  soil, the field       ~  water
##     #  rock face      p  path                  =  wooden floor and jetty
##     T  tree           r  loose rock            o  iron ore
##     S  stone seam     W  the workshop
##     H  the farmhouse  $  the shop stall
##
## `validate()` checks the shape, so a row typed one character short is a red
## line rather than a farm that is subtly wrong down one edge.
const FARM_MAP: Array = [
	"TTT.TTTT....TTT..TT.....TTT...TT..TTT.TT",
	"T...................#####...........T..T",
	"T..ssssss......ppp..##S##r.o...........T",
	"...ssssss.....pHHHp.#S###..o...........T",
	"...ssssss......HHH..###S##o.....r.......",
	"T..ssssss......HHH...###S#.............T",
	"...ssssss.....ppppp..#S###r...o.........",
	"T.........w...............o............T",
	"..ssssss....WW.p....r.....r...........TT",
	"..ssssss....WW.p...$$........o...T.T...T",
	"..ssssss.......p...............rTT.TT.TT",
	"T..............p.................TT.T..T",
	".....r.........p....T.........TT.TT.TT..",
	"T.........=====p......T.........TT.T...T",
	"..~~~~~~~~=====.........................",
	".~~~~~~~~~~~~~~~~~..............TT......",
	"~~~~~~~~~~~~~~~~~~~~~~~....TT.........TT",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~..TTT...TTTTTT",
]

## What each character means: the terrain under it, and what is standing on it.
## Terrain values are `Farm.Terrain`; an empty occupant is `&""`.
const MAP_LEGEND: Dictionary = {
	".": [0, &""],          # grass
	"s": [1, &""],          # soil
	"~": [2, &""],          # water
	"#": [3, &""],          # rock face
	"p": [4, &""],          # path
	"=": [5, &""],          # wooden floor
	"T": [0, &"tree"],
	"r": [0, &"rock"],
	"o": [3, &"ore"],
	"S": [3, &"seam"],
	"H": [5, &"house"],
	"$": [5, &"shop"],
	"W": [5, &"workshop"],
	"w": [0, &"well"],
}


# ==================================================================== validate

## Every id that one table points at, checked against the table that defines it.
##
## Returns a list of problems, empty when there are none. `headless_check` calls
## it, so a typo in a recipe is a red line the same minute rather than a crash
## on night 7.
##
## The checks below each take their table rather than reading the constant, so
## that `headless_check` can hand one a deliberately broken table and assert
## that it complains. A validator nobody has ever seen fail is a validator
## nobody should trust.
static func validate() -> Array:
	var errors: Array = []
	errors.append_array(check_crops(CROPS))
	errors.append_array(check_gathering(GATHERING))
	errors.append_array(check_recipes(RECIPES))
	errors.append_array(check_buildings(BUILDINGS))
	errors.append_array(check_defences(DEFENCES))
	errors.append_array(check_nights(NIGHTS))
	errors.append_array(check_map(FARM_MAP))

	for key in [&"common_yield", &"rare_yield"]:
		for res in (FISHING[key] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("fishing %s yields unknown '%s'" % [key, res])

	for res in REPAIR_COST_PER_HP:
		if not RESOURCES.has(res):
			errors.append("repair costs unknown '%s'" % res)

	for key in [&"resources", &"resources_per_night"]:
		for res in (REWARDS[key] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("rewards %s gives unknown '%s'" % [key, res])

	if DUSK_AT_TICK > DAY_TICKS:
		errors.append("dusk falls after the day is over")

	return errors


## Sort ids alphabetically, by the text of them.
##
## **`Array.sort()` on StringNames does not do this.** GDScript compares a
## StringName by its internal pointer, which is fast and is why the type
## exists - and which means a "sorted" array of them comes out in the order the
## strings happened to be interned in. Measured, not assumed: adding a fourth
## crop produced `[pumpkin, carrot, corn, wheat]` out of a `.sort()`.
##
## That order is stable within a build and changes when somebody moves two
## `const` lines, which is the worst kind of stable: the rules would iterate in
## a different order and the determinism hash would move, for a diff that
## touched no behaviour at all. Every place in `src/core/` that sorts ids goes
## through here.
static func sorted_names(values: Array) -> Array:
	var text: Array = []
	for v in values:
		text.append(String(v))
	text.sort()
	var out: Array = []
	for s in text:
		out.append(StringName(s))
	return out


static func check_crops(crops: Dictionary) -> Array:
	var errors: Array = []
	for crop_id in crops:
		if not RESOURCES.has(crop_id):
			errors.append("crop '%s' is not a resource" % crop_id)
		if not SELL_PRICE.has(crop_id):
			errors.append("crop '%s' has no sell price" % crop_id)
		if int((crops[crop_id] as Dictionary)["growth_ticks"]) <= 0:
			errors.append("crop '%s' grows in no time at all" % crop_id)

	# **No crop may be the right answer at every money level.** A crop that
	# pays at least as much per day, for no more visits, off a no larger seed,
	# is a crop that makes every other one a mistake - and three crops one of
	# which is always correct is one crop and two traps.
	#
	# This is computed rather than asserted so that the fourth crop somebody
	# adds is checked on the way in, at boot, by name.
	var ids := sorted_names(crops.keys())
	for a in ids:
		for b in ids:
			if a == b:
				continue
			var x := _crop_offer(crops, a)
			var y := _crop_offer(crops, b)
			if x["value"] >= y["value"] and x["visits"] <= y["visits"] 					and x["seed"] <= y["seed"]:
				errors.append(("crop '%s' dominates '%s' - %s against %s; "
					+ "move a seed cost") % [a, b, x, y])
	return errors


## What one plot of a crop offers over a day: money, trips, and the money it
## takes to start. The three axes `check_crops()` refuses to let one crop win
## outright.
static func _crop_offer(crops: Dictionary, id: StringName) -> Dictionary:
	var data: Dictionary = crops[id]
	var visits := DAY_TICKS / maxi(int(data["growth_ticks"]), 1)
	var net := int(data["yield"]) * int(SELL_PRICE.get(id, 0)) 		- int(data["seed_cost"])
	return {"value": net * visits, "visits": visits,
		"seed": int(data["seed_cost"])}


static func check_gathering(nodes: Dictionary) -> Array:
	var errors: Array = []
	for node_id in nodes:
		for res in ((nodes[node_id] as Dictionary)["yield"] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("gathering '%s' yields unknown '%s'"
					% [node_id, res])
	return errors


static func check_recipes(recipes: Dictionary) -> Array:
	var errors: Array = []
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if not BUILDINGS.has(recipe["station"]):
			errors.append("recipe '%s' wants unknown station '%s'"
				% [recipe_id, recipe["station"]])
		for res in (recipe["inputs"] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("recipe '%s' takes unknown '%s'"
					% [recipe_id, res])
		for out in (recipe["output"] as Dictionary):
			# An output is either a resource or something placeable.
			if not RESOURCES.has(out) and not DEFENCES.has(out):
				errors.append("recipe '%s' makes unknown '%s'"
					% [recipe_id, out])
				continue
			# **A kit is the structure's cost, paid early.** Two places to
			# write one price is two places for it to drift, so the drift is a
			# red line rather than a surprise at the shop counter.
			if DEFENCES.has(out) and int((recipe["output"] as Dictionary)[out]) == 1:
				var price: Dictionary = (DEFENCES[out] as Dictionary)["cost"]
				if recipe["inputs"] != price:
					errors.append(("recipe '%s' costs %s and the '%s' it makes "
						+ "costs %s - a kit has to be the price paid early")
						% [recipe_id, recipe["inputs"], out, price])
	return errors


static func check_buildings(buildings: Dictionary) -> Array:
	var errors: Array = []
	for building_id in buildings:
		var building: Dictionary = buildings[building_id]
		for res in (building["cost"] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("building '%s' costs unknown '%s'"
					% [building_id, res])
		if building.has("fuel"):
			for res in (building["fuel"] as Dictionary):
				if not RESOURCES.has(res):
					errors.append("building '%s' burns unknown '%s'"
						% [building_id, res])
	return errors


static func check_defences(defences: Dictionary) -> Array:
	var errors: Array = []
	for defence_id in defences:
		var defence: Dictionary = defences[defence_id]
		for res in (defence["cost"] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("defence '%s' costs unknown '%s'"
					% [defence_id, res])
		if defence.has("ammo"):
			for res in (defence["ammo"] as Dictionary):
				if not RESOURCES.has(res):
					errors.append("defence '%s' fires unknown '%s'"
						% [defence_id, res])
		if defence.has("min_range") and defence.has("range"):
			if int(defence["min_range"]) >= int(defence["range"]):
				errors.append(("defence '%s' has a minimum range at or past "
					+ "its maximum") % defence_id)
	return errors


static func check_map(rows: Array) -> Array:
	var errors: Array = []
	if rows.size() != GRID_HEIGHT:
		errors.append("the farm map is %d rows, not %d"
			% [rows.size(), GRID_HEIGHT])
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != GRID_WIDTH:
			errors.append("farm map row %d is %d wide, not %d"
				% [y, row.length(), GRID_WIDTH])
		for x in row.length():
			if not MAP_LEGEND.has(row[x]):
				errors.append("farm map row %d column %d is '%s', which the "
					% [y, x, row[x]] + "legend does not know")
	return errors


static func check_nights(nights: Array) -> Array:
	var errors: Array = []
	for n in nights.size():
		for wave in (nights[n] as Array):
			if not ENEMIES.has(wave[0]):
				errors.append("night %d sends unknown enemy '%s'"
					% [n + 1, wave[0]])
			if int(wave[1]) <= 0:
				errors.append("night %d has a wave of %d" % [n + 1, wave[1]])
	if nights.size() != MVP_NIGHTS:
		errors.append("MVP_NIGHTS is %d but %d nights are written"
			% [MVP_NIGHTS, nights.size()])
	return errors


## One integer standing for every balance table in this file.
##
## The **data guard**, which is a different question from the simulation guard.
## The simulation hash answers "do the rules still do the same thing"; this one
## answers "is the design still the design". Today no rule reads a lever yet -
## the systems that will are tasks 0018 onward - so a state hash would be blind
## to a balance change, and a balance change is exactly the thing that must
## never happen by accident.
##
## Every table is listed here by hand. **A new table means a line here**, and
## the alternative - reflecting over the class - would silently stop covering
## whatever was added last.
static func digest() -> int:
	return State.hash_of({
		"time": [TICK_HZ, DAY_TICKS, DUSK_AT_TICK, PREPARATION_TICKS,
			MAX_CATCH_UP_TICKS],
		"farm": [GRID_WIDTH, GRID_HEIGHT, TILE_SIZE, HOUSE_HP,
			PLAYER_SPEED],
		"map": FARM_MAP,
		"resources": RESOURCES,
		"sell_price": SELL_PRICE,
		"starting": STARTING_RESOURCES,
		"trade": [BUY_MARKUP, SELL_BACK_FRACTION],
		"crops": CROPS,
		"water": [WATER_GROWTH_BONUS, WATER_CAN_CAPACITY,
			WATER_LASTS_UNTIL_NIGHT],
		"gathering": GATHERING,
		"fishing": FISHING,
		"recipes": RECIPES,
		"queue": [QUEUE_LENGTH],
		"buildings": BUILDINGS,
		"power": [BROWNOUT_RATE],
		"defences": DEFENCES,
		"repair": [REPAIR_COST_PER_HP, REPAIR_TICKS_PER_HP,
			HOUSE_REPAIR_PENALTY],
		"ability": ABILITY,
		"hurt": [HURT_TICKS],
		"speeds": SPEEDS,
		"enemies": ENEMIES,
		"nights": NIGHTS,
		"wave_gap": [WAVE_GAP_TICKS, SPAWN_INTERVAL_TICKS, MVP_NIGHTS],
		"spawns": SPAWNS,
		"rewards": REWARDS,
		"defeat": [DEFEAT_RESOURCE_LOSS, DEFEAT_KEEPS_MONEY, DEFEAT_KEEPS_TECH],
	})
