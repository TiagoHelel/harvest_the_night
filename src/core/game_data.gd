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

## Ticks from waking at 06:00 until passing out at 02:00.
## Bedtime can end the day earlier; dusk is derived below at 18:00.
const DAY_TICKS := 16800               # LEVER: ticks, 14400-18000; whole ticks/game minute

## **The clock** (task 0126): `DAY_TICKS` is mapped onto the hours from
## `DAY_START_MINUTE` to `DAY_END_MINUTE`, in minutes since the midnight the
## day began - 02:00 the next morning is 26 * 60. 1.0's day runs from waking
## at 06:00 to passing out at 02:00 (`docs/PLANO-DO-JOGO.md`), and every later
## task speaks in times of day through `Phases.clock_minute()`.
## `check_clock()` holds `DAY_TICKS` to a whole number of ticks per minute.
const DAY_START_MINUTE := 6 * 60        # LEVER: minutes, 05:00-08:00
const DAY_END_MINUTE := 26 * 60         # LEVER: minutes, 24:00-27:00
const DUSK_MINUTE := 18 * 60            # LEVER: minutes, 16:00-20:00

## The tick dusk falls on, **derived from the clock** rather than set beside
## it, so the hour and the tick can never disagree.
const DUSK_AT_TICK := (DUSK_MINUTE - DAY_START_MINUTE) * DAY_TICKS \
	/ (DAY_END_MINUTE - DAY_START_MINUTE)

## **The calendar** (task 0149): a year is the `SEASONS` in order, each
## `SEASON_DAYS` days long, and day 1 is Spring 1 of Year 1. `Calendar`
## (`src/core/calendar.gd`) is the one place that turns a day into a date;
## `check_calendar()` holds the shape.
const SEASON_DAYS := 14                 # LEVER: days a season, 7-28
## The seasons of a year, in order. Names, not a lever: `Names.KEYS` says
## them in the player's language.
const SEASONS: Array = [&"spring", &"summer", &"autumn", &"winter"]

## **Full Moon nights** (task 0152): these days of every season send a bigger
## horde and pay more. `Waves.night_of` scales the night's record and
## `Rewards` the night's pay; `Calendar.is_full_moon` says which dates.
const FULL_MOON_DAYS: Array = [7, 14]   # LEVER: days of the season
## How big a Full Moon's horde is: this percent of every ordinary wave's
## count. Boss rows are left as written.
const FULL_MOON_HORDE_PERCENT := 150    # LEVER: percent of the night's count, 120-200
## What a won Full Moon pays: this percent of the night's money and
## materials. Technology is a point a night whatever the moon.
const FULL_MOON_REWARD_PERCENT := 200   # LEVER: percent of the night's pay, 150-300

## **Each season's boss** (task 0153), in `SEASONS` order: the one that comes
## on the season's last night, and back every night after until it falls.
## The Giant for all four until 0253-0255 bring the Harvester, the Scarecrow
## King and the Winter Lord.
const SEASON_BOSSES: Array = [&"giant", &"giant", &"giant", &"giant"]

## **The calm night's gift** (task 0154): what is waiting on the porch the
## morning after the first night of a season, when the horde regroups after
## its boss and sends nothing. The only thing that night pays - nothing was
## defended, so no night money, materials or technology.
const CALM_NIGHT_GIFT: Dictionary = {WOOD: 20, STONE: 20, FOOD: 10}  # LEVER: units each, 0-60

## **The short build step after passing out** (task 0128). A farmer still up
## at 02:00 collapses where he stands and the night begins anyway, with this
## much time to build: staying up late is allowed, and it costs preparation,
## not the run.
const PASS_OUT_PREPARATION_TICKS := 30 * SECONDS  # LEVER: ticks, 15-60 seconds worth

## **Bedtime, on the day HUD** (task 0140): from the reminder minute a quiet
## line says it is time for bed and GO TO BED lights up; from the warning
## minute the line counts what is left before he passes out at
## `DAY_END_MINUTE`. View thresholds, not balance: they stay out of
## `digest()`, and `check_bedtime` holds them in order.
const BEDTIME_REMINDER_MINUTE := 22 * 60       # LEVER: minutes, 20:00-24:00
const PASS_OUT_WARNING_MINUTE := 25 * 60 + 30  # LEVER: minutes, 00:30-01:50

## **The night ends at 06:00** (task 0137): the waves' length from the build
## step's end to dawn - the plan's three to five real minutes - the same
## after a 21:00 bedtime and after a pass-out. A house still standing at
## dawn wins the night; killing everything sooner still does.
const NIGHT_TICKS := 240 * SECONDS     # LEVER: ticks, 180-300 seconds worth
## Every night sends its last member at least this long before dawn, so the
## last wave has time to arrive and be fought (`check_nights`).
const DAWN_MARGIN_TICKS := 60 * SECONDS  # LEVER: ticks, 30-120 seconds worth


# ===================================================================== the farm

## How often the tutorial looks to see whether a step has been done.
##
## It only watches, so it can watch slowly: every fifteen ticks is twice a
## second, which nobody can tell from instant, and it is fifteen times less of
## the day tick than asking every one.
const TUTORIAL_CHECK_TICKS := 15        # LEVER: ticks, 1-30

## What crossing one tile of each terrain costs somebody walking in, in
## **tiles-equivalent**: ordinary ground is 1, so a structure's `path_cost`
## reads as "how many tiles of detour going through this is worth".
##
## Zero means nothing crosses it at all. In `Farm.Terrain` order - `Farm`
## indexes this, because the enum is its and the number is a lever, and
## `check_pathing()` holds the two to the same length.
const TERRAIN_COST: Array = [
	1,      # GRASS  - LEVER: ordinary ground, and the unit everything else is in
	2,      # SOIL   - LEVER: tilled earth is heavy going, 1-3
	0,      # WATER  - nothing crosses it
	0,      # ROCK   - nor this
	1,      # PATH   - LEVER: the lane between the beds, 1-2
	1,      # FLOOR  - LEVER: inside a building's footprint, 1-2
]

## The most one step onto a neighbouring cell can possibly cost. It sizes the
## bucket wheel the flow field is swept with, so it has to be at least the
## worst terrain plus the worst `path_cost` - which `check_pathing()` checks
## rather than trusting.
const WIDEST_STEP := 32

## The whole world, in tiles: Stardew Valley's Standard Farm, 80 x 65. A
## 480x270 screen shows 30 x 17 of them, the view Stardew gives at 1920x1080,
## so the farm is about two and a half screens wide and four tall.
const GRID_WIDTH := 80
const GRID_HEIGHT := 65
const TILE_SIZE := 16
const HOUSE_SIZE := Vector2i(6, 4)
const SHOP_SIZE := Vector2i(4, 2)
const HOUSE_ROOM := Vector2i(20, 13)
const HOUSE_DOOR := Vector2i(10, 12)
const HOUSE_SPAWN := Vector2i(10, 11)
const HOUSE_FURNITURE := [
	{"id": &"kitchen", "cell": Vector2i(1, 3), "size": Vector2i(6, 2)},
	{"id": &"fireplace", "cell": Vector2i(10, 3), "size": Vector2i(3, 2)},
	{"id": &"bed", "cell": Vector2i(16, 3), "size": Vector2i(3, 3)},
	{"id": &"nightstand", "cell": Vector2i(14, 3), "size": Vector2i(2, 1)},
	{"id": &"table", "cell": Vector2i(3, 8), "size": Vector2i(5, 2)},
	{"id": &"storage", "cell": Vector2i(17, 8), "size": Vector2i(2, 3)},
	{"id": &"plant", "cell": Vector2i(1, 10), "size": Vector2i(2, 1)},
]

## Where a new game starts the farmer: on the farmhouse porch, the head of the
## south road. `check_map()` holds it to the house the map draws.
const PLAYER_START := Vector2i(40, 26)

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
## **Technology, and it is a resource on purpose.** It goes through the same
## ledger as everything else, so saving it, showing it and spending it are
## problems already solved - and `Rewards._is_tech()` has been waiting for
## this name since task 0061.
const TECH := &"tech"
## `design.md` section 5: "Oleo + Madeira -> Municao incendiaria". The
## flamethrower used to declare it burned raw oil, which at $26 a drop every
## two seconds was the most expensive trigger in the game - forty-five drops
## over a night, eleven hundred dollars of fuel. Rounds are what it burns now.
const INCENDIARY := &"incendiary"
const MONEY := &"money"
const ENERGY := &"energy"

## Every resource the ledger knows about, in the order the reference sheet
## lays them out.
const RESOURCES: Array = [
	WOOD, STONE, IRON, FOOD, FISH, OIL,
	WHEAT, CORN, CARROT, MEAT, GUNPOWDER, INCENDIARY, MONEY, ENERGY, TECH,
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
	# **The most valuable thing on the farm to sell, and that is the point.**
	# Four corn is $20 of crop; pressing it is twenty seconds and turns it into
	# $26 of oil. So the press pays for itself - and then every drop of it is
	# also the only fuel a flamethrower burns, and that tower wants ten of them.
	# Two hundred and sixty dollars, or a tower. Task 0032 exists for that
	# sentence.
	OIL: 26,
	WHEAT: 4,
	CORN: 5,
	CARROT: 3,
	MEAT: 9,
	# Above the oil it is made from, per craft: two corn and a drop of oil is
	# $36 in and $44 out. `check_chain()` is what keeps that true.
	GUNPOWDER: 22,
	# A drop of oil and two logs make four rounds: $30 of goods into $36 of
	# ammunition. A thin margin on purpose - rounds are for burning, not for
	# selling, and `check_chain()` still wants the kitchen to beat the stall.
	INCENDIARY: 9,
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
## Per plot across a fourteen-day season, with the seed paid for:
##
##     carrot   3d   seed $1   net  5  x 4 harvests  = 20
##     wheat    4d   seed $2   net  6  x 3 harvests  = 18
##     corn     8d   seed $4   net 11  x 1 harvest   = 11
##
## Water every day to earn these harvests. Missing a watering delays the crop
## without destroying it. No crop wins on money, harvest visits and seed cost
## at once; `check_crops()` preserves that choice.
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
		"growth_days": 4,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,
	},
	CORN: {
		"seed_cost": 4,                 # LEVER: money, 1-10
		"growth_days": 8,              # LEVER: watered mornings, 1-14
		"yield": 3,                     # LEVER: units per harvest, 2-5
		"stages": 4,
	},
	CARROT: {
		"seed_cost": 1,                 # LEVER: money, 1-8
		"growth_days": 3,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,
	},
}

## How many tiles one canful waters.
##
## The field is sixty plots, so watering all of it takes eight trips to the
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
		"regrow_ticks": DAY_TICKS / 2,  # LEVER: ticks, half a day between harvests
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
	# Stone, out of the same cliff as the iron and much easier to get: the
	# short swing, the big yield and the quick regrowth. Five seams at 3 stone,
	# back every 210 seconds, retains three harvests per node across a
	# 560-second day; travel and swings reduce the cliff-wide total.
	&"seam": {
		"work_ticks": 2 * SECONDS,      # LEVER: ticks per swing, 20-120
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {STONE: 3},            # LEVER: units, 2-5
		"regrow_ticks": DAY_TICKS * 3 / 8,  # LEVER: ticks, three eighths of a day
	},
	# Iron, and the thing you are always slightly short of - which is
	# deliberate, because it gates every tower.
	#
	# **Worse than stone on all three dials**, which is what makes the cliff a
	# choice about what you came for rather than a place you leave with
	# everything:
	#
	#     seam   2s a swing, 3 swings, 3 stone, back in 210s
	#     ore    3s a swing, 3 swings, 1 iron,  back in 280s
	# Eight ore nodes still give two harvests each: sixteen iron per day on
	# a tight route. The longer day leaves more time for walking the farm;
	# production has not doubled, and the thirteen-iron tower is still work.
	&"ore": {
		"work_ticks": 3 * SECONDS,      # LEVER: ticks per swing, 20-150
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {IRON: 1},             # LEVER: units, 1-2
		"regrow_ticks": DAY_TICKS / 2,  # LEVER: ticks, half a day between harvests
	},
}

## Fishing: how long the wait is, how long you have to react, how often it is
## the good one. The pond pays the most per action and costs attention rather
## than resources.
const FISHING: Dictionary = {
	"bite_min_ticks": DAY_TICKS / 120,  # LEVER: ticks, 1/120 day (4.67 seconds)
	"bite_max_ticks": DAY_TICKS / 24,   # LEVER: ticks, 1/24 day (23.33 seconds)
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
		"inputs": {WOOD: 4},
		"output": {&"barricade": 1},
		"ticks": DAY_TICKS * 6 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"fence_kit": {
		"station": &"workshop",
		"inputs": {WOOD: 5},
		"output": {&"fence": 1},
		"ticks": DAY_TICKS * 5 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	# **The mine is made, not bought.** A mine spent is a mine to craft again,
	# which is what "replenished by crafting" means and what keeps gunpowder
	# worth having. `check_recipes()` holds these inputs to the mine's own
	# cost, so the two cannot drift.
	&"mine_kit": {
		"station": &"workshop",
		"inputs": {IRON: 5, GUNPOWDER: 8},
		"output": {&"mine": 1},
		"ticks": DAY_TICKS * 8 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"wall_kit": {
		"station": &"workshop",
		"inputs": {STONE: 10},
		"output": {&"wall": 1},
		"ticks": DAY_TICKS * 10 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	# Corn is the oil crop, and this is where it stops being food.
	&"press_oil": {
		"station": &"press",
		"inputs": {CORN: 4},
		"output": {OIL: 1},
		"ticks": DAY_TICKS * 20 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	# **The other way in**, for the day you have a good pond and a bad field.
	# Deliberately the worse deal - three fish is $24 against corn's $20, and
	# a fish is worth more cooked than pressed - so this is the fallback rather
	# than the route.
	&"press_fish_oil": {
		"station": &"press",
		"inputs": {FISH: 3},
		"output": {OIL: 1},
		"ticks": DAY_TICKS * 25 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	# The flamethrower's rounds. `design.md` section 5 names this one exactly.
	&"make_incendiary": {
		"station": &"workshop",
		"inputs": {OIL: 1, WOOD: 2},
		"output": {INCENDIARY: 4},
		"ticks": DAY_TICKS * 10 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"make_gunpowder": {
		"station": &"workshop",
		"inputs": {CORN: 2, OIL: 1},
		"output": {GUNPOWDER: 2},
		"ticks": DAY_TICKS * 15 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"cook_meal": {
		"station": &"kitchen",
		"inputs": {CARROT: 2, WHEAT: 1},
		"output": {FOOD: 2},
		"ticks": DAY_TICKS * 12 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"cook_fish": {
		"station": &"kitchen",
		"inputs": {FISH: 1, CARROT: 1},
		"output": {FOOD: 3},
		"ticks": DAY_TICKS * 15 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"cook_roast": {
		"station": &"kitchen",
		"inputs": {MEAT: 1, CORN: 1},
		"output": {FOOD: 4},
		"ticks": DAY_TICKS * 18 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
}

## How many items a production building may have queued at once.
const QUEUE_LENGTH := 5                 # LEVER: items, 3-10


# ================================================================== buildings

## The production side of the farm. Energy draw is what task 0033 turns into a
## reason to care where the generator is.
## What the farm makes without a generator.
##
## **The reason the first press is not miserable.** With nothing here, a press
## on day one would draw two against a supply of nothing and grind along at a
## quarter speed until the player built a generator - which burns oil, which
## comes out of the press. Not a deadlock, but an hour of wondering what is
## wrong. Four is the press and a tower or two; past that the farm has grown
## beyond its own means, which is exactly when a generator should be the
## answer.
const BASE_ENERGY := 4                  # LEVER: energy per tick, 0-10

const BUILDINGS: Dictionary = {
	# **Buildings have hit points.** They had none at all until task 0060,
	# which meant `Building.place()` gave them one apiece and the workshop
	# `FARM_MAP` puts on the farm got none - so `Farm.damage()` read zero,
	# refused to take anything off, and eight breakers stood beside it
	# chewing for fifty-six thousand ticks. The night never ended.
	#
	# Sturdier than a fence, softer than a wall: losing one is meant to hurt
	# without being the thing that ends a night.
	&"workshop": {
		"hp": 80,                       # LEVER: hit points, 40-160
		"cost": {WOOD: 20, STONE: 10},
		"energy_draw": 0,
		"size": Vector2i(4, 3),
	},
	&"press": {
		"hp": 80,                       # LEVER: hit points, 40-160
		"cost": {WOOD: 25, IRON: 5},
		"energy_draw": 2,               # LEVER: energy per tick, 1-5
		"size": Vector2i(4, 3),
	},
	&"kitchen": {
		"hp": 70,                       # LEVER: hit points, 40-160
		"cost": {WOOD: 15, STONE: 15},
		"energy_draw": 1,               # LEVER: energy per tick, 0-3
		"size": Vector2i(4, 3),
	},
	&"generator": {
		"hp": 90,                       # LEVER: hit points, 40-160
		"cost": {IRON: 20, STONE: 10},
		"energy_draw": 0,
		"energy_output": 10,            # LEVER: energy per tick, 5-20
		"fuel": {OIL: 1},
		# A drop a minute, so a full day and night of running is five or six oil
		# against the twelve a press can make in a day. Expensive enough to be a
		# decision, cheap enough that the answer is sometimes yes.
		"fuel_every_ticks": DAY_TICKS / 4,  # LEVER: ticks, four oil per full day
		"size": Vector2i(4, 3),
	},
}

## How well things run on no power at all.
##
## Degraded, never dead: a brown-out slows the defence and lets the night
## resolve, rather than switching the towers off and ending it. `design.md`
## calls a lost night a setback and not an ending, and a night the player
## watches instead of playing is the wrong kind of loss.
##
## **A percentage, not a fraction.** This was `0.5` from the day the table was
## written and nothing ever read it; a float in `src/core/` is a desync waiting
## for a machine that rounds differently, so it became an integer the moment
## something needed it. Twenty-five rather than fifty, because with
## `BASE_ENERGY` below the farm only reaches this floor when it has been built
## well past its means.
const UNPOWERED_PERCENT := 50           # LEVER: percent of full speed, 10-60


# =================================================================== defences

## **How a tower picks what to shoot.** Declared rather than assumed, because
## the next five towers do not all want the same answer: a mortar wants the
## thickest part of the crowd and a crossbow wants the longest line.
##
## `closest_to_house` is what every tower did implicitly before this task, and
## it is the default, so a tower that says nothing behaves exactly as it did.
const TARGET_CLOSEST_TO_HOUSE := &"closest_to_house"
const TARGET_NEAREST := &"nearest"
const TARGET_WEAKEST := &"weakest"
const TARGET_STRONGEST := &"strongest"

const TARGETING: Array = [
	TARGET_CLOSEST_TO_HOUSE, TARGET_NEAREST, TARGET_WEAKEST, TARGET_STRONGEST,
]


## **How the damage lands.** `single` is one target and is the default;
## `splash` is everything within `splash_tiles`, falling off to
## `splash_falloff` of the damage at the edge.
##
## A new tower that deals three fire in a radius is
## `{"shape": SHAPE_SPLASH, "damage": 3, "damage_type": DAMAGE_FIRE,
## "splash_tiles": 2}` and no edit to `towers.gd` at all. There is an assert
## that builds exactly that and then deletes it again.
const SHAPE_SINGLE := &"single"
const SHAPE_SPLASH := &"splash"

## A wedge in front of the tower, pointed at whatever it is shooting.
##
## **It lands the instant it is fired.** A flamethrower does not throw
## anything: there is nothing in the air to chase a target that has already
## moved, which is why a cone is the one shape with no projectile.
const SHAPE_CONE := &"cone"

## A bolt along the straight line to the target, through everything on it.
##
## Like the cone, it lands the instant it is fired: a crossbow bolt crosses its
## whole range in a third of a second, and a projectile that had to be chased
## down a line would be three ticks of bookkeeping for something the player
## reads as instantaneous anyway.
const SHAPE_LINE := &"line"

const SHAPES: Array = [SHAPE_SINGLE, SHAPE_SPLASH, SHAPE_CONE, SHAPE_LINE]


## **What a shot in the air is doing.** `guided` follows what it was fired at
## and cannot miss; `ballistic` is aimed at a place, takes `flight_ticks` to
## get there, and lands whether or not anything is still standing on it.
##
## Guided is the default, because it is what every tower did before task 0044
## and because a bullet that leads its target is a bullet nobody can read.
## A mortar is the exception and the whole of its character: it is the only
## thing on the farm that can miss, which is what makes standing still in
## front of one a mistake and walking out of it a save.
const AIM_GUIDED := &"guided"
const AIM_BALLISTIC := &"ballistic"

const AIMS: Array = [AIM_GUIDED, AIM_BALLISTIC]


const DAMAGE_IMPACT := &"impact"
const DAMAGE_FIRE := &"fire"
const DAMAGE_EXPLOSIVE := &"explosive"

const DAMAGE_TYPES: Array = [DAMAGE_IMPACT, DAMAGE_FIRE, DAMAGE_EXPLOSIVE]

## How often a burning thing takes its burn damage.
##
## Once a second rather than once a tick, so `burn_damage` in the tables reads
## as what a designer means by it - "two a second" - and so that a burn is a
## handful of arithmetic over its life instead of ninety.
const BURN_EVERY_TICKS := SECONDS

## The six things from the reference sheet that go on the farm at night.
##
## `range` and `min_range` are in tiles. `reload_ticks` is the gap between
## shots. Task 0042 turns these entries into declarative behaviour so the combat
## code stops growing a branch per tower.
const DEFENCES: Dictionary = {
	&"gun_tower": {
		# **Twelve iron, not fifteen**, and the autoplayer of task 0067 is
		# what found it. A whole day of mining nothing else yields thirteen
		# iron - the cliff has eight seams and they come back once in a day -
		# so at fifteen the first tower could not be built on the first day
		# except by the one perfect line: mine all day, sell every stone you
		# started with, and buy two iron at eighteen dollars each.
		#
		# The iron itself was not the thing to change. `check_iron()` holds
		# ore to being slower per swing, worth less per pull and scarcer to
		# come back than stone, and all three are right - iron is meant to be
		# the hard one. What was wrong was a first tower that cost more than
		# a first day can make.
		"cost": {WOOD: 10, IRON: 12},
		"targeting": TARGET_CLOSEST_TO_HOUSE,
		"shape": SHAPE_SINGLE,
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
		"targeting": TARGET_NEAREST,
		"shape": SHAPE_CONE,
		"hp": 70,                       # LEVER: hit points, 40-140
		"damage": 3,                    # LEVER: per tick in the cone, 1-6
		"damage_type": DAMAGE_FIRE,
		"range": 3,                     # LEVER: tiles, 2-5
		"cone_degrees": 60,             # LEVER: degrees, 30-90
		"burn_ticks": 3 * SECONDS,      # LEVER: ticks, 1-6 seconds worth
		"burn_damage": 2,               # LEVER: per second burning, 1-5
		# **How wide the wedge opens, in thousandths of a tile per tile.** The
		# rules use this and `cone_degrees` is what a designer reads;
		# `check_defences()` refuses a farm where the two have drifted apart, the
		# same way `check_recipes()` does for a kit's price.
		#
		# Trigonometry belongs in the check, not in the tick: `tan(30 degrees)`
		# is 577 thousandths, and a rule that worked it out every tick would be
		# floating-point arithmetic in the one place this game does not allow
		# any.
		"cone_spread_permille": 577,
		# **How often the cone goes off.** The flamethrower had no
		# `reload_ticks` at all, which meant `Towers._find_towers()` - which
		# collects everything with one - never saw it: it could be built, it
		# cost twenty wood, twenty-five iron and ten oil, and it had never
		# fired a shot in its life. Found in task 0043 when the cone that was
		# written for it turned out to be unreachable.
		#
		# Twice a second: a flamethrower is a continuous thing and this is as
		# close as a fixed tick gets without pretending otherwise.
		"reload_ticks": SECONDS / 2,    # LEVER: ticks, 5-30
		"ammo": {INCENDIARY: 1},
		# One thing at a time until a level says otherwise.
		"targets": 1,
		# **One round per this many ticks of firing**, not one a cone: a
		# round is two seconds of flame. Read by `Towers._load()` since task
		# 0116 - before that nothing did, and the cone burnt a round twice a
		# second.
		"ammo_every_ticks": 2 * SECONDS,  # LEVER: ticks, 1-4 seconds worth
		"energy_draw": 2,
	},
	&"mortar": {
		"cost": {STONE: 30, IRON: 35, GUNPOWDER: 15},
		"targeting": TARGET_CLOSEST_TO_HOUSE,
		"shape": SHAPE_SPLASH,
		"hp": 55,                       # LEVER: hit points, 30-100
		"damage": 40,                   # LEVER: at the centre, 20-70
		"damage_type": DAMAGE_EXPLOSIVE,
		"range": 12,                    # LEVER: tiles, 8-16
		# A minimum range is what makes placing a mortar a decision rather than
		# a purchase: it cannot defend itself.
		"min_range": 4,                 # LEVER: tiles, 2-6
		"splash_tiles": 2,              # LEVER: tiles, 1-3
		# **A percentage, not a fraction.** This was `0.5` and `towers.gd` was
		# turning it into one at the moment of firing - a float multiply in the
		# one place this game does not allow any. Same story as
		# `WATER_GROWTH_BONUS` in task 0029 and `BROWNOUT_RATE` in 0033: the
		# table was written in fractions and the rules want integers.
		"splash_falloff_percent": 50,   # LEVER: percent at the edge, 20-80
		"reload_ticks": 5 * SECONDS,    # LEVER: ticks, 3-8 seconds worth
		# **Aimed at a place, not at a zombie.** A shell that followed its
		# target would be a guided missile with a long fuse, and the minimum
		# range below would be the only interesting thing about the tower.
		"aim": AIM_BALLISTIC,
		"flight_ticks": 45,             # LEVER: ticks in the air, 20-75
		"ammo": {GUNPOWDER: 1},
		# One thing at a time until a level says otherwise.
		"targets": 1,
		"energy_draw": 1,
	},
	&"auto_crossbow": {
		"cost": {WOOD: 15, IRON: 20},
		"targeting": TARGET_CLOSEST_TO_HOUSE,
		"shape": SHAPE_LINE,
		"hp": 50,                       # LEVER: hit points, 30-90
		# **Five, not three.** The falloff below takes a fifth of the original
		# off each target the bolt goes through, and at three damage that is a
		# curve of 3, 2, 1, 1, 1 - the minimum-hit floor eats it and the lever
		# stops meaning anything. At five it reads exactly as it is written:
		# 5, 4, 3, 2, 1 down a line of five.
		#
		# It stays the wrong answer against a tank, which is the point: armour 3
		# takes a five-damage bolt down to two, and a tank has a hundred and
		# twenty hit points.
		"damage": 5,                    # LEVER: per bolt, 1-8
		"damage_type": DAMAGE_IMPACT,
		"range": 7,                     # LEVER: tiles, 5-10
		"reload_ticks": 15,             # LEVER: ticks, 8-30
		# Bolts, not powder: the crossbow is the tower you can keep firing
		# on a night when the workshop stood idle. It pays for that in
		# energy instead - three, the hungriest thing on the farm.
		"projectile_tiles_per_second": 22,
		"pierce": 5,                    # LEVER: targets in the line, 2-8
		# **A fifth of the original off each target passed**, not a fifth of
		# whatever is left - which would be 5, 4, 3.2, 2.56 and an integer mess
		# that floors out after three. Subtracting from the original gives a
		# curve a player can count: 5, 4, 3, 2, 1.
		#
		# Another fraction turned into a percentage, after `WATER_GROWTH_BONUS`
		# (0029), `BROWNOUT_RATE` (0033) and `splash_falloff` (0044). The table
		# was written in fractions; the rules want integers.
		"pierce_falloff_percent": 20,
		# One thing at a time until a level says otherwise.
		"targets": 1,   # LEVER: percent of the original, 10-40
		"energy_draw": 3,               # hungry: the reason to build a generator
	},
	&"mine": {
		"cost": {IRON: 5, GUNPOWDER: 8},
		"hp": 1,
		"damage": 60,                   # LEVER: on trigger, 30-100
		"damage_type": DAMAGE_EXPLOSIVE,
		"splash_tiles": 1,              # LEVER: tiles, 1-2
		"splash_falloff_percent": 60,   # LEVER: percent at the rim, 30-90
		# **It goes off once and is then gone**, which is what `Traps` reads to
		# know a thing is a trap at all. It is also why a mine has no
		# `reload_ticks`: it never aims at anything, so `Towers` must never
		# collect it.
		"one_shot": true,
		# How many may be armed on the farm at a time. Crafting is what
		# replenishes them - each one spent is one to make again - and this is
		# what stops a rich player carpeting the approach.
		"armed_limit": 6,               # LEVER: how many, 3-12
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
		# **The cheapest thing in the game, and wood alone.** Three wood and
		# two stone came to $12 of goods against the fence's $10, so the
		# "cheapest structure" the task asks for was not - and stone is the
		# wrong currency for a thing you throw down while they are already
		# coming. Four wood is $8, and it is one trip to one tree.
		"cost": {WOOD: 4},
		"hp": 20,                       # LEVER: hit points, 10-40
		"path_cost": 4,                 # LEVER: tiles-equivalent detour, 2-8
		# **Cheap, temporary and limited** - its identity since every defence
		# goes down at night (task 0132). It expires, so it cannot quietly
		# become a cheaper wall: the clock starts with the waves, wherever in
		# the night it went down.
		"lifetime_ticks": 60 * SECONDS, # LEVER: ticks, 30-120 seconds worth
		"per_night_limit": 5,           # LEVER: how many, 2-10
		"energy_draw": 0,
	},
}

## The animals on the reference sheet, and the meat that comes off them.
##
## **A trickle, and nothing to manage.** No feed, no water, no breeding, no
## happiness - an animal stands on the grass and slowly has something worth
## taking. A farm sim's animal loop is a game of its own and this is a tower
## defence with a farm attached.
##
## `holds` is what stops it being idle income: a full animal stops producing,
## so meat is something you collect on your rounds rather than something that
## piles up while you are at the rock face. The cow is the slow, worthwhile
## one; the chickens are the quick, small ones.
const LIVESTOCK: Dictionary = {
	&"cow": {
		"produces": {MEAT: 1},
		"every_ticks": DAY_TICKS / 3,   # LEVER: ticks, three production intervals/day
		"holds": 2,                     # LEVER: units before it stops, 1-5
	},
	&"chicken": {
		"produces": {MEAT: 1},
		"every_ticks": DAY_TICKS * 5 / 24,  # LEVER: ticks, 4.8 production intervals/day
		"holds": 1,                     # LEVER: units before it stops, 1-4
	},
}

## How the inventory panel groups things, in the order it draws them.
##
## **Off the reference sheet.** `docs/reference-sheet.png` lays its resource
## panel out in two rows of six - wood, stone, iron, food, fish, oil on the
## top and wheat, corn, meat, gunpowder, money, energy underneath - which is
## not alphabetical and not arbitrary: it is what you gather, then what you
## grow and what you make of it. These groups are that, named, with the two
## resources the sheet does not show (carrot, incendiary) sitting with their
## own kind.
##
## **A resource in no group still appears.** `Inventory.groups()` sweeps
## whatever is left into `GROUP_OTHER` rather than dropping it, so adding one
## to `RESOURCES` and forgetting this table is a cosmetic mistake and not an
## invisible resource. That is the done-when of task 0036.
const GROUP_OTHER := &"other"

const RESOURCE_GROUPS: Array = [
	{"name": &"materials", "members": [WOOD, STONE, IRON]},
	{"name": &"larder", "members": [FOOD, FISH, MEAT]},
	{"name": &"crops", "members": [WHEAT, CORN, CARROT]},
	{"name": &"workshop", "members": [OIL, GUNPOWDER, INCENDIARY]},
	{"name": &"the farm", "members": [MONEY, ENERGY, TECH]},
]


## What a tower manages on an empty pool.
##
## **A slow basic shot, never a silent tower.** A tower that stopped would be a
## tower the player stops looking at, and a night that is lost before it starts
## is not the setback `design.md` asks for - it is an ending. So an empty
## mortar still lobs something: three times as long to reload, a third of the
## damage, and none of what made it a mortar. Enough to survive an easy night
## and nowhere near enough for a hard one.
const EMPTY_RELOAD_PERCENT := 300       # LEVER: percent of normal, 150-500
const EMPTY_DAMAGE_PERCENT := 30        # LEVER: percent of normal, 10-60

## How much day one is allowed to say.
##
## Nine since task 0141: the five day lines and the four of the new night -
## to bed, the build step, START, dawn - the top of the range rather than
## two day lines merged into one that says two things. The length is here
## too because a line that wraps is two lines wearing a hat.
const MAX_TUTORIAL_LINES := 9           # LEVER: lines, 3-9
const MAX_TUTORIAL_LINE_LENGTH := 76    # LEVER: characters, 40-90


## What the stall has of each thing when the day starts.
##
## **Small, and it refreshes once a day rather than once a visit.** A stall
## with unlimited stock is a stall a player with money never has to leave, and
## one that restocked when you walked away and came back is the same thing with
## extra walking. Running it dry is meant to be a thing that happens and a
## reason to go and gather.
const DAILY_STOCK: Dictionary = {        # LEVER: units a day, 2-40
	WOOD: 15,
	STONE: 12,
	IRON: 8,
	WHEAT: 10,
	CORN: 8,
	CARROT: 12,
}


## Day one, in five lines.
##
## **Five, and the task allows seven.** Every line has to earn its place: it
## names the thing, says which key, and stops. A tutorial the player reads is
## already a tutorial that is too long, so these are written to be understood
## from the corner of the eye while walking towards the thing they are stuck
## to.
##
## `src/core/tutorial.gd` decides when each is finished, from the state, and
## `src/ui/` draws it over the cell it is about. Nothing here locks anything:
## a player who ignores all five reaches exactly the same night.
##
## **Task 0097 took the words out.** What is left is the key of the line,
## and `assets/locale/strings.csv` holds what it says - so a rule file names
## a step and never speaks to a player, and the Portuguese arrives without
## anything in `src/core/` changing.
## **Seven, in the order a first day happens in.** Task 0101 added the two
## a stranger would otherwise never find - the well and the stall - and put
## them where they are about the thing that just happened: watering is about
## the seed you have this second put in, and the stall is about the wood in
## your hands.
##
## Nothing here describes the switch of reality. The transition shows it, and
## a line that said "your farm becomes the map you defend" would be a line
## spending a stranger's attention on something the game is about to do to
## them anyway. There is a check for that.
##
## **Nine since task 0141**, the night's four after the day's five: go to bed,
## set something down in the build step, press START, hold till dawn. They
## are practical lines too - what to press and where - and the first night
## is taught as it is played, in the build step and the waves, where the
## prompt now follows.
const TUTORIAL: Array = [
	{"id": &"chop", "line": &"TUT_CHOP"},
	{"id": &"plant", "line": &"TUT_PLANT"},
	{"id": &"water", "line": &"TUT_WATER"},
	{"id": &"sell", "line": &"TUT_SELL"},
	{"id": &"craft", "line": &"TUT_CRAFT"},
	# **The new night** (task 0141): to bed, which is the switch; the build
	# step, where defences go down since 0132; START; and holding till dawn.
	{"id": &"bed", "line": &"TUT_BED"},
	{"id": &"build", "line": &"TUT_BUILD"},
	{"id": &"start", "line": &"TUT_START"},
	{"id": &"dawn", "line": &"TUT_DAWN"},
]


## What repairing costs, per hit point put back.
## What a hit point of **the house** costs. The house has no build cost to
## take a share of, and `design.md`'s resource table gives food the night's
## "cura/reparo" job, so this is where food does it.
const REPAIR_COST_PER_HP: Dictionary = {FOOD: 1, WOOD: 1}

## What mending a structure all the way costs, as a percentage of building a
## new one - in **its own materials**, a wall in stone and a tower in iron.
##
## **A flat price per hit point could not work.** Task 0057 measured the old
## rule and found repairing dearer than rebuilding for every structure in the
## game, by between seven and fifty-six times: a hundred and twenty hit points
## of wall at one food and one wood each is $1680 of goods against a $30 wall.
## Food is the most valuable thing on the farm after oil, and a hit point is a
## very small thing. A share of what the thing cost is the only rule that
## scales from a four-wood barricade to a mortar.
##
## Half, so mending is plainly the right move and still costs enough that
## letting a wall fall hurts.
const REPAIR_PERCENT := 50              # LEVER: percent of building new, 20-80
const REPAIR_TICKS_PER_HP := 3          # LEVER: ticks, 1-8
## **A percentage, not a multiplier.** This was `2.0` and nothing read it, for
## the same reason nothing could: `src/core/` is integer arithmetic. The sixth
## fraction found that way, after `WATER_GROWTH_BONUS`, `BROWNOUT_RATE`,
## `splash_falloff`, `pierce_falloff` and `structure_damage_multiplier`.
##
## It costs the house twice as much per hit point **and** takes twice as long,
## which is one number doing both jobs: patching the roof is not the same kind
## of work as nailing a plank back on a fence, and a player who wants the wall
## up before the next wave should be out there rather than indoors.
const HOUSE_REPAIR_PERCENT := 200       # LEVER: percent, 150-300

## The one button the player has during a night.
## The one button of `design.md`'s fourth pillar: the player "pode
## eventualmente" step into a night they are losing, and this is the stepping.
##
## The slow is what turns a wave, not the damage. Twenty-five kills a walker
## and dents a tank; five seconds of half speed is five seconds of every tower
## on the farm getting a free volley into the same crowd.
const ABILITY: Dictionary = {
	"damage": 25,                       # LEVER: in the area, 10-50
	"damage_type": DAMAGE_EXPLOSIVE,
	"radius_tiles": 3,                  # LEVER: tiles, 2-5
	# **Percent of normal speed, not a fraction.** This was `0.5` and nothing
	# read it - the seventh fraction found that way, after
	# `WATER_GROWTH_BONUS`, `BROWNOUT_RATE`, `splash_falloff`,
	# `pierce_falloff`, `structure_damage_multiplier` and
	# `HOUSE_REPAIR_PENALTY`. The rules are integers.
	"slow_percent": 50,                 # LEVER: percent of speed, 20-80
	"slow_ticks": 5 * SECONDS,          # LEVER: ticks, 2-10 seconds worth
	# **Long enough that using it is a decision.** Measured against the
	# nights rather than picked: at 45 seconds a three-minute night got four
	# flares, which is one a wave and no decision at all. At 80 it is one
	# turned wave and a second only if the night runs long.
	"cooldown_ticks": 80 * SECONDS,     # LEVER: ticks, 20-90 seconds worth
	# How long the view keeps drawing the burst. Purely how it looks.
	"flare_ticks": 1 * SECONDS,         # LEVER: ticks, 10-45
}

## How long something stays lit after it is hit.
##
## Long enough to read at 30 ticks a second, short enough that a crowd being
## shot does not become a wall of white.
const HURT_TICKS := 5                   # LEVER: ticks, 2-12

## Speeds the night may be watched at. **Ticks per frame, never a changed tick
## rate**: at 4x the sim runs four ticks where it would have run one, and every
## rule still sees the same fixed tick it always saw. A changed rate would make
## the speed button part of the simulation, and then two players watching at
## different speeds would be playing different games.
const SPEEDS: Array = [1, 2, 4]

## Below this the house bar goes red and pulses. **Above the skip line on
## purpose**: the warning has to arrive before the night stops being skippable,
## or the first the player knows of trouble is a control going dead.
const HOUSE_DANGER_PERCENT := 60        # LEVER: percent of full, 40-75

## How long before a wave arrives the HUD says it is coming.
##
## Long enough to decide something - a barricade goes down in a moment, a wall
## mended takes a few seconds - and short enough that the warning is about
## this wave rather than a permanent fixture.
const WAVE_WARNING_TICKS := 4 * SECONDS # LEVER: ticks, 2-8 seconds worth

## How much house has to be left before the night may be skipped.
##
## **Because that night is worth watching.** Skipping is the semi-idle promise
## for a night that is clearly going to hold; a night that is nearly lost is
## the one the player should see, and the one where a flare or a barricade in
## the right second is the difference. Letting it be skipped would be letting
## the player skip the only interesting part of the game.
const SKIP_MIN_HOUSE_PERCENT := 50      # LEVER: percent of full, 25-75


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
		#
		# Half a walker's hit points and better than twice its speed, which is
		# the shape the task asks for: twenty against ten, twenty ticks a tile
		# against nine.
		"hp": 10,                       # LEVER: hit points, 6-20
		"ticks_per_tile": 9,            # LEVER: ticks, 6-14
		"damage": 3,                    # LEVER: to the house, 1-6
		"reward": 4,                    # LEVER: money, 2-8
		"armour": 0,
		# **It does not stop for what you built.** Everything else takes a
		# wall apart when the wall is the cheapest way home (task 0049); a
		# runner goes round, and if there is no way round it gives up and
		# breaks through like the rest. A runner that stood still in front of
		# a wall would make walling the farm a win condition, which is the
		# thing task 0046 already learned once.
		#
		# It is what makes the runner a different problem rather than a fast
		# walker: a maze does nothing to it, and only something that shoots
		# will do.
		"ignores_structures": true,
	},
	&"tank": {
		# Armour is flat and applies per hit, so many small hits are worse than
		# a few big ones.
		#
		# **Four, and four is where the lever stops meaning anything.** A
		# crossbow bolt is five, so armour four leaves one - and one is
		# `Combat.MINIMUM_HIT`, the floor that stops an enemy being immune.
		# Armour five and six take nothing more off a bolt and do take more
		# off a shell, so they make the tank *worse* at being the thing the
		# mortar is for. Measured in task 0051: a bolt lands 20% of its
		# damage on a tank and a shell lands 90%.
		"armour": 4,                    # LEVER: damage off each hit, 1-4
		# **A hundred and twenty, left alone.** Task 0051 tried 160 and 220
		# looking for the fight its prompt describes - a crossbow wall that
		# barely scratches a tank and a mortar that drops it - and measured
		# its way to the conclusion that no hit points produce it. Four
		# crossbows and one mortar do 0.267 and 0.240 damage a tick against
		# armour four, which is an eleven percent difference: every value
		# either lets both of them win or leaves both on a knife edge. At 160
		# the tank reached the house with 10 hit points of 160; at 220 the
		# mortars missed the kill by 8.
		#
		# So the armour does the work and the hit points stay where the rest
		# of the curve was built around them. The balance pass at 0060 has
		# the arithmetic in the journal.
		"hp": 120,                      # LEVER: hit points, 70-220
		# Slow enough to watch it come: one tile and a quarter a second.
		"ticks_per_tile": 38,           # LEVER: ticks, 30-50
		"damage": 15,                   # LEVER: to the house, 8-25
		"reward": 12,                   # LEVER: money, 6-20
	},
	&"breaker": {
		# It goes for what you built rather than what you live in, which makes
		# an uncovered tower line a liability.
		"hp": 45,                       # LEVER: hit points, 25-80
		"ticks_per_tile": 21,           # LEVER: ticks, 15-30
		# **Five, which is half a walker.** "Little against the house" is half
		# the requirement and it has to be visible in the number: at eight it
		# was almost a walker with a hobby. What it costs you is the tower it
		# is standing on, not the roof.
		"damage": 5,                    # LEVER: to the house, 3-10
		# **A percentage, not a multiplier.** This was `3.0` and nothing read
		# it - the same story as `WATER_GROWTH_BONUS` (0029), `BROWNOUT_RATE`
		# (0033), `splash_falloff` (0044) and `pierce_falloff` (0045). The
		# table was written in fractions and the rules want integers.
		#
		# Three hundred of five is fifteen: half again what a walker does to a
		# structure, out of something that does half what a walker does to the
		# house.
		"structure_damage_percent": 300,   # LEVER: percent, 200-500
		# **What it walks towards.** Read by `Enemies` through the hunt field
		# in `Pathing`: a breaker goes to the nearest thing you built and
		# takes it apart, and only heads for the house when there is nothing
		# left standing. Declared since the table was written and read by
		# nothing until task 0052.
		"targets_structures": true,
		"reward": 8,                    # LEVER: money, 4-14
		"armour": 1,
	},
	&"giant": {
		"hp": 900,                      # LEVER: hit points, 500-1600
		"ticks_per_tile": 50,           # LEVER: ticks, 40-70
		"damage": 40,                   # LEVER: to the house, 25-60
		"structure_damage_percent": 400,   # LEVER: percent, 200-600
		# A giant walks at the house and flattens whatever is in the way; it
		# does not go looking. The going-looking one is the breaker.
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
## **The pace of an ordinary night**, and what a night is measured against
## when it does not set its own. Nights one and two take it; the other eight
## tighten it deliberately, and that tightening is the second difficulty curve
## described under `NIGHTS`.
const WAVE_GAP_TICKS := 15 * SECONDS    # LEVER: ticks, 8-30 seconds worth

## How long between two members of the same wave.
##
## Eight zombies materialising on one tick is a magic trick; eight walking out
## of the dark in a line is a wave, and it gives the towers something to do
## while the player watches.
const SPAWN_INTERVAL_TICKS := 20        # LEVER: ticks, 8-45

## The ten nights of `design.md`, section 10.
##
## **A night is a record, not a bare list of rows.** Task 0059 turned it into
## one so that the two numbers a designer most wants to turn - how long before
## the first wave, and how long between them - live on the night they belong
## to rather than being repeated on every row of it. A night is:
##
##     {"note": ..., "opening_ticks": ..., "gap_ticks": ..., "waves": [...]}
##
## and a wave is `[enemy, count, spawn]`, with an optional fourth entry that
## overrides the night's gap for that one wave. The old shape repeated
## `WAVE_GAP_TICKS` on thirty-four rows; changing the pace of a night meant
## editing every row of it and hoping none were missed.
##
## `note` is for the summary `tools/nights.py` prints, which is the whole of
## "a summary of all ten nights can be printed headlessly".
## The ten nights of `design.md`, section 10.
##
## **A night is a record, not a bare list of rows.** Task 0059 turned it into
## one so that the two numbers a designer most wants to turn - how long before
## the first wave, and how long between them - live on the night they belong
## to rather than being repeated on every row of it. A night is:
##
##     {"note": ..., "opening_ticks": ..., "gap_ticks": ..., "waves": [...]}
##
## and a wave is `[enemy, count, spawn]`, with an optional fourth entry that
## overrides the night's gap for that one wave.
##
## ## The curve, and what it is measured in
##
## Task 0060 authored these against three numbers that all have to climb:
## **how many arrive**, **what they are worth**, and **how many hit points
## there are to get through**. The last is the honest measure of a night's
## size, because three tanks are not three walkers - and the old table dipped
## on four of the ten by it.
##
## `python tools/nights.py` prints all three, and
## `python tools/play_nights.py` plays them with a scripted build and says
## which fell. Both were written for this task and are the instrument it was
## authored with.
##
## ## One new thing a night, and the night after is where it bites
##
## The walker on 1, the runner on 3, the tank on 5, the breaker on 7 and the
## Giant on 10 - which is section 10 exactly. Each of those is a gentle
## introduction and the night after it is the hard one, so a player meets a
## new problem while they can still afford to get it wrong, and is examined on
## it when they cannot.
##
## The gap between waves tightens as the run goes on, from fifteen seconds to
## ten. That is a second curve under the first one: the same crowd arriving
## with less room to breathe between waves is a harder crowd, and it is the
## cheapest difficulty there is because it costs no extra enemies.
const NIGHTS: Array = [
	{
		"note": "the tutorial night: one tower, one side, and time to watch",
		"opening_ticks": 0,
		"waves": [
			[&"walker", 3, 0],
			[&"walker", 4, 0],
			[&"walker", 5, 0],
		],
	},
	{
		"note": "the same again from two sides, so one tower is not enough",
		"opening_ticks": 0,
		"waves": [
			[&"walker", 6, 0],
			[&"walker", 6, 1],
			[&"walker", 8, 0],
		],
	},
	{
		"note": "the first runners: fast, fragile, and they ignore your walls",
		"opening_ticks": 0,
		"gap_ticks": 14 * SECONDS,
		# **Six, not ten.** At ten this was the hardest night of the first
		# five - a player meeting the runner for the first time lost to it,
		# with night four, the one that is meant to examine them on it,
		# holding comfortably. An introduction that kills you is not an
		# introduction. Measured with `tools/play_nights.py` at $150 a day.
		"waves": [
			[&"walker", 6, 0],
			[&"runner", 2, 1],
			[&"walker", 12, 0],
			[&"runner", 4, 1],
		],
	},
	{
		"note": "runners in numbers - the night that asks for rate of fire",
		"opening_ticks": 0,
		"gap_ticks": 14 * SECONDS,
		"waves": [
			[&"walker", 10, 0],
			[&"runner", 8, 1],
			[&"walker", 12, 0],
			[&"runner", 10, 1],
		],
	},
	{
		"note": "the first tank: one thing a crossbow line cannot chew through",
		"opening_ticks": 0,
		"gap_ticks": 13 * SECONDS,
		"waves": [
			[&"walker", 10, 0],
			[&"tank", 1, 0],
			[&"runner", 14, 1],
			[&"walker", 14, 0],
			[&"tank", 2, 0],
		],
	},
	{
		"note": "tanks in threes, with the crowd still coming",
		"opening_ticks": 0,
		"gap_ticks": 13 * SECONDS,
		"waves": [
			[&"walker", 12, 0],
			[&"tank", 2, 0],
			[&"runner", 16, 1],
			[&"walker", 14, 1],
			[&"tank", 4, 0],
		],
	},
	{
		"note": "the breakers arrive, and an uncovered tower line is a debt",
		"opening_ticks": 0,
		"gap_ticks": 9 * SECONDS,
		"waves": [
			[&"walker", 12, 0],
			[&"breaker", 4, 1],
			[&"runner", 16, 1],
			[&"tank", 4, 0],
			[&"walker", 14, 0],
			[&"breaker", 4, 1],
		],
	},
	{
		"note": "a large night: everything at once and more of it",
		"opening_ticks": 0,
		"gap_ticks": 8 * SECONDS,
		"waves": [
			[&"walker", 14, 0],
			[&"breaker", 6, 1],
			[&"runner", 20, 1],
			[&"tank", 5, 0],
			[&"walker", 16, 0],
			[&"breaker", 8, 1],
		],
	},
	{
		"note": "the heavy mix, and the dress rehearsal for the Giant",
		"opening_ticks": 0,
		"gap_ticks": 6 * SECONDS,
		"waves": [
			[&"walker", 16, 0],
			[&"breaker", 8, 1],
			[&"runner", 24, 1],
			[&"tank", 8, 0],
			[&"walker", 16, 0],
			[&"breaker", 8, 1],
		],
	},
	{
		"note": "the Giant, with company so it cannot be focused down alone",
		"opening_ticks": 0,
		"gap_ticks": 4 * SECONDS,
		"waves": [
			[&"walker", 16, 0],
			[&"breaker", 6, 1],
			# **It walks in while the farm is already busy.** A Giant that
			# arrived alone would be a duel; arriving third, with runners
			# behind it, is a test of the whole build.
			[&"giant", 1, 0],
			[&"runner", 26, 1],
			[&"tank", 8, 0],
			[&"walker", 20, 0],
			[&"breaker", 8, 1],
		],
	},
]

## How long the world takes to change, in seconds.
##
## **A lever here and not in the view**, because task 0078 asks for one and
## because it is a number a designer will want to turn while watching it. It
## is deliberately **not** in `digest()`: that guard watches the balance
## tables, and a two-second fade is not balance - putting it in would mean a
## purely visual tweak failing a check about whether the game plays the same.
## `video/transition_seconds` lets a player move it as well.
const TRANSITION_SECONDS := 1.6         # LEVER: seconds, 0.4-4.0

## **The night camera** (task 0130): from the build step to the morning the
## camera is the player's, panned with the move keys, the right stick or the
## pointer at the window's edge. View feel, not balance, so like the fade
## above these stay out of `digest()`. The speed is in **real** seconds: 2x and
## 4x make the night faster, not the camera.
const CAMERA_PAN_SPEED := 240.0         # LEVER: world pixels a second at full tilt, 120-480
const CAMERA_EDGE_PIXELS := 8           # LEVER: world pixels from the window's edge that pan, 4-16

## **The guardian's cursor on a pad** (task 0131): one cell per press, and a
## held direction repeats after the delay at the rate. View feel, out of
## `digest()` like the camera's; real seconds.
const CURSOR_REPEAT_DELAY := 0.3        # LEVER: seconds before a held step repeats, 0.15-0.6
const CURSOR_REPEAT_RATE := 0.08        # LEVER: seconds between repeated steps, 0.04-0.2

## Task 0109: the little bubble over the farmer's head.
##
## **Off is a supported state.** The done-when is that turning every reaction
## off changes nothing, and the only way to mean that is for somebody to be
## able to do it - so this is a switch and not a comment. With it off,
## `Reactions.tick()` counts the current one down and raises no more.
const REACTIONS_ON := true              # LEVER: on or off

## How long a bubble stays up. A second and a half: long enough to be read at
## four times speed, short enough that two things happening in a row are two
## bubbles rather than one that never leaves.
const REACTION_TICKS := 45              # LEVER: ticks, 20-120

## How close a crop has to come ready for the farmer to notice, in tiles of
## walking. A crop on the far side of the farm is not something somebody
## standing at the pond can see.
const REACTION_NEAR := 6                # LEVER: tiles, 3-12

## The curve that writes night eleven and everything after it.
##
## **The authored ten are the shape; this is the extrapolation.** A generated
## night is the same record as a written one - note, opening, gap, waves - so
## everything downstream of `Waves.night_of()` cannot tell the difference, and
## nothing in `Enemies`, `Rewards` or the HUD needed a line about endless.
##
## ## What grows, and what must not
##
## `growth_percent` is added per night past the tenth, **not compounded**:
## compounding turns night forty into a number with no relationship to a farm
## anyone could build, and the point of endless is "how far does my build go",
## not "watch an exponent win". Night ten sends 85, so at 12 a night past it
## sends 85 + ten more each night: night 25 sends around 238.
##
## `mix` is a weight per kind and how much that weight shifts per night. The
## walker's share falls and the tank's and breaker's rise, so a late night is
## not merely a bigger early night - which is the difference between a curve
## and a multiplier. **A weight never falls below one**: a kind that dropped
## out entirely would quietly narrow the game the longer you played it.
##
## `is_boss` kinds are not in `mix` and cannot be: the Giant arrives on its own
## schedule below, and rolling one out of the mix would put a boss on night
## eleven. `validate()` refuses a mix that names one, or that names an enemy
## which does not exist.
const ENDLESS: Dictionary = {
	# Added to the night's size per night past the tenth, of night ten's size.
	"growth_percent": 12,           # LEVER: percent a night, 4-30
	# **About** how many waves a generated night arrives in, and how often
	# that grows. A target rather than a count: the bodies are dealt to the
	# kinds in proportion, and the rounding sometimes lands a wave short.
	"waves": 7,                     # LEVER: waves, 4-12
	"extra_wave_every": 10,         # LEVER: nights per extra wave, 5-25
	# A generated night is paced at the tightest the authored ten reach.
	"opening_ticks": 0,
	"gap_ticks": 4 * SECONDS,       # LEVER: ticks, 2-10 seconds worth
	# The Giant comes back every fifth night - 15, 20, 25 - and one more of
	# them every tenth, so night twenty brings two and night thirty three.
	"giant_every": 5,               # LEVER: nights, 3-10
	"giant_extra_every": 10,        # LEVER: nights per extra Giant, 5-30
	# **The drift stops here.** Left to run, `walker` reaches its floor of one
	# and stays there: night 99 was measured at 992 bodies of which **one** was
	# a walker, against 386 breakers. A weight clamped at one is not a kind
	# that still turns up, it is a kind that has dropped out with a rounding
	# error for a headstone - which is exactly the narrowing the floor was put
	# there to prevent. Twenty nights of drift and then a fixed heavy mix:
	# night 99 becomes 110 walkers, 275 runners, 286 tanks and 319 breakers,
	# which is a wall with everything still in it.
	"mix_settles_after": 20,        # LEVER: nights of drift, 5-40
	# kind -> [weight at night ten, how much it shifts each night after]
	"mix": {
		&"walker": [40, -1],        # LEVER: weight and drift
		&"runner": [30, 1],         # LEVER: weight and drift
		&"tank": [12, 2],           # LEVER: weight and drift
		&"breaker": [18, 2],        # LEVER: weight and drift
	},
}

## Where the horde comes in, as `[[x, y], ...]` per spawn point.
##
## The wave tables above name these by index: `0` comes from the east and `1`
## from the south east. **Where they always were, relative to the house**: when
## the farmstead moved to the middle of the farm (2026-10-06) both moved with
## it, 24 tiles east and 18 south, so a night is fought over the same ground
## at the same distances it was balanced on. A cell that is not walkable or
## cannot reach the house is skipped at spawn time rather than being kept in
## step by hand here.
##
## **Not every side at once.** A farm attacked from every direction on its
## first night cannot be defended with the handful of towers it affords, and
## the reason to choose where a wall goes disappears with it. So a side opens
## with each season (task 0157, `SIDES_BY_SEASON`): spring comes from the
## east, and winter from all five.
##
## Regions 2-4 are 0156's spawn ground (`SPAWN_BANDS`), the same cells -
## `check_sides` keeps the two in step.
const SPAWNS: Array = [
	# 0 - the east, a line across the east road out in the open field.
	[[68, 22], [68, 23], [68, 24], [68, 25], [68, 26], [68, 27],
	 [68, 28], [68, 29], [68, 30], [68, 31]],
	# 1 - the south east, along the open ground below the stall.
	[[50, 32], [52, 32], [54, 32], [56, 32], [58, 32],
	 [48, 31], [60, 31]],
	# 2 - the north, along the top edge under the tree line.
	[[35, 1], [36, 1], [37, 1], [38, 1], [39, 1], [40, 1], [41, 1],
	 [42, 1], [43, 1], [44, 1]],
	# 3 - the west, down the open ground west of the farmstead.
	[[8, 20], [8, 21], [8, 22], [8, 23], [8, 24], [8, 25], [8, 26],
	 [8, 27], [8, 28], [8, 29]],
	# 4 - the south, across the south road near the bottom edge.
	[[35, 55], [36, 55], [37, 55], [38, 55], [39, 55], [40, 55],
	 [41, 55], [42, 55], [43, 55], [44, 55]],
]

## What each `SPAWNS` region is called (task 0157) - the forecast's words,
## and the order of `SPAWNS`.
const SPAWN_SIDES: Array = [&"east", &"south_east", &"north", &"west", &"south"]

## **Which sides each season attacks from** (task 0157), as `SPAWNS`
## indices, in `SEASONS` order. Each season keeps the sides of the one before
## and opens a new one; `Calendar.open_sides` reads it.
const SIDES_BY_SEASON: Array = [[0], [0, 1], [0, 1, 2], [0, 1, 2, 3, 4]]  # LEVER: sides per season

## **Today's ten nights, allowed the south east in spring** (task 0157). They
## were balanced on two sides and a ten-night run, and nights 2 to 10 come
## from the south east, which spring does not open. `check_nights` lets
## these dates use region 1 until 0271 rewrites spring and deletes this.
const SPRING_DRAFT_SIDES: Dictionary = {1: [2, 3, 4, 5, 6, 7, 8, 9, 10]}


# ===================================================================== rewards

## What a night pays, and what losing one costs.
const REWARDS: Dictionary = {
	# Paid for finishing the night at all, growing with the night number.
	"base_money": 30,                   # LEVER: money, 15-60
	"money_per_night": 15,              # LEVER: money added per night, 5-30
	"resources": {WOOD: 10, STONE: 8, IRON: 4},
	"resources_per_night": {WOOD: 4, STONE: 3, IRON: 2},
	# **Defending well should pay more than barely holding**, so this is paid
	# per structure that came through **without a scratch** rather than per
	# structure still upright. A wall at one hit point held the line and is
	# worth nothing here; the player who never let it be touched is the one
	# being paid.
	"intact_structure_bonus": 4,        # LEVER: money each, 1-10
	# And a smaller one for the ones that took damage and held anyway, so
	# that a hard-won night is not worth less than a quiet one.
	"standing_structure_bonus": 1,      # LEVER: money each, 0-4
	"house_untouched_bonus": 25,        # LEVER: money, 10-50
	"tech_points": 1,                   # LEVER: per night survived, 1-2
}

## What a tower becomes, twice. `design.md` section 12 draws it as
## Torre I -> Torre II -> Torre Automatica.
##
## **Entries in a table, not subclasses.** A level is a handful of fields laid
## over the tower's own, so a level three gun tower is `DEFENCES[&"gun_tower"]`
## with three numbers changed - and `Building.entry_at()` is the one place
## that does the laying-over. Adding a fourth level is a row here.
##
## ## Level three earns the word "automatic"
##
## Each one ends in a **behaviour** change rather than another number: the gun
## tower and the crossbow start shooting two things at once (`targets`, which
## has been in the table since it was written and read by nothing), the mortar
## stops needing a minimum range, and the flamethrower's fire lasts twice as
## long. A level three that was only bigger numbers would be a lever with a
## price tag on it.
##
## ## Gated by the tree as well as by the purse
##
## Level two wants `true sights` and level three wants `oiled works` - the
## first and third of the defence branch. That is deliberate: it makes the
## branch task 0063's journal recommends worth more than its own numbers, and
## it means upgrading is a thing you unlock once and then pay for every time.
const TOWER_LEVELS: Dictionary = {
	&"gun_tower": [
		{"needs": &"true sights", "cost": {WOOD: 10, IRON: 20},
			"gives": {"damage": 9, "hp": 90, "range": 6}},
		{"needs": &"oiled works", "cost": {IRON: 35, GUNPOWDER: 10},
			"gives": {"damage": 11, "hp": 120, "range": 6, "targets": 2}},
	],
	&"auto_crossbow": [
		{"needs": &"true sights", "cost": {WOOD: 15, IRON: 25},
			"gives": {"damage": 7, "hp": 75, "pierce": 6}},
		{"needs": &"oiled works", "cost": {IRON: 40, GUNPOWDER: 15},
			"gives": {"damage": 9, "hp": 100, "pierce": 7, "targets": 2}},
	],
	&"mortar": [
		{"needs": &"true sights", "cost": {STONE: 25, IRON: 30},
			"gives": {"damage": 55, "hp": 80, "splash_tiles": 2}},
		{"needs": &"oiled works", "cost": {IRON: 45, GUNPOWDER: 25},
			# **No minimum range.** The thing that made a mortar a decision
			# rather than a purchase, lifted - which is what the last level
			# of anything should be worth.
			"gives": {"damage": 70, "hp": 110, "splash_tiles": 3,
				"min_range": 0}},
	],
	&"flame_tower": [
		{"needs": &"true sights", "cost": {WOOD: 15, IRON: 20, OIL: 10},
			"gives": {"damage": 4, "hp": 95, "burn_damage": 3}},
		{"needs": &"oiled works", "cost": {IRON: 35, OIL: 25},
			"gives": {"damage": 5, "hp": 130, "burn_damage": 4,
				"burn_ticks": 6 * SECONDS}},
	],
}

## The most any tower can be upgraded to. Level one is the thing as built.
const TOP_TOWER_LEVEL := 3


## The tech tree: twelve nodes, three branches, four deep.
##
## `design.md` section 12 wants somewhere to spend technology and is explicit
## that the MVP does **not** get a giant tree. Twelve fits on one screen, and
## the shape - three branches of four - is what makes the choice legible: a
## player can see the whole thing and still not have it.
##
## ## Priced against the ten nights
##
## A run pays 10 technology at worst and 40 at best (`Tech.total_available()`).
## A branch costs 2 + 3 + 4 + 6 = 15, so all three cost 45 - **more than the
## best run earns**. That is the point: every node is reachable inside ten
## nights and not all of them are, which is the done-when.
##
## A good run takes two branches and the shallow end of the third. A bad run
## takes four or five shallow nodes and feels it.
##
## ## The effect is a number the rules already read
##
## Every node hands one entry to `Tech.bonus()`, and the system that owns that
## number asks for it. Nothing here knows what a tower is; `Towers` knows what
## `tower_damage_percent` is worth and asks. A thirteenth node is a row here
## plus one `Tech.bonus()` call wherever it belongs.
const TECH_TREE: Array = [
	# ---------------------------------------------------------- production
	{"id": &"sharp tools", "branch": &"production", "cost": 2, "needs": [],
		"gives": {"gather_percent": 130},
		"note": "chopping and mining go half again as fast"},
	{"id": &"full cans", "branch": &"production", "cost": 3,
		"needs": [&"sharp tools"], "gives": {"water_can_bonus": 4},
		"note": "the watering can holds four more"},
	{"id": &"steady hands", "branch": &"production", "cost": 4,
		"needs": [&"full cans"], "gives": {"craft_percent": 135},
		"note": "the workshop, press and kitchen work a third faster"},
	{"id": &"a name at market", "branch": &"production", "cost": 6,
		"needs": [&"steady hands"], "gives": {"sell_percent": 125},
		"note": "everything you sell fetches a quarter more"},

	# ------------------------------------------------------------- defence
	{"id": &"true sights", "branch": &"defence", "cost": 2, "needs": [],
		"gives": {"tower_damage_percent": 120},
		"note": "every tower hits a fifth harder"},
	{"id": &"long barrels", "branch": &"defence", "cost": 3,
		"needs": [&"true sights"], "gives": {"tower_range_bonus": 1},
		"note": "every tower reaches one tile further"},
	{"id": &"oiled works", "branch": &"defence", "cost": 4,
		"needs": [&"long barrels"], "gives": {"tower_reload_percent": 80},
		"note": "every tower reloads a fifth sooner"},
	{"id": &"a standing order", "branch": &"defence", "cost": 6,
		"needs": [&"oiled works"], "gives": {"tower_cost_percent": 75},
		"note": "towers cost a quarter less to build"},

	# ------------------------------------------------------------ survival
	{"id": &"stout timbers", "branch": &"survival", "cost": 2, "needs": [],
		"gives": {"house_hp_bonus": 40},
		"note": "the house takes forty more before it falls"},
	{"id": &"a full larder", "branch": &"survival", "cost": 3,
		"needs": [&"stout timbers"], "gives": {"repair_percent": 60},
		"note": "mending costs two fifths less"},
	{"id": &"spare stakes", "branch": &"survival", "cost": 4,
		"needs": [&"a full larder"], "gives": {"barricade_bonus": 3},
		"note": "three more barricades a night"},
	{"id": &"a second flare", "branch": &"survival", "cost": 6,
		"needs": [&"spare stakes"], "gives": {"flare_percent": 55},
		"note": "the flare comes back in a little over half the time"},
]

## What refunding a node costs, as a percentage of what it cost to buy. **Not
## free and not forbidden**: a player who spent six points on the wrong branch
## on night three should not have to live with it for seven nights, and a
## player who can shuffle the whole tree between waves is not choosing.
const TECH_REFUND_PERCENT := 50         # LEVER: percent returned, 0-100


## What a night can be worth **beyond finishing it**, as conditions rather
## than as code. `Tech._earned()` has one arm per `id` here and shouts if a
## row arrives without one: a bonus that silently never pays is worse than a
## bonus that does not exist.
##
## Three of them, each asking for something a little harder than the last, so
## that a player who wants the tree faster has three things to aim at rather
## than one number to grind.
const TECH_BONUSES: Array = [
	{"id": &"house untouched", "points": 1},    # LEVER: points, 0-2
	{"id": &"nothing lost", "points": 1},       # LEVER: points, 0-2
	{"id": &"not one got through", "points": 1},# LEVER: points, 0-2
]

## Losing a night takes a share of the stock. It must hurt enough to matter and
## little enough to keep playing: `design.md` is explicit that a loss costs a
## day, never the run.
## **A percentage, not a fraction.** This was `0.25` - the eighth of them
## found this way, after `WATER_GROWTH_BONUS`, `BROWNOUT_RATE`,
## `splash_falloff`, `pierce_falloff`, `structure_damage_multiplier`,
## `HOUSE_REPAIR_PENALTY` and `slow_fraction`. The rules are integers.
const DEFEAT_LOSS_PERCENT := 25         # LEVER: percent of the stock, 10-40

## What a loss does **not** take. Both were declared with the table and read
## by nothing: `Rewards` skipped money by name and energy by accident, so
## turning either of these off changed nothing at all.
const DEFEAT_KEEPS_MONEY := true
const DEFEAT_KEEPS_TECH := true

## **How wide the horde tramples** (task 0155): when the house falls, every
## crop on the cells the horde walked to it is lost, and this many tiles
## either side of those cells too. The routes are the flow field's, never
## dice - see `Pathing.horde_routes`.
const TRAMPLE_REACH := 0                # LEVER: tiles either side of a route, 0-2


# ====================================================================== the map

## The farm, as one 80x65 picture: **Stardew Valley's Standard Farm size**,
## 5,200 cells. `design.md` asked for 1.2-1.5 screens; the owner asked for
## this one on 2026-10-05.
##
## **The farmstead is in the middle**, at the head of the south road, where the
## owner put it on 2026-10-06: the house facing down the road, the workshop and
## its animals to the west, the stall to the east, the well by the porch and
## the beds in two fields either side of the road, with the small southern
## garden behind the workshop. Roads run from it to the east and south edges,
## and the night comes from the east and the south east (`SPAWNS`). The top
## left is what the first farm was - its pond and jetty, the quarry, the
## trees - with the old yard gone back to saplings and stones. Around it all:
## a tree line, woods, a forest with a pond to the south west, an orchard, a
## second pond with a jetty, a rocky outcrop, and open ground strewn the way a
## new Stardew farm is. Saves keep their own farm: migrations widen older ones
## without moving anything on them.
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
##     u  copper ore     k  coal seam             g  gold ore
##     h  a hardwood stump, one thing over 2x2 cells
##
## **The 1.0 farm** (task 0156): spawn ground cleared for the sides 0157
## opens (`SPAWN_BANDS`), copper, coal and gold on the north-east outcrop and
## four hardwood stumps in the south-west woods under their final ids - inert
## obstacles until 0176 and 0177 give them `GATHERING` rows - the ponds named
## in `PONDS`, and the coop's, the barn's and the shipping bin's room kept
## clear in `MAP_SITES`.
##
## `validate()` checks the shape, so a row typed one character short is a red
## line rather than a farm that is subtly wrong down one edge.
const FARM_MAP: Array = [
	"TTT.TTTT....TTT..TT.....TT....TT..TTT.TTT.TT...TTTTT..TTTTT..TTTTT..TTTTT..TTT.T",
	"....................S######o........................................r..........T",
	"T......T............S######o...........T.......T.T...r.........................T",
	"....................S######o...........T...........r...............u###gg#r....T",
	".....T...r..........S######o....r.............T.T.T...............r#######.....T",
	"T..........r........S######o...........T..............T........T...u######r....T",
	"......T.............#####ooo...................T.T................r##kk###.....T",
	"T.........T.....T......................T.........................r..r..r.r.....T",
	"...............pp...r.....r............T......T.T.T............................T",
	"...T........T..pp................T.T...T...............................r.......T",
	".........r.....pp.T............rTT.TT..T.......T.TT..T.........................T",
	"T..............pp................TT.T..T.......................................T",
	".....r......r..pp...T.........TT.TT.TT........T.T.T............................T",
	"T.........=====p......T.........TT.T...T.......................................T",
	"..~~~~~~~~=====................................T.T.............................T",
	".~~~~~~~~~~~~~~~~~..............TT.....................T..T..T..T..T..T.TT..T..T",
	"~~~~~~~~~~~~~~~~~~~~~~~....TT.................T.T.T............................T",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~..TTT...TTTTTT...........................T...........T",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~............................T..T..T..T..T..T.TT..T..T",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~...TT...TT..TTTTT..................................T",
	"..............................ssss........................T......r.............T",
	"..............................ssss.....................T..T..T..T..T..T..T..T..T",
	"..............................ssss...HHHHHH....................................T",
	".....................................HHHHHH....................................T",
	"..............................WWWW...HHHHHH.$$$$....r.......T...T..r...........T",
	"T.............................WWWW...HHHHHH.$$$$...............................T",
	"T.............................WWWW..w..pp.................T....................T",
	"T......................T...C....pppppppppppppppppppppppppppppppppppppppppppppppp",
	"T.T.T.T...T.T.T.T.T.T.Tr...............pp.......pppppppppppppppppppppppppppppppp",
	"T.........................c.....ssssss.pp.ssssss...............................T",
	"T..T.T.T.T.T...T.T.T........c...ssssss.pp.ssssss.....T.........................T",
	"T...............................ssssss.pp.ssssss...T.....r.....................T",
	"T.T.T.T.T.T.T.T.T.T.T.T.........ssssss.pp.ssssss...........T...................T",
	"T......................................pp..............r.......................T",
	"T..T.T.T...T...T.T.T.T.................pp............r.........................T",
	"T......................................pp......................................T",
	"T.T.T.T.T.T.T.T.T.T.T.T...........r....pp......................................T",
	"T....hh................................pp......................................T",
	"T..T.hh..........T.T.T.......T.........pp......................................T",
	"T......................................pp.......T...r...T............T.........T",
	"T.T...T...~~~~......T.T..............T.pp.............................TT.......T",
	"T........~~~~~~........................pp......................==.r............T",
	"T..T.T...~~~~~~..T.T.T.................pp......................==..............T",
	"T........~~~~~~..pppppppp..............pp....................~~==~~............T",
	"T.T.T.T...~~~~....T.T..................pp..................~~~~==~~~~~.r.......T",
	"T.......hh..................T......T...pp.................~~~~~==~~~~~~...r....T",
	"T..T.T..hh.......T.T.T.....T...T.......pp...........TT...~~~~~~~~~~~~~~~.r.....T",
	"T.......................hh..r..........pp...T............~~~~~~~~~~~~~~~~......T",
	"T.T.T.T.............T...hh........r....pp................~~~~~~~~~~~~~~~~......T",
	"T......................................pp..T....T..T......~~~~~~~~~~~~~~.......T",
	"T..T.T.T.T.T.T.T.T.T.T...............r.pp.................~~~~~~~~~~~~~........T",
	"T..............................r.......pp..............r....~~~~~~~~~..........T",
	"T.T.T.T...T...T.T.T.T.T...r............ppr....................~~~~~............T",
	"T......................................pp.....T................................T",
	"T..T.T.T.T.T...T.T.T.T.........TT......pp...............................r......T",
	"T......................................pp................................r.....T",
	"T.T.T.T...T.T.T.T.T...T................pp................................T.....T",
	"T......................T..............Tpp...T...........T.......T..............T",
	"T..T.Thh.T.T.T.T...T.T.................pp......................................T",
	"T.....hh...............................pp....................T.......T.........T",
	"T.T...T.T.T.T...T.T.T.T......r.........pp......................................T",
	"T....................................rTpp...................T..............r...T",
	"T......................................pp......................................T",
	"T......................................pp......................................T",
	"T.TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT.pp.TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT.T",
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
	"C": [0, &"cow"],
	"c": [0, &"chicken"],
	"u": [3, &"copper_ore"],
	"k": [3, &"coal_seam"],
	"g": [3, &"gold_ore"],
	"h": [0, &"hardwood_stump"],
}

## **Nodes on the map with no `GATHERING` row yet** (task 0156): under their
## final ids, so 0176 (copper, coal, gold) and 0177 (hardwood) change data
## only. Until then they are inert, impassable obstacles with no verb - and
## `check_reachable` still sees that each can be stood beside. Each task
## takes its own off this list when it gives them a row.
const UNGATHERED_NODES: Array = [&"copper_ore", &"coal_seam", &"gold_ore", &"hardwood_stump"]

## Map props bigger than one cell, by id: one thing over its footprint, with
## an `anchor` on every cell as a building's footprint is kept.
const MAP_PROP_SIZES: Dictionary = {&"hardwood_stump": Vector2i(2, 2)}

## **Spawn ground for the sides 0157 opens** (task 0156): lines of cleared,
## walkable cells near the north, west and south edges, away from the
## farmstead and about as far from the house by path as the east band of
## `SPAWNS` (26-32 steps): the north 22-27, the west 29-34, the south
## 30-33, measured with `Pathing.distance` on a new farm. Nothing on them
## regrows. 0157 turns them into `SPAWNS` regions; until then nothing spawns
## here.
const SPAWN_BANDS: Dictionary = {
	&"north": [[35, 1], [36, 1], [37, 1], [38, 1], [39, 1], [40, 1], [41, 1],
		[42, 1], [43, 1], [44, 1]],
	&"west": [[8, 20], [8, 21], [8, 22], [8, 23], [8, 24], [8, 25], [8, 26],
		[8, 27], [8, 28], [8, 29]],
	&"south": [[35, 55], [36, 55], [37, 55], [38, 55], [39, 55], [40, 55],
		[41, 55], [42, 55], [43, 55], [44, 55]],
}

## **The farm's waters, by name** (task 0156): one cell of each body, which
## `Farm.pond_of` finds by flood fill over the state's own terrain - so 0179
## can key a fish to a pond, and a save's pond is still that pond.
const PONDS: Dictionary = {
	&"north_west_pond": [10, 16],
	&"forest_pond": [11, 42],
	&"south_east_lake": [66, 48],
}

## **Room kept clear** (task 0156), as `[x, y, width, height]`: the coop and
## the barn by the workshop and the animals, each room for a footprint up to
## 7x4 (0183 decides the real ones), and the shipping bin by the porch
## (0189). Nothing on the map stands in them, and `check_sites` keeps it so.
const MAP_SITES: Dictionary = {
	&"coop": [21, 21, 7, 4],
	&"barn": [23, 33, 7, 4],
	&"shipping_bin": [43, 26, 2, 1],
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
	errors.append_array(check_enemies(ENEMIES))
	errors.append_array(check_nights(NIGHTS))
	errors.append_array(check_map(FARM_MAP))
	errors.append_array(check_fishing(FISHING))
	errors.append_array(check_iron(GATHERING, FARM_MAP))
	errors.append_array(check_reachable(GATHERING, FARM_MAP))
	errors.append_array(check_spawn_bands(SPAWN_BANDS, FARM_MAP))
	errors.append_array(check_sides(SPAWNS, SPAWN_SIDES, SIDES_BY_SEASON))
	errors.append_array(check_ponds(PONDS, FARM_MAP))
	errors.append_array(check_sites(MAP_SITES, FARM_MAP))
	errors.append_array(check_chain(RECIPES, SELL_PRICE))
	errors.append_array(check_livestock(LIVESTOCK, FARM_MAP))
	errors.append_array(check_ammo(DEFENCES, RECIPES))
	errors.append_array(check_groups(RESOURCE_GROUPS, RESOURCES))
	errors.append_array(check_stall(DAILY_STOCK, SELL_PRICE, BUY_MARKUP))
	errors.append_array(check_tutorial(TUTORIAL))
	errors.append_array(check_pathing(TERRAIN_COST, DEFENCES, BUILDINGS))

	for res in sorted_names(REPAIR_COST_PER_HP.keys()):
		if not RESOURCES.has(res):
			errors.append("repair costs unknown '%s'" % res)

	for key in [&"resources", &"resources_per_night"]:
		for res in (REWARDS[key] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("rewards %s gives unknown '%s'" % [key, res])

	errors.append_array(check_clock(DAY_START_MINUTE, DUSK_MINUTE,
		DAY_END_MINUTE, DAY_TICKS))
	errors.append_array(check_bedtime(DUSK_MINUTE, BEDTIME_REMINDER_MINUTE,
		PASS_OUT_WARNING_MINUTE, DAY_END_MINUTE))
	errors.append_array(check_calendar(SEASONS, SEASON_DAYS, FULL_MOON_DAYS,
		FULL_MOON_HORDE_PERCENT, FULL_MOON_REWARD_PERCENT, SEASON_BOSSES))
	errors.append_array(check_gift(CALM_NIGHT_GIFT))
	if TRAMPLE_REACH < 0 or TRAMPLE_REACH > 2:
		errors.append("TRAMPLE_REACH is %d tiles, outside 0-2" % TRAMPLE_REACH)
	if PASS_OUT_PREPARATION_TICKS <= 0 \
			or PASS_OUT_PREPARATION_TICKS >= Sim.MOST_TICKS_IN_A_NIGHT:
		errors.append("the build step after passing out is %d ticks, outside 1..%d"
			% [PASS_OUT_PREPARATION_TICKS, Sim.MOST_TICKS_IN_A_NIGHT - 1])
	# **Dawn comes before the bound that catches a night that never ends**
	# (task 0137), and leaves the night some room after its margin.
	if NIGHT_TICKS <= 0 or NIGHT_TICKS >= Sim.MOST_TICKS_IN_A_NIGHT:
		errors.append("the night is %d ticks to dawn, outside 1..%d"
			% [NIGHT_TICKS, Sim.MOST_TICKS_IN_A_NIGHT - 1])
	if DAWN_MARGIN_TICKS < 0 or DAWN_MARGIN_TICKS >= NIGHT_TICKS:
		errors.append("the margin before dawn is %d ticks of a %d-tick night"
			% [DAWN_MARGIN_TICKS, NIGHT_TICKS])

	return errors


## The clock is a clock: the day starts, darkens and ends in that order, and
## every game minute is the same whole number of ticks - so the HUD never shows
## a minute twice or skips one. Takes its numbers as arguments, like
## `check_tutorial()`, so a check can hand it a bad clock.
static func check_clock(start: int, dusk: int, end: int, day_ticks: int) -> Array:
	var errors: Array = []
	if not (start < dusk and dusk < end):
		errors.append("the clock runs %d, dusk %d, end %d - not in that order"
			% [start, dusk, end])
	var span := end - start
	if span <= 0 or day_ticks <= 0 or day_ticks % span != 0:
		errors.append("%d ticks are not a whole number of ticks per minute over %d minutes"
			% [day_ticks, span])
	return errors


## The day HUD's bedtime thresholds in their order (task 0140): the reminder
## no earlier than dusk, the warning after it, and both before the day ends.
static func check_bedtime(dusk: int, reminder: int, warning: int, end: int) -> Array:
	if dusk <= reminder and reminder < warning and warning < end:
		return []
	return ["bedtime runs dusk %d, reminder %d, warning %d, end %d - not in that order"
		% [dusk, reminder, warning, end]]


## The calm night's gift (task 0154): things the ledger knows, in whole
## numbers, and never money or technology - a night nobody defended earns
## neither.
static func check_gift(gift: Dictionary) -> Array:
	var errors: Array = []
	for id in sorted_names(gift.keys()):
		if not RESOURCES.has(id):
			errors.append("the calm night's gift names unknown '%s'" % id)
		elif id == MONEY or id == TECH:
			errors.append("the calm night's gift may not be %s" % id)
		if int(gift[id]) < 0:
			errors.append("the calm night's gift takes %s away" % id)
	return errors


## The calendar's shape (task 0149): four seasons, each named once, and a
## season long enough to have a first day and a last. Since task 0152, its
## Full Moons fall inside the season and make a night bigger and better paid,
## never smaller.
static func check_calendar(seasons: Array, season_days: int,
		full_moon_days: Array = [], horde_percent: int = 100,
		reward_percent: int = 100, bosses: Array = []) -> Array:
	var errors: Array = []
	# **A boss for every season, and a boss it is** (task 0153).
	if not bosses.is_empty() and bosses.size() != seasons.size():
		errors.append("%d season bosses for %d seasons" % [bosses.size(), seasons.size()])
	for boss in bosses:
		var kind: Dictionary = ENEMIES.get(StringName(boss), {})
		if not bool(kind.get("is_boss", false)):
			errors.append("the season boss '%s' is not an is_boss enemy" % boss)
	for day in full_moon_days:
		if int(day) < 1 or int(day) > season_days:
			errors.append("a Full Moon on day %d is outside a %d-day season"
				% [int(day), season_days])
	if horde_percent < 100:
		errors.append("a Full Moon horde of %d%% is smaller than the night"
			% horde_percent)
	if reward_percent < 100:
		errors.append("a Full Moon paying %d%% pays less than the night"
			% reward_percent)
	if seasons.size() != 4:
		errors.append("a year has %d seasons, not four" % seasons.size())
	for i in seasons.size():
		if seasons.find(seasons[i]) != i:
			errors.append("the season '%s' is in the year twice" % seasons[i])
	if season_days < 2:
		errors.append("a season of %d days has no first day and last day apart"
			% season_days)
	return errors


## The cost field has to be able to represent every step it can be asked to
## take, and a bucket wheel that is one short does not fail loudly - it puts a
## cell in the wrong bucket and the route comes out subtly wrong. So the
## widest step is checked against the tables rather than kept in step by hand.
static func check_pathing(terrain: Array, defences: Dictionary,
		buildings: Dictionary) -> Array:
	var errors: Array = []

	var ground := 0
	for cost in terrain:
		if int(cost) < 0:
			errors.append("a terrain costs less than nothing to cross")
		ground = maxi(ground, int(cost))
	if ground <= 0:
		errors.append("no terrain can be crossed at all")

	for table in [defences, buildings]:
		for id in sorted_names((table as Dictionary).keys()):
			var entry: Dictionary = (table as Dictionary)[id]
			var through := int(entry.get("path_cost", 0))
			if through < 0:
				errors.append("'%s' costs less than nothing to break" % id)
			if ground + through > WIDEST_STEP:
				errors.append(("stepping into '%s' costs %d, which is wider than "
					+ "WIDEST_STEP (%d)") % [id, ground + through, WIDEST_STEP])
			# **A thing you can walk through is a thing you can break.** The
			# field prices a barrier by how long getting through it takes; if
			# nothing could take it apart, a zombie would route into it and then
			# stand there for the rest of the night.
			if through > 0 and int(entry.get("hp", 0)) <= 0:
				errors.append(("'%s' declares a path cost but has no hit points - "
					+ "there would be no way through it after all") % id)

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
		if int((crops[crop_id] as Dictionary)["growth_days"]) <= 0:
			errors.append("crop '%s' grows in no time at all" % crop_id)

	# **No crop may be the right answer at every money level.** A crop that
	# pays at least as much per season, for no more visits, off a no larger seed,
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


## What one plot of a crop offers over a season: money, trips, and the money it
## takes to start. The three axes `check_crops()` refuses to let one crop win
## outright.
static func _crop_offer(crops: Dictionary, id: StringName) -> Dictionary:
	var data: Dictionary = crops[id]
	var visits := SEASON_DAYS / maxi(int(data["growth_days"]), 1)
	var net := int(data["yield"]) * int(SELL_PRICE.get(id, 0)) 		- int(data["seed_cost"])
	return {"value": net * visits, "visits": visits,
		"seed": int(data["seed_cost"])}


## The four cells beside a cell. Typed, because an untyped array literal
## makes its loop variable a Variant and `cell + step` stops being a
## Vector2i the moment it is.
const NEIGHBOUR_STEPS: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
]


## Iron comes out of the cliff and nowhere else, and it is dearer than stone.
##
## Both are things a balance pass could undo without anything else noticing:
## a node dropped on the lawn would be iron with no walk attached, and ore made
## quicker than stone would make the whole rock face one resource with two
## names.
static func check_iron(nodes: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	var ore: Dictionary = nodes[&"ore"]
	var seam: Dictionary = nodes[&"seam"]

	if int(ore["work_ticks"]) <= int(seam["work_ticks"]):
		errors.append("ore swings in %d ticks and stone in %d - iron is meant "
			% [ore["work_ticks"], seam["work_ticks"]] + "to be the slow one")
	if _worth(ore["yield"]) >= _worth(seam["yield"]):
		errors.append("a swing at ore is worth %d and at stone %d"
			% [_worth(ore["yield"]), _worth(seam["yield"])])
	if int(ore["regrow_ticks"]) <= int(seam["regrow_ticks"]):
		errors.append("ore comes back in %d ticks and stone in %d - iron is "
			% [ore["regrow_ticks"], seam["regrow_ticks"]] + "meant to be scarcer")

	# Every source of iron, and where it is standing.
	for id in sorted_names(nodes.keys()):
		var node: Dictionary = nodes[id]
		if not (node["yield"] as Dictionary).has(IRON):
			continue
		if id != &"ore":
			errors.append("'%s' gives iron as well as ore does" % id)
		for found in _cells_of_char(rows, _char_for(id)):
			var cell: Vector2i = found
			if not _in_a_cliff(rows, cell):
				errors.append("there is %s at %s with no rock face around it"
					% [id, cell])
	return errors


## Which map character puts this occupant down. Read off the legend rather than
## written twice.
static func _char_for(id: StringName) -> String:
	for ch in MAP_LEGEND:
		if StringName((MAP_LEGEND[ch] as Array)[1]) == id:
			return ch
	return ""


static func _cells_of_char(rows: Array, ch: String) -> Array:
	var out: Array = []
	if ch == "":
		return out
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == ch:
				out.append(Vector2i(x, y))
	return out


## Whether a cell has rock-face terrain orthogonally beside it. One lonely
## boulder is not a cliff, and iron is only meant to come out of a cliff.
static func _in_a_cliff(rows: Array, cell: Vector2i) -> bool:
	for step in NEIGHBOUR_STEPS:
		var at: Vector2i = cell + step
		if at.y < 0 or at.y >= rows.size():
			continue
		var row: String = rows[at.y]
		if at.x < 0 or at.x >= row.length():
			continue
		var entry: Variant = MAP_LEGEND.get(row[at.x], null)
		if entry != null and int((entry as Array)[0]) == 3:
			return true
	return false


## Every node on the map has somewhere to stand next to it.
##
## **The five stone seams failed this from the day the map was written.** They
## were drawn inside the rock-face block, walled in on all four sides by
## unwalkable cliff, and nothing noticed for thirty tasks - because the asserts
## fetched a seam by its id and asked what it offered, which it answered
## perfectly well from a cell no farmer could ever get to. A resource that is
## on the map and not in the game is the kind of bug that only a real walk
## finds, so the walk is now a check.
static func check_reachable(nodes: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	# **And the nodes with no row yet** (task 0156): each must be ready to
	# be stood beside the day its row arrives.
	var ids := sorted_names(nodes.keys())
	for waiting in UNGATHERED_NODES:
		if not ids.has(waiting):
			ids.append(waiting)
	for id in ids:
		var ch := _char_for(id)
		if ch == "":
			continue        # not something the map places
		var placed := _cells_of_char(rows, ch)
		if placed.is_empty():
			continue        # regrowth-only, or placed by something else
		for found in placed:
			var cell: Vector2i = found
			if not _has_room_beside(rows, cell):
				errors.append(("'%s' at %s is walled in - there is nowhere to "
					+ "stand and mine it") % [id, cell])
	return errors


## **The sides** (task 0157): a name for every region; a season's sides
## real regions, each season keeping the last one's; and regions 2-4 laid
## on 0156's cleared ground.
static func check_sides(spawns: Array, names: Array, by_season: Array) -> Array:
	var errors: Array = []
	if names.size() != spawns.size():
		errors.append("%d side names for %d spawn regions" % [names.size(), spawns.size()])
	if by_season.size() != SEASONS.size():
		errors.append("sides for %d seasons, and there are %d" % [by_season.size(), SEASONS.size()])
	var before: Array = []
	for season in by_season.size():
		var open: Array = by_season[season]
		if open.is_empty():
			errors.append("season %d opens no side at all" % season)
		for side in open:
			if int(side) < 0 or int(side) >= spawns.size():
				errors.append("season %d opens side %d, and there are %d"
					% [season, int(side), spawns.size()])
		for side in before:
			if not open.has(side):
				errors.append("season %d closes side %d, which the season before opened"
					% [season, int(side)])
		before = open
	var bands := {2: &"north", 3: &"west", 4: &"south"}
	for region in bands:
		if region < spawns.size() and SPAWN_BANDS.has(bands[region]) \
				and str(spawns[region]) != str(SPAWN_BANDS[bands[region]]):
			errors.append("spawn region %d is not 0156's %s band" % [region, bands[region]])
	return errors


## **Spawn ground** (task 0156): every band cell is on the map and is ground
## that can be walked and holds nothing - grass, soil, path or floor.
static func check_spawn_bands(bands: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	for side in sorted_names(bands.keys()):
		for pair in (bands[side] as Array):
			var cell := Vector2i(int(pair[0]), int(pair[1]))
			if not _clear_ground(rows, cell):
				errors.append("the %s spawn band's %s is not clear walkable ground"
					% [side, cell])
	return errors


## **The ponds** (task 0156): every anchor is water, and no two name the
## same body - checked by the anchors being apart, `Farm.pond_of` decides.
static func check_ponds(ponds: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	for id in sorted_names(ponds.keys()):
		var pair: Array = ponds[id]
		var cell := Vector2i(int(pair[0]), int(pair[1]))
		var entry: Variant = _legend_at(rows, cell)
		if entry == null or int((entry as Array)[0]) != 2:
			errors.append("the pond '%s' is anchored at %s, which is not water" % [id, cell])
	return errors


## **The sites** (task 0156): every cell of every site is clear walkable
## ground, so the coop, the barn and the bin have their room.
static func check_sites(sites: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	for id in sorted_names(sites.keys()):
		var box: Array = sites[id]
		for y in range(int(box[1]), int(box[1]) + int(box[3])):
			for x in range(int(box[0]), int(box[0]) + int(box[2])):
				if not _clear_ground(rows, Vector2i(x, y)):
					errors.append("the %s site's %s is not clear ground"
						% [id, Vector2i(x, y)])
	return errors


## A map cell's legend entry, or null off the map.
static func _legend_at(rows: Array, cell: Vector2i) -> Variant:
	if cell.y < 0 or cell.y >= rows.size():
		return null
	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return null
	return MAP_LEGEND.get(row[cell.x], null)


## Ground that can be walked and holds nothing: not water, not rock face,
## and no occupant.
static func _clear_ground(rows: Array, cell: Vector2i) -> bool:
	var entry: Variant = _legend_at(rows, cell)
	if entry == null:
		return false
	var pair: Array = entry
	return int(pair[0]) != 2 and int(pair[0]) != 3 and StringName(pair[1]) == &""


## Whether any orthogonal neighbour of a cell is ground a person can stand on.
static func _has_room_beside(rows: Array, cell: Vector2i) -> bool:
	for step in NEIGHBOUR_STEPS:
		var at: Vector2i = cell + step
		if at.y < 0 or at.y >= rows.size():
			continue
		var row: String = rows[at.y]
		if at.x < 0 or at.x >= row.length():
			continue
		var entry: Variant = MAP_LEGEND.get(row[at.x], null)
		if entry == null:
			continue
		var pair: Array = entry
		# Water and the rock face cannot be stood on, and neither can a cell
		# with something already on it.
		if int(pair[0]) == 2 or int(pair[0]) == 3:
			continue
		if StringName(pair[1]) != &"":
			continue
		return true
	return false


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
	for defence_id in sorted_names(defences.keys()):
		var defence: Dictionary = defences[defence_id]

		# **A tower that shoots says how it picks and how it lands.** The words
		# are checked against the lists above, so a typo is a red line at boot
		# rather than a tower that quietly falls back to the default and looks
		# like a balance problem.
		if defence.has("reload_ticks"):
			var aim := StringName(defence.get("targeting",
				TARGET_CLOSEST_TO_HOUSE))
			if not TARGETING.has(aim):
				errors.append("defence '%s' aims by '%s', which is not a way of "
					% [defence_id, aim] + "aiming")
			var shape := StringName(defence.get("shape", SHAPE_SINGLE))
			if not SHAPES.has(shape):
				errors.append("defence '%s' lands as '%s', which is not a shape"
					% [defence_id, shape])
			elif shape == SHAPE_SPLASH and int(defence.get("splash_tiles", 0)) <= 0:
				errors.append("defence '%s' splashes over no tiles at all"
					% defence_id)
			elif shape == SHAPE_LINE and int(defence.get("pierce", 0)) < 1:
				errors.append(("defence '%s' fires a line that goes through "
					+ "nobody, which is a single shot with extra words")
					% defence_id)
			elif shape == SHAPE_CONE:
				# **The angle a designer reads and the number the rules use have
				# to agree.** Two ways of saying one thing is two things that
				# drift, which is what `check_recipes()` exists for one table
				# along. The trigonometry is here, once, at boot - never in a
				# tick.
				var degrees := int(defence.get("cone_degrees", 0))
				var spread := int(defence.get("cone_spread_permille", 0))
				if degrees <= 0 or degrees >= 180:
					errors.append("defence '%s' has a cone of %d degrees"
						% [defence_id, degrees])
				else:
					var wanted := int(round(tan(deg_to_rad(float(degrees) / 2.0))
						* 1000.0))
					if absi(spread - wanted) > 2:
						errors.append(("defence '%s' opens %d degrees, which is "
							+ "%d per mille, but says %d")
							% [defence_id, degrees, wanted, spread])
			# `aim` is taken: task 0042 uses it for the targeting word.
			var travel := StringName(defence.get("aim", AIM_GUIDED))
			if not AIMS.has(travel):
				errors.append("defence '%s' fires '%s' shots, which is not a way "
					% [defence_id, travel] + "for a shot to travel")
			elif travel == AIM_BALLISTIC 					and int(defence.get("flight_ticks", 0)) <= 0:
				errors.append(("defence '%s' lobs a shell that arrives instantly, "
					+ "which is a bullet with extra words") % defence_id)

			# **A thing that looks like a tower has to be one.** The flamethrower
			# declared a range, a damage, a cone and a burn and had no
			# `reload_ticks`, so `Towers` never collected it and it had never
			# fired a shot in its life - found in task 0043, eighteen tasks after
			# it was written. Nothing said so because every check in here was
			# guarded on the field it was missing.
			var kind := StringName(defence.get("damage_type", DAMAGE_IMPACT))
			if not DAMAGE_TYPES.has(kind):
				errors.append("defence '%s' deals '%s', which is not a damage type"
					% [defence_id, kind])

		for res in (defence["cost"] as Dictionary):
			if not RESOURCES.has(res):
				errors.append("defence '%s' costs unknown '%s'"
					% [defence_id, res])
		# Outside the `reload_ticks` guard on purpose: this is the check for the
		# hole that guard left.
		if defence.has("damage") and defence.has("range") \
				and not defence.has("reload_ticks"):
			errors.append(("defence '%s' has a damage and a range and no way of "
				+ "firing - it looks exactly like a tower and is not one")
				% defence_id)

		# **A trap is not a tower and must never look like one.** It has no
		# range and no reload on purpose: `Towers` collects by `reload_ticks`
		# and a mine that had one would start aiming, drawing a line and
		# costing a targeting loop every tick for something that only ever
		# waits.
		if bool(defence.get("one_shot", false)):
			if defence.has("reload_ticks") or defence.has("range"):
				errors.append(("defence '%s' goes off once and also declares a "
					+ "range or a reload - a trap does not aim") % defence_id)
			if int(defence.get("damage", 0)) <= 0:
				errors.append("defence '%s' goes off and does nothing" % defence_id)

		if defence.has("ammo"):
			for res in (defence["ammo"] as Dictionary):
				if not RESOURCES.has(res):
					errors.append("defence '%s' fires unknown '%s'"
						% [defence_id, res])
		# **A round per so many ticks of firing needs rounds, and at least a
		# shot's worth of ticks** (task 0116): fewer than `reload_ticks`
		# would light a fresh round for every single shot, which is the
		# one-a-shot rule wearing a different number.
		if defence.has("ammo_every_ticks"):
			var every := int(defence["ammo_every_ticks"])
			if not defence.has("ammo"):
				errors.append(("defence '%s' spends a round every %d ticks and "
					+ "fires no rounds") % [defence_id, every])
			elif every < int(defence.get("reload_ticks", 0)):
				errors.append(("defence '%s' spends a round every %d ticks, "
					+ "sooner than it fires (every %d)")
					% [defence_id, every, int(defence["reload_ticks"])])
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
	# **The farmer starts on the porch** - the middle of the cell row below
	# the house - so moving the house on the map and not the start is a red
	# line rather than a farmer standing in a field on day one.
	var house := _cells_of_char(rows, _char_for(&"house"))
	if not house.is_empty():
		var low := Vector2i(GRID_WIDTH, GRID_HEIGHT)
		var high := Vector2i(-1, -1)
		for found in house:
			var cell: Vector2i = found
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
		var porch := Vector2i(low.x + (high.x - low.x + 1) / 2, high.y + 1)
		if porch != PLAYER_START:
			errors.append("the farmer starts at %s but the porch is %s"
				% [PLAYER_START, porch])
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


## The pond. Checked like the rest of the tables rather than trusted, because
## a bite window of zero ticks is a pond that can never be fished and nothing
## else in the game would say so.
static func check_fishing(table: Dictionary) -> Array:
	var errors: Array = []
	for key in [&"common_yield", &"rare_yield"]:
		var out: Dictionary = table[key]
		if out.is_empty():
			errors.append("fishing %s gives nothing at all" % key)
		for res in sorted_names(out.keys()):
			if not RESOURCES.has(res):
				errors.append("fishing %s yields unknown '%s'" % [key, res])
	if int(table["bite_min_ticks"]) > int(table["bite_max_ticks"]):
		errors.append("fishing bites sooner than it can - min %d, max %d"
			% [table["bite_min_ticks"], table["bite_max_ticks"]])
	if int(table["window_ticks"]) <= 0:
		errors.append("fishing gives no window to react in")
	if int(table["rare_in"]) < 1:
		errors.append("fishing rare_in must be at least 1")
	# The rare one has to be worth the wait, or it is not a rare one.
	var common := _worth(table["common_yield"])
	var rare := _worth(table["rare_yield"])
	if rare <= common:
		errors.append("the rare fish is worth %d and the common one %d"
			% [rare, common])
	return errors


## What a pile of resources sells for, against a given price list.
##
## **The price list is a parameter and it has to be.** It read `SELL_PRICE`
## directly at first, which made `check_chain`'s argument decorative - the
## teeth-test handed it a table where oil was worth a dollar, the check looked
## at the real one, and the test passed by agreeing with itself.
static func _worth(amounts: Dictionary, prices: Dictionary = SELL_PRICE) -> int:
	var total := 0
	for res in sorted_names(amounts.keys()):
		total += int(prices.get(res, 0)) * int(amounts[res])
	return total


## Every recipe is worth making.
##
## A recipe whose output sells for less than its inputs is a station the player
## should never walk to, and it is the easiest thing in the game to break by
## moving one price: before this existed, four corn worth $20 pressed into one
## oil worth $10, so the press destroyed half the value of everything put into
## it and the "sell it or keep it" tension the design wants was no tension at
## all - you kept it because selling it was strictly worse.
##
## Kits are skipped: their output is a structure, which has no sale price
## because it is not a resource. `check_recipes()` already holds them to the
## structure's build cost.
static func check_chain(recipes: Dictionary, prices: Dictionary) -> Array:
	var errors: Array = []
	for id in sorted_names(recipes.keys()):
		var recipe: Dictionary = recipes[id]
		var out: Dictionary = recipe["output"]
		var sellable := true
		for res in sorted_names(out.keys()):
			if not prices.has(res):
				sellable = false
				break
		if not sellable:
			continue
		var into := _worth(recipe["inputs"], prices)
		var made := _worth(out, prices)
		if made <= into:
			errors.append(("'%s' turns $%d of goods into $%d - nobody would "
				+ "ever walk to that station") % [id, into, made])
	return errors


## The animals, and the meat they are the only source of.
static func check_livestock(animals: Dictionary, rows: Array) -> Array:
	var errors: Array = []
	var makes_meat := false
	for id in sorted_names(animals.keys()):
		var animal: Dictionary = animals[id]
		for res in sorted_names((animal["produces"] as Dictionary).keys()):
			if not RESOURCES.has(res):
				errors.append("'%s' produces unknown '%s'" % [id, res])
			if res == MEAT:
				makes_meat = true
		if int(animal["every_ticks"]) <= 0:
			errors.append("'%s' produces in no time at all" % id)
		if int(animal["holds"]) <= 0:
			errors.append("'%s' holds nothing, so it can never be collected" % id)
		if _cells_of_char(rows, _char_for(id)).is_empty():
			errors.append("there is no '%s' anywhere on the farm" % id)

	# **Meat has to come from somewhere.** It is in the resource table, it has a
	# price, and a recipe turns it into the best meal in the game - and for the
	# first thirty-three tasks nothing in the world produced a single unit of
	# it.
	if not makes_meat:
		errors.append("nothing on the farm produces meat")
	for id in sorted_names(RECIPES.keys()):
		var inputs: Dictionary = (RECIPES[id] as Dictionary)["inputs"]
		if inputs.has(MEAT) and not makes_meat:
			errors.append("'%s' wants meat and nothing makes any" % id)
	return errors


## Every round a tower fires is a round the farm can make.
##
## The same bug as the meat of task 0034, one table along: a tower can declare
## it fires anything, and until this existed nothing asked whether the player
## had any way of producing it. A tower whose ammunition cannot be made is a
## tower that is permanently on its weak shot, and nothing in the game would
## say why.
static func check_ammo(defences: Dictionary, recipes: Dictionary) -> Array:
	var errors: Array = []
	var makeable: Dictionary = {}
	for id in sorted_names(recipes.keys()):
		for res in sorted_names(((recipes[id] as Dictionary)["output"]
				as Dictionary).keys()):
			makeable[res] = true

	for id in sorted_names(defences.keys()):
		var defence: Dictionary = defences[id]
		if not defence.has("ammo"):
			continue
		for res in sorted_names((defence["ammo"] as Dictionary).keys()):
			if not RESOURCES.has(res):
				errors.append("'%s' fires unknown '%s'" % [id, res])
			elif not makeable.has(res):
				errors.append(("'%s' fires '%s' and no recipe makes any - that "
					+ "tower can never fire a proper shot") % [id, res])
	return errors


## The inventory grouping. Nothing named twice, nothing named that is not a
## resource - a stray in no group is fine and lands in "other".
static func check_groups(grouped: Array, resources: Array) -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	for entry in grouped:
		var group: Dictionary = entry
		for id in (group["members"] as Array):
			if not resources.has(id):
				errors.append("group '%s' lists '%s', which is not a resource"
					% [group["name"], id])
			if seen.has(id):
				errors.append("'%s' is in two groups: '%s' and '%s'"
					% [id, seen[id], group["name"]])
			seen[id] = group["name"]
	return errors


## The stall. Everything it sells is a real resource with a real price, and
## buying one and selling it straight back is always a loss.
##
## **The second half is the one that matters.** `BUY_MARKUP` is a float and a
## rounding rule sits between it and the price, so "the markup is above one" is
## not the same claim as "you cannot make money going round in a circle" - and
## it is the circle that would break the game.
static func check_stall(stock: Dictionary, prices: Dictionary,
		markup: float) -> Array:
	var errors: Array = []
	for id in sorted_names(stock.keys()):
		if not RESOURCES.has(id):
			errors.append("the stall stocks '%s', which is not a resource" % id)
		elif not prices.has(id):
			errors.append("the stall stocks '%s', which has no price" % id)
		if int(stock[id]) <= 0:
			errors.append("the stall stocks no '%s' at all" % id)

	for id in sorted_names(prices.keys()):
		var sells_for := int(prices[id])
		var costs := int(ceil(float(sells_for) * markup))
		if costs <= sells_for:
			errors.append(("'%s' costs $%d and sells for $%d - buy it and sell "
				+ "it back and you are richer") % [id, costs, sells_for])
	return errors


## Day one's lines. Short, few, and each about something the game has.
static func check_tutorial(steps: Array) -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	if steps.size() > MAX_TUTORIAL_LINES:
		errors.append("day one has %d lines and may have %d"
			% [steps.size(), MAX_TUTORIAL_LINES])
	for entry in steps:
		var step: Dictionary = entry
		var id := StringName(step["id"])
		if seen.has(id):
			errors.append("tutorial step '%s' appears twice" % id)
		seen[id] = true
		# The key, not the words: how long the words are is
		# `tools/i18n_check.py`'s question now, in every language rather than
		# in one, and it measures them in the font rather than counting them.
		var line: String = String(step["line"])
		if line.strip_edges().is_empty():
			errors.append("tutorial step '%s' says nothing" % id)
		if line.length() > MAX_TUTORIAL_LINE_LENGTH:
			errors.append(("tutorial step '%s' is %d characters and may be %d - "
				+ "a line nobody reads at a glance is a line nobody reads")
				% [id, line.length(), MAX_TUTORIAL_LINE_LENGTH])
	return errors


## Every enemy needs the four numbers the night loop reads off it, and the one
## that ignores structures has to be worth ignoring them for.
##
## The second half is the design claim written down: a runner that was not
## faster than a walker would just be a walker that takes the long way round,
## and the tower line that stops it would be the same tower line.
static func check_enemies(enemies: Dictionary) -> Array:
	var errors: Array = []
	# **The fastest thing that does stop**, not the slowest. Measuring against
	# the slowest meant measuring against the giant at fifty ticks a tile,
	# which anything is faster than - the check passed a "runner" slower than
	# a walker and said nothing.
	var fastest := 1 << 30
	for id in sorted_names(enemies.keys()):
		var one: Dictionary = enemies[id]
		for field in ["hp", "ticks_per_tile", "damage", "reward"]:
			if int(one.get(field, 0)) <= 0:
				errors.append("enemy '%s' has no %s" % [id, field])
		if int(one.get("armour", 0)) < 0:
			errors.append("enemy '%s' has less than no armour" % id)
		# **No floats in the table.** `src/core/` is integer arithmetic and a
		# fraction in a lever is a float multiply waiting to happen in the
		# tick. Two of these went unread for fifty tasks precisely because
		# nothing could use them as written.
		for key in sorted_names(one.keys()):
			if typeof(one[key]) == TYPE_FLOAT:
				errors.append(("enemy '%s' declares '%s' as a fraction - the "
					+ "rules are integers, so it wants a percentage")
					% [id, key])
		var percent := int(one.get("structure_damage_percent", 100))
		if percent < 100:
			errors.append(("enemy '%s' does less to a structure than to the "
				+ "house, which is what the multiplier is for not to do")
				% id)
		if not bool(one.get("ignores_structures", false)):
			fastest = mini(fastest, int(one.get("ticks_per_tile", 1 << 30)))

	for id in sorted_names(enemies.keys()):
		var one: Dictionary = enemies[id]
		if not bool(one.get("ignores_structures", false)):
			continue
		if int(one.get("ticks_per_tile", 0)) >= fastest:
			errors.append(("enemy '%s' ignores structures without being "
				+ "faster than the ones that do not - it would be a slow "
				+ "zombie taking the long way round") % id)
	return errors


## Every night, checked at load. **An unknown enemy id fails loudly**, which
## is the requirement, and so does every other way a hand-written table can be
## wrong: no waves, a wave of nobody, a spawn point that is not on the map, a
## night with no pace.
static func check_nights(nights: Array) -> Array:
	var errors: Array = []
	for n in nights.size():
		var night: Variant = nights[n]
		if typeof(night) != TYPE_DICTIONARY:
			errors.append("night %d is not a record" % [n + 1])
			continue
		var one: Dictionary = night

		# `gap_ticks` is not in this list: a night that does not name one
		# takes `WAVE_GAP_TICKS`, which is what that lever is for.
		for field in ["waves", "note", "opening_ticks"]:
			if not one.has(field):
				errors.append("night %d has no '%s'" % [n + 1, field])
		if not one.has("waves"):
			continue
		if int(one.get("opening_ticks", -1)) < 0 \
				or int(one.get("gap_ticks", WAVE_GAP_TICKS)) < 0:
			errors.append("night %d waits less than no time" % [n + 1])

		var waves: Array = one["waves"]
		# **Nothing at all, only when it says so** (task 0154): the calm
		# night after a boss is the one record allowed an empty list.
		if waves.is_empty() and not bool(one.get("calm", false)):
			errors.append("night %d sends nothing at all" % [n + 1])
		for w in waves.size():
			var wave: Array = waves[w]
			if wave.size() < 3 or wave.size() > 4:
				errors.append(("night %d wave %d is not (enemy, count, "
					+ "spawn) with an optional delay") % [n + 1, w + 1])
				continue
			if not ENEMIES.has(wave[0]):
				errors.append("night %d sends unknown enemy '%s'"
					% [n + 1, wave[0]])
			if int(wave[1]) <= 0:
				errors.append("night %d has a wave of %d" % [n + 1, wave[1]])
			if int(wave[2]) < 0 or int(wave[2]) >= SPAWNS.size():
				errors.append("night %d wave %d comes from spawn %d, and "
					% [n + 1, w + 1, int(wave[2])]
					+ "there are %d" % SPAWNS.size())
			if wave.size() > 3 and int(wave[3]) < 0:
				errors.append("night %d wave %d waits less than no time"
					% [n + 1, w + 1])

	# **Every night comes only from the sides its season has open** (task
	# 0157), read off the record's index: the table is a year's, date n + 1.
	# Today's ten are allowed the south east in spring (`SPRING_DRAFT_SIDES`).
	for n in nights.size():
		if typeof(nights[n]) != TYPE_DICTIONARY or not (nights[n] as Dictionary).has("waves"):
			continue
		var date := n + 1
		var open := Calendar.open_sides(date)
		for wave in ((nights[n] as Dictionary)["waves"] as Array):
			if (wave as Array).size() < 3:
				continue
			var side := int((wave as Array)[2])
			var allowed: Array = SPRING_DRAFT_SIDES.get(side, [])
			if not open.has(side) and not allowed.has(date):
				errors.append("night %d comes from side %d, which its season has not opened"
					% [date, side])

	# **Every night is sent inside the night** (task 0137): its schedule ends
	# `DAWN_MARGIN_TICKS` before dawn, so the last wave has time to arrive.
	for n in nights.size():
		if typeof(nights[n]) != TYPE_DICTIONARY or not (nights[n] as Dictionary).has("waves"):
			continue
		var sent := Waves.schedule_ticks(nights[n])
		if sent + DAWN_MARGIN_TICKS > NIGHT_TICKS:
			errors.append(("night %d takes %d ticks to send, which leaves less "
				+ "than DAWN_MARGIN_TICKS before dawn at %d") % [n + 1, sent, NIGHT_TICKS])

	# **The endless curve may not invent an enemy**, which is task 0070's own
	# requirement, and may not name a boss: the Giant arrives on the schedule
	# in `ENDLESS.giant_every`, and one rolled out of the weighted mix would
	# turn up on night eleven.
	var mix: Dictionary = ENDLESS["mix"]
	if mix.is_empty():
		errors.append("the endless mix is empty, so night eleven sends "
			+ "nothing")
	for kind in sorted_names(mix.keys()):
		if not ENEMIES.has(kind):
			errors.append("the endless mix names '%s', which is not an enemy"
				% kind)
			continue
		if bool((ENEMIES[kind] as Dictionary).get("is_boss", false)):
			errors.append("the endless mix names '%s', which is a boss - "
				% kind + "bosses come from giant_every, not from the bag")
		var pair: Variant = mix[kind]
		if not (pair is Array) or (pair as Array).size() != 2:
			errors.append("the endless mix entry for '%s' is not "
				% kind + "[weight, drift]")
	for field in ["growth_percent", "waves", "extra_wave_every", "gap_ticks",
			"giant_every", "giant_extra_every", "mix_settles_after"]:
		if not ENDLESS.has(field):
			errors.append("the endless curve has no '%s'" % field)
		elif int(ENDLESS.get(field, 0)) < 0:
			errors.append("the endless curve's '%s' is negative" % field)
	for field in ["waves", "extra_wave_every", "giant_every",
			"giant_extra_every"]:
		if int(ENDLESS.get(field, 0)) < 1:
			errors.append("the endless curve's '%s' must be at least one, "
				% field + "or it divides by zero or sends nothing")

	# **At least one written night and no more than a year of them** (task
	# 0150): past the written ones the curve takes over, and a year has
	# `Calendar.year_days()`.
	if nights.is_empty() or nights.size() > Calendar.year_days():
		errors.append("%d nights are written, outside 1..%d"
			% [nights.size(), Calendar.year_days()])
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
		"time": [TICK_HZ, DAY_TICKS, DUSK_AT_TICK, NIGHT_TICKS, DAWN_MARGIN_TICKS,
			DAY_START_MINUTE, DAY_END_MINUTE, DUSK_MINUTE,
			PASS_OUT_PREPARATION_TICKS,
			MAX_CATCH_UP_TICKS],
		"calendar": [SEASONS, SEASON_DAYS, FULL_MOON_DAYS,
			FULL_MOON_HORDE_PERCENT, FULL_MOON_REWARD_PERCENT, SEASON_BOSSES],
		"calm": CALM_NIGHT_GIFT,
		"farm": [GRID_WIDTH, GRID_HEIGHT, TILE_SIZE, HOUSE_HP,
			PLAYER_SPEED],
		"house": [HOUSE_SIZE, SHOP_SIZE, HOUSE_ROOM, HOUSE_DOOR,
			HOUSE_SPAWN, HOUSE_FURNITURE],
		"map": FARM_MAP,
		# **The 1.0 farm's tables** (task 0156).
		"map_v1": [UNGATHERED_NODES, MAP_PROP_SIZES, SPAWN_BANDS, PONDS, MAP_SITES],
		# **The legend is half the map.** Which character is soil, water, a
		# rock or a vein of ore decides the farm as much as the characters
		# do; until task 0112 it could be redrawn with the guard quiet.
		"legend": MAP_LEGEND,
		"resources": RESOURCES,
		"sell_price": SELL_PRICE,
		"starting": STARTING_RESOURCES,
		"trade": [BUY_MARKUP, SELL_BACK_FRACTION],
		"stock": DAILY_STOCK,
		"tutorial": TUTORIAL,
		"crops": CROPS,
		"water": [WATER_CAN_CAPACITY],
		"power": [BASE_ENERGY, UNPOWERED_PERCENT],
		"livestock": LIVESTOCK,
		"ammo": [EMPTY_RELOAD_PERCENT, EMPTY_DAMAGE_PERCENT],
		"groups": RESOURCE_GROUPS,
		"gathering": GATHERING,
		"fishing": FISHING,
		"recipes": RECIPES,
		"queue": [QUEUE_LENGTH],
		"buildings": BUILDINGS,
		"defences": DEFENCES,
		"pathing": [TERRAIN_COST, WIDEST_STEP],
		"repair": [REPAIR_COST_PER_HP, REPAIR_TICKS_PER_HP,
			HOUSE_REPAIR_PERCENT, REPAIR_PERCENT],
		"ability": ABILITY,
		"hurt": [HURT_TICKS],
		"speeds": [SPEEDS, SKIP_MIN_HOUSE_PERCENT],
		"night_hud": [HOUSE_DANGER_PERCENT, WAVE_WARNING_TICKS],
		"enemies": ENEMIES,
		"nights": NIGHTS,
		"wave_gap": [WAVE_GAP_TICKS, SPAWN_INTERVAL_TICKS],
		# **The generated nights are balance too.** They are not in `NIGHTS`,
		# so without this line every lever of the endless curve could be
		# turned without the data guard noticing - which is the one thing the
		# guard exists to stop.
		"endless": ENDLESS,
		"spawns": SPAWNS,
		# **The sides, by season** (task 0157).
		"sides": [SPAWN_SIDES, SIDES_BY_SEASON, SPRING_DRAFT_SIDES],
		"rewards": REWARDS,
		"defeat": [DEFEAT_LOSS_PERCENT, DEFEAT_KEEPS_MONEY,
			DEFEAT_KEEPS_TECH, TRAMPLE_REACH],
		"tech": [TECH_BONUSES, TECH_TREE, TECH_REFUND_PERCENT],
		"levels": [TOWER_LEVELS, TOP_TOWER_LEVEL],
	})
