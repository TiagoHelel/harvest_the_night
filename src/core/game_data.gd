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
## Outdoor crops cannot earn a watered morning in these seasons (0171).
const NO_GROWTH_SEASONS: Array = [&"winter"]  # LEVER: season ids

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
## The Giant's spring, then the Harvester's summer (task 0253), the Scarecrow
## King's autumn (0254) and the Winter Lord's winter (0255) - whose fall on
## the year's last night is its ending (0160).
const SEASON_BOSSES: Array = [&"giant", &"harvester", &"scarecrow_king", &"winter_lord"]

## **Where a summoner's flock rises** (task 0254), round the cell it casts
## on, taken in this order and clipped to the map - never a draw from the
## RNG, so a cast lands the same on every machine. A ring two tiles out: west
## and east, north and south, then the corners.
const SUMMON_OFFSETS: Array = [
	Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2),
	Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2),
]

## **The calm night's gift** (task 0154): what is waiting on the porch the
## morning after the first night of a season, when the horde regroups after
## its boss and sends nothing. The only thing that night pays - nothing was
## defended, so no night money, materials or technology.
const CALM_NIGHT_GIFT: Dictionary = {WOOD: 20, STONE: 20, FOOD: 10}  # LEVER: units each, 0-60

## **The night's weather** (task 0256; `Weather`): what share of each
## season's nights are foggy and what share rain - percent, rolled once a
## night from the run's seed and the date, so the forecast knows it at dusk -
## and what each does. At most one a night, so a season's shares add up to at
## most 100; never on the first night of the game or a calm one.
##
## - **Fog**: a tower in the dark reaches `fog_reach_penalty` tiles less,
##   never under one; one on a lit cell (`Light.is_lit`) does not.
## - **Rain**: fire - a `DAMAGE_FIRE` hit and a burn's tick - deals
##   `rain_fire_percent` of itself, never under one, and the mud takes
##   `rain_mud_percent` off a walker's speed. A flyer is over it.
## - **Blood Moon** (task 0257): from autumn on and rare, never on a boss
##   night or a Full Moon (`Weather.event`). Every body that comes is an
##   elite with `blood_moon_hp_percent` of its hit points - a boss never -
##   and a won one pays `REWARDS.blood_moon_essence` on its own line.
##
## Spring and summer rain more than they fog; autumn and winter fog more,
## and winter's nights are cold and clear or foggy - the searchlight, winter's
## own, has the fog to answer. The Blood Moon is last in `Weather.EVENTS`, so
## the fog and the rain keep the nights they had before it rose.
const NIGHT_EVENTS: Dictionary = {
	&"fog": {
		"weights": {&"spring": 10, &"summer": 10, &"autumn": 20, &"winter": 20},  # LEVER: percent of a season's nights, 0-100
		"fog_reach_penalty": 1,         # LEVER: tiles off a tower in the dark, 1-2
	},
	&"rain": {
		"weights": {&"spring": 20, &"summer": 15, &"autumn": 15, &"winter": 0},  # LEVER: percent of a season's nights, 0-100
		"rain_fire_percent": 50,        # LEVER: percent of fire's damage in the rain, 25-90
		"rain_mud_percent": 20,         # LEVER: percent of a walker's speed the mud takes, 10-50
	},
	&"blood_moon": {
		"weights": {&"spring": 0, &"summer": 0, &"autumn": 5, &"winter": 5},  # LEVER: percent of a season's nights, 0 before autumn, 0-100
		"blood_moon_hp_percent": 150,   # LEVER: percent of an elite's hit points, 120-200
	},
}

## The range each night event's levers are held to (`check_night_events`).
const NIGHT_EVENT_LEVERS: Dictionary = {
	&"fog": {"fog_reach_penalty": [1, 2]},
	&"rain": {"rain_fire_percent": [25, 90], "rain_mud_percent": [10, 50]},
	&"blood_moon": {"blood_moon_hp_percent": [120, 200]},
}

## **The season a night event first falls in** (task 0257): before it, its
## share must be 0 (`check_night_events`) - the plan's Blood Moon, rare and
## only from autumn on.
const NIGHT_EVENT_FIRST_SEASON: Dictionary = {&"blood_moon": &"autumn"}

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
## **And no sooner than this before the margin** (task 0271, after 0148): a
## night's last send comes after `Waves.fill_line()`, so the night is still
## coming when the fill line passes. 0148 found every night sent by 36-84 s of
## its 240 and over, everything dead, a minute in - dawn had nothing to do.
const NIGHT_FILL_TICKS := 60 * SECONDS  # LEVER: ticks, 30-120 seconds worth


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

## **The house in three tiers** (task 0191; plan section 3.8): money buys a
## sturdier house, because the house is what keeps the sleeping farmer safe.
## Tier I is the house a new game has. Each tier's `hp_bonus` is added to
## `HOUSE_HP` (and 'stout timbers' on top), and its `repair_discount` is the
## percentage off every hit point of house mended, after 'a full larder'.
## Bought at the workshop, by day. `check_house_tiers` keeps the bonuses from
## falling from one tier to the next.
const HOUSE_TIERS: Array = [
	{"cost": {}, "hp_bonus": 0, "repair_discount": 0},
	{"cost": {MONEY: 500, WOOD: 80, STONE: 60},   # LEVER: money and materials
		"hp_bonus": 40,                          # LEVER: hit points, 20-80
		"repair_discount": 20},                  # LEVER: percent, 0-50
	{"cost": {MONEY: 1500, STONE: 120, IRON: 30}, # LEVER: money and materials
		"hp_bonus": 100,                         # LEVER: hit points, 50-200
		"repair_discount": 40},                  # LEVER: percent, 0-70
]

## How fast the player walks, in `Player.SUBTILE` units per tick.
##
## 64 units is a tile and there are 30 ticks a second, so 6 is 2.8 tiles a
## second - brisk enough to cross the farm without the day feeling like a
## commute, slow enough that the farm feels like a place rather than a menu.
const PLAYER_SPEED := 6                 # LEVER: subtile units per tick, 3-12


# ================================================================== resources

const WOOD := &"wood"
const HARDWOOD := &"hardwood"
const STONE := &"stone"
const IRON := &"iron"
const COPPER := &"copper"
const COAL := &"coal"
const GOLD := &"gold"
const FOOD := &"food"
## **Any fish** (task 0179): since the pond became three ponds and twelve
## species this is the fish group, not a resource. A cost or a recipe input
## may name it (`ANY_OF`), and it is paid from the species held, cheapest
## first.
const FISH := &"fish"
const CARP := &"carp"
const PERCH := &"perch"
const CATFISH := &"catfish"
const TILAPIA := &"tilapia"
const SUNFISH := &"sunfish"
const BREAM := &"bream"
const TROUT := &"trout"
const PIKE := &"pike"
const EEL := &"eel"
const DORADO := &"dorado"
const SALMON := &"salmon"
const STURGEON := &"sturgeon"
## **The legendaries** (task 0182; plan section 3.2): one a season, each
## with its own water, hours and condition, only on the iron rod and once a
## run. Ids as pack A022 names them.
const OLD_CATFISH := &"old_catfish"
const GOLDEN_QUEEN := &"golden_queen"
const GHOST_PIKE := &"ghost_pike"
const ICE_STURGEON := &"ice_sturgeon"
## **Bait** (task 0181): a worm the hoe turns up, and fish scraps cut at the
## workshop. Only the iron rod has the slot to use either.
const WORM := &"worm"
const BAIT := &"bait"
## **The animals' goods and their feed** (task 0184; plan section 3.4):
## straw off every wheat harvest, hay made from it, and what the coop and
## the barn give for being fed - eggs and milk.
const STRAW := &"straw"
const HAY := &"hay"
const EGG := &"egg"
const MILK := &"milk"
## **The barn's other two** (task 0185): wool off a fed sheep, and the
## truffles a fed pig noses up on the grass round its barn.
const WOOL := &"wool"
const TRUFFLE := &"truffle"
## **The artisan goods** (task 0187; plan section 3.5): what the keg and the
## preserves jar make of the farm's fruit and vegetables over days - wine and
## juice, jelly and pickles.
const WINE := &"wine"
const JUICE := &"juice"
const JELLY := &"jelly"
const PICKLES := &"pickles"
## **The dairy's, the loom's and the mill's** (task 0188; plan section 3.5):
## cheese and butter from milk, cloth from wool and sandbags from cloth, flour
## from wheat and sugar from beet.
const CHEESE := &"cheese"
const BUTTER := &"butter"
const CLOTH := &"cloth"
const SANDBAG := &"sandbag"
const FLOUR := &"flour"
const SUGAR := &"sugar"
## **The kitchen's bread** (task 0192; plan section 3.5, "the mill: flour,
## then bread"): baked from the mill's flour, and the best of what goes into
## the kitchen's supper.
const BREAD := &"bread"
const OIL := &"oil"
const WHEAT := &"wheat"
const CORN := &"corn"
const CARROT := &"carrot"
const POTATO := &"potato"
const GARLIC := &"garlic"
const STRAWBERRY := &"strawberry"
const PEPPER := &"pepper"
const SUNFLOWER := &"sunflower"
const MELON := &"melon"
const PUMPKIN := &"pumpkin"
const GRAPE := &"grape"
const BEET := &"beet"
const CARROT_SEED := &"carrot_seed"
const POTATO_SEED := &"potato_seed"
const GARLIC_SEED := &"garlic_seed"
const STRAWBERRY_SEED := &"strawberry_seed"
const CORN_SEED := &"corn_seed"
const PEPPER_SEED := &"pepper_seed"
const SUNFLOWER_SEED := &"sunflower_seed"
const MELON_SEED := &"melon_seed"
const WHEAT_SEED := &"wheat_seed"
const PUMPKIN_SEED := &"pumpkin_seed"
const GRAPE_SEED := &"grape_seed"
const BEET_SEED := &"beet_seed"
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
## **What the night leaves on the farm** (task 0221; plan sections 3.3
## and 4.6): the bones of whatever fell, and the morning after a Full Moon
## the moon stones along the road the horde came by. `Loot` lays them and
## the farmer's boots pick them up.
const BONES := &"bones"
## **Bones ground into the ground's own** (task 0222): bone meal, one more
## morning of growth for a plot. The night paying for the day.
const BONE_MEAL := &"bone_meal"
const MOON_STONE := &"moon_stone"
const MONEY := &"money"
const ENERGY := &"energy"

## Every resource the ledger knows about, in the order the reference sheet
## lays them out.
const RESOURCES: Array = [
	WOOD, HARDWOOD, STONE, IRON, COPPER, COAL, GOLD, FOOD, OIL,
	CARP, PERCH, CATFISH, TILAPIA, SUNFISH, BREAM, TROUT, PIKE, EEL, DORADO, SALMON, STURGEON,
	OLD_CATFISH, GOLDEN_QUEEN, GHOST_PIKE, ICE_STURGEON,
	WORM, BAIT, STRAW, HAY, EGG, MILK, WOOL, TRUFFLE,
	WINE, JUICE, JELLY, PICKLES, CHEESE, BUTTER, CLOTH, SANDBAG, FLOUR, SUGAR, BREAD,
	WHEAT, CORN, CARROT, POTATO, GARLIC, STRAWBERRY, PEPPER, SUNFLOWER, MELON, PUMPKIN, GRAPE, BEET, MEAT, GUNPOWDER, INCENDIARY, MONEY, ENERGY, TECH, BONES, BONE_MEAL, MOON_STONE,
	CARROT_SEED, POTATO_SEED, GARLIC_SEED, STRAWBERRY_SEED, CORN_SEED, PEPPER_SEED, SUNFLOWER_SEED, MELON_SEED, WHEAT_SEED, PUMPKIN_SEED, GRAPE_SEED, BEET_SEED,
]

## What the shop will buy, and for how much.
##
## `design.md` sets wood, stone, iron, wheat, fish and oil; the rest follow the
## same scale. Money is not here because money does not sell for money, and
## neither does energy, which is a rate rather than a stock (task 0033).
const SELL_PRICE: Dictionary = {        # LEVER: money each, 1-30
	# **A dollar since task 0194.** At two, felling trees all day was the
	# best money on the farm in every season - three wood a tree, a tree in
	# under four seconds - so it beat every other way of earning. Wood is for
	# building; selling it is the leftover.
	WOOD: 1,                         # LEVER: money each, 1-2
	# Hardwood only sells until the strong wall (task 0231) builds with it,
	# and sells low: a stump's two pieces are about half a tree's money per
	# second of swinging. Its worth is the wall's, not the stall's.
	HARDWOOD: 6,                     # LEVER: money each, 3-10
	STONE: 3,
	IRON: 7,
	COPPER: 5,                       # LEVER: money each, 1-8
	COAL: 3,                         # LEVER: money each, 1-4
	GOLD: 8,                         # LEVER: money each, 1-8
	FOOD: 12,
	# **The fish** (task 0179): what each species sells for, the rare ones
	# about three commons - and none above oil, which stays the dearest thing
	# in the ledger (0032). **Task 0194 raised all but the cheapest two**, so
	# a day at the pond earns its season's band (`Economy.fishing`). Carp and
	# tilapia stay at $7: fish bait (four at $2) and fish oil (three under a
	# drop's $26) are priced against the cheapest fish.
	CARP: 7,                         # LEVER: money each, 4-7, under four bait and a third of oil
	PERCH: 10,                       # LEVER: money each, 7-12
	CATFISH: 13,                     # LEVER: money each, 8-16
	TILAPIA: 7,                      # LEVER: money each, 4-7, under four bait and a third of oil
	SUNFISH: 11,                     # LEVER: money each, 7-12
	BREAM: 12,                       # LEVER: money each, 8-14
	TROUT: 17,                       # LEVER: money each, 12-20
	PIKE: 18,                        # LEVER: money each, 12-20
	EEL: 19,                         # LEVER: money each, 12-22
	DORADO: 22,                      # LEVER: money each, 18-25, under oil
	SALMON: 24,                      # LEVER: money each, 18-25, under oil
	STURGEON: 25,                    # LEVER: money each, 18-25, under oil
	# A legendary sells for no more than a sturgeon: oil stays the dearest
	# thing in the ledger (0032), and what one is worth is its page in the
	# book (task 0182).
	OLD_CATFISH: 25,                 # LEVER: money each, 18-25, under oil
	GOLDEN_QUEEN: 25,                # LEVER: money each, 18-25, under oil
	GHOST_PIKE: 25,                  # LEVER: money each, 18-25, under oil
	ICE_STURGEON: 25,                # LEVER: money each, 18-25, under oil
	# Bait sells for little: a fish cut into four is worth a little more than
	# the cheapest fish whole (`check_chain`), and a worm is a worm.
	WORM: 1,                         # LEVER: money each, 1-3
	BAIT: 2,                         # LEVER: money each, 2-4
	# **Straw is cheap and hay a little less so** (task 0184): pressed into
	# a bale at the workshop it is worth more than it was loose
	# (`check_chain`), and a day of an animal's keep is one of them.
	STRAW: 1,                        # LEVER: money each, 1-2
	HAY: 2,                          # LEVER: money each, 2-4
	# What a fed hen and a fed cow give. **Raised by task 0194**, so a day
	# of animals earns its season's band (`Economy.animals`): an egg still
	# under the meat a hen used to be, a pail of milk a little over it.
	EGG: 6,                          # LEVER: money each, 3-8
	MILK: 11,                        # LEVER: money each, 6-12
	# A fleece a day, and a truffle - the find of the barnyard, still under
	# oil (task 0185; both raised by 0194).
	WOOL: 14,                        # LEVER: money each, 6-16
	TRUFFLE: 24,                     # LEVER: money each, 12-25, under oil
	# **The artisan goods** (task 0187) are the only things on the farm worth
	# more than oil, and on purpose: plan section 3.5's road for the player
	# who wants to farm money, where a wine sells for far more than its
	# grapes. They take days in a machine, never a day's work, so oil is
	# still the dearest thing a day makes - 0032's assert, narrowed to that.
	WINE: 60,                        # LEVER: money each, 40-80
	JUICE: 45,                       # LEVER: money each, 30-60
	JELLY: 40,                       # LEVER: money each, 30-60
	PICKLES: 25,                     # LEVER: money each, 15-35
	# **The dairy's, the loom's and the mill's** (task 0188): each above what
	# it is made of (`check_chain`) and, made within a day, under oil - all
	# but the cheese, which ages two mornings. A sandbag is a material, its
	# night 0231's; flour is bread's (0192) and sugar the jelly's.
	CHEESE: 20,                      # LEVER: money each, 14-30
	BUTTER: 25,                      # LEVER: money each, 23-25, over two milk and under oil (0194)
	CLOTH: 18,                       # LEVER: money each, 15-25, over its wool (0194)
	SANDBAG: 8,                      # LEVER: money each, 5-12
	FLOUR: 7,                        # LEVER: money each, 5-10
	SUGAR: 5,                        # LEVER: money each, 4-8
	# A loaf is worth more than its sack of flour (`check_chain`), baked
	# within the day and under oil (task 0192).
	BREAD: 11,                       # LEVER: money each, 9-14
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
	POTATO: 8,                    # LEVER: money each, 1-30
	GARLIC: 5,                    # LEVER: money each, 1-30
	STRAWBERRY: 20,                    # LEVER: money each, 1-30
	PEPPER: 9,                    # LEVER: money each, 1-30
	SUNFLOWER: 10,                    # LEVER: money each, 1-30
	MELON: 25,                    # LEVER: money each, 1-30
	PUMPKIN: 26,                    # LEVER: money each, 1-30
	GRAPE: 22,                    # LEVER: money each, 1-30
	BEET: 11,                    # LEVER: money each, 1-30
	CARROT_SEED: 1,                 # LEVER: packet resale, 1-10
	POTATO_SEED: 1,                 # LEVER: packet resale, 1-10
	GARLIC_SEED: 1,                 # LEVER: packet resale, 1-10
	STRAWBERRY_SEED: 3,                 # LEVER: packet resale, 1-10
	CORN_SEED: 1,                 # LEVER: packet resale, 1-10
	PEPPER_SEED: 2,                 # LEVER: packet resale, 1-10
	SUNFLOWER_SEED: 2,                 # LEVER: packet resale, 1-10
	MELON_SEED: 4,                 # LEVER: packet resale, 1-10
	WHEAT_SEED: 1,                 # LEVER: packet resale, 1-10
	PUMPKIN_SEED: 4,                 # LEVER: packet resale, 1-10
	GRAPE_SEED: 3,                 # LEVER: packet resale, 1-10
	BEET_SEED: 2,                 # LEVER: packet resale, 1-10
	MEAT: 9,
	# Above the oil it is made from, per craft: two corn and a drop of oil is
	# $36 in and $44 out. `check_chain()` is what keeps that true.
	GUNPOWDER: 22,
	# A drop of oil and two logs make four rounds: $30 of goods into $36 of
	# ammunition. A thin margin on purpose - rounds are for burning, not for
	# selling, and `check_chain()` still wants the kitchen to beat the stall.
	INCENDIARY: 9,
	# **The night's leftovers** (task 0221). A bone is a dollar, so a night's
	# bodies are pocket money beside its purse, and 0222 grinds them into
	# something worth more. A moon stone sells for a good hour of a day, or
	# trades for essence at the tree (`Tech.trade_moon_stones`).
	BONES: 1,                        # LEVER: money each, 1-3
	MOON_STONE: 20,                  # LEVER: money each, 10-40
	# Above its two bones (`check_chain`), and well under the morning of
	# growth it buys a good crop. Its worth is the field's, not the stall's.
	BONE_MEAL: 4,                    # LEVER: money each, 3-8
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
	CARROT_SEED: 6,
	POTATO_SEED: 2,
	GARLIC_SEED: 2,
}


# ===================================================================== crops

## The twelve crops of the 1.0 plan, each with a different reason to plant it.
## Sowing seasons and watered regrowth mornings are rules (0170, 0172).
##
## ## Money, attention, capital - pick two
##
## The original offers per plot across a fourteen-day season, seed paid for:
##
##     carrot   3d   seed $2   net  4  x 4 harvests  = 16
##     wheat    4d   seed $2   net  6  x 3 harvests  = 18
##     corn     8d   seed $4   net 11  x 1 harvest   = 11
##
## Water every day to earn these harvests. Missing a watering delays the crop
## without destroying it. No crop wins on money, harvest visits and seed cost
## at once; `check_crops()` preserves that choice.
##
## The **seed costs** carry the balance. The original sale prices remain
## those of `design.md` section 6; the new 1.0 crops ask for more capital
## as their seasonal value rises. `check_crops()` compares crops sharing a sowing season.
##
## On top of the money each one feeds something the others do not: wheat is the
## money crop, corn is the industry crop - oil and gunpowder come out of it -
## and carrot is the food crop, which is what repairs a wall at three in the
## morning. Which is why corn stays worth planting even on the arithmetic
## above: the day you need gunpowder, corn is the only crop that makes any.
const CROPS: Dictionary = {
	WHEAT: {
		"seasons": [&"autumn"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 2,                 # LEVER: money, 1-8
		"growth_days": 4,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		# **The straw comes with it** (task 0184): what a harvest leaves
		# besides the grain, for the animals' hay.
		"byproduct": {STRAW: 3},        # LEVER: straw per harvest, 1-6
		"stages": 4,
	},
	CORN: {
		"seasons": [&"summer"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 4,                 # LEVER: money, 1-10
		"growth_days": 8,              # LEVER: watered mornings, 1-14
		"yield": 3,                     # LEVER: units per harvest, 2-5
		"regrow_days": 4,              # LEVER: watered mornings, 1-growth_days
		"stages": 4,
	},
	CARROT: {
		"seasons": [&"spring"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 2,                 # LEVER: money, 1-8
		"growth_days": 3,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,
	},
	POTATO: {
		"seasons": [&"spring"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 4,                 # LEVER: money, 1-16
		"growth_days": 5,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	GARLIC: {
		"seasons": [&"spring"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 3,                 # LEVER: money, 1-16
		"growth_days": 4,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	STRAWBERRY: {
		"seasons": [&"spring"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 8,                 # LEVER: money, 1-16
		"growth_days": 8,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"regrow_days": 4,              # LEVER: watered mornings, 1-growth_days
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	PEPPER: {
		"seasons": [&"summer"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 5,                 # LEVER: money, 1-16
		"growth_days": 5,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"regrow_days": 3,              # LEVER: watered mornings, 1-growth_days
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	SUNFLOWER: {
		"seasons": [&"summer"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 6,                 # LEVER: money, 1-16
		"growth_days": 7,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	MELON: {
		"seasons": [&"summer"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 10,                 # LEVER: money, 1-16
		"growth_days": 10,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	PUMPKIN: {
		"seasons": [&"autumn"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 11,                 # LEVER: money, 1-16
		"growth_days": 10,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	GRAPE: {
		"seasons": [&"autumn"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 9,                 # LEVER: money, 1-16
		"growth_days": 8,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"regrow_days": 3,              # LEVER: watered mornings, 1-growth_days
		"stages": 4,                    # LEVER: art stages, 4-4
	},
	BEET: {
		"seasons": [&"autumn"],        # LEVER: sowing seasons, spring-autumn
		"seed_cost": 7,                 # LEVER: money, 1-16
		"growth_days": 6,              # LEVER: watered mornings, 1-14
		"yield": 2,                     # LEVER: units per harvest, 1-4
		"stages": 4,                    # LEVER: art stages, 4-4
	},
}

## How many tiles one canful waters.
##
## The starter field is sixty plots, so watering it takes eight trips to the
## water. That is the chore: worth doing, never required, and the reason the
## well is somewhere you have to walk to.
const WATER_CAN_CAPACITY := 8           # LEVER: tiles per fill, 3-20

## Empty turned grass returns to lawn; original soil beds stay forever.
const TILLED_GRASS_FADES_DAYS := 3       # LEVER: idle empty grass plots, 1-7 mornings

## **What bone meal buys** (task 0222): the extra mornings a fertilised plot
## grows on the first morning it grows at all, and then the mark is spent.
const FERTILISED_EXTRA_DAYS := 1        # LEVER: mornings, 1-2


# ================================================================== gathering

## Trees, rocks and ore: how long a hit takes, what it gives, how long until it
## comes back. Nothing on the farm can be exhausted permanently.
const GATHERING: Dictionary = {
	&"tree": {
		"tool": &"axe", "min_tier": 0, # LEVER: required axe tier, 0-2
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
		"tool": &"pickaxe", "min_tier": 0, # LEVER: required pickaxe tier, 0-2
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
		"tool": &"pickaxe", "min_tier": 0, # LEVER: required pickaxe tier, 0-2
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
		"tool": &"pickaxe", "min_tier": 0, # LEVER: required pickaxe tier, 0-2
		"work_ticks": 3 * SECONDS,      # LEVER: ticks per swing, 20-150
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {IRON: 1},             # LEVER: units, 1-2
		"regrow_ticks": DAY_TICKS / 2,  # LEVER: ticks, half a day between harvests
	},
	# Scarcer quarry materials: slower work, lower sale yield and longer
	# regrowth than stone. Gold opens permanently on the first autumn.
	&"copper_ore": {
		"tool": &"pickaxe", "min_tier": 0, # LEVER: required tier, 0-2
		"work_ticks": 3 * SECONDS,      # LEVER: ticks per swing, 65-150
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {COPPER: 1},           # LEVER: units, 1-2
		"regrow_ticks": 6 * 60 * SECONDS, # LEVER: ticks, 5-8 minutes
	},
	&"coal_seam": {
		"tool": &"pickaxe", "min_tier": 0, # LEVER: required tier, 0-2
		"work_ticks": 3 * SECONDS,      # LEVER: ticks per swing, 65-150
		"hits": 3,                      # LEVER: swings, 2-5
		"yield": {COAL: 2},             # LEVER: units, 1-2
		"regrow_ticks": 5 * 60 * SECONDS, # LEVER: ticks, 4-8 minutes
	},
	&"gold_ore": {
		"tool": &"pickaxe", "min_tier": 1, # LEVER: iron pickaxe, 0-2
		"first_season": &"autumn",     # LEVER: permanent opening season
		"work_ticks": 4 * SECONDS,      # LEVER: ticks per swing, 90-180
		"hits": 4,                      # LEVER: swings, 3-6
		"yield": {GOLD: 1},             # LEVER: units, 1-2
		"regrow_ticks": 7 * 60 * SECONDS, # LEVER: ticks, 5-9 minutes
	},
	# **The big stumps** (task 0177): one thing over 2x2 cells in the
	# south-west woods, and the reason to buy an iron axe early. Twice a
	# tree's swings, each slower, for the strong wall's hardwood (0231); a
	# swing at any of its four cells strikes it, and it comes back whole the
	# next day - nothing on the farm is spent for good.
	&"hardwood_stump": {
		"tool": &"axe", "min_tier": 1,  # LEVER: iron axe, 0-2
		"work_ticks": 2 * SECONDS,      # LEVER: ticks per swing, 30-120
		"hits": 6,                      # LEVER: swings, 4-8 (a tree takes 3)
		"yield": {HARDWOOD: 2},         # LEVER: units, 1-3
		"regrow_ticks": DAY_TICKS,      # LEVER: ticks, a whole day
	},
}

## Fishing: how long the wait is and how long you have to react. The pond pays
## the most per action and costs attention rather than resources; what bites
## is `FISH_SPECIES`'s.
const FISHING: Dictionary = {
	"bite_min_ticks": DAY_TICKS / 120,  # LEVER: ticks, 1/120 day (4.67 seconds)
	"bite_max_ticks": DAY_TICKS / 24,   # LEVER: ticks, 1/24 day (23.33 seconds)
	# **The bar** (task 0180). When the float goes under, a marker sweeps a
	# bar of `bar_units` steps back and forth at the species' `speed`, and a
	# press while it is over the green counts. The species' `hits` of them
	# land it; more than `misses_allowed` presses outside lose it, and so
	# does the bar running out - which costs the fish and nothing else.
	"bar_units": 100,                   # LEVER: steps across the bar, 60-160
	"bar_ticks": 10 * SECONDS,          # LEVER: ticks the bar runs, 6-20 seconds
	"misses_allowed": 2,                # LEVER: presses outside the green that are forgiven, 0-4
	# The assist (a run flag, `state["fishing_assist"]`, written from the
	# `gameplay/fishing_assist` setting): a wider green, a slower marker.
	"assist_zone": 12,                  # LEVER: steps added to every green, 0-30
	"assist_speed_percent": 60,         # LEVER: the marker's speed under the assist, 40-100
}

## **The fish, by pond, season and hour** (task 0179; plan section 3.2). A
## cast draws one at the moment it goes in, among those its pond (0156's
## `PONDS`, by `Farm.pond_of`), the date's season and the clock's minute
## (`Phases.clock_minute`, `[from, to]` inclusive) allow, weighted by
## `weight` - so the pond asks where and when as well as whether. What one
## sells for is `SELL_PRICE`. Every pond has a catch in every season at
## every minute of the day (`check_fishing`), the legendaries apart: they
## bite only when their `condition` holds (task 0182).
## **Rarity** (task 0181): `tier` - common, uncommon or rare. A fibre or
## iron rod (`TOOLS` rod `rare_percent`) and fish bait (`BAIT_EFFECTS`)
## raise the draw weight of every species that is not common.
## A legendary (task 0182) is drawn only on a rod that takes one
## (`TOOLS` rod `legendary`), when its `condition` holds, and once a run.
const FISH_TIERS: Array = [&"common", &"uncommon", &"rare", &"legendary"]

## **What a legendary waits for** (task 0182): its `condition`, one of these - a
## Full Moon day (`FULL_MOON_DAYS`), or that bait on the hook (`BAITS`).
const FISH_CONDITIONS: Array = [&"full_moon", WORM, BAIT]

const FISH_SPECIES: Dictionary = {
	# The commons: carp in the two western waters all year and all day,
	# perch and the summer's tilapia keeping the south-east lake, the
	# catfish after dark everywhere.
	CARP: {"ponds": [&"north_west_pond", &"forest_pond"], # LEVER: where
		"seasons": [&"spring", &"summer", &"autumn", &"winter"], # LEVER: when
		"hours": [6 * 60, 26 * 60], "weight": 30,  # LEVER: clock minutes; draw weight
		"speed": 60, "zone": 26, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	PERCH: {"ponds": [&"north_west_pond", &"south_east_lake"], # LEVER: where
		"seasons": [&"spring", &"autumn", &"winter"], # LEVER: when
		"hours": [6 * 60, 26 * 60], "weight": 25,  # LEVER: clock minutes; draw weight
		"speed": 60, "zone": 26, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	TILAPIA: {"ponds": [&"forest_pond", &"south_east_lake"], # LEVER: where
		"seasons": [&"summer"],      # LEVER: when
		"hours": [6 * 60, 26 * 60], "weight": 25,  # LEVER: clock minutes; draw weight
		"speed": 60, "zone": 26, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	CATFISH: {"ponds": [&"north_west_pond", &"forest_pond", &"south_east_lake"], # LEVER: where
		"seasons": [&"spring", &"summer", &"autumn", &"winter"], # LEVER: when
		"hours": [18 * 60, 26 * 60], "weight": 18,  # LEVER: clock minutes; draw weight
		"speed": 66, "zone": 24, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	SUNFISH: {"ponds": [&"forest_pond"], # LEVER: where
		"seasons": [&"summer"],      # LEVER: when
		"hours": [6 * 60, 18 * 60], "weight": 15,  # LEVER: clock minutes; draw weight
		"speed": 60, "zone": 26, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	BREAM: {"ponds": [&"north_west_pond", &"south_east_lake"], # LEVER: where
		"seasons": [&"spring", &"summer"], # LEVER: when
		"hours": [6 * 60, 26 * 60], "weight": 12,  # LEVER: clock minutes; draw weight
		"speed": 66, "zone": 24, "hits": 1, "tier": &"common"}, # LEVER: bar steps a second, green steps, presses to land
	# The middling three: each one water, one or two seasons, part of the day.
	TROUT: {"ponds": [&"north_west_pond"], # LEVER: where
		"seasons": [&"spring", &"autumn"], # LEVER: when
		"hours": [6 * 60, 12 * 60], "weight": 10,  # LEVER: clock minutes; draw weight
		"speed": 84, "zone": 22, "hits": 2, "tier": &"uncommon"}, # LEVER: bar steps a second, green steps, presses to land
	PIKE: {"ponds": [&"north_west_pond", &"forest_pond"], # LEVER: where
		"seasons": [&"autumn", &"winter"], # LEVER: when
		"hours": [6 * 60, 26 * 60], "weight": 10,  # LEVER: clock minutes; draw weight
		"speed": 84, "zone": 22, "hits": 2, "tier": &"uncommon"}, # LEVER: bar steps a second, green steps, presses to land
	EEL: {"ponds": [&"forest_pond", &"south_east_lake"], # LEVER: where
		"seasons": [&"spring", &"summer"], # LEVER: when
		"hours": [20 * 60, 26 * 60], "weight": 8,  # LEVER: clock minutes; draw weight
		"speed": 90, "zone": 20, "hits": 2, "tier": &"uncommon"}, # LEVER: bar steps a second, green steps, presses to land
	# The rare three: one water, one season, a few hours.
	DORADO: {"ponds": [&"south_east_lake"], # LEVER: where
		"seasons": [&"summer"],      # LEVER: when
		"hours": [10 * 60, 16 * 60], "weight": 4,  # LEVER: clock minutes; draw weight
		"speed": 96, "zone": 18, "hits": 3, "tier": &"rare"}, # LEVER: bar steps a second, green steps, presses to land
	SALMON: {"ponds": [&"north_west_pond"], # LEVER: where
		"seasons": [&"autumn"],      # LEVER: when
		"hours": [6 * 60, 18 * 60], "weight": 3,  # LEVER: clock minutes; draw weight
		"speed": 96, "zone": 18, "hits": 3, "tier": &"rare"}, # LEVER: bar steps a second, green steps, presses to land
	STURGEON: {"ponds": [&"south_east_lake"], # LEVER: where
		"seasons": [&"winter"],      # LEVER: when
		"hours": [18 * 60, 26 * 60], "weight": 2,  # LEVER: clock minutes; draw weight
		"speed": 90, "zone": 18, "hits": 3, "tier": &"rare"}, # LEVER: bar steps a second, green steps, presses to land
	# **The legendaries** (task 0182): one a season, in one water, a few
	# hours, and a `condition` - a Full Moon day or a bait on the hook. The
	# hardest bar there is: three hits, the fastest marker, the narrowest
	# green (`check_fishing`).
	OLD_CATFISH: {"ponds": [&"forest_pond"], # LEVER: where
		"seasons": [&"spring"],      # LEVER: when
		"hours": [20 * 60, 26 * 60], "weight": 2, "condition": &"full_moon",  # LEVER: clock minutes; draw weight; condition
		"speed": 108, "zone": 14, "hits": 3, "tier": &"legendary"}, # LEVER: bar steps a second, green steps, presses to land
	GOLDEN_QUEEN: {"ponds": [&"south_east_lake"], # LEVER: where
		"seasons": [&"summer"],      # LEVER: when
		"hours": [11 * 60, 14 * 60], "weight": 2, "condition": WORM,  # LEVER: clock minutes; draw weight; condition
		"speed": 108, "zone": 14, "hits": 3, "tier": &"legendary"}, # LEVER: bar steps a second, green steps, presses to land
	GHOST_PIKE: {"ponds": [&"north_west_pond"], # LEVER: where
		"seasons": [&"autumn"],      # LEVER: when
		"hours": [22 * 60, 26 * 60], "weight": 2, "condition": BAIT,  # LEVER: clock minutes; draw weight; condition
		"speed": 108, "zone": 14, "hits": 3, "tier": &"legendary"}, # LEVER: bar steps a second, green steps, presses to land
	ICE_STURGEON: {"ponds": [&"south_east_lake"], # LEVER: where
		"seasons": [&"winter"],      # LEVER: when
		"hours": [6 * 60, 9 * 60], "weight": 2, "condition": &"full_moon",  # LEVER: clock minutes; draw weight; condition
		"speed": 108, "zone": 14, "hits": 3, "tier": &"legendary"}, # LEVER: bar steps a second, green steps, presses to land
}


## Transverse offsets, visited centre, left, right, then the outer pair.
const TOOL_AREA_OFFSETS := {
	1: [0], # LEVER: basic tool footprint, one cell
	3: [0, -1, 1], # LEVER: iron tool footprint, three cells
	5: [0, -1, 1, -2, 2], # LEVER: gold tool footprint, five cells
}

## Five permanent tools, each on one three-step ladder (0173).
## Effect fields are consumed by 0174/0175/0180/0181; gold costs arrive in 0176.
const TOOLS: Dictionary = {
	&"hoe": [
		{"name": &"basic", "cost": {}, "enabled": true, "area": 1, "capacity_bonus": 0}, # LEVER: money/ore and tier effects
		{"name": &"iron", "cost": {MONEY: 100, IRON: 5}, "enabled": true, "area": 3, "capacity_bonus": 0}, # LEVER: money/ore and tier effects
		{"name": &"gold", "cost": {MONEY: 300, GOLD: 5}, "enabled": true, "area": 5, "capacity_bonus": 0}, # LEVER: money/ore and tier effects
	],
	&"can": [
		{"name": &"basic", "cost": {}, "enabled": true, "area": 1, "capacity_bonus": 0}, # LEVER: money/ore and tier effects
		{"name": &"iron", "cost": {MONEY: 100, IRON: 5}, "enabled": true, "area": 3, "capacity_bonus": 4}, # LEVER: money/ore and tier effects
		{"name": &"gold", "cost": {MONEY: 300, GOLD: 5}, "enabled": true, "area": 5, "capacity_bonus": 8}, # LEVER: money/ore and tier effects
	],
	&"axe": [
		{"name": &"basic", "cost": {}, "enabled": true, "gather_percent": 100}, # LEVER: money/ore and tier effects
		{"name": &"iron", "cost": {MONEY: 150, IRON: 8}, "enabled": true, "gather_percent": 150}, # LEVER: money/ore and tier effects
		{"name": &"gold", "cost": {MONEY: 450, GOLD: 8}, "enabled": true, "gather_percent": 200}, # LEVER: money/ore and tier effects
	],
	&"pickaxe": [
		{"name": &"basic", "cost": {}, "enabled": true, "gather_percent": 100}, # LEVER: money/ore and tier effects
		{"name": &"iron", "cost": {MONEY: 150, IRON: 8}, "enabled": true, "gather_percent": 150}, # LEVER: money/ore and tier effects
		{"name": &"gold", "cost": {MONEY: 450, GOLD: 8}, "enabled": true, "gather_percent": 200}, # LEVER: money/ore and tier effects
	],
	&"rod": [
		{"name": &"bamboo", "cost": {}, "enabled": true, "bite_percent": 100, "rare_percent": 100, "zone_percent": 100, "bait_slot": false, "legendary": false}, # LEVER: money/ore and tier effects
		{"name": &"fibre", "cost": {MONEY: 120, IRON: 4}, "enabled": true, "bite_percent": 80, "rare_percent": 125, "zone_percent": 125, "bait_slot": false, "legendary": false}, # LEVER: money/ore and tier effects
		{"name": &"iron", "cost": {MONEY: 300, IRON: 12}, "enabled": true, "bite_percent": 65, "rare_percent": 150, "zone_percent": 150, "bait_slot": true, "legendary": true}, # LEVER: money/ore and tier effects
	],
}


# ==================================================================== recipes

## What turns into what, and how long it takes.
##
## The bridge the whole game rests on: everything here takes something the day
## produced and makes something the night needs.
const RECIPES: Dictionary = {
	&"upgrade_hoe_iron": {"station": &"workshop", "inputs": TOOLS[&"hoe"][1]["cost"],
		"output": {&"hoe_iron": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_hoe_gold": {"station": &"workshop", "inputs": TOOLS[&"hoe"][2]["cost"],
		"output": {&"hoe_gold": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_can_iron": {"station": &"workshop", "inputs": TOOLS[&"can"][1]["cost"],
		"output": {&"can_iron": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_can_gold": {"station": &"workshop", "inputs": TOOLS[&"can"][2]["cost"],
		"output": {&"can_gold": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_axe_iron": {"station": &"workshop", "inputs": TOOLS[&"axe"][1]["cost"],
		"output": {&"axe_iron": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_axe_gold": {"station": &"workshop", "inputs": TOOLS[&"axe"][2]["cost"],
		"output": {&"axe_gold": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_pickaxe_iron": {"station": &"workshop", "inputs": TOOLS[&"pickaxe"][1]["cost"],
		"output": {&"pickaxe_iron": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_pickaxe_gold": {"station": &"workshop", "inputs": TOOLS[&"pickaxe"][2]["cost"],
		"output": {&"pickaxe_gold": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_rod_fibre": {"station": &"workshop", "inputs": TOOLS[&"rod"][1]["cost"],
		"output": {&"rod_fibre": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
	&"upgrade_rod_iron": {"station": &"workshop", "inputs": TOOLS[&"rod"][2]["cost"],
		"output": {&"rod_iron": 1}, "ticks": TICK_HZ * 3}, # LEVER: workshop seconds, 1-10
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
	# **Sunflower seeds into oil** (task 0193; plan section 3.1): summer's
	# other oil crop, two heads a drop - the margin corn's four make.
	&"press_sunflower_oil": {
		"station": &"press",
		"inputs": {SUNFLOWER: 2},       # LEVER: sunflowers a drop, 1-2
		"output": {OIL: 1},
		"ticks": DAY_TICKS * 20 / 240,  # LEVER: fraction of a day
	},
	# **Rotten fish for the night** (task 0225): any fish, the cheapest first
	# (`ANY_OF`), pressed and left to turn. The press's, where fish already go
	# for oil - the kitchen's recipes are all food, each held to its margin
	# (0192). Its inputs are the bait's own cost, as every kit's are.
	&"zombie_bait_kit": {
		"station": &"press",
		"inputs": {FISH: 2},
		"output": {&"zombie_bait": 1},
		"ticks": DAY_TICKS * 6 / 240,   # LEVER: fraction of a day
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
	# **Gunpowder without corn** (task 0193): corn is summer's, and the mine,
	# the mortar and the towers' second level want gunpowder from the first
	# spring. Coal from the cliff's seams and the oil the press gets out of
	# fish (`press_fish_oil`) make it then.
	&"make_gunpowder_coal": {
		"station": &"workshop",
		"inputs": {COAL: 2, OIL: 1},    # LEVER: coal and oil a batch
		"output": {GUNPOWDER: 2},
		"ticks": DAY_TICKS * 15 / 240,  # LEVER: fraction of a day
	},
	# **Pepper rounds** (task 0193; plan section 3.1, pepper for "stronger
	# incendiary ammunition"): the same round, more of them a drop of oil -
	# six against the wood's four. A recipe, not a new kind of round.
	&"make_incendiary_pepper": {
		"station": &"workshop",
		"inputs": {OIL: 1, PEPPER: 1},  # LEVER: oil and peppers a batch
		"output": {INCENDIARY: 6},      # LEVER: rounds a batch, 5-8 - more than the wood's four
		"ticks": DAY_TICKS * 10 / 240,  # LEVER: fraction of a day
	},
	&"cook_meal": {
		"station": &"kitchen",
		"inputs": {CARROT: 2, WHEAT: 1},
		"output": {FOOD: 2},            # LEVER: food a batch, 1-3
		"ticks": DAY_TICKS * 12 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"cook_fish": {
		"station": &"kitchen",
		"inputs": {FISH: 1, CARROT: 1},
		"output": {FOOD: 3},            # LEVER: food a batch, 2-4
		"ticks": DAY_TICKS * 15 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	&"cook_roast": {
		"station": &"kitchen",
		"inputs": {MEAT: 1, CORN: 1},
		"output": {FOOD: 4},            # LEVER: food a batch, 3-5
		"ticks": DAY_TICKS * 18 / 240,  # LEVER: fraction of a day; preserves daily capacity
	},
	# **The new harvest in the pot** (task 0192): potatoes, eggs, milk and
	# the mill's flour. A stew is spring's meal without wheat - potato and
	# carrot, the crops a new farm is given seed for - so the house can be
	# mended from the first week; `cook_meal`'s wheat is autumn's. The
	# kitchen bakes flour into bread, and bread goes into supper: the better
	# the dish, the bigger the batch of food.
	&"cook_stew": {
		"station": &"kitchen",
		"inputs": {POTATO: 1, CARROT: 1},
		"output": {FOOD: 2},            # LEVER: food a batch, 1-3
		"ticks": DAY_TICKS * 12 / 240,  # LEVER: fraction of a day
	},
	&"cook_omelette": {
		"station": &"kitchen",
		"inputs": {EGG: 2, MILK: 1},    # LEVER: eggs and milk a batch
		"output": {FOOD: 3},            # LEVER: food a batch, 2-4
		"ticks": DAY_TICKS * 15 / 240,  # LEVER: fraction of a day
	},
	# **Not `bake_bread`.** A station's default recipe is the first by name
	# (`Crafting._default_selection`) and it is what SPACE there makes, so a
	# bread recipe named to sort first would have the kitchen ask a new farm
	# for flour. `cook_fish` stays the kitchen's default.
	&"make_bread": {
		"station": &"kitchen",
		"inputs": {FLOUR: 1},           # LEVER: flour a loaf, 1-2
		"output": {BREAD: 1},
		"ticks": DAY_TICKS * 8 / 240,   # LEVER: fraction of a day
	},
	&"cook_supper": {
		"station": &"kitchen",
		"inputs": {BREAD: 1, POTATO: 1, MILK: 1},
		"output": {FOOD: 6},            # LEVER: food a batch, 4-8 - the kitchen's biggest
		"ticks": DAY_TICKS * 24 / 240,  # LEVER: fraction of a day
	},
	# **Fish scraps into bait** (task 0181), at the workshop beside the other
	# supplies it makes - the kitchen's recipes are all food (task 0034): any
	# fish, the cheapest first (`ANY_OF`), into four.
	&"make_bait": {
		"station": &"workshop",
		"inputs": {FISH: 1},
		"output": {BAIT: 4},             # LEVER: bait a fish makes, 2-6
		"ticks": DAY_TICKS * 5 / 240,   # LEVER: fraction of a day
	},
	# **Straw into hay** (task 0184), at the workshop, which every farm has
	# from the first morning: the press's work is oil (0032) and the
	# kitchen's is food (0034). A bale is a day of one animal's keep.
	&"make_hay": {
		"station": &"workshop",
		"inputs": {STRAW: 1},
		"output": {HAY: 1},             # LEVER: hay a straw makes, 1-3
		"ticks": DAY_TICKS * 3 / 240,   # LEVER: fraction of a day
	},
	# **Days in a barrel** (task 0187; plan section 3.5): a recipe may take
	# `days` instead of `ticks`. Its batch is credited a day each morning,
	# from `Phases.begin_day`, never by the tick - so grapes put in today are
	# wine on the seventh morning, whatever the farmer does with the days
	# between. The keg ages grapes into wine and melons into juice; the
	# preserves jar sets strawberries into jelly and peppers into pickles:
	# a crop of every growing season, and winter lives off the barrels.
	&"make_wine": {
		"station": &"keg",
		"inputs": {GRAPE: 3},           # LEVER: grapes a batch, 1-5
		"output": {WINE: 3},
		"days": 7,                      # LEVER: mornings, 4-10
	},
	&"make_juice": {
		"station": &"keg",
		"inputs": {MELON: 3},           # LEVER: melons a batch, 1-5
		"output": {JUICE: 3},
		"days": 4,                      # LEVER: mornings, 2-7
	},
	# **Jelly takes sugar** (task 0188; plan section 3.1, "beet becomes sugar
	# for jellies"): the mill's beet sugar, or the stall's in a first spring
	# with no autumn behind it.
	&"make_jelly": {
		"station": &"preserves_jar",
		"inputs": {STRAWBERRY: 3, SUGAR: 1},  # LEVER: strawberries and sugar a batch
		"output": {JELLY: 3},
		"days": 3,                      # LEVER: mornings, 2-5
	},
	&"make_pickles": {
		"station": &"preserves_jar",
		"inputs": {PEPPER: 3},          # LEVER: peppers a batch, 1-5
		"output": {PICKLES: 3},
		"days": 3,                      # LEVER: mornings, 2-5
	},
	# **The dairy, the loom and the mill** (task 0188; plan section 3.5).
	# Butter is churned and cloth woven within the day, by the tick; cheese
	# is pressed and aged two mornings, the dairy's slow money. A sandbag is
	# a sack of cloth packed with stone - the filler a farm has by the
	# cartload - and the mill grinds wheat into flour and boils beet down to
	# three cubes of sugar a root.
	&"make_butter": {
		"station": &"dairy",
		"inputs": {MILK: 2},            # LEVER: milk a block, 1-3
		"output": {BUTTER: 1},
		"ticks": DAY_TICKS * 12 / 240,  # LEVER: fraction of a day
	},
	&"make_cheese": {
		"station": &"dairy",
		"inputs": {MILK: 3},            # LEVER: milk a batch, 1-5
		"output": {CHEESE: 3},
		"days": 2,                      # LEVER: mornings, 1-5
	},
	&"make_cloth": {
		"station": &"loom",
		"inputs": {WOOL: 1},            # LEVER: wool a bolt, 1-3
		"output": {CLOTH: 1},
		"ticks": DAY_TICKS * 20 / 240,  # LEVER: fraction of a day
	},
	&"make_sandbag": {
		"station": &"loom",
		"inputs": {CLOTH: 1, STONE: 4}, # LEVER: cloth and stone a batch
		"output": {SANDBAG: 4},         # LEVER: sandbags a cloth makes, 2-6
		"ticks": DAY_TICKS * 10 / 240,  # LEVER: fraction of a day
	},
	&"make_flour": {
		"station": &"mill",
		"inputs": {WHEAT: 1},           # LEVER: wheat a sack, 1-3
		"output": {FLOUR: 1},
		"ticks": DAY_TICKS * 6 / 240,   # LEVER: fraction of a day
	},
	&"make_sugar": {
		"station": &"mill",
		"inputs": {BEET: 1},
		"output": {SUGAR: 3},           # LEVER: sugar a beet makes, 2-4
		"ticks": DAY_TICKS * 10 / 240,  # LEVER: fraction of a day
	},
	# **Bones into bone meal** (task 0222), at the workshop the farm starts
	# with, so the first night's bones are the second morning's. Two a sack:
	# a spring night held well leaves about eleven (0221), a handful of
	# plots' worth and never the field.
	&"grind_bone_meal": {
		"station": &"workshop",
		"inputs": {BONES: 2},           # LEVER: bones a sack, 1-4
		"output": {BONE_MEAL: 1},
		"ticks": DAY_TICKS * 4 / 240,   # LEVER: fraction of a day
	},
}

## How many items a production building may have queued at once.
const QUEUE_LENGTH := 5                 # LEVER: items, 3-10

## **A day in a barrel has to pay** (task 0187): a recipe that takes days
## adds at least this much to its inputs' worth for every morning it holds
## its machine (`check_chain`), or nobody would leave fruit in a keg for a
## week.
const AGED_MARGIN_PER_DAY := 10         # LEVER: money a batch adds a morning, 5-20


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
		"fuel_fallback": {COAL: 1},     # LEVER: units per tank; oil first
		# A drop a minute, so a full day and night of running is five or six oil
		# against the twelve a press can make in a day. Expensive enough to be a
		# decision, cheap enough that the answer is sometimes yes.
		"fuel_every_ticks": DAY_TICKS / 4,  # LEVER: ticks, four oil per full day
		"size": Vector2i(4, 3),
	},
	# **Sprinklers** (task 0178): the chore, automated. Every morning, after
	# the growth credit, each one waters the plots of its pattern for the new
	# day - copper the four beside it, iron the 3x3 round it, gold the 5x5 -
	# and they dry at night like any plot. Built by day on one cell, out of
	# their own metal and money. **Walked over, never a wall** (`walked_over`):
	# a row of them must not fence the farm, so the flow field crosses one at
	# its ground's cost and nothing hunts it. The farmer walks round one, as
	# round anything built.
	&"copper_sprinkler": {
		"hp": 30,                       # LEVER: hit points, 15-60
		"cost": {MONEY: 50, COPPER: 3}, # LEVER: money and copper
		"energy_draw": 0,
		"size": Vector2i(1, 1),
		"walked_over": true,
		"spray": &"cross",              # LEVER: cross (the four beside) or square
		"spray_reach": 1,               # LEVER: cells out from it, 1-3
	},
	&"iron_sprinkler": {
		"hp": 40,                       # LEVER: hit points, 15-60
		"cost": {MONEY: 120, IRON: 6},  # LEVER: money and iron
		"energy_draw": 0,
		"size": Vector2i(1, 1),
		"walked_over": true,
		"spray": &"square",             # LEVER: cross or square (the 3x3)
		"spray_reach": 1,               # LEVER: cells out from it, 1-3
	},
	&"gold_sprinkler": {
		"hp": 50,                       # LEVER: hit points, 15-60
		"cost": {MONEY: 250, GOLD: 4},  # LEVER: money and gold
		"energy_draw": 0,
		"size": Vector2i(1, 1),
		"walked_over": true,
		"spray": &"square",             # LEVER: cross or square (the 5x5)
		"spray_reach": 2,               # LEVER: cells out from it, 1-3
	},
	# **The coop and the barn** (task 0183; plan section 3.4): the animals'
	# homes, built by day - on 0156's sites by the workshop, or anywhere
	# buildable. The first of each takes in the map's loose animals that live
	# there (`LIVESTOCK` `home`), and `capacity` is how many it holds. The
	# door is the middle of the front row, where they are collected from.
	&"coop": {
		"hp": 60,                       # LEVER: hit points, 40-160
		"cost": {WOOD: 30, STONE: 10, MONEY: 80},  # LEVER: wood, stone and money
		"energy_draw": 0,
		"size": Vector2i(3, 2),         # LEVER: cells, up to the 7x4 site
		"capacity": 4,                  # LEVER: chickens it holds, 2-8
		# **Wrecked, never lost** (task 0186): at 0 HP it stands, out of use,
		# its animals inside, until it is mended by day.
		"wrecks": true,
	},
	&"barn": {
		"hp": 100,                      # LEVER: hit points, 60-200
		"cost": {WOOD: 60, STONE: 25, MONEY: 200},  # LEVER: wood, stone and money
		"energy_draw": 0,
		"size": Vector2i(5, 4),         # LEVER: cells, up to the 7x4 site
		"capacity": 4,                  # LEVER: animals it holds, 2-8
		"wrecks": true,
	},
	# **The artisan machines** (task 0187; plan section 3.5), built by day:
	# the keg ages fruit into wine and juice, the preserves jar sets jelly
	# and pickles. Breakers hunt them like any building with no path cost.
	# **Wrecked, never lost**, as the coop and the barn are (0186): a keg
	# holds a week of grapes, and rubble would pour it out in one night. At
	# 0 HP it stands with its batch inside, aging nothing, until it is mended.
	&"keg": {
		"hp": 60,                       # LEVER: hit points, 30-120
		"cost": {WOOD: 30, IRON: 3, MONEY: 50},  # LEVER: wood, iron and money
		"energy_draw": 0,
		"size": Vector2i(2, 2),         # A031's footprint (task 0188)
		"wrecks": true,
	},
	&"preserves_jar": {
		"hp": 50,                       # LEVER: hit points, 30-120
		"cost": {STONE: 20, WOOD: 10, MONEY: 50},  # LEVER: stone, wood and money
		"energy_draw": 0,
		"size": Vector2i(2, 2),         # A031's footprint (task 0188)
		"wrecks": true,
	},
	# **The dairy, the loom and the mill** (task 0188), built by day like the
	# keg and the jar, and wrecked rather than lost at 0 HP (0187). The mill
	# is the tall one: sails over a stone base, three cells square, and the
	# wind turns it - none of them draws power.
	&"dairy": {
		"hp": 70,                       # LEVER: hit points, 30-120
		"cost": {WOOD: 40, STONE: 10, MONEY: 120},  # LEVER: wood, stone and money
		"energy_draw": 0,
		"size": Vector2i(3, 2),         # A031's footprint (task 0188)
		"wrecks": true,
	},
	&"loom": {
		"hp": 60,                       # LEVER: hit points, 30-120
		"cost": {WOOD: 50, IRON: 4, MONEY: 120},  # LEVER: wood, iron and money
		"energy_draw": 0,
		"size": Vector2i(3, 2),         # A031's footprint (task 0188)
		"wrecks": true,
	},
	&"mill": {
		"hp": 90,                       # LEVER: hit points, 40-160
		"cost": {WOOD: 60, STONE: 30, MONEY: 200},  # LEVER: wood, stone and money
		"energy_draw": 0,
		"size": Vector2i(3, 3),         # A031's footprint (task 0188)
		"wrecks": true,
	},
}

## **How often the hoe turns up a worm** (task 0181): one cell in this many,
## drawn from the run's RNG as each cell is turned.
const WORM_IN := 8                     # LEVER: cells turned per worm, 4-20

## **What a bait on the iron rod does** (task 0181), spent at the cast: a worm
## brings the bite sooner, fish bait brings the rarer fish. In percent of
## the wait and of the non-common species' draw weight. The order is the
## order the choice steps through, after none.
const BAITS: Array = [WORM, BAIT]
const BAIT_EFFECTS: Dictionary = {
	WORM: {"bite_percent": 60, "rare_percent": 100},   # LEVER: percents, 40-100 / 100-300
	BAIT: {"bite_percent": 100, "rare_percent": 200},  # LEVER: percents, 40-100 / 100-300
}

## The shapes a sprinkler's spray can take (task 0178).
const SPRAY_SHAPES: Array = [&"cross", &"square"]

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

## **A sting** (task 0226): it lands the instant it is given, as the cone
## does, and keeps hurting for `sting_ticks` - `Combat.sting()`, refreshed and
## never stacked, the way a fire is. Nothing flies. The hive's.
const SHAPE_STING := &"sting"

const SHAPES: Array = [SHAPE_SINGLE, SHAPE_SPLASH, SHAPE_CONE, SHAPE_LINE, SHAPE_STING]


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
## The hive's (task 0226): its own word, so a sting is never a fire to the
## rain of task 0256.
const DAMAGE_STING := &"sting"

const DAMAGE_TYPES: Array = [DAMAGE_IMPACT, DAMAGE_FIRE, DAMAGE_EXPLOSIVE, DAMAGE_STING]

## How often a burning thing takes its burn damage.
##
## Once a second rather than once a tick, so `burn_damage` in the tables reads
## as what a designer means by it - "two a second" - and so that a burn is a
## handful of arithmetic over its life instead of ninety.
const BURN_EVERY_TICKS := SECONDS

## How often a stung thing takes its sting (task 0226): once a second, as a
## burn does, so `damage` on the hive's row reads as "one a second".
const STING_EVERY_TICKS := SECONDS

## The six things from the reference sheet that go on the farm at night.
##
## `range` and `min_range` are in tiles. `reload_ticks` is the gap between
## shots. Task 0042 turns these entries into declarative behaviour so the combat
## code stops growing a branch per tower.
##
## **The arsenal grows with the seasons** (task 0234; the plan's sections 2, 5
## and 7). Each `season` is a rule, asked by `Building.why_not` through
## `Calendar.season_reached`, so Year 2 keeps them all:
## - spring: the gun tower, the crossbow, the mine and the three barriers;
## - summer: the flamethrower, the decoy, the hive, the bait and the sandbags;
## - autumn: the mortar, the catapult and the garlic;
## - winter: the searchlight and the electric fence.
##
## **Every defence costs money as well as materials**: a `MONEY` share in its
## `cost`. A kit is the materials paid early, so placing one still charges
## the money. The shares grow with the season a defence opens in, as the
## day's money does (0194):
## - spring's are small, so a new game's $25 still puts up the first gun
##   tower and a fence on night one, off a day at the rock face;
## - none reaches $100, so a price still fits its hotbar slot.
## `implementation/BALANCE.md` argues each one against the day.
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
		"cost": {WOOD: 10, IRON: 12, MONEY: 15},  # LEVER: wood, iron and $10-25
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
		"targeting": TARGET_CLOSEST_TO_HOUSE,
		"shape": SHAPE_SINGLE,
		"hp": 60,                       # LEVER: hit points, 30-120
		"damage": 6,                    # LEVER: per shot, 3-12
		"damage_type": DAMAGE_IMPACT,
		"range": 5,                     # LEVER: tiles, 3-8
		"reload_ticks": 1 * SECONDS,    # LEVER: ticks, 15-60
		# **Whether it reaches the air** (task 0249): a gun shoots up.
		"hits_flying": true,
		"projectile_tiles_per_second": 14,
		"energy_draw": 1,               # LEVER: energy per tick, 0-3
		"targets": 1,
	},
	&"flame_tower": {
		"cost": {WOOD: 20, IRON: 25, OIL: 10, MONEY: 90},  # LEVER: wood, iron, oil and $60-99
		# **Summer's** (task 0234): the oil and the rounds it burns are a
		# summer's work, and its fire is the first answer to the summer's rats.
		"season": &"summer",            # LEVER: the season it opens in (task 0234)
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
		# Fire along the ground: a crow over it is out of the cone (task 0249).
		"hits_flying": false,
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
		"cost": {STONE: 30, IRON: 35, GUNPOWDER: 15, MONEY: 95},  # LEVER: stone, iron, powder and $60-99
		# **Autumn's** (task 0234): a shell lobbed over the walls, for the
		# season the diggers come under them and the crows over.
		"season": &"autumn",            # LEVER: the season it opens in (task 0234)
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
		# A lobbed shell bursts on the ground (task 0249).
		"hits_flying": false,
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
		"cost": {WOOD: 15, IRON: 20, MONEY: 30},  # LEVER: wood, iron and $20-45
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
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
		# A bolt flies level and true: it takes a bird (task 0249).
		"hits_flying": true,
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
		"cost": {IRON: 5, GUNPOWDER: 8, MONEY: 8},  # LEVER: iron, powder and $4-15
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
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
		"cost": {WOOD: 5, MONEY: 2},    # LEVER: wood and $1-4
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
		"hp": 30,                       # LEVER: hit points, 15-60
		"path_cost": 6,                 # LEVER: tiles-equivalent detour, 3-12
		# **A digger goes under** (task 0250): posts and rails over open ground.
		"burrowable": true,
		"energy_draw": 0,
	},
	&"wall": {
		"cost": {STONE: 10, MONEY: 4},  # LEVER: stone and $2-8
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
		"hp": 120,                      # LEVER: hit points, 60-250
		"path_cost": 20,                # LEVER: tiles-equivalent detour, 10-40
		# **The real wall a digger cannot get under** (task 0250): footings in
		# the ground. Its hardwood level is the same wall.
		"burrowable": false,
		"energy_draw": 0,
	},
	&"barricade": {
		# **The cheapest thing in the game, and wood alone.** Three wood and
		# two stone came to $12 of goods against the fence's $10, so the
		# "cheapest structure" the task asks for was not - and stone is the
		# wrong currency for a thing you throw down while they are already
		# coming. Four wood is $4 (since 0194), and it is one trip to one tree.
		"cost": {WOOD: 4, MONEY: 1},    # LEVER: wood and $1-2
		"season": &"spring",            # LEVER: the season it opens in (task 0234)
		"hp": 20,                       # LEVER: hit points, 10-40
		"path_cost": 4,                 # LEVER: tiles-equivalent detour, 2-8
		# Thrown down on the ground: a digger goes under (task 0250).
		"burrowable": true,
		# **Cheap, temporary and limited** - its identity since every defence
		# goes down at night (task 0132). It expires, so it cannot quietly
		# become a cheaper wall: the clock starts with the waves, wherever in
		# the night it went down.
		"lifetime_ticks": 60 * SECONDS, # LEVER: ticks, 30-120 seconds worth
		"per_night_limit": 5,           # LEVER: how many, 2-10
		"energy_draw": 0,
	},
	&"decoy": {
		# **A straw figure that takes the blows** (task 0224; the plan's
		# summer defence, "chamariz: atrai os zumbis e aguenta pancada").
		# Straw from the wheat and the stall, and wood for its stake: $12 of
		# goods, three barricades' worth, for something that stands ten times
		# as long under the teeth.
		#
		# **No `path_cost`**: a wave flows round it like a tower, and a
		# breaker hunts it as prey. **No `reload_ticks` and no `damage`**:
		# nothing in `Towers` collects it and it makes no sound of its own.
		"cost": {STRAW: 8, WOOD: 4, MONEY: 8},  # LEVER: straw, wood and $5-15
		"season": &"summer",            # LEVER: the season it opens in (task 0234)
		# **Two hundred: it is there to be bitten.** Twenty walker bites, and
		# a crowd bites it four sides at once - the seconds it buys are the
		# seconds the towers get.
		"hp": 200,                      # LEVER: hit points, 100-250
		# **How far it pulls**: a lurable enemy whose walk to the nearest
		# decoy, by the lure field, is at most this many tiles leaves its
		# road and comes to bite the straw instead.
		"lure_tiles": 5,                # LEVER: tiles, 3-8
		"energy_draw": 0,
	},
	&"zombie_bait": {
		# **A rotten fish thrown down at night** (task 0225; the plan's 3.2,
		# "um peixe podre que atrai a horda para uma armadilha"). For a few
		# seconds everything that can be lured, from further off than a decoy
		# pulls, turns toward it - and stops on it to eat, wherever the
		# player laid the trap.
		#
		# **From a kit only** (`kit_only`): the press rots any fish into one
		# by day (`zombie_bait_kit`), and the night has no fish to spare. The
		# cost names the fish group, which a recipe pays from any species
		# (task 0179) and the ledger never holds - so there is no road from
		# the ledger at night, and nothing to refund in fish.
		"cost": {FISH: 2, MONEY: 2},    # LEVER: fish a bait 1-4, and $1-4
		"kit_only": true,
		"season": &"summer",            # LEVER: the season it opens in (task 0234)
		# One hit point, as a mine has: nothing bites a thing it walks over.
		"hp": 1,
		# **Walked over** (0178's flag, the sprinklers'): the ground's cost
		# to the field, so nothing breaks through it and nothing hunts it.
		"walked_over": true,
		# **Further than a decoy pulls**: the lure field seeds every lure at
		# how much less far it pulls than the widest (`Pathing._heads_of`).
		"lure_tiles": 10,               # LEVER: tiles, 6-14
		# **Eaten, then gone**: it lasts this long from the waves, or until
		# this many have reached it to eat, whichever comes first - and it
		# leaves nothing behind.
		"lifetime_ticks": 10 * SECONDS, # LEVER: ticks, 5-20 seconds worth
		"eaten_by": 8,                  # LEVER: zombies, 3-16
		"per_night_limit": 3,           # LEVER: how many, 1-6
		"energy_draw": 0,
	},
	&"beehive": {
		# **Bees that sting what comes near and keep stinging** (task 0226;
		# the plan's section 5, summer). Wood for the box and sunflowers for
		# the colony - and as strong as the field planted round it.
		"cost": {WOOD: 15, SUNFLOWER: 4, MONEY: 60},  # LEVER: wood, sunflowers and $40-80
		"season": &"summer",            # LEVER: the season it opens in (task 0234)
		"targeting": TARGET_NEAREST,
		# **A sting lands at once and keeps hurting** (`Combat.sting()`),
		# refreshed and never stacked, as a fire is. Nothing flies.
		"shape": SHAPE_STING,
		"hp": 60,                       # LEVER: hit points, 40-100
		# **Per second stung**, before the sunflowers: armour takes its slice
		# off every one, so a tank feels the minimum hit and no more.
		"damage": 1,                    # LEVER: per second stung, 1-3
		"damage_type": DAMAGE_STING,
		"range": 2,                     # LEVER: tiles, 1-3
		# A new sting a second, given to one not yet stung while there is one
		# in reach (`Towers.tick`): the bees spread over a crowd.
		"reload_ticks": SECONDS,        # LEVER: ticks, 15-60
		# Bees fly (task 0249).
		"hits_flying": true,
		"sting_ticks": 4 * SECONDS,     # LEVER: ticks, 2-8 seconds worth
		"targets": 1,
		# **As strong as the field round it**, worked out once a night at
		# `begin_night` (`Towers.feed_hives`): every sunflower growing within
		# `flower_reach` tiles counts, and each `flowers_per_sting` of them
		# add one to the sting, up to `most_flowers`. With too few growing -
		# autumn, winter - it eats up to `stock_flowers` from the store a
		# night instead, in whole stings' worth.
		"flower_reach": 3,              # LEVER: tiles, 2-4
		"flowers_per_sting": 3,         # LEVER: sunflowers a +1, 2-5
		"most_flowers": 9,              # LEVER: sunflowers that count, 3-15
		"stock_flowers": 6,             # LEVER: from the store, a hive a night, 1-12
		# Bees run on nothing the generator makes (`Towers.tick`).
		"energy_draw": 0,
	},
	&"catapult": {
		# **A pumpkin lobbed into the crowd** (task 0227; the plan's section 5,
		# autumn): timber, rope and the harvest - an autumn field become an
		# autumn defence. The id is never `pumpkin`, which is the crop.
		#
		# **Not a cheaper mortar.** It reaches little more than half as far
		# and hits softer, but it has no ground it cannot touch (no
		# `min_range`), it lobs at whatever comes nearest it, and it needs no
		# gunpowder, no iron and no power - only wood and what the field grew.
		"cost": {WOOD: 30, PUMPKIN: 4, MONEY: 40},  # LEVER: wood, pumpkins and $25-60
		"season": &"autumn",            # LEVER: the season it opens in (task 0234)
		"targeting": TARGET_NEAREST,
		"shape": SHAPE_SPLASH,
		"hp": 70,                       # LEVER: hit points, 40-110
		"damage": 30,                   # LEVER: at the centre, 15-45
		# A pumpkin is a blunt thing, however it bursts.
		"damage_type": DAMAGE_IMPACT,
		"range": 7,                     # LEVER: tiles, 5-9
		"splash_tiles": 2,              # LEVER: tiles, 1-3
		"splash_falloff_percent": 60,   # LEVER: percent at the edge, 30-90
		"reload_ticks": 4 * SECONDS,    # LEVER: ticks, 3-6 seconds worth
		# A lobbed pumpkin lands on the ground, as a shell does (task 0249).
		"hits_flying": false,
		# **Lobbed at a place**, as a mortar's shell is: it lands where it was
		# aimed, and a zombie can walk out from under it.
		"aim": AIM_BALLISTIC,
		"flight_ticks": 30,             # LEVER: ticks in the air, 20-45
		# **One pumpkin a throw**, from the store: an empty one throws stones,
		# the weak shot every tower has, never nothing (`Ammo`).
		"ammo": {PUMPKIN: 1},
		# One thing at a time until a level says otherwise.
		"targets": 1,
		# Timber and rope: the generator's shortage never slows it (`Towers.tick`).
		"energy_draw": 0,
	},
	&"garlic_braid": {
		# **A braid of garlic hung on a post** (task 0228; the plan's 3.1 and
		# 5, autumn): the ground round it is somewhere zombies would rather
		# walk round, and the ones that come through anyway walk slowly
		# (`Garlic`). The id is never `garlic`, which is the crop.
		"cost": {GARLIC: 4, WOOD: 2, MONEY: 8},  # LEVER: garlic, a little wood and $5-15
		"season": &"autumn",            # LEVER: the season it opens in (task 0234)
		# One hit point, as a bait has: it is walked over, and nothing bites
		# a thing it walks over.
		"hp": 1,
		# **Walked over** (0178's flag): the ground's cost on its own cell,
		# never prey, never broken through - the repelling is the area's.
		"walked_over": true,
		# **The area**: every cell within this many tiles, a square, costs
		# `repel_cost` more to enter - in the priced field and the open one,
		# never more than one braid's worth where two overlap - and is walked
		# at `repel_speed_percent` of a zombie's speed. `check_pathing` holds
		# the cost and the worst step to `WIDEST_STEP`.
		"repel_tiles": 2,               # LEVER: tiles round it, 1-3
		"repel_cost": 6,                # LEVER: tiles of detour a cell is worth, 2-10
		"repel_speed_percent": 60,      # LEVER: percent of speed inside, 30-90
		# **It wears out**: fresh the first night, at this share of both the
		# second, spent after.
		"wilted_percent": 50,           # LEVER: percent of its strength, 20-80
		"energy_draw": 0,
	},
	&"searchlight": {
		# **A powered lamp on a mast** (task 0229; the plan's section 5,
		# winter): the ground round it is lit (`Light`), and every tower
		# standing in light sees `LIGHT_REACH_BONUS` further - and light is
		# what the wraith and the fog will read. It does not shoot: no
		# `reload_ticks`, no `damage`. A breaker hunts it like anything built.
		"cost": {IRON: 12, COPPER: 8, MONEY: 80},  # LEVER: iron, copper and $50-99
		"season": &"winter",            # LEVER: the season it opens in (task 0234)
		"hp": 60,                       # LEVER: hit points, 40-100
		# **How far round it is lit**, a square as a tower's reach is.
		"light_tiles": 4,               # LEVER: tiles, 3-6
		# **Powered**: a farm short of it lights `LIGHT_SHORT_SHRINK` fewer
		# tiles, never none - degraded, never dead, as the rest of `Power`.
		"energy_draw": 2,               # LEVER: energy per tick, 1-3
	},
	&"electric_fence": {
		# **A fence that bites back** (task 0230; the plan's section 5,
		# winter): built as the wooden fence is - a barrier the field prices,
		# joined to its neighbours - except that whatever bites it is thrown
		# back stunned (`Enemies.stun()`), standing where it is, neither
		# walking nor biting. Copper for the wire and wood for the posts.
		"cost": {COPPER: 2, WOOD: 5, MONEY: 6},  # LEVER: copper, wood and $3-10
		"season": &"winter",            # LEVER: the season it opens in (task 0234)
		"hp": 40,                       # LEVER: hit points, 20-80
		"path_cost": 8,                 # LEVER: tiles-equivalent detour, 4-16
		# **A fence for all its wire** (task 0250): a digger goes under, and
		# what never bites it never shocks it.
		"burrowable": true,
		# **The shock**: the ticks a biter stands stunned, the bite landing
		# all the same. Not `damage`: it hurts nothing and shoots nothing, so
		# no tower sound (0283 gives it its zap).
		"stun_ticks": 2 * SECONDS,      # LEVER: ticks, 1-3 seconds worth
		# **A boss shrugs most of it off**: this share of the stun, never
		# less than a tick - and none at all at 0.
		"boss_stun_percent": 25,        # LEVER: percent of the stun, 0-100
		# **Powered**: a farm short of it stuns for `Power.percent()` of the
		# time, never none - degraded, never dead, as the rest of `Power`.
		"energy_draw": 1,               # LEVER: energy per tick, 1-2
	},
	&"sandbag_wall": {
		# **Sacks of the loom's sandbags stacked into a line** (task 0231; the
		# plan's 3.5, the loom's cloth made into sandbags). Cheap where the
		# wall is dear - two sacks are half a bolt of cloth and two stone,
		# where a wall is ten - and it soaks more than a fence: between the two
		# on hit points and on what the field asks to break through it.
		"cost": {SANDBAG: 2, MONEY: 3}, # LEVER: sandbags 1-4, and $2-6
		# **Summer's**, and task 0234 keeps it there: a flock in a barn and a
		# loom are a summer's work, not a first spring's.
		"season": &"summer",            # LEVER: the season it opens in (task 0234)
		"hp": 70,                       # LEVER: hit points, 40-100 (a fence 30, a wall 120)
		"path_cost": 12,                # LEVER: tiles-equivalent detour, 8-16 (a fence 6, a wall 20)
		# **No way under a heap of sand** (task 0250): the bags fill the
		# trench they would dig - the cheaper wall a digger stops at.
		"burrowable": false,
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
		# **Milk, since task 0184** (plan section 3.4), and only when fed.
		"produces": {MILK: 1},
		"every_ticks": DAY_TICKS / 3,   # LEVER: ticks, three production intervals/day
		"holds": 2,                     # LEVER: units before it stops, 1-5
		# Hay eaten each morning by a housed one (`ANIMAL_FEED`).
		"feed_per_day": 1,              # LEVER: hay a day, 0-3
		# **Where it lives and where it comes from** (task 0183): the
		# `BUILDINGS` home that houses it, and its source - the map, or the
		# stall (0190).
		"home": &"barn",
		"source": &"map",
	},
	&"chicken": {
		# **Eggs, since task 0184.**
		"produces": {EGG: 1},
		"every_ticks": DAY_TICKS * 5 / 24,  # LEVER: ticks, 4.8 production intervals/day
		"holds": 1,                     # LEVER: units before it stops, 1-4
		"feed_per_day": 1,              # LEVER: hay a day, 0-3
		"home": &"coop",
		"source": &"map",
	},
	# **Sheep and pigs** (task 0185; plan section 3.4) live in the barn and
	# come from the stall (0190). A fed sheep grows a fleece a day; a fed pig
	# gives nothing at the door - it marks `digs` spots on the grass round its
	# barn each morning, and the farmer digs the truffles up.
	&"sheep": {
		"produces": {WOOL: 1},
		"every_ticks": DAY_TICKS,       # LEVER: ticks, one fleece a day
		"holds": 1,                     # LEVER: units before it stops, 1-3
		"feed_per_day": 1,              # LEVER: hay a day, 0-3
		"home": &"barn",
		"source": &"stall",
	},
	&"pig": {
		"produces": {},
		"every_ticks": DAY_TICKS,
		"holds": 1,
		"feed_per_day": 1,              # LEVER: hay a day, 0-3
		"digs": 1,                      # LEVER: dig spots a fed pig marks a morning, 1-3
		"home": &"barn",
		"source": &"stall",
	},
}

## Where an animal kind comes from (task 0183): standing on `FARM_MAP`, or
## bought at the stall (0190).
const LIVESTOCK_SOURCES: Array = [&"map", &"stall"]

## **What a housed animal eats** (task 0184): `feed_per_day` of it each
## morning, or nothing comes off it that day. The map's loose animals graze.
const ANIMAL_FEED := HAY

## **Where a pig digs** (task 0185): open grass - no plot, no path, nothing
## standing on it or just south of it - up to this many cells out from its
## barn's walls, beside it or in front and never behind, chosen each morning
## from the run's RNG.
## The spots go with the sun.
const DIG_REACH := 4                    # LEVER: cells out from the barn, 2-8
## What the farmer turns up at a spot.
const DIG_GIVES: Dictionary = {TRUFFLE: 1}  # LEVER: truffles a spot, 1-2

## The plan's inventory categories, including categories filled by later tasks.
## Empty categories have no tab. Every shipped resource belongs to one category;
## GROUP_OTHER remains a diagnostic fallback for an invalid table, never content.
const GROUP_OTHER := &"other"

const RESOURCE_GROUPS: Array = [
	{"name": &"materials", "members": [WOOD, HARDWOOD, STONE, IRON, COPPER, COAL, GOLD, STRAW, HAY, SANDBAG]},
	{"name": &"crops", "members": [WHEAT, CORN, CARROT, POTATO, GARLIC, STRAWBERRY, PEPPER, SUNFLOWER, MELON, PUMPKIN, GRAPE, BEET]},
	{"name": &"seeds", "members": [CARROT_SEED, POTATO_SEED, GARLIC_SEED, STRAWBERRY_SEED, CORN_SEED, PEPPER_SEED, SUNFLOWER_SEED, MELON_SEED, WHEAT_SEED, PUMPKIN_SEED, GRAPE_SEED, BEET_SEED]},
	{"name": FISH, "members": [CARP, PERCH, CATFISH, TILAPIA, SUNFISH, BREAM, TROUT, PIKE, EEL, DORADO, SALMON, STURGEON,
		OLD_CATFISH, GOLDEN_QUEEN, GHOST_PIKE, ICE_STURGEON]},
	# Its own group, never the fish's: a recipe that takes any fish pays the
	# cheapest first, and a bait at $2 would be cheaper than any of them.
	{"name": &"bait", "members": [WORM, BAIT]},
	{"name": &"animal_goods", "members": [EGG, MILK, WOOL, TRUFFLE, MEAT]},
	{"name": &"artisan_goods", "members": [FOOD, OIL, WINE, JUICE, JELLY, PICKLES, CHEESE, BUTTER, CLOTH, FLOUR, SUGAR, BREAD]},
	{"name": &"ammunition", "members": [GUNPOWDER, INCENDIARY]},
	{"name": &"night_leftovers", "members": [BONES, BONE_MEAL, MOON_STONE]},
	{"name": &"farm", "members": [MONEY, ENERGY, TECH]},
]


## **Groups a cost may name instead of one resource** (task 0179): a recipe
## that takes `{FISH: 3}` takes three fish of any species. Paid from the
## members held in `pay_order` - the cheapest first, then by name - and
## valued at the cheapest member where a price is asked.
const ANY_OF: Array = [FISH]


## The members of one of `RESOURCE_GROUPS`, in table order; empty for none.
static func group_members(name: StringName) -> Array:
	for entry in RESOURCE_GROUPS:
		if StringName((entry as Dictionary)["name"]) == name:
			return (entry as Dictionary)["members"]
	return []


## Whether a cost may name this instead of a resource (`ANY_OF`).
static func is_any_of(id: StringName) -> bool:
	return ANY_OF.has(id)


## The members of an `ANY_OF` group in the order a cost takes them: cheapest
## first, then by name - fixed, so two runs pay with the same fish.
static func pay_order(group: StringName, prices: Dictionary = SELL_PRICE) -> Array:
	var members: Array = sorted_names(group_members(group))
	members.sort_custom(func(a, b) -> bool:
		var pa := int(prices.get(a, 0))
		var pb := int(prices.get(b, 0))
		return pa < pb or (pa == pb and str(a) < str(b)))
	return members


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
	# **Meat at the stall** (task 0184): the cow gives milk now and the hens
	# eggs, so the roast's meat is bought - `check_livestock` holds the farm
	# to having it from somewhere.
	MEAT: 6,
	# **Sugar at the stall** (task 0188): jelly takes it, and a first spring
	# has no autumn's beets behind it.
	SUGAR: 10,
}

## **This season's packets** (task 0190, moved here from 0170): the peddler
## carries the seeds that can be sown now, beside the materials above, and
## none in winter, when nothing grows outside. `check_season_stock` holds
## every packet to its crop's sowing seasons.
##
## **And feed until the farm grows its own** (task 0193): the animals eat
## hay from the first morning, and hay is pressed from straw, which comes off
## wheat - an autumn crop. So the peddler carries straw and hay in spring and
## summer, and `check_seasonal_supply` holds the shelf to it.
const SEASON_STOCK: Dictionary = {
	&"spring": {CARROT_SEED: 20, POTATO_SEED: 20, GARLIC_SEED: 20, STRAWBERRY_SEED: 20,  # LEVER: packets a day, 2-40
		STRAW: 10, HAY: 10},            # LEVER: feed a day, 0-20
	&"summer": {CORN_SEED: 20, PEPPER_SEED: 20, SUNFLOWER_SEED: 20, MELON_SEED: 20,  # LEVER: packets a day, 2-40
		STRAW: 10, HAY: 10},            # LEVER: feed a day, 0-20
	&"autumn": {WHEAT_SEED: 20, PUMPKIN_SEED: 20, GRAPE_SEED: 20, BEET_SEED: 20},  # LEVER: packets a day, 2-40
	&"winter": {},
}

## **Animals at the stall** (task 0190): what the peddler asks for each, and
## how many he brings a day. One bought goes into a coop or a barn of its
## kind with room (`Livestock.house`), or is not sold at all. Priced at some
## two weeks of what one gives; `check_stall` keeps each over whatever the
## stall would pay back for it.
const ANIMAL_PRICE: Dictionary = {
	&"chicken": 60,                  # LEVER: money, 30-120
	&"cow": 150,                     # LEVER: money, 80-300
	&"sheep": 150,                   # LEVER: money, 80-300
	&"pig": 220,                     # LEVER: money, 120-400
}
const ANIMAL_STOCK: Dictionary = {
	&"chicken": 4,                   # LEVER: a day, 1-8
	&"cow": 1,                       # LEVER: a day, 1-4
	&"sheep": 2,                     # LEVER: a day, 1-4
	&"pig": 2,                       # LEVER: a day, 1-4
}

## **The workshop's tool upgrades, from his pack too** (task 0190): each
## one on the stall's shelf this many times a day, at the workshop's price
## and through its rules (`ToolTiers`) - ready the next morning, as there.
const UPGRADE_STOCK := 1                # LEVER: of each upgrade a day, 1-3

## **The day's money, on purpose** (task 0194; plan section 5's rule of
## thumb): at the start of each season, a well-worked day should buy about
## one new defence. Each season's band is `[low, high]` money a day.
## `Economy` computes a day of each way of earning, and
## `_task_0194_economy` holds every one inside its season's band.
## Centred on a gun tower's materials at the stall in spring ($266: ten wood
## and twelve iron), and about a seventh more each season: the towers rise
## a level and the nights grow, so the defence a later day buys costs more.
const DAY_TARGETS: Dictionary = {
	&"spring": [180, 400],             # LEVER: money a well-worked day, low-high
	&"summer": [205, 460],             # LEVER: money a well-worked day, low-high
	&"autumn": [235, 530],             # LEVER: money a well-worked day, low-high
	&"winter": [270, 610],             # LEVER: money a well-worked day, low-high
}

## **The farm a well-worked day stands on** (task 0194): what a player who
## spent the season before on that way of earning has at the start of this
## one. A season with no entry for a strategy has no means for it, and the
## strategy is not one then: crops in winter, when nothing grows, and the
## animals and the machines at a new game's start.
const DAY_FARM: Dictionary = {
	# The tier every tool has reached: 0 the first, 1 iron (fibre for the
	# rod), 2 gold (iron for the rod).
	"tool_tier": {&"spring": 0, &"summer": 1, &"autumn": 1, &"winter": 2},  # LEVER: tool tier, 0-2
	# The plots a crops day tends: the starter beds, then turned grass.
	"plots": {&"spring": 60, &"summer": 80, &"autumn": 80},               # LEVER: plots, 20-200
	# The herd an animals day collects from: two coops of hens, and a barn
	# (two from autumn) of the rest.
	"herd": {
		&"summer": {&"chicken": 8, &"cow": 1, &"sheep": 2, &"pig": 1},   # LEVER: animals of each kind
		&"autumn": {&"chicken": 8, &"cow": 2, &"sheep": 3, &"pig": 3},   # LEVER: animals of each kind
		&"winter": {&"chicken": 8, &"cow": 2, &"sheep": 3, &"pig": 3},   # LEVER: animals of each kind
	},
	# The machines an artisan day keeps busy, by the recipe each runs.
	"machines": {
		&"summer": {&"make_jelly": 4, &"make_pickles": 1, &"make_juice": 1, &"make_cheese": 1},  # LEVER: machines
		&"autumn": {&"make_wine": 4, &"make_jelly": 4, &"make_pickles": 1, &"make_cheese": 1},   # LEVER: machines
		&"winter": {&"make_wine": 6, &"make_jelly": 4, &"make_pickles": 1, &"make_cheese": 1},   # LEVER: machines
	},
	# From a bite to the fish in hand: the bar, played well (the day sweep
	# measured under a second for a common).
	"landing_ticks": 1 * SECONDS,       # LEVER: ticks, 1-3 seconds
	# When the animals' day ends: bedtime, for collecting is a moment and
	# the hens lay into the evening.
	"animal_bed_minute": 25 * 60 + 30,  # LEVER: minutes, 20:00-01:59
	# Tiles walked to each node on the cliff, and from tree to tree.
	"walk_to_node": 8,                  # LEVER: tiles, 4-16
	"walk_to_tree": 2,                  # LEVER: tiles, 1-4
}

## **The peddler's hours** (task 0190; plan section 3.6): the stall trades
## from 08:00 to 17:00 on 0126's clock, in game minutes. `check_stall_hours`
## keeps them in order inside the day, and before dusk.
const STALL_OPENS := 8 * 60             # LEVER: minutes, 06:00-12:00
const STALL_CLOSES := 17 * 60           # LEVER: minutes, 13:00-dusk


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

## **The new day's tips** (task 0195). There is one each for what the first
## day does not teach: tilling grass, the seasons, the shipping bin, the
## fishing bar and the animals.
## - **When:** each shows once ever, at the moment it first matters, from the
##   second day on. The first day is `TUTORIAL`'s, still capped by
##   `MAX_TUTORIAL_LINES`.
## - **Who reads it:** this is data for the view. `Tips` (in `src/ui/`)
##   reads each trigger off the state and what was shown off the profile.
##   No rule reads this table.
const TIPS: Array = [
	{"id": &"till", "line": &"TIP_TILL"},
	{"id": &"season", "line": &"TIP_SEASON"},
	{"id": &"bin", "line": &"TIP_BIN"},
	{"id": &"bite", "line": &"TIP_BITE"},
	{"id": &"animal", "line": &"TIP_ANIMAL"},
]
## How long a tip stays up, in the screen's seconds. It stays while its
## moment lasts, but never less than the first number (a line that flickers
## past is a line spent) and never more than the second. It goes by itself.
const TIP_MIN_SECONDS := 2              # LEVER: seconds, 1-4
const TIP_SECONDS := 6                  # LEVER: seconds, 3-12


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

## **The guardian's other powers** (task 0233; the plan's 4.4), beside the
## flare's `ABILITY`: each with its own wait, each unlocked by a node of the
## survival branch a season from summer (`<id>_bonus` in its `gives`), each
## aimed with the guardian's cursor and asked for by id (`Ability`). Every
## night starts with them charged, as it does the flare.
const POWERS: Dictionary = {
	&"farm_bell": {
		# **The farm bell**: every zombie on the farm stops where it is - not
		# walking, not biting - for `stun_ticks`, on the count the electric
		# fence's shock writes (`Enemies.stun()`). It rings at the house,
		# wherever it is aimed.
		"stun_ticks": 2 * SECONDS,       # LEVER: ticks, 1-4 seconds worth
		# **A boss stops for half**: long enough to see, too short for two
		# bells to hold the season's boss through a wave.
		"boss_stun_percent": 50,         # LEVER: percent of the stop, 0-100
		"cooldown_ticks": 100 * SECONDS, # LEVER: ticks, 60-150 seconds worth
		"show_ticks": 1 * SECONDS,       # LEVER: ticks the ring shows, 10-60
	},
	&"call_dog": {
		# **The dog**: it runs from the porch to the aimed cell and bites the
		# zombie nearest it within `radius_tiles` - after a delay worked out
		# from how far it ran, `ticks_per_tile` a tile by Manhattan, no
		# chance in it - then runs back. Its run and its bite are the view's;
		# the rules know the delay and the bite.
		"damage": 40,                    # LEVER: per bite, 20-80
		"damage_type": DAMAGE_IMPACT,
		"radius_tiles": 3,               # LEVER: tiles round the aimed cell, 2-5
		"ticks_per_tile": 3,             # LEVER: ticks a tile it runs, 2-6
		"bite_ticks": 9,                 # LEVER: ticks it stays to bite, 3-20
		"cooldown_ticks": 40 * SECONDS,  # LEVER: ticks, 20-60 seconds worth
	},
	&"emergency_repair": {
		# **The emergency repair**: the aimed structure gets back this share of
		# its levelled hit points at once, free (`Repair.restore()`, the cap
		# mending goes through too). Not the house - mending the house is the
		# slow, dear thing on purpose - and never rubble.
		"restore_percent": 30,           # LEVER: percent of its levelled hit points, 15-50
		"cooldown_ticks": 60 * SECONDS,  # LEVER: ticks, 30-120 seconds worth
		"show_ticks": 1 * SECONDS,       # LEVER: ticks the mark shows, 10-60
	},
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
		# **Left where it falls** (task 0221), and on no other ending: one
		# that bites the house or walks off at dawn takes its own away.
		"bones": 1,                     # LEVER: bones, 0-6
		"armour": 0,
		# **A decoy turns it** (task 0224): within the decoy's `lure_tiles`
		# by the lure field it walks to the straw figure and bites that
		# instead of the house.
		"lurable": true,
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
		"bones": 1,                     # LEVER: bones, 0-6
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
		# A maze does nothing to it and a decoy does (task 0224): the straw
		# figure is the one thing that stops a runner short of the door.
		"lurable": true,
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
		"bones": 2,                     # LEVER: bones, 0-6
		# **Lured too** (task 0224): the slow brute is the one worth holding
		# still where the mortars land, and a straw figure is how.
		"lurable": true,
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
		"bones": 1,                     # LEVER: bones, 0-6
		"armour": 1,
		# **Not lured** (task 0224): it already goes for what you built by its
		# own hunt field, and a decoy - no `path_cost`, hit points - is among
		# what it hunts, nearest first. A pull on top would only make it
		# skip a nearer tower for the straw.
		"lurable": false,
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
		# A heap of its own, the most one cell holds.
		"bones": 9,                     # LEVER: bones, 6-9 (LOOT_PILE_CAP)
		"armour": 6,                    # LEVER: damage off each hit, 3-10
		"is_boss": true,
	},
	&"spitter": {
		# **The first that hurts what you built without touching it** (task
		# 0247): summer's ranged zombie. With a tower within `spit_range` it
		# stands off and spits at it (`Enemies`); with none it walks and
		# bites like a walker. A tower line in the open becomes something to
		# cover, not only something to build.
		#
		# A little frailer and slower than a walker: what it costs you is a
		# tower at range, not the roof.
		"hp": 30,                       # LEVER: hit points, 18-50
		"ticks_per_tile": 24,           # LEVER: ticks, 18-32 (lower is faster)
		"damage": 8,                    # LEVER: to the house, 4-12
		"reward": 6,                    # LEVER: money, 3-9
		"bones": 1,                     # LEVER: bones, 0-6
		"armour": 0,
		# **A tile short of the gun tower's reach**, so a tower can always
		# answer it: `check_enemies` refuses a spit range of nothing, or one
		# as long as the gun tower's base `range`. A flamethrower's three
		# cannot reach it at four; a gun tower's five can.
		"spit_range": 4,                # LEVER: tiles, 3-4 (under the gun tower's 5)
		"spit_damage": 10,              # LEVER: to a structure, a spit, 5-20
		"spit_every_ticks": 2 * SECONDS,   # LEVER: ticks, 1-4 seconds worth
		# The glob's flight, slow enough to watch cross the dark.
		"spit_tiles_per_second": 6,     # LEVER: tiles a second, 4-10
		# **Not lured** (task 0247): it stops for a tower in reach, not for
		# straw, and a decoy is not a tower.
		"lurable": false,
	},
	&"rat": {
		# **A crowd of small fast bodies** (task 0248): summer's swarm. A
		# single-target tower spends a whole shot on each, a mine's splash
		# and the flamethrower's cone take many at once.
		#
		# **It stops for walls**, and chews through them as a walker does: a
		# rat that went round them would make every wall on the farm useless
		# against a summer night, where a wall that funnels a swarm onto a mine
		# is the answer. Stopping, it has to be slower than the runner, which
		# `check_enemies` holds to going round faster than anything that stops.
		"hp": 4,                        # LEVER: hit points, 2-6
		"ticks_per_tile": 12,           # LEVER: ticks, 10-14 (lower is faster)
		"damage": 1,                    # LEVER: to the house, 1-2
		"reward": 1,                    # LEVER: money, 1-2
		# **Nothing worth the morning's walk.** One body in `BONES_EVERY`
		# leaves its bones, and a swarm's bones would out-earn its bounty.
		"bones": 0,                     # LEVER: bones, 0-1
		"armour": 0,
		# **How many come out at once** (task 0248): one wave release is a
		# cluster this big on adjacent cells (`Waves.tick`), so a wave of
		# twenty-four is four clusters of six. A wave still counts bodies.
		# `check_enemies` refuses less than one.
		"cluster": 6,                   # LEVER: rats a release, 4-10
		# Not turned by straw: a swarm pours.
		"lurable": false,
	},
	&"crow": {
		# **The first that does not walk** (task 0249): autumn's flyer. It
		# flies straight over walls and mines to the nearest plot with a crop
		# on it, lands, eats it and takes off for the next one (`Enemies`);
		# with nothing growing it flies at the house and bites. Only what
		# `hits_flying` reaches it in the air - landed, it is on the ground
		# like anything else.
		"flies": true,
		"hp": 8,                        # LEVER: hit points, 5-15
		# In flight: no wall slows it and no field routes it.
		"ticks_per_tile": 14,           # LEVER: ticks, 10-20 (lower is faster)
		"damage": 3,                    # LEVER: to the house, 2-6
		"reward": 3,                    # LEVER: money, 2-5
		# How long it stands on a plot before the crop is gone.
		"peck_ticks": 3 * SECONDS,      # LEVER: ticks, 1-6 seconds worth
		"bones": 0,                     # LEVER: bones, 0-1
		"armour": 0,
		"lurable": false,
	},
	&"digger": {
		# **The one that makes a fence a different thing from a wall** (task
		# 0250): autumn's tunneller. It walks the burrow field (`Pathing`),
		# where a `burrowable` barrier costs only the ground under it, and goes
		# under one rather than through - the barrier loses nothing and no
		# tower can see it while it is down there. A wall, the house and
		# everything else it gnaws and bites as a walker does.
		"burrows": true,
		"hp": 35,                       # LEVER: hit points, 20-60
		# Slower than the runner, so `check_enemies` holds: it stops for walls.
		"ticks_per_tile": 16,           # LEVER: ticks, 12-24 (lower is faster)
		"damage": 6,                    # LEVER: to the house, 4-10
		"reward": 5,                    # LEVER: money, 3-8
		"bones": 1,                     # LEVER: bones, 0-6
		"armour": 1,                    # LEVER: damage off each hit, 0-2
		# Not lured: it has a road of its own, under the fences.
		"lurable": false,
	},
	&"frost_zombie": {
		# **Its death is the attack** (task 0251): winter's first new enemy.
		# It walks and bites as a walker does; killed, it bursts into ice, and
		# every tower within `chill_tiles` of where it fell reloads slowly for
		# `chill_ticks` (`Combat._kill`, `Towers.chill_around`). Killing one
		# right under the tower line now costs something.
		#
		# One mortar shell at the centre puts it down (40, its armour off) -
		# the answer that reaches it far from the line.
		"hp": 35,                       # LEVER: hit points, 25-60
		# A stiff, frozen-jointed shamble: a little slower than the walker.
		"ticks_per_tile": 24,           # LEVER: ticks, 18-30 (lower is faster)
		"damage": 10,                   # LEVER: to the house, 6-16
		"reward": 6,                    # LEVER: money, 4-10
		"bones": 1,                     # LEVER: bones, 0-6
		"armour": 1,                    # LEVER: damage off each hit, 0-2
		# **The burst**: how far it reaches (Chebyshev, so a square round the
		# cell it fell on), how long a tower stays chilled, and how fast it
		# reloads meanwhile - fifty is twice as slow. `check_enemies` refuses
		# a burst of nothing and a speed outside 1-99.
		"chill_tiles": 2,               # LEVER: tiles, 1-3
		"chill_ticks": 5 * SECONDS,     # LEVER: ticks, 3-8 seconds worth
		"chill_reload_percent": 50,     # LEVER: percent of the reload speed, 25-75
		# A decoy turns it as it turns a walker - and one pulled away from
		# the guns before it dies is an answer to its burst.
		"lurable": true,
	},
	&"wraith": {
		# **Winter's answer to a defence that only shoots** (task 0252): in
		# the dark no tower can aim at it (`needs_light`). A searchlight's
		# square, the porch, a flare's burst or a fire under it (`Light`) make
		# it a target from the tick it stands in one, and a shot already in
		# the air still lands. What does not aim finds it anywhere: a shell's
		# splash, a mine, the cone and the bolt through the line, the flare,
		# the bell, and the dog, which goes by its nose.
		"needs_light": true,
		"hp": 30,                       # LEVER: hit points, 18-45
		# It drifts: a little quicker than the walker.
		"ticks_per_tile": 18,           # LEVER: ticks, 14-26 (lower is faster)
		"damage": 12,                   # LEVER: to the house, 8-16
		"reward": 7,                    # LEVER: money, 4-10
		# A shade leaves nothing to pick up in the morning.
		"bones": 0,                     # LEVER: bones, 0-1
		"armour": 0,
		# Straw does not fool what drifts in from the dark.
		"lurable": false,
	},
	&"harvester": {
		# **Summer's boss** (task 0253; the plan's Colheitadeira): an old
		# harvesting machine possessed by the rot. It rolls in slowly, and
		# every `charge_every_ticks` of rolling and gnawing it stops, winds up
		# on a line fixed then - the row or column towards the house along the
		# dominant axis, ties to the row - and charges down it at
		# `charge_ticks_per_tile`, ignoring the field (`Enemies`). Every
		# structure it enters takes `crush_damage`: it carries on through what
		# that brings down and stops at the first that holds, at ground
		# nothing crosses, after `charge_tiles`, or at the house with a bite.
		# Then it rolls and gnaws as before. One thick wall is a speed bump;
		# layers are a defence.
		#
		# **The wind-up is `telegraph_ticks`**, its one tell: the same rear
		# before a charge, a gnaw and the house, so a player learns one
		# rhythm for it.
		"is_boss": true,
		"hp": 1100,                     # LEVER: hit points, 700-1600
		# Slower than every one that walks (0246) - it rolls.
		"ticks_per_tile": 44,           # LEVER: ticks, 39-60
		"damage": 45,                   # LEVER: to the house, 30-60
		"structure_damage_percent": 300,   # LEVER: percent, 200-500
		"telegraph_ticks": 3 * SECONDS / 2,   # LEVER: ticks, 1-2 seconds worth
		"charge_every_ticks": 8 * SECONDS,    # LEVER: ticks of rolling, 5-12 seconds worth
		"charge_tiles": 6,              # LEVER: tiles, 4-10
		"charge_ticks_per_tile": 3,     # LEVER: ticks, 1-6 (lower is faster)
		# **A stone wall falls to it, the hardwood wall holds** (0231's level,
		# 240): one charge takes down every stone wall in its row and stops at
		# the first hardwood - which it leaves at 60.
		"crush_damage": 180,            # LEVER: to a structure, 121-239 (a stone wall 120, hardwood 240)
		"reward": 150,                  # LEVER: money, 80-250
		"bones": 9,                     # LEVER: bones, 6-9 (LOOT_PILE_CAP)
		# Armoured as a machine, more than anything that is not a boss.
		"armour": 6,                    # LEVER: damage off each hit, 5-10
		"lurable": false,
	},
	&"scarecrow_king": {
		# **Autumn's boss** (task 0254; the plan's Rei Espantalho): it calls the
		# sky down. It walks the field and bites as a walker does, and every
		# `summon_every_ticks` of walking it stops and casts - standing
		# `telegraph_ticks`, its one tell, before a blow and at the house too -
		# and a flock of `flock_size` crows rises round it on
		# `SUMMON_OFFSETS`, flying for the field (`Enemies`). No more than
		# `summon_cap` in a night, so a long fight cannot flood the farm. It
		# asks what the crow asked - cover in the air and care for the field
		# - under pressure.
		#
		# **Its flock is not the night's**: a summoned crow pays no bounty and
		# leaves no bones (`Combat._kill`) - a King left casting would be a
		# farm of them.
		"is_boss": true,
		"hp": 1200,                     # LEVER: hit points, 800-1600
		# Slower than every one that walks (0246): a lurch on stilts.
		"ticks_per_tile": 42,           # LEVER: ticks, 39-60
		"damage": 40,                   # LEVER: to the house, 25-60
		"telegraph_ticks": 2 * SECONDS, # LEVER: ticks, 1-3 seconds worth (the cast)
		"summons": &"crow",
		"summon_every_ticks": 10 * SECONDS,   # LEVER: ticks of walking, 6-15 seconds worth
		"flock_size": 6,                # LEVER: crows a cast, 3-8 (SUMMON_OFFSETS holds 8)
		"summon_cap": 18,               # LEVER: crows a night, at least a flock
		"reward": 140,                  # LEVER: money, 80-220
		"bones": 9,                     # LEVER: bones, 6-9 (LOOT_PILE_CAP)
		# More than anything that is not a boss.
		"armour": 5,                    # LEVER: damage off each hit, 5-10
		"lurable": false,
	},
	&"winter_lord": {
		# **The year's last boss** (task 0255; the plan's Senhor do Inverno):
		# a lord of ice. It walks the field and bites as a walker does, and
		# every `freeze_every_ticks` of walking it stops and casts - standing
		# `telegraph_ticks`, its one tell, before a blow and at the house too
		# - and every tower within `aura_tiles` of it when the cast lands
		# stops counting its reload for `freeze_ticks` (`Towers.freeze_around`,
		# beside 0251's chill). It tests the whole build - spread, depth,
		# light and the powers - and its fall on Winter 14 is the year's
		# ending (0160).
		"is_boss": true,
		# **The strongest boss in the table**: more than the Harvester's and
		# the King's.
		"hp": 1800,                     # LEVER: hit points, 1300-2400
		# Slower than every one that walks (0246).
		"ticks_per_tile": 48,           # LEVER: ticks, 39-60
		"damage": 50,                   # LEVER: to the house, 30-70
		"structure_damage_percent": 300,   # LEVER: percent, 200-500
		"telegraph_ticks": 2 * SECONDS, # LEVER: ticks, 1-3 seconds worth (the cast)
		"freeze_every_ticks": 12 * SECONDS,   # LEVER: ticks of walking, 8-20 seconds worth
		# A square, as a tower's reach is: the towers it freezes are the ones
		# a spread-out build keeps out of it.
		"aura_tiles": 3,                # LEVER: tiles, 2-5
		"freeze_ticks": 4 * SECONDS,    # LEVER: ticks, 2-8 seconds worth
		"reward": 250,                  # LEVER: money, 120-400
		"bones": 9,                     # LEVER: bones, 6-9 (LOOT_PILE_CAP)
		"armour": 7,                    # LEVER: damage off each hit, 5-10
		"lurable": false,
	},
}


# ====================================================================== nights

## The year's nights (task 0270, after `design.md` section 10's ten).
## **The house pace**: the gap of a night that does not set its own. Since
## task 0271 that is the tutorial night, Spring 1 - a minute between its
## three waves, so one tower meets them one at a time and the night is still
## coming at the fill line (`NIGHT_FILL_TICKS`). Every later night names a
## shorter one, and that tightening is the second difficulty curve described
## under `SEASON_NIGHTS`.
const WAVE_GAP_TICKS := 60 * SECONDS    # LEVER: ticks, 30-90 seconds worth

## How long between two members of the same wave.
##
## Eight zombies materialising on one tick is a magic trick; eight walking out
## of the dark in a line is a wave, and it gives the towers something to do
## while the player watches.
const SPAWN_INTERVAL_TICKS := 20        # LEVER: ticks, 8-45

## **A night is a record, not a bare list of rows** (task 0059), so the two
## numbers a designer most wants to turn - how long before the first wave, and
## how long between them - live on the night they belong to:
##
##     {"note": ..., "opening_ticks": ..., "gap_ticks": ..., "waves": [...]}
##
## and a wave is `[enemy, count, spawn]`, with an optional fourth entry that
## overrides the night's gap for that one wave. A night may set its own
## `interval_ticks` too, to be all out before dawn (0137), and a key night an
## `event` (below).
##
## ## The year is tables (task 0270)
##
## Not ten written nights and a curve: **a template per season** that every
## ordinary day is made from (`Almanac`), and **the key nights** a person
## writes - every kind's introduction and the Full Moons on the seventh and
## fourteenth day of every season. Nothing downstream of `Waves.night_of`
## can tell which is which. The calm first day of summer, autumn and winter
## (0154) carries neither: `night_of` answers it.
##
## **A template** says, for its season:
## - `sides`: `[side, the day it joins]`, each a side `SIDES_BY_SEASON` opens
##   that season, so a season brings a new one in gently;
## - `mix`: kind -> `[weight, the day it joins]`, the weight a share of the
##   night's hit points - never a boss, which is 0153's row;
## - `size`: the night's **hit points** on the season's second and thirteenth
##   day - the honest measure 0060 authored by, because three tanks are not
##   three walkers - and the line between them on the days between;
## - `waves` and `gap_ticks`, on the same two days. The gap is the least: a
##   made night whose waves would all be sent before the fill line spaces
##   them further (`Almanac`, task 0271), so it fills the night.
##
## A season's size never falls and its gap never grows (0060's curve rules);
## `check_nights` holds both.
##
## ## The key nights
##
## **One new thing a night, and the night after is where it bites** (0060).
## A season writes its introductions and its two Full Moons, and its template
## makes every other day. **Spring** (task 0271) keeps the plan's rhythm:
## days 1-6 grow gently - the walker on 1, the runner on 3, the tank on 5 -
## day 7 is a Full Moon of the three, days 8-13 grow again with the season's
## novelty, the breaker, met on 8, and day 14 is the Full Moon in the Giant's
## company, where 0153's rule brings him. All of it from the east, which is
## all spring opens (0157). **Summer** (task 0272) keeps the rhythm a side
## wider: its first fight on its second day from the east alone, the south
## east opened on its third by a handful, the spitter on its fifth, a Full
## Moon of what is known on its seventh, the rats on its eighth and the
## Harvester's company on its fourteenth. An introduction pins its weather
## off, so a first look is a clear one. Autumn and winter have only their
## Full Moons, drafts of the old seventh and tenth nights to their season's
## size, sending spring's kinds round every side their season opens:
## 0273-0274 write them for real.
##
## **Every night fills the night** (task 0271, after 0148): its last send
## comes between the fill line (`Waves.fill_line`) and the dawn margin, so the
## night is not over a minute in. A key night is written to it - long gaps,
## quiet stretches between its waves - and a made one is spaced to it.
##
## **A Full Moon's record is written at an ordinary night's size**, and
## `FULL_MOON_HORDE_PERCENT` scales it in `Waves.night_of` - in that one
## place, never written in as well - so the forecast's count is what is sent.
##
## **`event`**, optional on a key night, pins the night's weather (`&"fog"`)
## or forbids it (`&""`), read by `Weather.event` - and still held to
## `Weather`'s own rules: nothing on Spring 1 or a calm date, no Blood Moon
## before autumn, on a boss night or on a Full Moon.
##
## `python tools/nights.py` prints the year, and `python tools/play_nights.py`
## plays it with a scripted build - the instruments 0060 authored the ten
## with.
const SEASON_NIGHTS: Array = [
	# Spring (task 0271): the east alone, and its four kinds as they are
	# met - the runner on its third day, the tank on its fifth, the breaker on
	# its eighth, as its key nights introduce them. Long gaps, so its nights
	# fill; its line climbs past each key night but the Full Moons.
	{
		"sides": [[0, 1]],                      # LEVER: [side, the day of the season it joins]
		"mix": {&"walker": [30, 1], &"runner": [10, 3], &"tank": [25, 5], &"breaker": [35, 8]},  # LEVER: kind -> [weight in hit points, the day it joins]
		"size": [380, 2800],             # LEVER: hit points on its second and thirteenth day, 200-12000
		"waves": [4, 7],                    # LEVER: waves on its second and thirteenth day, 2-12
		"gap_ticks": [40 * SECONDS, 18 * SECONDS],  # LEVER: the least gap on its second and thirteenth day, 2-60 seconds
	},
	# Summer (task 0272): spring's four kinds at summer's share, the south
	# east from its third day - a key night that sends it a handful - the
	# spitter from its fifth and the rats from its eighth, as its key nights
	# introduce them. Its second day starts between spring's sixth and its
	# Full Moon, so the year still climbs.
	{
		"sides": [[0, 1], [1, 3]],              # LEVER: [side, the day of the season it joins]
		"mix": {&"walker": [26, 1], &"runner": [10, 1], &"tank": [22, 1], &"breaker": [22, 1],
			&"spitter": [12, 5], &"rat": [8, 8]},  # LEVER: kind -> [weight in hit points, the day it joins]
		"size": [1800, 5000],            # LEVER: hit points on its second and thirteenth day, 200-12000
		"waves": [5, 7],                    # LEVER: waves on its second and thirteenth day, 2-12
		"gap_ticks": [24 * SECONDS, 6 * SECONDS],  # LEVER: the least gap on its second and thirteenth day, 2-60 seconds
	},
	# Autumn: the north joins on its third day. Spring's kinds until 0273.
	{
		"sides": [[0, 1], [1, 1], [2, 3]],      # LEVER: [side, the day of the season it joins]
		"mix": {&"walker": [25, 1], &"runner": [10, 1], &"tank": [37, 1], &"breaker": [28, 1]},  # LEVER: kind -> [weight in hit points, the day it joins]
		"size": [3000, 6000],            # LEVER: hit points on its second and thirteenth day, 200-12000
		"waves": [6, 8],                    # LEVER: waves on its second and thirteenth day, 2-12
		"gap_ticks": [8 * SECONDS, 4 * SECONDS],  # LEVER: the gap on its second and thirteenth day, 2-30 seconds
	},
	# Winter: the west joins on its third day and the south on its fifth.
	# Spring's kinds until 0274.
	{
		"sides": [[0, 1], [1, 1], [2, 1], [3, 3], [4, 5]], # LEVER: [side, the day of the season it joins]
		"mix": {&"walker": [25, 1], &"runner": [10, 1], &"tank": [37, 1], &"breaker": [28, 1]},  # LEVER: kind -> [weight in hit points, the day it joins]
		"size": [4500, 8500],            # LEVER: hit points on its second and thirteenth day, 200-12000
		"waves": [7, 9],                    # LEVER: waves on its second and thirteenth day, 2-12
		"gap_ticks": [6 * SECONDS, 3 * SECONDS],  # LEVER: the gap on its second and thirteenth day, 2-30 seconds
	},
]

const KEY_NIGHTS: Dictionary = {
	# ---------------------------------------------------------------- spring
	# **The plan's rhythm** (task 0271): the walker on 1, the runner on 3, the
	# tank on 5, a Full Moon of the three on 7, the breaker on 8 and the
	# Giant's company on 14. Every other day of spring is its template's.
	1: {
		"note": "the tutorial night: one tower, one side, and time to watch",
		"opening_ticks": 0,
		# **No gap of its own**: the house pace, `WAVE_GAP_TICKS`, a minute
		# between its three waves - one tower meets them one at a time.
		"waves": [
			[&"walker", 3, 0],
			[&"walker", 4, 0],
			[&"walker", 5, 0],
		],
	},
	3: {
		"note": "the first runners: fast, fragile, and they ignore your walls",
		"opening_ticks": 0,
		"gap_ticks": 30 * SECONDS,
		# **Eight, and the night after is where they bite.** An introduction
		# that kills you is not an introduction: at ten runners the old third
		# night was the hardest of the first five (0060), and with a wave of
		# sixteen walkers this one fell at $150 a day in `tools/play_nights.py`
		# (0271). Spring 4 is made with a quarter of its hit points in runners.
		"waves": [
			[&"walker", 6, 0],
			[&"runner", 3, 0],
			[&"walker", 8, 0],
			[&"runner", 5, 0],
			[&"walker", 6, 0],
		],
	},
	5: {
		"note": "the first tank: one thing a crossbow line cannot chew through",
		"opening_ticks": 0,
		"gap_ticks": 30 * SECONDS,
		"waves": [
			[&"walker", 14, 0],
			[&"tank", 1, 0],
			[&"runner", 16, 0],
			[&"walker", 18, 0],
			[&"tank", 2, 0],
		],
	},
	7: {
		"note": "the first Full Moon: all three of them at once, and more of each",
		"opening_ticks": 0,
		"gap_ticks": 22 * SECONDS,
		"waves": [
			[&"walker", 14, 0],
			[&"runner", 10, 0],
			[&"tank", 2, 0],
			[&"walker", 16, 0],
			[&"runner", 12, 0],
			[&"tank", 3, 0],
		],
	},
	8: {
		"note": "the breakers arrive, and an uncovered tower line is a debt",
		"opening_ticks": 0,
		"gap_ticks": 22 * SECONDS,
		"waves": [
			[&"walker", 16, 0],
			[&"breaker", 3, 0],
			[&"runner", 18, 0],
			[&"tank", 4, 0],
			[&"walker", 18, 0],
			[&"breaker", 3, 0],
		],
	},
	14: {
		"note": "the Giant's company, so it cannot be focused down alone",
		"opening_ticks": 0,
		"gap_ticks": 12 * SECONDS,
		"waves": [
			[&"walker", 16, 0],
			[&"breaker", 6, 0],
			[&"runner", 26, 0],
			[&"tank", 8, 0],
			[&"walker", 20, 0],
			[&"breaker", 8, 0],
		],
	},
	# ---------------------------------------------------------------- summer
	# **Spring's rhythm, a side wider** (task 0272): the calm night on 15,
	# summer's first fight on 16 from the east alone, the south east opened
	# by a handful on 17, the spitter on 19, a Full Moon of what is known on
	# 21, the rats on 22 and the Harvester's company on 28. Every other day
	# is the template's, and side 1 is the south east.
	17: {
		"note": "the south-east opens: a handful from a new side, the rest the way they always came",
		"opening_ticks": 0,
		"gap_ticks": 12 * SECONDS,
		# **A first look is a clear one**: no fog or rain on an introduction
		# (0270's `event`, as 0273 says of a night weather would drown).
		"event": &"",
		# **Learned before it is tested**: six walkers, the plainest thing
		# summer has, are all the new side sends. Summer 4 is made from
		# both sides alike.
		"waves": [
			[&"walker", 14, 0],
			[&"runner", 12, 0],
			[&"breaker", 6, 0],
			[&"walker", 6, 1],
			[&"tank", 4, 0],
			[&"walker", 16, 0],
			[&"runner", 10, 0],
			[&"breaker", 6, 0],
		],
	},
	19: {
		"note": "the first spitters: they stop short of your towers and spit at them, not at your roof",
		"opening_ticks": 0,
		"gap_ticks": 10 * SECONDS,
		"event": &"",
		# Seven, from the side the towers already face. A tile short of the
		# gun tower's reach (0247), so a line that covers itself answers
		# them; summer's flamethrower cannot, which is the lesson.
		"waves": [
			[&"walker", 18, 0],
			[&"runner", 12, 1],
			[&"spitter", 3, 0],
			[&"tank", 4, 0],
			[&"breaker", 8, 1],
			[&"walker", 18, 1],
			[&"spitter", 4, 0],
			[&"runner", 14, 0],
			[&"tank", 2, 1],
			[&"breaker", 8, 0],
		],
	},
	21: {
		"note": "summer's Full Moon: both sides, and everything summer has shown you so far",
		"opening_ticks": 0,
		"gap_ticks": 12 * SECONDS,
		# **In crowds**: each wave out twice as close as an ordinary night's
		# and a longer quiet after it, so a Full Moon arrives as one.
		"interval_ticks": 10,
		"waves": [
			[&"walker", 22, 0],
			[&"spitter", 6, 1],
			[&"runner", 16, 1],
			[&"tank", 5, 0],
			[&"breaker", 10, 1],
			[&"walker", 20, 1],
			[&"spitter", 6, 0],
			[&"runner", 16, 0],
			[&"tank", 3, 1],
			[&"breaker", 8, 0],
		],
	},
	22: {
		"note": "the rats: too small to aim at and too many to count, and fire loves a crowd",
		"opening_ticks": 0,
		"gap_ticks": 8 * SECONDS,
		"event": &"",
		# Six clusters of six from the east. Summer 9 is made with a share
		# of its hit points in rats, so the night after brings more of them.
		"waves": [
			[&"walker", 24, 0],
			[&"rat", 18, 0],
			[&"breaker", 10, 1],
			[&"runner", 16, 1],
			[&"tank", 5, 0],
			[&"spitter", 8, 1],
			[&"walker", 24, 1],
			[&"rat", 18, 0],
			[&"tank", 3, 1],
			[&"breaker", 8, 0],
		],
	},
	28: {
		"note": "the Harvester's company: everything summer brought, so the machine is never the only target",
		"opening_ticks": 0,
		"gap_ticks": 7 * SECONDS,
		"interval_ticks": 10,
		"waves": [
			[&"walker", 28, 0],
			[&"rat", 36, 1],
			[&"breaker", 13, 0],
			[&"spitter", 9, 1],
			[&"runner", 22, 0],
			[&"tank", 7, 1],
			[&"walker", 26, 1],
			[&"rat", 36, 0],
			[&"spitter", 9, 0],
			[&"tank", 7, 0],
			[&"breaker", 13, 1],
		],
	},
	# ---------------------------------------------------------------- autumn
	35: {
		"note": "autumn 7, the Full Moon: a draft of spring's night 7 to this season's size, until 0273",
		"opening_ticks": 0,
		"gap_ticks": 9 * SECONDS,
		"waves": [
			[&"walker", 34, 0],
			[&"breaker", 11, 1],
			[&"runner", 45, 2],
			[&"tank", 11, 0],
			[&"walker", 40, 1],
			[&"breaker", 11, 2],
		],
	},
	42: {
		"note": "autumn 14, the boss's company: a draft of spring's night 10 to this season's size, until 0273",
		"opening_ticks": 0,
		"gap_ticks": 4 * SECONDS,
		"waves": [
			[&"walker", 37, 0],
			[&"breaker", 14, 1],
			[&"runner", 60, 2],
			[&"tank", 18, 0],
			[&"walker", 46, 1],
			[&"breaker", 18, 2],
		],
	},
	# ---------------------------------------------------------------- winter
	49: {
		"note": "winter 7, the Full Moon: a draft of spring's night 7 to this season's size, until 0274",
		"opening_ticks": 0,
		"gap_ticks": 9 * SECONDS,
		# Sent closer together so it is all out before dawn (0137).
		"interval_ticks": 17,
		"waves": [
			[&"walker", 49, 0],
			[&"breaker", 16, 1],
			[&"runner", 66, 2],
			[&"tank", 16, 3],
			[&"walker", 58, 4],
			[&"breaker", 16, 0],
		],
	},
	56: {
		"note": "winter 14, the boss's company: a draft of spring's night 10 to this season's size, until 0274",
		"opening_ticks": 0,
		"gap_ticks": 4 * SECONDS,
		# Sent closer together so it is all out before dawn (0137).
		"interval_ticks": 16,
		"waves": [
			[&"walker", 52, 0],
			[&"breaker", 19, 1],
			[&"runner", 85, 2],
			[&"tank", 26, 3],
			[&"walker", 66, 4],
			[&"breaker", 26, 0],
		],
	},
}

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

## The curve that writes every night past the year (Year 2 on, until 0279
## retires it - task 0270 moved it past day 56).
##
## **The ten nights `design.md` wrote were the shape; this is the
## extrapolation**, counted past the tenth as it always was. A generated
## night is the same record as a written one - note, opening, gap, waves - so
## everything downstream of `Waves.night_of()` cannot tell the difference, and
## nothing in `Enemies`, `Rewards` or the HUD needed a line about endless.
##
## ## What grows, and what must not
##
## `growth_percent` is added per night past the tenth, **not compounded**:
## compounding turns night forty into a number with no relationship to a farm
## anyone could build, and the point of endless is "how far does my build go",
## not "watch an exponent win". Its base is the tenth night as written - since
## task 0270 Spring 14's key night, the Giant's company, 84 - so at 12 a night
## past the tenth it sends 84 + ten more each night: night 25 sends 235.
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


# ===================================================================== rewards

## What a night pays, and what losing one costs.
##
## **A smaller purse and essence** (task 0219, plan section 4.6): the day earns
## the money and the night spends it. A night held well paid two or three
## well-worked days' money in spring before this, and ten in winter; it now
## pays about a quarter of one in spring, in money, beside its essence.
## `implementation/BALANCE.md` sets a spring night beside a spring day.
const REWARDS: Dictionary = {
	# Paid for finishing the night at all, growing with the night number.
	"base_money": 10,                   # LEVER: money, 5-30
	"money_per_night": 1,               # LEVER: money added per night, 1-5
	# **The bounty is a share of what the kills are worth** (task 0219): each
	# kind's `reward` is its worth, and a night pays this percent of the
	# worth of everything it killed, rounded down once. At five, killing
	# everything pays about what holding to dawn does in spring - the plan's
	# 'holding to the sunrise is worth as much as killing everything'.
	"bounty_percent": 5,                # LEVER: percent of the kills' worth, 0-100
	"resources": {WOOD: 5, STONE: 3, IRON: 1},
	"resources_per_night": {WOOD: 1},
	# **Defending well should pay more than barely holding**, so this is paid
	# per structure that came through **without a scratch** rather than per
	# structure still upright. A wall at one hit point held the line and is
	# worth nothing here; the player who never let it be touched is the one
	# being paid.
	"intact_structure_bonus": 2,        # LEVER: money each, 1-10
	# And a smaller one for the ones that took damage and held anyway, so
	# that a hard-won night is not worth less than a quiet one.
	"standing_structure_bonus": 1,      # LEVER: money each, 0-4
	"house_untouched_bonus": 10,        # LEVER: money, 10-50
	# **Essence**, the tree's currency (task 0219; the id is still `tech`):
	# this for a night won, and `TECH_BONUSES` on top.
	"tech_points": 1,                   # LEVER: essence per night won, 1-2
	# **A Full Moon pays its essence over again** (task 0219): what the
	# night's lines add up to, times this over a hundred, as its own line in
	# `Tech.would_pay`. `check_rewards` refuses less than an ordinary night.
	"full_moon_essence_percent": 200,   # LEVER: percent of the night's essence, 100-300
	# **A Blood Moon pays its own line** (task 0257): this much essence for a
	# won Blood Moon night, on top of the rest - its elites were the work.
	"blood_moon_essence": 2,            # LEVER: essence, 1-5
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
## long; the catapult (task 0227) throws two pumpkins at once. A level three
## that was only bigger numbers would be a lever with a price tag on it.
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
	# **A hive has one step** (task 0226): a broader, sturdier box with
	# bees enough to sting two at a time (`targets`) - how it works, not
	# only its numbers. Bees are not a machine and "automatic" is not a word
	# for them, so there is no third: `Building.why_not_upgrade` stops a
	# family at its last row.
	&"beehive": [
		{"needs": &"true sights", "cost": {WOOD: 20, SUNFLOWER: 8},
			"gives": {"hp": 90, "targets": 2}},
	],
	# **The catapult** (task 0227): an iron-banded arm on wheels, then a
	# heavier frame on a stone footing - A039's levels - which ends in a
	# second arm: two pumpkins a throw (`targets`), a volley.
	# **The searchlight** (task 0229): a larger drum on a lattice mast - a
	# wider light, which is the whole of how a lamp works. One step.
	&"searchlight": [
		{"needs": &"true sights", "cost": {IRON: 15, COPPER: 12},
			"gives": {"light_tiles": 6, "hp": 90}},
	],
	# **The hardwood wall** (task 0231; plan section 3.3): the stone wall
	# rebuilt with the big stumps' hardwood - beams and iron straps - into
	# something a breaker has to work at, and dearer for the field to go
	# through. One step, behind 'stout timbers' - the survival branch's,
	# where the house's timbers are - and the iron axe that fells a stump.
	# **It rebuilds** (`rebuilds`): the hardwood is in its walls from then
	# on, so mending it costs stone and hardwood, where the gunpowder that
	# bought a tower's level three is not in its walls (0113).
	&"wall": [
		{"needs": &"stout timbers", "cost": {HARDWOOD: 4},   # LEVER: hardwood, 2-8
			"rebuilds": true,
			# `path_cost` 24 is the most the field's wheel holds (`WIDEST_STEP`)
			# with garlic's over the worst ground.
			"gives": {"hp": 240, "path_cost": 24}},   # LEVER: hit points 160-320, path cost 21-24
	],
	&"catapult": [
		{"needs": &"true sights", "cost": {WOOD: 20, IRON: 10},
			"gives": {"damage": 36, "hp": 95, "range": 8}},
		{"needs": &"oiled works", "cost": {WOOD: 25, STONE: 30, IRON: 15},
			"gives": {"damage": 42, "hp": 125, "range": 8, "splash_tiles": 3,
				"targets": 2}},
	],
}

## The most any tower can be upgraded to. Level one is the thing as built. A
## family with fewer rows stops at its last (task 0226).
const TOP_TOWER_LEVEL := 3

## **Light** (task 0229; `Light`): how far round the house's porch is lit, how
## much further a tower standing in light reaches, and how many tiles a
## searchlight loses on a farm short of power - degraded, never dead.
const PORCH_LIGHT_TILES := 2            # LEVER: tiles round the porch, 1-3
const LIGHT_REACH_BONUS := 1            # LEVER: tiles further in light, 1-2
const LIGHT_SHORT_SHRINK := 1           # LEVER: tiles lost short of power, 1-2


## The tech tree: three branches, a floor a season.
##
## `design.md` section 12 wants somewhere to spend technology and is explicit
## that the MVP does **not** get a giant tree. Spring's floor is the twelve
## nodes the MVP had - three branches of four, on one screen - and the shape
## is what makes the choice legible: a player can see the whole thing and
## still not have it.
##
## ## A floor a season (task 0220, plan section 7)
##
## Summer, autumn and winter each add a node to every branch, so a season's
## essence buys something the season before could not, and the tree grows
## with the year rather than being done in the first fortnight. `season` is
## the floor (0 spring to 3 winter); a floor opens when the run reaches its
## season (`Calendar.season_reached`) and stays open - in Year 2's spring too.
## Each later node needs the floor below it in its branch, so a branch is a
## chain of seven.
##
## **A later floor strengthens a number an earlier one gave**, and the
## stronger wins (`Tech.bonus`): owning both is owning the later.
##
## ## Priced against the year
##
## A year pays 64 essence at worst and 256 at best (`Tech.total_available()`,
## a Full Moon's share included). The tree costs 377:
## - spring's floor 45, as before: each branch 2 + 3 + 4 + 6;
## - summer's 4 x 16, autumn's 4 x 27 and winter's 4 x 40 - a floor's three
##   and, since task 0233, the survival branch's power on it.
##
## That is **half again what the best year earns**, where it was a seventh
## over: the powers are a second road through the survival branch, and a
## year buys one of the two roads and some of the other, not both. The
## dearest node with everything under it - a winter one, the emergency kit
## through the bell and the dog as much as a stake pile through its own - is
## still 15 + 16 + 27 + 40 = 98, well inside the best year and over the
## worst's 64. Spring alone is still the old sum: a branch, 15, fits ten
## nights' 44 and three of them do not.
##
## ## The effect is a number the rules already read
##
## Every node hands one entry to `Tech.bonus()`, and the system that owns that
## number asks for it. Nothing here knows what a tower is; `Towers` knows what
## `tower_damage_percent` is worth and asks. A thirteenth node is a row here
## plus one `Tech.bonus()` call wherever it belongs.
const TECH_TREE: Array = [
	# ---------------------------------------------------------- production
	{"id": &"sharp tools", "branch": &"production", "season": 0, "cost": 2, "needs": [],
		"gives": {"gather_percent": 110},
		"note": "chopping and mining speed +10%"},
	{"id": &"full cans", "branch": &"production", "season": 0, "cost": 3,
		"needs": [&"sharp tools"], "gives": {"water_can_bonus": 2},
		"note": "the watering can holds two more"},
	{"id": &"steady hands", "branch": &"production", "season": 0, "cost": 4,
		"needs": [&"full cans"], "gives": {"craft_percent": 135},
		"note": "the workshop, press and kitchen work a third faster"},
	{"id": &"a name at market", "branch": &"production", "season": 0, "cost": 6,
		"needs": [&"steady hands"], "gives": {"sell_percent": 125},
		"note": "everything you sell fetches a quarter more"},
	# Task 0220's floors: each a stronger `sharp tools`, `a name at market`
	# and `steady hands`.
	{"id": &"keen edges", "branch": &"production", "season": 1, "cost": 16,   # LEVER: essence, 10-30
		"needs": [&"a name at market"], "gives": {"gather_percent": 125},
		"note": "chopping and mining speed +25%"},
	{"id": &"a full ledger", "branch": &"production", "season": 2, "cost": 27,   # LEVER: essence, 15-45
		"needs": [&"keen edges"], "gives": {"sell_percent": 140},
		"note": "everything you sell fetches two fifths more"},
	{"id": &"master hands", "branch": &"production", "season": 3, "cost": 40,   # LEVER: essence, 25-60
		"needs": [&"a full ledger"], "gives": {"craft_percent": 170},
		"note": "every bench and machine works seven tenths faster"},

	# ------------------------------------------------------------- defence
	{"id": &"true sights", "branch": &"defence", "season": 0, "cost": 2, "needs": [],
		"gives": {"tower_damage_percent": 120},
		"note": "every tower hits a fifth harder"},
	{"id": &"long barrels", "branch": &"defence", "season": 0, "cost": 3,
		"needs": [&"true sights"], "gives": {"tower_range_bonus": 1},
		"note": "every tower reaches one tile further"},
	{"id": &"oiled works", "branch": &"defence", "season": 0, "cost": 4,
		"needs": [&"long barrels"], "gives": {"tower_reload_percent": 80},
		"note": "every tower reloads a fifth sooner"},
	{"id": &"a standing order", "branch": &"defence", "season": 0, "cost": 6,
		"needs": [&"oiled works"], "gives": {"tower_cost_percent": 75},
		"note": "towers cost a quarter less to build"},
	# Each a stronger `true sights`, `long barrels` and `oiled works`.
	{"id": &"heavy shot", "branch": &"defence", "season": 1, "cost": 16,   # LEVER: essence, 10-30
		"needs": [&"a standing order"], "gives": {"tower_damage_percent": 140},
		"note": "every tower hits two fifths harder"},
	{"id": &"tall mounts", "branch": &"defence", "season": 2, "cost": 27,   # LEVER: essence, 15-45
		"needs": [&"heavy shot"], "gives": {"tower_range_bonus": 2},
		"note": "every tower reaches two tiles further"},
	{"id": &"greased works", "branch": &"defence", "season": 3, "cost": 40,   # LEVER: essence, 25-60
		"needs": [&"tall mounts"], "gives": {"tower_reload_percent": 65},
		"note": "every tower reloads a third sooner"},

	# ------------------------------------------------------------ survival
	{"id": &"stout timbers", "branch": &"survival", "season": 0, "cost": 2, "needs": [],
		"gives": {"house_hp_bonus": 40},
		"note": "the house takes forty more before it falls, and a stone wall can be rebuilt in hardwood"},
	{"id": &"a full larder", "branch": &"survival", "season": 0, "cost": 3,
		"needs": [&"stout timbers"], "gives": {"repair_percent": 60},
		"note": "mending costs two fifths less"},
	{"id": &"spare stakes", "branch": &"survival", "season": 0, "cost": 4,
		"needs": [&"a full larder"], "gives": {"barricade_bonus": 3},
		"note": "three more barricades a night"},
	{"id": &"a second flare", "branch": &"survival", "season": 0, "cost": 6,
		"needs": [&"spare stakes"], "gives": {"flare_percent": 55},
		"note": "the flare comes back in a little over half the time"},
	# Each a stronger `stout timbers`, `a full larder` and `spare stakes`. The
	# powers are 0233's, which adds a survival node a season from summer.
	{"id": &"brick footings", "branch": &"survival", "season": 1, "cost": 16,   # LEVER: essence, 10-30
		"needs": [&"a second flare"], "gives": {"house_hp_bonus": 80},
		"note": "the house takes eighty more before it falls"},
	{"id": &"cheap timber", "branch": &"survival", "season": 2, "cost": 27,   # LEVER: essence, 15-45
		"needs": [&"brick footings"], "gives": {"repair_percent": 40},
		"note": "mending costs three fifths less"},
	{"id": &"a stake pile", "branch": &"survival", "season": 3, "cost": 40,   # LEVER: essence, 25-60
		"needs": [&"cheap timber"], "gives": {"barricade_bonus": 6},
		"note": "six more barricades a night"},
	# **The powers** (task 0233; the plan's 4.4): a node a season from
	# summer, a chain of their own off spring's last, each giving its power
	# (`Ability.unlocked()`) at a floor's price.
	{"id": &"a farm bell", "branch": &"survival", "season": 1, "cost": 16,   # LEVER: essence, 10-30
		"needs": [&"a second flare"], "gives": {"farm_bell_bonus": 1},
		"note": "the farm bell: every zombie on the farm stops for two seconds"},
	{"id": &"a good dog", "branch": &"survival", "season": 2, "cost": 27,   # LEVER: essence, 15-45
		"needs": [&"a farm bell"], "gives": {"call_dog_bonus": 1},
		"note": "the dog runs out at night and bites the zombie nearest the cursor"},
	{"id": &"an emergency kit", "branch": &"survival", "season": 3, "cost": 40,   # LEVER: essence, 25-60
		"needs": [&"a good dog"], "gives": {"emergency_repair_bonus": 1},
		"note": "an emergency repair: a structure gets back three tenths at once"},
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

## **What the night leaves lying about** (task 0221; plan sections 3.3 and
## 4.6): `Loot` lays it, and the farmer picks it up by walking over it.
##
## How many of one thing a cell holds. A choke point where forty walkers
## fell is a heap of nine bones, not forty.
const LOOT_PILE_CAP := 9                # LEVER: of one thing on a cell, 3-20
## **One body of a kind in this many leaves its bones** - the night's
## first, its ninth, its seventeenth - and a boss always does. At every
## body a spring night left eighty bones and a winter one six hundred: a
## second purse bigger than the first, where the plan's own spring
## morning picks up six.
const BONES_EVERY := 8                  # LEVER: bodies of a kind, 1-20
## How far a pile that fell where nobody can stand - a spike trap, a wall,
## the pond's edge - looks for ground the farmer can reach. Past it, it is
## lost.
const LOOT_REACH := 4                   # LEVER: tiles, 1-6
## How many mornings a pile lies before it is gone, from the night it was
## last added to.
const LOOT_FADE_DAYS := 3               # LEVER: mornings, 1-7
## **The moon stones a Full Moon leaves** along the horde's road (plan
## section 3.3: the night feeding the day).
const MOON_STONES := 4                  # LEVER: stones, 2-8
## What one trades for at the tree, by day (`Tech.trade_moon_stones`).
const MOON_STONE_ESSENCE := 1           # LEVER: essence a stone, 1-3


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
	"T.............................WWWW..w..pp..B..............T....................T",
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
	# The shipping bin by the porch (task 0189), on grass, on the site 0156
	# kept for it.
	"B": [0, &"shipping_bin"],
}

## **The nodes 0156 put on the map before they had a `GATHERING` row**,
## under their final ids: 0176 gave copper, coal and gold theirs and 0177 the
## hardwood stump. The list stays because it is what the v5-to-v6 save
## migration lays into an old farm (`Save`), and `check_reachable` walks it
## as well as the table.
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
	errors.append_array(check_rewards(REWARDS))
	if FERTILISED_EXTRA_DAYS < 1:
		errors.append("bone meal grows a plot %d mornings: it needs at least one"
			% FERTILISED_EXTRA_DAYS)
	errors.append_array(check_loot(LOOT_PILE_CAP, MOON_STONES,
		MOON_STONE_ESSENCE, LOOT_FADE_DAYS, LOOT_REACH, ENEMIES, BONES_EVERY))
	errors.append_array(check_tech_tree(TECH_TREE))
	errors.append_array(check_powers(POWERS, TECH_TREE))
	errors.append_array(check_crops(CROPS))
	errors.append_array(check_gathering(GATHERING))
	errors.append_array(check_recipes(RECIPES))
	errors.append_array(check_tools(TOOLS))
	errors.append_array(check_house_tiers(HOUSE_TIERS))
	errors.append_array(check_tool_areas(TOOL_AREA_OFFSETS))
	errors.append_array(check_buildings(BUILDINGS))
	errors.append_array(check_defences(DEFENCES))
	errors.append_array(check_enemies(ENEMIES))
	errors.append_array(check_nights(SEASON_NIGHTS, KEY_NIGHTS))
	# **The per-record rules on seed 0's year** (task 0270), so loading stays
	# cheap: `python tools/nights.py --check` runs them on every date for two
	# seeds.
	for day in range(1, Calendar.year_days() + 1):
		errors.append_array(check_record(Waves.night_of(day, 0), day))
	errors.append_array(check_map(FARM_MAP))
	errors.append_array(check_fishing(FISHING))
	errors.append_array(check_bait(BAIT_EFFECTS))
	errors.append_array(check_iron(GATHERING, FARM_MAP))
	errors.append_array(check_reachable(GATHERING, FARM_MAP))
	errors.append_array(check_spawn_bands(SPAWN_BANDS, FARM_MAP))
	errors.append_array(check_sides(SPAWNS, SPAWN_SIDES, SIDES_BY_SEASON))
	errors.append_array(check_ponds(PONDS, FARM_MAP))
	errors.append_array(check_sites(MAP_SITES, FARM_MAP))
	errors.append_array(check_chain(RECIPES, SELL_PRICE))
	errors.append_array(check_livestock(LIVESTOCK, FARM_MAP))
	errors.append_array(check_ammo(DEFENCES, RECIPES))
	errors.append_array(check_kits(DEFENCES, RECIPES))
	errors.append_array(check_groups(RESOURCE_GROUPS, RESOURCES))
	errors.append_array(check_resource_prices(RESOURCES, SELL_PRICE))
	# Every season's shelf (task 0190), animals and upgrades on it.
	for season in SEASONS:
		errors.append_array(check_stall(stall_stock(season), SELL_PRICE, BUY_MARKUP))
	errors.append_array(check_season_stock(SEASON_STOCK))
	errors.append_array(check_seasonal_supply(DEFENCES, RECIPES))
	errors.append_array(check_day_targets(DAY_TARGETS, DAY_FARM))
	errors.append_array(check_stall_hours(STALL_OPENS, STALL_CLOSES))
	errors.append_array(check_tutorial(TUTORIAL))
	errors.append_array(check_tips(TIPS))
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
	errors.append_array(check_night_events(NIGHT_EVENTS))
	errors.append_array(check_no_growth_seasons(NO_GROWTH_SEASONS))
	errors.append_array(check_gift(CALM_NIGHT_GIFT))
	if TILLED_GRASS_FADES_DAYS < 1 or TILLED_GRASS_FADES_DAYS > 7:
		errors.append("TILLED_GRASS_FADES_DAYS must be within 1-7 mornings")
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
	# **The fill line falls inside the night** (task 0271), before the margin.
	if NIGHT_FILL_TICKS < 0 or NIGHT_FILL_TICKS + DAWN_MARGIN_TICKS >= NIGHT_TICKS:
		errors.append("the fill line is %d ticks before a %d-tick margin of a %d-tick night"
			% [NIGHT_FILL_TICKS, DAWN_MARGIN_TICKS, NIGHT_TICKS])

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


## Every outdoor growth pause must name an existing season (0171).
static func check_no_growth_seasons(seasons: Array) -> Array:
	var errors: Array = []
	for season in seasons:
		if season not in SEASONS:
			errors.append("NO_GROWTH_SEASONS names unknown season '%s'" % season)
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


## **The night's weather holds together** (task 0256): every event is one
## `Weather` can play, with a share of every season's nights from 0 to 100 -
## and at most 100 between them, since a night has one event at most - and
## its levers in `NIGHT_EVENT_LEVERS`' ranges, and none of it in a season
## before `NIGHT_EVENT_FIRST_SEASON` says it rises (task 0257). Takes the
## table as an argument, like `check_calendar()`, so a check can hand it a
## bad one.
static func check_night_events(events: Dictionary, seasons: Array = SEASONS) -> Array:
	var errors: Array = []
	var total := {}
	for kind in sorted_names(events.keys()):
		var name := StringName(kind)
		var row: Dictionary = events[kind]
		if not Weather.EVENTS.has(name):
			errors.append("the night event '%s' is not one Weather can play" % name)
		var weights: Dictionary = row.get("weights", {})
		for season in seasons:
			if not weights.has(season):
				errors.append("the night event '%s' has no share of %s's nights" % [name, season])
				continue
			var weight := int(weights[season])
			if weight < 0 or weight > 100:
				errors.append("the night event '%s' falls on %d%% of %s's nights, outside 0-100"
					% [name, weight, season])
			total[season] = int(total.get(season, 0)) + weight
		for season in sorted_names(weights.keys()):
			if not seasons.has(StringName(season)):
				errors.append("the night event '%s' has a share of '%s', which is no season"
					% [name, season])
		var first := seasons.find(StringName(NIGHT_EVENT_FIRST_SEASON.get(name, &"")))
		for i in maxi(first, 0):
			if int(weights.get(seasons[i], 0)) > 0:
				errors.append("the night event '%s' falls in %s, before %s"
					% [name, seasons[i], seasons[first]])
		var levers: Dictionary = NIGHT_EVENT_LEVERS.get(name, {})
		for lever in sorted_names(levers.keys()):
			var key := String(lever)
			var span: Array = levers[key]
			if not row.has(key):
				errors.append("the night event '%s' has no %s" % [name, key])
			elif int(row[key]) < int(span[0]) or int(row[key]) > int(span[1]):
				errors.append("the night event '%s' has a %s of %d, outside %d-%d"
					% [name, key, int(row[key]), int(span[0]), int(span[1])])
	for season in seasons:
		if int(total.get(season, 0)) > 100:
			errors.append("%s's night events add up to %d%% of its nights: a night has one at most"
				% [season, int(total[season])])
	return errors


## The cost field has to be able to represent every step it can be asked to
## take, and a bucket wheel that is one short does not fail loudly - it puts a
## cell in the wrong bucket and the route comes out subtly wrong. So the
## widest step is checked against the tables rather than kept in step by hand.
static func check_pathing(terrain: Array, defences: Dictionary,
		buildings: Dictionary, levels: Dictionary = TOWER_LEVELS) -> Array:
	var errors: Array = []

	var ground := 0
	for cost in terrain:
		if int(cost) < 0:
			errors.append("a terrain costs less than nothing to cross")
		ground = maxi(ground, int(cost))
	if ground <= 0:
		errors.append("no terrain can be crossed at all")

	# **Garlic's extra on top of any step** (task 0228): a braid's area can lie
	# over the worst ground and the worst barrier, and the sum has to fit the
	# wheel as surely as either does alone.
	var garlic := 0
	for id in sorted_names(defences.keys()):
		garlic = maxi(garlic, int((defences[id] as Dictionary).get("repel_cost", 0)))
	for table in [defences, buildings]:
		for id in sorted_names((table as Dictionary).keys()):
			var entry: Dictionary = (table as Dictionary)[id]
			var through := int(entry.get("path_cost", 0))
			if through < 0:
				errors.append("'%s' costs less than nothing to break" % id)
			if ground + through + garlic > WIDEST_STEP:
				errors.append(("stepping into '%s' costs %d, garlic's %d included, which is "
					+ "wider than WIDEST_STEP (%d)") % [id, ground + through + garlic, garlic,
					WIDEST_STEP])
			# **A thing you can walk through is a thing you can break.** The
			# field prices a barrier by how long getting through it takes; if
			# nothing could take it apart, a zombie would route into it and then
			# stand there for the rest of the night.
			if through > 0 and int(entry.get("hp", 0)) <= 0:
				errors.append(("'%s' declares a path cost but has no hit points - "
					+ "there would be no way through it after all") % id)
	# **A level is priced too** (task 0231): the field prices a levelled
	# occupant from its levelled row, so a hardwood wall's dearer way through
	# has to fit the wheel as surely as the stone wall's.
	for id in sorted_names(levels.keys()):
		for step in (levels[id] as Array):
			var through := int(((step as Dictionary)["gives"] as Dictionary).get("path_cost", 0))
			if ground + through + garlic > WIDEST_STEP:
				errors.append(("stepping into a levelled '%s' costs %d, garlic's %d included, "
					+ "which is wider than WIDEST_STEP (%d)") % [id, ground + through + garlic,
					garlic, WIDEST_STEP])

	# **Every lure's head start fits the wheel** (task 0225): the lure field
	# seeds each lure at how much less far it pulls than the widest, and the
	# sweep files that start in its bucket wheel.
	var widest := 0
	var narrowest := 1 << 30
	for id in sorted_names(defences.keys()):
		var tiles := int((defences[id] as Dictionary).get("lure_tiles", 0))
		if tiles > 0:
			widest = maxi(widest, tiles)
			narrowest = mini(narrowest, tiles)
	if widest > 0 and widest - narrowest > WIDEST_STEP:
		errors.append(("lures pull from %d to %d tiles, and the head start "
			+ "between them is wider than WIDEST_STEP (%d)") % [narrowest, widest, WIDEST_STEP])

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
	for crop_id in sorted_names(crops.keys()):
		if not RESOURCES.has(crop_id):
			errors.append("crop '%s' is not a resource" % crop_id)
		if not SELL_PRICE.has(crop_id):
			errors.append("crop '%s' has no sell price" % crop_id)
		if int((crops[crop_id] as Dictionary)["growth_days"]) <= 0:
			errors.append("crop '%s' grows in no time at all" % crop_id)

		var regrow := int(crops[crop_id].get("regrow_days", 0))
		if regrow < 0 or regrow > int(crops[crop_id]["growth_days"]):
			errors.append("crop '%s' regrows outside 0-growth_days" % crop_id)
		var seasons: Array = crops[crop_id].get("seasons", [])
		if seasons.is_empty():
			errors.append("crop '%s' has no sowing season" % crop_id)
		# What a harvest leaves besides the crop (task 0184): real things.
		var leaves: Dictionary = crops[crop_id].get("byproduct", {})
		for res in sorted_names(leaves.keys()):
			if not RESOURCES.has(res) or int(leaves[res]) < 1:
				errors.append("crop '%s' leaves '%s', which is no resource" % [crop_id, res])
		for season in seasons:
			if season not in SEASONS or season == &"winter":
				errors.append("crop '%s' has invalid sowing season '%s'" % [crop_id, season])
		var packet := StringName("%s_seed" % crop_id)
		if int(crops[crop_id]["seed_cost"]) <= int(SELL_PRICE.get(packet, 0)):
			errors.append("crop '%s' packet must lose money on resale" % crop_id)

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
			var shared := false
			for season in crops[a].get("seasons", []):
				if season in crops[b].get("seasons", []):
					shared = true
			if not shared:
				continue

			var x := _crop_offer(crops, a)
			var y := _crop_offer(crops, b)
			if x["value"] >= y["value"] and x["visits"] <= y["visits"] 					and x["seed"] <= y["seed"]:
				errors.append(("crop '%s' dominates '%s' - %s against %s; "
					+ "move a seed cost") % [a, b, x, y])
	return errors


## Whole watered harvests in the season estimate shared by the HUD and balance.
##
## **Thirteen mornings, not fourteen.** A crop sown on the season's first day
## is credited on the mornings of days 2 to 14; the next season's first
## morning withers it before its credit (task 0171), so a seven-day crop
## ripens once, not twice.
static func crop_harvests(data: Dictionary) -> int:
	var mornings := SEASON_DAYS - 1
	var grown := maxi(int(data["growth_days"]), 1)
	var regrow := int(data.get("regrow_days", 0))
	if regrow <= 0:
		return mornings / grown
	return 0 if grown > mornings else 1 + (mornings - grown) / regrow


## What one plot of a crop offers over a season: money, trips, and the money it
## takes to start. The three axes `check_crops()` refuses to let one crop win
## outright.
static func _crop_offer(crops: Dictionary, id: StringName) -> Dictionary:
	var data: Dictionary = crops[id]
	var visits := crop_harvests(data)
	var revenue := int(data["yield"]) * int(SELL_PRICE.get(id, 0)) * visits
	var seeds := 1 if int(data.get("regrow_days", 0)) > 0 else visits
	return {"value": revenue - int(data["seed_cost"]) * seeds, "visits": visits,
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

	# New quarry materials follow the same scarcity dials as iron.
	for id in [&"copper_ore", &"coal_seam", &"gold_ore"]:
		if not nodes.has(id):
			continue
		var node: Dictionary = nodes[id]
		if int(node["work_ticks"]) <= int(seam["work_ticks"]) \
				or _worth(node["yield"]) >= _worth(seam["yield"]) \
				or int(node["regrow_ticks"]) <= int(seam["regrow_ticks"]):
			errors.append("quarry '%s' must be slower and scarcer than stone" % id)
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
				# What the site was kept for may stand on it (task 0189: the
				# shipping bin on its own).
				var entry: Variant = _legend_at(rows, Vector2i(x, y))
				if entry != null and StringName((entry as Array)[1]) == id:
					continue
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
	for node_id in sorted_names(nodes.keys()):
		var entry: Dictionary = nodes[node_id]
		if entry.has("min_tier") or entry.has("tool"):
			var tool := StringName(entry.get("tool", &""))
			var minimum: Variant = entry.get("min_tier", 0)
			if tool not in [&"axe", &"pickaxe"] or not TOOLS.has(tool):
				errors.append("gathering '%s' needs an axe or pickaxe ladder" % node_id)
			elif typeof(minimum) != TYPE_INT or int(minimum) < 0 or int(minimum) >= TOOLS[tool].size():
				errors.append("gathering '%s' has an invalid minimum tool tier" % node_id)
		if entry.has("first_season") and not SEASONS.has(entry["first_season"]):
			errors.append("gathering '%s' has an unknown opening season" % node_id)
		for res in sorted_names(entry["yield"].keys()):
			if not RESOURCES.has(res):
				errors.append("gathering '%s' yields unknown '%s'"
					% [node_id, res])
	return errors


## Decode the output's tool and tier without treating tools as resources.
##
## **Read off the id, not built for every tool** (task 0192): an output is
## `<tool>_<tier name>`, so each underscore is a place the tool's name may
## end, tried shortest first - which for names that are each other's
## prefixes is name order, the order the old search took. Formatting every
## tool's every tier to compare against made `tool_upgrades()` cost the stall
## a third of a millisecond on every purchase.
static func tool_output(id: StringName) -> Dictionary:
	var text := String(id)
	var cut := text.find("_")
	while cut > 0:
		var tool := StringName(text.substr(0, cut))
		if TOOLS.has(tool):
			var tier_name := text.substr(cut + 1)
			for tier in range(1, TOOLS[tool].size()):
				if String(TOOLS[tool][tier]["name"]) == tier_name:
					return {"tool": tool, "tier": tier}
		cut = text.find("_", cut + 1)
	return {}


## Costs are actual ledger resources; all five ladders retain three tiers.
## **The house's tiers** (task 0191): the first is free - it is the house a
## new game has - every later one costs something in the ledger, and no
## bonus falls from one tier to the next; a discount stays within 0-100.
static func check_house_tiers(tiers: Array) -> Array:
	var errors: Array = []
	if tiers.is_empty() or not ((tiers[0] as Dictionary)["cost"] as Dictionary).is_empty():
		errors.append("the first house tier is the one a new game has, and costs nothing")
	var hp := -1
	var discount := -1
	for i in tiers.size():
		var tier: Dictionary = tiers[i]
		var bonus := int(tier.get("hp_bonus", -1))
		var off := int(tier.get("repair_discount", -1))
		if bonus < hp or off < discount:
			errors.append("house tier %d is weaker than the one before it" % (i + 1))
		if off < 0 or off > 100:
			errors.append("house tier %d takes %d%% off a repair" % [i + 1, off])
		for res in sorted_names((tier["cost"] as Dictionary).keys()):
			if not RESOURCES.has(res):
				errors.append("house tier %d costs unknown '%s'" % [i + 1, res])
		if i > 0 and (tier["cost"] as Dictionary).is_empty():
			errors.append("house tier %d costs nothing" % (i + 1))
		hp = bonus
		discount = off
	return errors


static func check_tools(tools: Dictionary) -> Array:
	var errors: Array = []
	for tool in sorted_names(tools.keys()):
		var tiers: Array = tools[tool]
		if tiers.size() != 3:
			errors.append("tool '%s' needs three tiers" % tool)
		for i in tiers.size():
			var tier: Dictionary = tiers[i]
			for res in sorted_names(tier["cost"].keys()):
				if res not in RESOURCES or int(tier["cost"][res]) <= 0:
					errors.append("tool '%s' has an invalid tier cost '%s'" % [tool, res])
			if i > 0 and bool(tier["enabled"]) and (int(tier["cost"].get(MONEY, 0)) <= 0 or tier["cost"].size() < 2):
				errors.append("tool '%s' needs money and ore" % tool)
			if tier.has("area") and int(tier["area"]) not in [1, 3, 5]:
				errors.append("tool '%s' has an invalid area" % tool)
			if tier.has("capacity_bonus") and int(tier["capacity_bonus"]) < 0:
				errors.append("tool '%s' has a negative can capacity bonus" % tool)
			for field in ["gather_percent", "bite_percent", "rare_percent", "zone_percent"]:
				if tier.has(field) and int(tier[field]) <= 0:
					errors.append("tool '%s' has an invalid effect '%s'" % [tool, field])
	return errors


## Each tier keeps its full width and a unique, centre-first stroke.
static func check_tool_areas(areas: Dictionary) -> Array:
	var errors: Array = []
	for count in [1, 3, 5]:
		var offsets: Array = areas.get(count, [])
		if offsets.size() != count or offsets.is_empty() or offsets[0] != 0:
			errors.append("tool area %d needs its width and centre first" % count)
		var seen: Array = []
		for offset in offsets:
			if offset in seen or absi(int(offset)) > count / 2:
				errors.append("tool area %d has an invalid offset" % count)
			seen.append(offset)
	return errors


static func check_recipes(recipes: Dictionary) -> Array:
	var errors: Array = []
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if not BUILDINGS.has(recipe["station"]):
			errors.append("recipe '%s' wants unknown station '%s'"
				% [recipe_id, recipe["station"]])
		# **Ticks or days, exactly one** (task 0187): a job is timed by the
		# tick at the bench or credited a day a morning - never both, and
		# never neither.
		var timed := int(recipe.has("ticks")) + int(recipe.has("days"))
		if timed != 1:
			errors.append("recipe '%s' must take ticks or days - exactly one of them" % recipe_id)
		elif int(recipe.get("ticks", recipe.get("days", 0))) <= 0:
			errors.append("recipe '%s' takes no time at all" % recipe_id)
		for res in (recipe["inputs"] as Dictionary):
			if not RESOURCES.has(res) and not is_any_of(StringName(res)):
				errors.append("recipe '%s' takes unknown '%s'"
					% [recipe_id, res])
		for out in (recipe["output"] as Dictionary):
			# An output is either a resource or something placeable.
			if not RESOURCES.has(out) and not DEFENCES.has(out) and tool_output(StringName(out)).is_empty():
				errors.append("recipe '%s' makes unknown '%s'"
					% [recipe_id, out])
				continue
			var upgrade := tool_output(StringName(out))
			if not upgrade.is_empty():
				var cost: Dictionary = TOOLS[upgrade["tool"]][upgrade["tier"]]["cost"]
				if recipe["station"] != &"workshop" or recipe["inputs"] != cost or int(recipe["output"][out]) != 1 or recipe["output"].size() != 1:
					errors.append("recipe '%s' is not the tool tier's exact workshop cost" % recipe_id)
			# **A kit is the structure's materials, paid early.** Two places
			# to write one price is two places for it to drift, so the drift is
			# a red line rather than a surprise at the shop counter. **Never
			# its money** (task 0234): placing a kit still charges that.
			if DEFENCES.has(out) and int((recipe["output"] as Dictionary)[out]) == 1:
				var price: Dictionary = ((DEFENCES[out] as Dictionary)["cost"] as Dictionary).duplicate()
				price.erase(MONEY)
				if recipe["inputs"] != price:
					errors.append(("recipe '%s' costs %s and the '%s' it makes "
						+ "is made of %s - a kit has to be the materials paid early")
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
		for field in ["fuel", "fuel_fallback"]:
			for res in sorted_names((building.get(field, {}) as Dictionary).keys()):
				if not RESOURCES.has(res):
					errors.append("building '%s' burns unknown '%s'" % [building_id, res])
		# **A sprinkler says how it sprays** (task 0178), in words this file
		# knows, and is one cell that is walked over: a shape typo would be a
		# sprinkler that waters nothing, and a solid one a wall.
		if building.has("spray"):
			if not SPRAY_SHAPES.has(building["spray"]):
				errors.append("sprinkler '%s' sprays an unknown '%s'" % [building_id, building["spray"]])
			if int(building.get("spray_reach", 0)) < 1 or int(building.get("spray_reach", 0)) > 3:
				errors.append("sprinkler '%s' reaches outside 1-3" % building_id)
			if building.get("size", Vector2i.ONE) != Vector2i.ONE or not bool(building.get("walked_over", false)):
				errors.append("sprinkler '%s' must be one cell that is walked over" % building_id)
	return errors


static func check_defences(defences: Dictionary) -> Array:
	var errors: Array = []
	for defence_id in sorted_names(defences.keys()):
		var defence: Dictionary = defences[defence_id]

		# **A season of the four, and money as well as materials** (task
		# 0234): the calendar opens a defence, and the day's purse pays a
		# share of every one.
		if not SEASONS.has(defence_season(defence)):
			errors.append("defence '%s' opens in '%s', which is no season"
				% [defence_id, defence.get("season", &"")])
		var price: Dictionary = defence.get("cost", {})
		if int(price.get(MONEY, 0)) <= 0 or price.size() < 2:
			errors.append("defence '%s' costs no money, or nothing but money" % defence_id)
		# **Every barrier says whether a digger goes under it** (task 0250),
		# so a later one cannot say nothing and be guessed at.
		if int(defence.get("path_cost", 0)) > 0 and not defence.has("burrowable"):
			errors.append("defence '%s' is a barrier and never says whether a digger goes under it"
				% defence_id)

		# **A tower that shoots says how it picks and how it lands.** The words
		# are checked against the lists above, so a typo is a red line at boot
		# rather than a tower that quietly falls back to the default and looks
		# like a balance problem.
		if defence.has("reload_ticks"):
			# **Every tower chooses whether it reaches the air** (task 0249),
			# so a later one cannot say nothing and be guessed at.
			if not defence.has("hits_flying"):
				errors.append("defence '%s' shoots and never says whether it hits what flies"
					% defence_id)
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
			elif shape == SHAPE_STING and (int(defence.get("damage", 0)) <= 0
					or int(defence.get("sting_ticks", 0)) <= 0):
				# **A sting hurts, for a while** (task 0226): one that did no
				# damage, or for no time, would be a tower that only buzzes.
				errors.append("defence '%s' stings for nothing, or for no time at all"
					% defence_id)
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
			# **A group only on a kit** (task 0225): the fish group is a
			# recipe's to pay from any species, never the ledger's.
			if not RESOURCES.has(res) and not (is_any_of(StringName(res))
					and bool(defence.get("kit_only", false))):
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
		# **A lure pulls from somewhere and can be bitten** (task 0224): one
		# that reached no tile would pull nobody, and one with no hit points
		# would be bitten for ever - and the hunt field would never lead a
		# breaker to it.
		if defence.has("lure_tiles"):
			if int(defence["lure_tiles"]) <= 0:
				errors.append("defence '%s' lures from no tiles at all" % defence_id)
			if int(defence.get("hp", 0)) <= 0:
				errors.append("defence '%s' lures and has no hit points to bite"
					% defence_id)
		# **Walked over is no barrier** (task 0225): the field gives it the
		# ground's cost, so a price for breaking through would never be read.
		if bool(defence.get("walked_over", false)) and defence.has("path_cost"):
			errors.append("defence '%s' is walked over and priced as a barrier"
				% defence_id)
		if defence.has("eaten_by") and int(defence["eaten_by"]) <= 0:
			errors.append("defence '%s' is eaten by nobody" % defence_id)
		# **A lamp lights something** (task 0229).
		if defence.has("light_tiles") and int(defence["light_tiles"]) <= 0:
			errors.append("defence '%s' lights no tiles" % defence_id)
		# **A shock stuns for something** (task 0230): one of no ticks would
		# be a fence with extra words, and a boss's share is a share.
		if defence.has("stun_ticks") and int(defence["stun_ticks"]) <= 0:
			errors.append("defence '%s' stuns for no time at all" % defence_id)
		if defence.has("boss_stun_percent"):
			var share := int(defence["boss_stun_percent"])
			if share < 0 or share > 100:
				errors.append("defence '%s' stuns a boss for %d%% of it" % [defence_id, share])
		# **Garlic's area** (task 0228): it reaches some tiles, costs something
		# to cross, slows without stopping, and keeps some strength wilted.
		if defence.has("repel_tiles"):
			if int(defence["repel_tiles"]) <= 0 or int(defence.get("repel_cost", 0)) <= 0:
				errors.append("defence '%s' repels from no tiles, or for nothing"
					% defence_id)
			var speed := int(defence.get("repel_speed_percent", 0))
			if speed <= 0 or speed >= 100:
				errors.append("defence '%s' walks them through at %d%% of their speed"
					% [defence_id, speed])
			var wilted := int(defence.get("wilted_percent", -1))
			if wilted < 0 or wilted > 100:
				errors.append("defence '%s' keeps %d%% of itself wilted"
					% [defence_id, wilted])
		# **A hive's sunflowers** (task 0226): counted from some tiles round
		# it, a sting's worth at a time, up to a most it can use, and eaten
		# from the store a night - none of them at zero, or the field it asks
		# for would do nothing.
		for lever in ["flower_reach", "flowers_per_sting", "most_flowers", "stock_flowers"]:
			if defence.has(lever) and int(defence[lever]) <= 0:
				errors.append("defence '%s' has a %s of %d"
					% [defence_id, lever, int(defence[lever])])
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
##
## **And the fish** (task 0179). Every species names real ponds, seasons
## and day-clock hours and has a weight, is a resource with a price, and is
## in the fish group. And every pond has a catch in every season at every
## minute of the day: worked out per pond and season by laying the hours
## that apply end to end, so a gap is a pond that went quiet.
static func check_fishing(table: Dictionary, species: Dictionary = FISH_SPECIES,
		ponds: Dictionary = PONDS) -> Array:
	var errors: Array = []
	if int(table["bite_min_ticks"]) > int(table["bite_max_ticks"]):
		errors.append("fishing bites sooner than it can - min %d, max %d"
			% [table["bite_min_ticks"], table["bite_max_ticks"]])
	# **The bar** (task 0180): something to sweep, time to sweep it, and a
	# green no rod or assist widens past the bar.
	var units := int(table["bar_units"])
	if units < 10:
		errors.append("the fishing bar is only %d steps across" % units)
	if int(table["bar_ticks"]) <= 0:
		errors.append("the fishing bar gives no time to land anything")
	if int(table["misses_allowed"]) < 0 or int(table["assist_zone"]) < 0:
		errors.append("fishing forgives a negative number of misses or narrows the green")
	var assisted := int(table["assist_speed_percent"])
	if assisted < 1 or assisted > 100:
		errors.append("the assist runs the marker at %d%%" % assisted)
	var widest := 100
	for tier in TOOLS[&"rod"]:
		var percent := int((tier as Dictionary).get("zone_percent", 100))
		if percent < 50 or percent > 200:
			errors.append("a rod widens the green to %d%%" % percent)
		widest = maxi(widest, percent)
	var fish := group_members(FISH)
	for id in sorted_names(species.keys()):
		var one: Dictionary = species[id]
		if not RESOURCES.has(id) or not SELL_PRICE.has(id) or not fish.has(id):
			errors.append("fish '%s' is not a priced resource in the fish group" % id)
		for pond in one["ponds"]:
			if not ponds.has(pond):
				errors.append("fish '%s' swims in no pond called '%s'" % [id, pond])
		for season in one["seasons"]:
			if not SEASONS.has(season):
				errors.append("fish '%s' bites in no season called '%s'" % [id, season])
		var hours: Array = one["hours"]
		if int(hours[0]) > int(hours[1]) or int(hours[0]) < DAY_START_MINUTE \
				or int(hours[1]) > DAY_END_MINUTE:
			errors.append("fish '%s' bites at %s, outside the day's clock" % [id, str(hours)])
		if int(one["weight"]) < 1:
			errors.append("fish '%s' has no weight in the draw" % id)
		var hits := int(one.get("hits", 0))
		if hits < 1 or hits > 3 or int(one.get("speed", 0)) < 1 or int(one.get("zone", 0)) < 1:
			errors.append("fish '%s' needs 1-3 hits, a speed and a green" % id)
			continue
		if int(one["zone"]) * widest / 100 + int(table["assist_zone"]) > units:
			errors.append("fish '%s' has a green wider than the bar" % id)
		# **Enough passes to land it**, at the assist's pace too: each sweep
		# across the bar crosses the green once.
		var slowest := int(one["speed"]) * mini(assisted, 100) / 100
		var passes := slowest * int(table["bar_ticks"]) / TICK_HZ / maxi(units, 1)
		if passes < hits:
			errors.append("fish '%s' needs %d hits and the bar crosses the green %d times" % [id, hits, passes])
	errors.append_array(_check_legendaries(species))
	for pond in sorted_names(ponds.keys()):
		for season in SEASONS:
			var spans: Array = []
			for id in sorted_names(species.keys()):
				var one: Dictionary = species[id]
				# A legendary bites only when its `condition` holds: it covers
				# no hour of any pond.
				if StringName(one.get("tier", &"")) == &"legendary":
					continue
				if (one["ponds"] as Array).has(pond) and (one["seasons"] as Array).has(season):
					spans.append([int(one["hours"][0]), int(one["hours"][1])])
			spans.sort_custom(func(a, b) -> bool: return int(a[0]) < int(b[0]))
			var reached := DAY_START_MINUTE - 1
			for span in spans:
				if int(span[0]) > reached + 1:
					break
				reached = maxi(reached, int(span[1]))
			if reached < DAY_END_MINUTE:
				errors.append("'%s' in %s has nothing biting from minute %d" % [pond, season, reached + 1])
	return errors


## **The legendaries** (task 0182): one a season, each in one season with a
## condition from `FISH_CONDITIONS`, rarer in the draw than any common, and the
## hardest bar there is - three hits, a marker no slower and a green no wider
## than any other species'. Nothing else has a `condition`.
static func _check_legendaries(species: Dictionary) -> Array:
	var errors: Array = []
	var fastest := 0
	var narrowest := 1 << 30
	var lightest_common := 1 << 30
	for id in sorted_names(species.keys()):
		var one: Dictionary = species[id]
		if StringName(one.get("tier", &"")) == &"legendary":
			continue
		if one.has("condition"):
			errors.append("fish '%s' waits for something and is not a legendary" % id)
		fastest = maxi(fastest, int(one.get("speed", 0)))
		narrowest = mini(narrowest, int(one.get("zone", 0)))
		if StringName(one.get("tier", &"")) == &"common":
			lightest_common = mini(lightest_common, int(one["weight"]))
	var seasons: Dictionary = {}
	for id in sorted_names(species.keys()):
		var one: Dictionary = species[id]
		if StringName(one.get("tier", &"")) != &"legendary":
			continue
		if not FISH_CONDITIONS.has(StringName(one.get("condition", &""))):
			errors.append("legendary '%s' waits for nothing a cast can meet" % id)
		var own: Array = one["seasons"]
		if own.size() != 1:
			errors.append("legendary '%s' bites in %d seasons, not one" % [id, own.size()])
		for season in own:
			if seasons.has(season):
				errors.append("%s has two legendaries: '%s' and '%s'" % [season, seasons[season], id])
			seasons[season] = id
		if int(one.get("hits", 0)) != 3 or int(one.get("speed", 0)) < fastest \
				or int(one.get("zone", 1 << 30)) > narrowest:
			errors.append("legendary '%s' is not the hardest bar there is" % id)
		if int(one["weight"]) >= lightest_common:
			errors.append("legendary '%s' is drawn as often as a common" % id)
	if not seasons.is_empty() and seasons.size() != SEASONS.size():
		errors.append("%d seasons of %d have a legendary" % [seasons.size(), SEASONS.size()])
	return errors


## **The rod and the bait** (task 0181): what each rod tier and each bait
## does to the wait and to the draw. Either may shorten the wait and favour
## the rarer fish - never lengthen it or starve them - and together they
## leave the quickest bite a second away at least. A bait is a priced
## resource in the bait group, the hoe finds a worm in some cells rather
## than in all of them, and every species has a rarity.
static func check_bait(effects: Dictionary, tools: Dictionary = TOOLS,
		worm_in: int = WORM_IN, species: Dictionary = FISH_SPECIES) -> Array:
	var errors: Array = []
	var bait_group := group_members(&"bait")
	if BAITS.size() != effects.size():
		errors.append("there are %d baits to choose and %d with an effect" % [BAITS.size(), effects.size()])
	var quickest_bait := 100
	for id in sorted_names(effects.keys()):
		if not BAITS.has(id) or not RESOURCES.has(id) or not SELL_PRICE.has(id) \
				or not bait_group.has(id):
			errors.append("bait '%s' is not a priced resource in the bait group" % id)
		errors.append_array(_check_fishing_percents("bait '%s'" % id, effects[id]))
		quickest_bait = mini(quickest_bait, int((effects[id] as Dictionary).get("bite_percent", 100)))
	var quickest_rod := 100
	var rods: Array = tools[&"rod"]
	for i in rods.size():
		errors.append_array(_check_fishing_percents("rod tier %d" % i, rods[i]))
		quickest_rod = mini(quickest_rod, int((rods[i] as Dictionary).get("bite_percent", 100)))
	if int(FISHING["bite_min_ticks"]) * quickest_rod * quickest_bait / 10000 < TICK_HZ:
		errors.append("the best rod and bait bring a bite in under a second")
	if worm_in < 2:
		errors.append("the hoe finds a worm in every cell it turns")
	for id in sorted_names(species.keys()):
		if not FISH_TIERS.has(StringName((species[id] as Dictionary).get("tier", &""))):
			errors.append("fish '%s' has no rarity" % id)
	return errors


## One rod tier's or bait's two percents, in bounds: a wait of 25-100% and
## the rarer fish at 100-400% of their weight.
static func _check_fishing_percents(what: String, one: Dictionary) -> Array:
	var bite := int(one.get("bite_percent", 100))
	var rare := int(one.get("rare_percent", 100))
	if bite < 25 or bite > 100 or rare < 100 or rare > 400:
		return ["%s waits %d%% and favours the rarer fish %d%%" % [what, bite, rare]]
	return []


## What a pile of resources sells for, against a given price list.
##
## **The price list is a parameter and it has to be.** It read `SELL_PRICE`
## directly at first, which made `check_chain`'s argument decorative - the
## teeth-test handed it a table where oil was worth a dollar, the check looked
## at the real one, and the test passed by agreeing with itself.
static func _worth(amounts: Dictionary, prices: Dictionary = SELL_PRICE) -> int:
	var total := 0
	for res in sorted_names(amounts.keys()):
		total += _price_of(StringName(res), prices) * int(amounts[res])
	return total


## What one of a thing sells for: its price, or for an `ANY_OF` group its
## cheapest member's (task 0179) - which is what a cost naming the group
## will spend first.
static func _price_of(res: StringName, prices: Dictionary) -> int:
	if is_any_of(res):
		var order := pay_order(res, prices)
		return 0 if order.is_empty() else int(prices.get(order[0], 0))
	return int(prices.get(res, 0))


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
		# **And a day in a barrel pays** (task 0187): a batch that holds its
		# machine for days adds `AGED_MARGIN_PER_DAY` for each of them.
		elif recipe.has("days") and made - into < AGED_MARGIN_PER_DAY * int(recipe["days"]):
			errors.append(("'%s' adds $%d over %d mornings - not worth "
				+ "a machine's days") % [id, made - into, int(recipe["days"])])
	return errors


## The animals, and the meat they are the only source of.
static func check_livestock(animals: Dictionary, rows: Array,
		stock: Dictionary = DAILY_STOCK) -> Array:
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
		if int(animal.get("feed_per_day", -1)) < 0:
			errors.append("'%s' says nothing of what it eats" % id)
		# **Something comes of keeping it** (task 0185): produce at the door,
		# or spots to dig - a pig gives the second.
		if (animal["produces"] as Dictionary).is_empty() and int(animal.get("digs", 0)) < 1:
			errors.append("'%s' gives nothing at the door and digs nothing" % id)
		# **Every kind names its home** (task 0183), a `BUILDINGS` entry
		# with room in it, and where it comes from. Standing on the map is
		# no longer every animal's rule: one from the stall (0190) does not.
		var home := StringName(animal.get("home", &""))
		if not BUILDINGS.has(home) or int((BUILDINGS[home] as Dictionary).get("capacity", 0)) < 1:
			errors.append("'%s' lives in '%s', which is no home with room" % [id, home])
		var source := StringName(animal.get("source", &""))
		if not LIVESTOCK_SOURCES.has(source):
			errors.append("'%s' comes from '%s', which is neither the map nor the stall" % [id, source])
		if source == &"map" and _cells_of_char(rows, _char_for(id)).is_empty():
			errors.append("there is no '%s' anywhere on the farm" % id)

	# **Meat has to come from somewhere.** It is in the resource table, it has a
	# price, and a recipe turns it into the best meal in the game - and for the
	# first thirty-three tasks nothing in the world produced a single unit of
	# it.
	# **Since task 0184 the stall is a source too**: the cow gives milk and
	# the hens eggs, and the roast's meat is bought.
	var meat_had := makes_meat or int(stock.get(MEAT, 0)) > 0
	if not meat_had:
		errors.append("nothing on the farm produces meat and the stall sells none")
	# And every home houses some kind: a coop nothing lives in is a building
	# that holds nobody.
	for building in sorted_names(BUILDINGS.keys()):
		if int((BUILDINGS[building] as Dictionary).get("capacity", 0)) < 1:
			continue
		var housed := false
		for id in sorted_names(animals.keys()):
			housed = housed or StringName((animals[id] as Dictionary).get("home", &"")) == building
		if not housed:
			errors.append("'%s' has room and no animal lives in it" % building)
	for id in sorted_names(RECIPES.keys()):
		var inputs: Dictionary = (RECIPES[id] as Dictionary)["inputs"]
		if inputs.has(MEAT) and not meat_had:
			errors.append("'%s' wants meat and nothing makes any" % id)
	# **And the feed comes from somewhere**: a recipe that makes it, or the
	# stall.
	var feed_made := int(stock.get(ANIMAL_FEED, 0)) > 0
	for id in sorted_names(RECIPES.keys()):
		feed_made = feed_made or ((RECIPES[id] as Dictionary)["output"] as Dictionary).has(ANIMAL_FEED)
	if not feed_made:
		errors.append("the animals eat '%s' and nothing makes it" % ANIMAL_FEED)
	return errors


## **A defence from a kit only has a kit to come from** (task 0225): one no
## recipe made could never go down at all.
static func check_kits(defences: Dictionary, recipes: Dictionary) -> Array:
	var errors: Array = []
	for id in sorted_names(defences.keys()):
		if not bool((defences[id] as Dictionary).get("kit_only", false)):
			continue
		var made := false
		for recipe_id in sorted_names(recipes.keys()):
			made = made or ((recipes[recipe_id] as Dictionary)["output"] as Dictionary).has(id)
		if not made:
			errors.append("defence '%s' goes down from a kit only and nothing makes one" % id)
	return errors


## Every round a tower fires is a round the farm can make.
##
## The same bug as the meat of task 0034, one table along: a tower can declare
## it fires anything, and until this existed nothing asked whether the player
## had any way of producing it. A tower whose ammunition cannot be made is a
## tower that is permanently on its weak shot, and nothing in the game would
## say why.
static func check_ammo(defences: Dictionary, recipes: Dictionary,
		crops: Dictionary = CROPS) -> Array:
	var errors: Array = []
	var makeable: Dictionary = {}
	for id in sorted_names(recipes.keys()):
		for res in sorted_names(((recipes[id] as Dictionary)["output"]
				as Dictionary).keys()):
			makeable[res] = true
	# **Or grown** (task 0227): the catapult's pumpkins come out of a field,
	# not off a bench, and a field is as sure a road to a proper shot as a
	# recipe is. Which season it grows in is `check_seasonal_supply`'s to say.
	for crop in sorted_names(crops.keys()):
		makeable[crop] = true

	for id in sorted_names(defences.keys()):
		var defence: Dictionary = defences[id]
		if not defence.has("ammo"):
			continue
		for res in sorted_names((defence["ammo"] as Dictionary).keys()):
			if not RESOURCES.has(res):
				errors.append("'%s' fires unknown '%s'" % [id, res])
			elif not makeable.has(res):
				errors.append(("'%s' fires '%s' and no recipe makes any nor any "
					+ "field grows it - that tower can never fire a proper shot")
					% [id, res])
	return errors


## The inventory grouping. Nothing named twice, nothing named that is not a
## resource. Missing membership is a named error, including the old catch-all.
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
	for id in resources:
		if not seen.has(id) or seen[id] == GROUP_OTHER:
			errors.append("resource '%s' has no inventory group" % id)
	return errors


## Every tangible resource must declare what it sells for.
static func check_resource_prices(resources: Array, prices: Dictionary) -> Array:
	var errors: Array = []
	for id in resources:
		if id not in [MONEY, ENERGY, TECH] and not prices.has(id):
			errors.append("resource '%s' has no sale price" % id)
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
		# **An animal** (task 0190): a price of its own, and nothing to be
		# made buying it and selling it back.
		if LIVESTOCK.has(id):
			var price := int(ANIMAL_PRICE.get(id, 0))
			if price <= 0:
				errors.append("the stall sells a '%s' at no price" % id)
			elif price <= int(prices.get(id, 0)):
				errors.append(("a '%s' costs $%d and sells for $%d - buy it and "
					+ "sell it back and you are richer") % [id, price, int(prices[id])])
		# **A tool upgrade** (task 0190): the workshop's recipe prices it.
		elif is_tool_upgrade(id):
			pass
		elif not RESOURCES.has(id):
			errors.append("the stall stocks '%s', which is not a resource" % id)
		elif not prices.has(id):
			errors.append("the stall stocks '%s', which has no price" % id)
		if int(stock[id]) <= 0:
			errors.append("the stall stocks no '%s' at all" % id)
	# Every animal the farm keeps is one the stall can sell.
	for kind in sorted_names(LIVESTOCK.keys()):
		if int(ANIMAL_PRICE.get(kind, 0)) <= 0 or int(ANIMAL_STOCK.get(kind, 0)) <= 0:
			errors.append("the stall has no '%s' to sell" % kind)

	for id in sorted_names(prices.keys()):
		var sells_for := int(prices[id])
		var costs := int(ceil(float(sells_for) * markup))
		var crop := StringName(String(id).trim_suffix("_seed"))
		if String(id).ends_with("_seed") and CROPS.has(crop):
			costs = int(CROPS[crop]["seed_cost"])
		if costs <= sells_for:
			errors.append(("'%s' costs $%d and sells for $%d - buy it and sell "
				+ "it back and you are richer") % [id, costs, sells_for])
	return errors


## **The stall's shelf on a day of this season** (task 0190): the materials,
## the season's packets, the animals and one of each tool upgrade. What
## `Shop` puts out each morning, and what `validate()` checks for each season.
static func stall_stock(season: StringName) -> Dictionary:
	var out: Dictionary = DAILY_STOCK.duplicate()
	out.merge(SEASON_STOCK.get(season, {}) as Dictionary)
	out.merge(ANIMAL_STOCK)
	for id in tool_upgrades():
		out[id] = UPGRADE_STOCK
	return out


## Whether the stall's shelf in this season has this on it, without building
## the shelf (task 0192): what `stall_stock(season).has(id)` says.
static func on_the_stall(season: StringName, id: StringName) -> bool:
	return DAILY_STOCK.has(id) or (SEASON_STOCK.get(season, {}) as Dictionary).has(id) \
		or ANIMAL_STOCK.has(id) or is_tool_upgrade(id)


## The workshop's tool upgrade recipes, in name order (task 0190).
static func tool_upgrades() -> Array:
	var out: Array = []
	for id in sorted_names(RECIPES.keys()):
		if is_tool_upgrade(id):
			out.append(id)
	return out


## Whether this is a tool upgrade's recipe id.
static func is_tool_upgrade(id: StringName) -> bool:
	if not RECIPES.has(id):
		return false
	var output: Dictionary = (RECIPES[id] as Dictionary)["output"]
	return output.size() == 1 and not tool_output(StringName(output.keys()[0])).is_empty()


## **Every season's packets are its own** (task 0190): each a crop's packet
## sown in that season, every season named, and none where nothing grows.
static func check_season_stock(table: Dictionary) -> Array:
	var errors: Array = []
	for season in SEASONS:
		if not table.has(season):
			errors.append("the stall says nothing about %s" % season)
	for season in sorted_names(table.keys()):
		if not SEASONS.has(season):
			errors.append("the stall stocks for '%s', which is no season" % season)
			continue
		for id in sorted_names((table[season] as Dictionary).keys()):
			# **Feed** (task 0193): straw and hay, which the farm cannot make
			# before its wheat comes in.
			if id == STRAW or id == ANIMAL_FEED:
				continue
			var crop := StringName(String(id).trim_suffix("_seed"))
			if not String(id).ends_with("_seed") or not CROPS.has(crop):
				errors.append("%s's shelf has '%s', which is no packet" % [season, id])
			elif not (CROPS[crop]["seasons"] as Array).has(season):
				errors.append("%s's shelf has '%s', not sown in %s" % [season, id, season])
		if NO_GROWTH_SEASONS.has(season) and not (table[season] as Dictionary).is_empty():
			errors.append("%s has packets, and nothing grows then" % season)
	return errors


## **Every season can make what it needs** (task 0193): in each season,
## everything unlocked by then - every defence's price, kit, rounds and
## tower levels, the house's repair and the animals' feed - can be made from
## what that season has (`seasonal_supply`), walked through the recipes. The
## tables are arguments, so a test can hand it a broken one. An error names
## the season, the thing it cannot make, and everything that wanted it.
static func check_seasonal_supply(defences: Dictionary, recipes: Dictionary,
		season_stock: Dictionary = SEASON_STOCK, daily_stock: Dictionary = DAILY_STOCK) -> Array:
	var errors: Array = []
	for id in sorted_names(defences.keys()):
		if not SEASONS.has(defence_season(defences[id])):
			errors.append("'%s' unlocks in '%s', which is no season" % [id, defence_season(defences[id])])
	for season in SEASONS:
		var have := seasonal_supply(season, recipes, season_stock, daily_stock)
		var needs := seasonal_needs(season, defences, recipes)
		for res in sorted_names(needs.keys()):
			if not have.has(res):
				var who: Array = needs[res]
				var named := ", ".join(who.slice(0, who.size() - 1)) + " and " + String(who.back()) \
					if who.size() > 1 else String(who[0])
				errors.append("%s cannot make %s, for %s" % [season, res, named])
	return errors


## **The day's targets and the farm they assume** (task 0194): a band for
## every season, low under high, neither end falling from one season to the
## next; and a farm of known tools, animals and machines - every machine's
## recipe one that takes days, which `Economy.artisan` counts by the morning.
static func check_day_targets(targets: Dictionary, farm: Dictionary) -> Array:
	var errors: Array = []
	var low := 0
	var high := 0
	for season in SEASONS:
		var band: Array = targets.get(season, [])
		if band.size() != 2 or int(band[0]) <= 0 or int(band[0]) >= int(band[1]):
			errors.append("%s's day has no band of money, low under high" % season)
			continue
		if int(band[0]) < low or int(band[1]) < high:
			errors.append("%s's day asks less than the season before it" % season)
		low = int(band[0])
		high = int(band[1])
	for season in sorted_names((farm.get("tool_tier", {}) as Dictionary).keys()):
		var tier := int(farm["tool_tier"][season])
		if tier < 0 or tier >= (TOOLS[&"rod"] as Array).size():
			errors.append("%s's tools are at no tier there is" % season)
	for season in sorted_names((farm.get("herd", {}) as Dictionary).keys()):
		for kind in sorted_names((farm["herd"][season] as Dictionary).keys()):
			if not LIVESTOCK.has(kind):
				errors.append("%s's herd has '%s', which is no animal" % [season, kind])
	for season in sorted_names((farm.get("machines", {}) as Dictionary).keys()):
		for id in sorted_names((farm["machines"][season] as Dictionary).keys()):
			if not RECIPES.has(id) or int((RECIPES[id] as Dictionary).get("days", 0)) <= 0:
				errors.append("%s's machines run '%s', which is no recipe that takes days" % [season, id])
	return errors


## The season a defence opens in (task 0193; a rule since task 0234): its
## `season`, or spring.
static func defence_season(entry: Dictionary) -> StringName:
	return StringName(entry.get("season", SEASONS[0]))


## **What a season needs** (task 0193), as `{resource: [who wants it]}`:
## the price, the kit, the rounds and the tower levels of every defence
## unlocked by then, what a hit point of house costs to mend, and hay for
## the animals (every kind is the stall's to sell all year).
static func seasonal_needs(season: StringName, defences: Dictionary, recipes: Dictionary) -> Dictionary:
	var by := SEASONS.find(season)
	var needs := {}
	for id in sorted_names(defences.keys()):
		var entry: Dictionary = defences[id]
		if SEASONS.find(defence_season(entry)) > by:
			continue
		var wanted: Array = [entry.get("cost", {}), entry.get("ammo", {})]
		for level in (TOWER_LEVELS.get(id, []) as Array):
			wanted.append((level as Dictionary).get("cost", {}))
		for recipe_id in sorted_names(recipes.keys()):
			if ((recipes[recipe_id] as Dictionary)["output"] as Dictionary).has(id):
				wanted.append((recipes[recipe_id] as Dictionary)["inputs"])
		for table in wanted:
			for res in sorted_names((table as Dictionary).keys()):
				_wanted_by(needs, res, "the %s" % id)
	for res in sorted_names(REPAIR_COST_PER_HP.keys()):
		_wanted_by(needs, res, "mending the house")
	for kind in sorted_names(LIVESTOCK.keys()):
		if int((LIVESTOCK[kind] as Dictionary).get("feed_per_day", 0)) > 0:
			_wanted_by(needs, ANIMAL_FEED, "the %s" % kind)
	return needs


static func _wanted_by(needs: Dictionary, res: StringName, who: String) -> void:
	if not needs.has(res):
		needs[res] = []
	if not (needs[res] as Array).has(who):
		(needs[res] as Array).append(who)


## **What a season has** (task 0193), as `{resource: where it comes from}`:
## the crops sown in it or before it and what their harvest leaves (wheat's
## straw), fish, what the farm's nodes give from their opening season, and
## what the stall sells then that is not a crop - a crop bought out of its
## season is still a crop whose season has not come. Then the recipes and
## the fed animals, to a fixed point; a made thing's source is the recipe's
## id, the first in name order that could make it.
static func seasonal_supply(season: StringName, recipes: Dictionary,
		season_stock: Dictionary = SEASON_STOCK, daily_stock: Dictionary = DAILY_STOCK) -> Dictionary:
	var by := SEASONS.find(season)
	var have := {MONEY: "money", FISH: "fishing"}
	for crop in sorted_names(CROPS.keys()):
		var first := SEASONS.size()
		for sown in (CROPS[crop]["seasons"] as Array):
			first = mini(first, SEASONS.find(sown))
		if first > by:
			continue
		have[crop] = "%s's field" % SEASONS[first]
		for res in sorted_names((CROPS[crop].get("byproduct", {}) as Dictionary).keys()):
			if not have.has(res):
				have[res] = "the %s harvest" % crop
	for node in sorted_names(GATHERING.keys()):
		var entry: Dictionary = GATHERING[node]
		if SEASONS.find(StringName(entry.get("first_season", SEASONS[0]))) > by:
			continue
		for res in sorted_names((entry["yield"] as Dictionary).keys()):
			if not have.has(res):
				have[res] = "the %s" % node
	var shelf: Dictionary = daily_stock.duplicate()
	shelf.merge(season_stock.get(season, {}) as Dictionary)
	for res in sorted_names(shelf.keys()):
		if RESOURCES.has(res) and not CROPS.has(res) and not have.has(res):
			have[res] = "the stall"
	var grew := true
	while grew:
		grew = false
		for id in sorted_names(recipes.keys()):
			var recipe: Dictionary = recipes[id]
			var ready := true
			for res in sorted_names((recipe["inputs"] as Dictionary).keys()):
				ready = ready and have.has(res)
			if not ready:
				continue
			for res in sorted_names((recipe["output"] as Dictionary).keys()):
				if not have.has(res):
					have[res] = String(id)
					grew = true
		for kind in sorted_names(LIVESTOCK.keys()):
			var animal: Dictionary = LIVESTOCK[kind]
			# **The map's loose ones graze** (task 0194): they are never fed
			# and never hungry (`Livestock`), so they give without hay.
			var grazes := StringName(animal.get("source", &"")) == &"map"
			if int(animal.get("feed_per_day", 0)) > 0 and not have.has(ANIMAL_FEED) and not grazes:
				continue
			for res in sorted_names((animal["produces"] as Dictionary).keys()):
				if not have.has(res):
					have[res] = ("a fed %s" if have.has(ANIMAL_FEED) else "a grazing %s") % kind
					grew = true
	return have


## **The peddler's hours** (task 0190): open after the day starts, closed
## before dusk, and open for some of it.
static func check_stall_hours(opens: int, closes: int) -> Array:
	var errors: Array = []
	if opens < DAY_START_MINUTE or closes > DUSK_MINUTE or opens >= closes:
		errors.append("the stall opens at %d and closes at %d - it has to keep hours inside %d-%d"
			% [opens, closes, DAY_START_MINUTE, DUSK_MINUTE])
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


## **The tips' table** (task 0195): each tip once, with a line that is a
## `TIP_` key - its words are `tools/i18n_check.py`'s to measure, as the
## tutorial's are - and a short one. The display times run in order.
## **The tree's floors hold together** (task 0220):
## - every `season` is a season, 0 to 3;
## - a node never needs one from a later floor;
## - every branch has a node on every floor;
## - every number a node gives is a `_percent` (none is 100) or a `_bonus`
##   (none is 0);
## - a number given on two floors moves the same way on both, and the later
##   floor's is the stronger - which is what lets `Tech.bonus` take the
##   stronger and mean the later.
static func check_tech_tree(tree: Array) -> Array:
	var errors: Array = []
	var season_of := {}
	var floors := {}
	for row in tree:
		var one: Dictionary = row
		var season := int(one.get("season", -1))
		if season < 0 or season >= SEASONS.size():
			errors.append("tech node '%s' is on floor %d: a season is 0-%d" % [one["id"], season, SEASONS.size() - 1])
		season_of[StringName(one["id"])] = season
		var mine: Array = floors.get(StringName(one["branch"]), [])
		if not mine.has(season):
			mine.append(season)
		floors[StringName(one["branch"])] = mine
	for row in tree:
		var one: Dictionary = row
		for needed in (one["needs"] as Array):
			if int(season_of.get(StringName(needed), -1)) > int(one.get("season", -1)):
				errors.append("tech node '%s' needs '%s', which is on a later floor" % [one["id"], needed])
	for branch in sorted_names(floors.keys()):
		for season in SEASONS.size():
			if not (floors[branch] as Array).has(season):
				errors.append("the %s branch has nothing on the %s floor" % [branch, SEASONS[season]])
	# The numbers, floor by floor: one key's values all on one side of
	# having none, and each later floor's farther out.
	var given := {}
	for row in tree:
		var one: Dictionary = row
		for key in sorted_names((one["gives"] as Dictionary).keys()):
			var neutral := 100 if String(key).ends_with("_percent") else 0
			if not String(key).ends_with("_percent") and not String(key).ends_with("_bonus"):
				errors.append("tech node '%s' gives '%s': a number is a _percent or a _bonus" % [one["id"], key])
				continue
			var value := int(one["gives"][key])
			if value == neutral:
				errors.append("tech node '%s' gives '%s' %d, which is having none" % [one["id"], key, value])
				continue
			var earlier: Array = given.get(key, [])
			for seen in earlier:
				var was: Array = seen
				if (value > neutral) != (int(was[1]) > neutral):
					errors.append("'%s' and '%s' move '%s' opposite ways" % [was[0], one["id"], key])
				elif int(was[2]) >= int(one.get("season", 0)):
					errors.append("'%s' and '%s' give '%s' on the same floor" % [was[0], one["id"], key])
				elif absi(value - neutral) <= absi(int(was[1]) - neutral):
					errors.append("'%s' gives '%s' no stronger than '%s' on an earlier floor" % [one["id"], key, was[0]])
			earlier.append([one["id"], value, int(one.get("season", 0))])
			given[key] = earlier
	return errors


## **The powers hold together** (task 0233): each waits for something and is
## given by exactly one node of the tree; the bell stops for something, a
## boss's share a share; the dog bites for something, round some cells, at
## some speed, with a damage type there is; the repair puts back a share.
static func check_powers(powers: Dictionary, tree: Array) -> Array:
	var errors: Array = []
	for id in sorted_names(powers.keys()):
		var power: Dictionary = powers[id]
		if int(power.get("cooldown_ticks", 0)) <= 0:
			errors.append("power '%s' waits for nothing" % id)
		var givers: Array = []
		for row in tree:
			if ((row as Dictionary)["gives"] as Dictionary).has("%s_bonus" % id):
				givers.append((row as Dictionary)["id"])
		if givers.size() != 1:
			errors.append("power '%s' is given by %d nodes of the tree, not one" % [id, givers.size()])
	var bell: Dictionary = powers.get(&"farm_bell", {})
	if int(bell.get("stun_ticks", 0)) <= 0:
		errors.append("the farm bell stops nobody")
	var share := int(bell.get("boss_stun_percent", -1))
	if share < 0 or share > 100:
		errors.append("the farm bell stops a boss for %d%% of it" % share)
	var dog: Dictionary = powers.get(&"call_dog", {})
	if int(dog.get("damage", 0)) <= 0 or int(dog.get("radius_tiles", 0)) <= 0 \
			or int(dog.get("ticks_per_tile", 0)) <= 0 or int(dog.get("bite_ticks", 0)) <= 0:
		errors.append("the dog bites for nothing, round no cells, or runs at no speed")
	if not DAMAGE_TYPES.has(StringName(dog.get("damage_type", &""))):
		errors.append("the dog bites with '%s', which is not a damage type" % dog.get("damage_type", &""))
	var mend := int((powers.get(&"emergency_repair", {}) as Dictionary).get("restore_percent", 0))
	if mend <= 0 or mend > 100:
		errors.append("the emergency repair puts back %d%%" % mend)
	return errors


## **The night's purse and its essence** (task 0219): a Full Moon never pays
## less essence than an ordinary night, and the bounty is a share of the
## kills' worth between none of it and all of it.
static func check_rewards(rewards: Dictionary) -> Array:
	var errors: Array = []
	var moon := int(rewards.get("full_moon_essence_percent", 100))
	if moon < 100:
		errors.append("a Full Moon pays %d%% of a night's essence: never less than 100" % moon)
	var share := int(rewards.get("bounty_percent", 100))
	if share < 0 or share > 100:
		errors.append("the bounty pays %d%% of the kills' worth: keep it within 0-100" % share)
	var blood := int(rewards.get("blood_moon_essence", 1))
	if blood < 1:
		errors.append("a Blood Moon pays %d essence: it needs at least one" % blood)
	return errors


## **The night's leftovers hold together** (task 0221): a pile holds
## something, a Full Moon leaves something, a stone trades for something,
## a pile lies a morning at least and looks a tile at least for ground -
## and no body leaves more bones than a pile holds, which would throw the
## rest away as it fell.
static func check_loot(cap: int, stones: int, rate: int, fade: int,
		reach: int, enemies: Dictionary, every: int = BONES_EVERY) -> Array:
	var errors: Array = []
	if every <= 0:
		errors.append("one body in %d leaves its bones: it needs at least one" % every)
	if cap <= 0:
		errors.append("a pile holds %d of a thing: it needs at least one" % cap)
	if stones <= 0:
		errors.append("a Full Moon leaves %d moon stones: it needs at least one" % stones)
	if rate <= 0:
		errors.append("a moon stone trades for %d essence: it needs at least one" % rate)
	if fade <= 0:
		errors.append("a pile lies %d mornings: it needs at least one" % fade)
	if reach <= 0:
		errors.append("a pile looks %d tiles for ground: it needs at least one" % reach)
	for id in sorted_names(enemies.keys()):
		var bones := int((enemies[id] as Dictionary).get("bones", 0))
		if bones < 0 or bones > cap:
			errors.append("enemy '%s' leaves %d bones and a pile holds %d"
				% [id, bones, cap])
	return errors


static func check_tips(tips: Array) -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	for entry in tips:
		var tip: Dictionary = entry
		var id := StringName(tip.get("id", &""))
		if id == &"" or seen.has(id):
			errors.append("tip '%s' is nameless or appears twice" % id)
		seen[id] = true
		var line := String(tip.get("line", ""))
		if not line.begins_with("TIP_") or line.length() > MAX_TUTORIAL_LINE_LENGTH:
			errors.append("tip '%s' names '%s', which is no short TIP_ key" % [id, line])
	if TIP_MIN_SECONDS <= 0 or TIP_MIN_SECONDS > TIP_SECONDS:
		errors.append("a tip stays %d-%d seconds, which is no range" % [TIP_MIN_SECONDS, TIP_SECONDS])
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
		# **A flyer is on no road** (task 0249): it neither goes round what
		# was built nor goes for it, and its speed in the air is no measure of
		# the fastest thing that stops for a wall - a fast crow counted there
		# would fail the runner.
		if bool(one.get("flies", false)):
			if bool(one.get("ignores_structures", false)) or bool(one.get("targets_structures", false)):
				errors.append("enemy '%s' flies and says how it walks round or at what was built" % id)
			if int(one.get("peck_ticks", 0)) <= 0:
				errors.append("enemy '%s' flies and eats a crop in no time" % id)
		elif not bool(one.get("ignores_structures", false)):
			fastest = mini(fastest, int(one.get("ticks_per_tile", 1 << 30)))
		# **A boss is never turned by straw** (task 0224): the season's
		# last night is not won with a decoy.
		if bool(one.get("is_boss", false)) and bool(one.get("lurable", false)):
			errors.append("enemy '%s' is a boss and can be lured" % id)
		errors.append_array(_check_spit(id, one))
		errors.append_array(_check_chill(id, one))
		errors.append_array(_check_charge(id, one))
		errors.append_array(_check_summon(id, one, enemies))
		errors.append_array(_check_freeze(id, one))
		# **A cluster is at least one** (task 0248): a release of nothing
		# would count bodies it never sent.
		if one.has("cluster") and int(one["cluster"]) < 1:
			errors.append("enemy '%s' comes %d at a time: at least one" % [id, int(one["cluster"])])

	for id in sorted_names(enemies.keys()):
		var one: Dictionary = enemies[id]
		if not bool(one.get("ignores_structures", false)):
			continue
		if int(one.get("ticks_per_tile", 0)) >= fastest:
			errors.append(("enemy '%s' ignores structures without being "
				+ "faster than the ones that do not - it would be a slow "
				+ "zombie taking the long way round") % id)
	return errors


## **A freezer's numbers** (task 0255), for an enemy that declares any
## `freeze_` lever or an `aura_tiles`: all three and the cast it runs on
## (`telegraph_ticks`), none of them zero.
static func _check_freeze(id: StringName, one: Dictionary) -> Array:
	var errors: Array = []
	if not (one.has("freeze_every_ticks") or one.has("freeze_ticks") or one.has("aura_tiles")):
		return errors
	for field in ["freeze_every_ticks", "aura_tiles", "freeze_ticks", "telegraph_ticks"]:
		if int(one.get(field, 0)) <= 0:
			errors.append("enemy '%s' freezes with no %s" % [id, field])
	return errors


## **A summoner's numbers** (task 0254), for an enemy that `summons`: a kind
## in the table that flies, a cast (`telegraph_ticks`) and a wait between
## casts, a flock of at least one and no more than `SUMMON_OFFSETS` has cells
## for, and a night's cap no smaller than one flock.
static func _check_summon(id: StringName, one: Dictionary, enemies: Dictionary) -> Array:
	var errors: Array = []
	if not one.has("summons"):
		return errors
	var kind := StringName(one["summons"])
	if not enemies.has(kind) or not bool((enemies[kind] as Dictionary).get("flies", false)):
		errors.append("enemy '%s' summons '%s', which does not fly" % [id, kind])
	for field in ["summon_every_ticks", "flock_size", "summon_cap", "telegraph_ticks"]:
		if int(one.get(field, 0)) <= 0:
			errors.append("enemy '%s' summons with no %s" % [id, field])
	if int(one.get("flock_size", 0)) > SUMMON_OFFSETS.size():
		errors.append("enemy '%s' summons a flock of %d and SUMMON_OFFSETS has %d cells"
			% [id, int(one.get("flock_size", 0)), SUMMON_OFFSETS.size()])
	if int(one.get("summon_cap", 0)) < int(one.get("flock_size", 0)):
		errors.append("enemy '%s' may summon %d a night, less than one flock of %d"
			% [id, int(one.get("summon_cap", 0)), int(one.get("flock_size", 0))])
	return errors


## **A charger's numbers** (task 0253), for an enemy that declares any
## `charge_` lever or a `crush_damage`: every one of them and the wind-up it
## runs on (`telegraph_ticks`), none of them zero, and a charge quicker than
## its walk.
static func _check_charge(id: StringName, one: Dictionary) -> Array:
	var errors: Array = []
	var charges := one.has("crush_damage")
	for key in sorted_names(one.keys()):
		charges = charges or String(key).begins_with("charge_")
	if not charges:
		return errors
	for field in ["charge_every_ticks", "charge_tiles", "charge_ticks_per_tile", "crush_damage",
			"telegraph_ticks"]:
		if int(one.get(field, 0)) <= 0:
			errors.append("enemy '%s' charges with no %s" % [id, field])
	if int(one.get("charge_ticks_per_tile", 0)) >= int(one.get("ticks_per_tile", 0)):
		errors.append("enemy '%s' charges no faster than it walks" % id)
	return errors


## **A frost zombie's burst** (task 0251), for an enemy that declares any
## `chill_` lever: a burst that reaches at least a tile and lasts at least a
## tick, and a chilled reload between 1 and 99 percent as fast - 100 would
## chill nothing, and nothing would stop a tower for good.
static func _check_chill(id: StringName, one: Dictionary) -> Array:
	var errors: Array = []
	var chills := false
	for key in sorted_names(one.keys()):
		chills = chills or String(key).begins_with("chill_")
	if not chills:
		return errors
	if int(one.get("chill_tiles", 0)) <= 0:
		errors.append("enemy '%s' bursts over no tiles" % id)
	if int(one.get("chill_ticks", 0)) <= 0:
		errors.append("enemy '%s' chills for no time" % id)
	var percent := int(one.get("chill_reload_percent", 0))
	if percent < 1 or percent > 99:
		errors.append("enemy '%s' leaves a chilled tower reloading at %d%% - it wants 1-99"
			% [id, percent])
	return errors


## **A spitter's numbers** (task 0247), for an enemy that declares any
## `spit_` lever: all four of them, and a range short of the gun tower's
## base `range` - so a tower can always answer it.
static func _check_spit(id: StringName, one: Dictionary) -> Array:
	var errors: Array = []
	var spits := false
	for key in sorted_names(one.keys()):
		spits = spits or String(key).begins_with("spit_")
	if not spits:
		return errors
	for field in ["spit_damage", "spit_every_ticks", "spit_tiles_per_second"]:
		if int(one.get(field, 0)) <= 0:
			errors.append("enemy '%s' spits with no %s" % [id, field])
	var reach := int(one.get("spit_range", 0))
	var gun := int((DEFENCES[&"gun_tower"] as Dictionary).get("range", 0))
	if reach <= 0:
		errors.append("enemy '%s' spits from no tiles" % id)
	elif reach >= gun:
		errors.append(("enemy '%s' spits from %d tiles, as far as a gun tower "
			+ "reaches (%d) - no tower could answer it") % [id, reach, gun])
	return errors


## **The year's tables hold together** (task 0270). Takes them as arguments,
## so a test can hand it a broken copy. It refuses:
## - in a template: a side its season has not opened (0157), a boss or an
##   unknown kind in its mix (the boss row is 0153's), a size that falls or a
##   gap that grows across the season (0060's curve rules), a join day outside
##   the season;
## - a key night outside the year or on a calm date, a key night naming a
##   boss, an `event` that is unknown or that `Weather`'s own rules forbid,
##   and every per-record rule (`check_record`);
## - a Full Moon with no key night;
## - and, for the curve past the year, what it always refused.
static func check_nights(templates: Array, key_nights: Dictionary) -> Array:
	var errors: Array = []
	if templates.size() != SEASONS.size():
		errors.append("%d season templates for %d seasons" % [templates.size(), SEASONS.size()])
	for t in templates.size():
		if typeof(templates[t]) != TYPE_DICTIONARY:
			errors.append("season template %d is not a record" % t)
			continue
		var template: Dictionary = templates[t]
		var season := String(SEASONS[t % SEASONS.size()])
		var open: Array = SIDES_BY_SEASON[t % SIDES_BY_SEASON.size()] if not SIDES_BY_SEASON.is_empty() else [0]
		var sides: Array = template.get("sides", [])
		if sides.is_empty():
			errors.append("the %s template deals from no side" % season)
		for pair in sides:
			if not (pair is Array) or (pair as Array).size() != 2:
				errors.append("the %s template's side %s is not [side, the day it joins]" % [season, str(pair)])
				continue
			if not open.has(int(pair[0])):
				errors.append("the %s template comes from side %d, which its season has not opened"
					% [season, int(pair[0])])
			if int(pair[1]) < 1 or int(pair[1]) > SEASON_DAYS:
				errors.append("the %s template's side %d joins on day %d, outside 1-%d"
					% [season, int(pair[0]), int(pair[1]), SEASON_DAYS])
		var mix: Dictionary = template.get("mix", {})
		if mix.is_empty():
			errors.append("the %s template mixes nothing" % season)
		for kind in sorted_names(mix.keys()):
			if not ENEMIES.has(kind):
				errors.append("the %s template mixes '%s', which is not an enemy" % [season, kind])
				continue
			if bool((ENEMIES[kind] as Dictionary).get("is_boss", false)):
				errors.append("the %s template mixes '%s', a boss - the boss row is 0153's" % [season, kind])
			var pair: Variant = mix[kind]
			if not (pair is Array) or (pair as Array).size() != 2 or int(pair[0]) < 1 \
					or int(pair[1]) < 1 or int(pair[1]) > SEASON_DAYS:
				errors.append("the %s template's '%s' is not [a weight of one or more, a day of the season]"
					% [season, kind])
		var pairs := {}
		for field in ["size", "waves", "gap_ticks"]:
			var pair: Variant = template.get(field, [])
			if not (pair is Array) or (pair as Array).size() != 2:
				errors.append("the %s template has no %s for its second and thirteenth day" % [season, field])
			else:
				pairs[field] = [int(pair[0]), int(pair[1])]
		if pairs.has("size") and (int(pairs["size"][0]) < 1 or int(pairs["size"][1]) < int(pairs["size"][0])):
			errors.append("the %s template's size falls across its season: %d to %d"
				% [season, int(pairs["size"][0]), int(pairs["size"][1])])
		if pairs.has("waves") and (int(pairs["waves"][0]) < 1 or int(pairs["waves"][1]) < int(pairs["waves"][0])):
			errors.append("the %s template's waves fall across its season: %d to %d"
				% [season, int(pairs["waves"][0]), int(pairs["waves"][1])])
		if pairs.has("gap_ticks") and (int(pairs["gap_ticks"][1]) < 0
				or int(pairs["gap_ticks"][1]) > int(pairs["gap_ticks"][0])):
			errors.append("the %s template's gap grows across its season: %d to %d"
				% [season, int(pairs["gap_ticks"][0]), int(pairs["gap_ticks"][1])])

	var year := SEASONS.size() * SEASON_DAYS
	for key in key_nights.keys():
		if typeof(key) != TYPE_INT:
			errors.append("a key night is filed under '%s', not a day" % str(key))
	var days: Array = []
	for key in key_nights.keys():
		if typeof(key) == TYPE_INT:
			days.append(int(key))
	days.sort()
	for day in days:
		if day < 1 or day > year:
			errors.append("a key night on day %d, outside 1-%d" % [day, year])
			continue
		if Calendar.is_calm(day):
			errors.append("a key night on day %d, a calm date" % day)
		if typeof(key_nights[day]) != TYPE_DICTIONARY:
			errors.append("the key night of day %d is not a record" % day)
			continue
		var one: Dictionary = key_nights[day]
		for row in (one.get("waves", []) as Array):
			if (row is Array) and (row as Array).size() >= 1 and ENEMIES.has((row as Array)[0]) \
					and bool((ENEMIES[(row as Array)[0]] as Dictionary).get("is_boss", false)):
				errors.append("the key night of day %d names a boss, '%s' - the boss row is 0153's"
					% [day, (row as Array)[0]])
		# **A pin keeps the weather's own rules** (0256, 0257): a real event,
		# never on the game's first night, never before the season
		# `NIGHT_EVENT_FIRST_SEASON` says it rises, and no Blood Moon on the
		# moon's own nights. `&""` forbids, and is always allowed.
		if one.has("event"):
			var event := StringName(one["event"])
			var rises := SEASONS.find(StringName(NIGHT_EVENT_FIRST_SEASON.get(event, SEASONS[0])))
			if event != &"" and not Weather.EVENTS.has(event):
				errors.append("the key night of day %d pins '%s', which is no event" % [day, event])
			elif event != &"" and day <= 1:
				errors.append("the key night of day %d pins '%s' on the game's first night" % [day, event])
			elif event != &"" and Calendar.season_of(day) < rises:
				errors.append("the key night of day %d pins '%s' before %s, when it rises"
					% [day, event, NIGHT_EVENT_FIRST_SEASON[event]])
			elif event == Weather.BLOOD_MOON and (Calendar.is_boss_night(day) or Calendar.is_full_moon(day)):
				errors.append("the key night of day %d pins a Blood Moon on the moon's own night" % day)
		errors.append_array(check_record(one, day))
	for day in range(1, year + 1):
		if Calendar.is_full_moon(day) and not key_nights.has(day):
			errors.append("day %d is a Full Moon with no key night" % day)

	# **The curve past the year may not invent an enemy**, which is task
	# 0070's own requirement, and may not name a boss: one rolled out of the
	# weighted mix would turn up on an ordinary night.
	var mix: Dictionary = ENDLESS["mix"]
	if mix.is_empty():
		errors.append("the endless mix is empty, so the night past the year sends nothing")
	for kind in sorted_names(mix.keys()):
		if not ENEMIES.has(kind):
			errors.append("the endless mix names '%s', which is not an enemy" % kind)
			continue
		if bool((ENEMIES[kind] as Dictionary).get("is_boss", false)):
			errors.append("the endless mix names '%s', which is a boss - " % kind
				+ "bosses come from giant_every, not from the bag")
		var pair: Variant = mix[kind]
		if not (pair is Array) or (pair as Array).size() != 2:
			errors.append("the endless mix entry for '%s' is not [weight, drift]" % kind)
	for field in ["growth_percent", "waves", "extra_wave_every", "gap_ticks",
			"giant_every", "giant_extra_every", "mix_settles_after"]:
		if not ENDLESS.has(field):
			errors.append("the endless curve has no '%s'" % field)
		elif int(ENDLESS.get(field, 0)) < 0:
			errors.append("the endless curve's '%s' is negative" % field)
	for field in ["waves", "extra_wave_every", "giant_every", "giant_extra_every"]:
		if int(ENDLESS.get(field, 0)) < 1:
			errors.append("the endless curve's '%s' must be at least one, " % field
				+ "or it divides by zero or sends nothing")
	return errors


## **The rules every night's record keeps** (tasks 0059, 0137, 0157 and
## 0270): a key night as written, a made one, and the record a date fights.
## One function, so a made night is held to exactly what a written one is:
## its fields, waves of a known kind from a real side its date has open, an
## empty list only on a calm night, and everything sent `DAWN_MARGIN_TICKS`
## before dawn.
static func check_record(one: Dictionary, day: int) -> Array:
	var errors: Array = []
	if one.is_empty():
		errors.append("night %d has no record" % day)
		return errors
	# `gap_ticks` is not in this list: a night that does not name one takes
	# `WAVE_GAP_TICKS`, which is what that lever is for.
	for field in ["waves", "note", "opening_ticks"]:
		if not one.has(field):
			errors.append("night %d has no '%s'" % [day, field])
	if not one.has("waves"):
		return errors
	if int(one.get("opening_ticks", -1)) < 0 or int(one.get("gap_ticks", WAVE_GAP_TICKS)) < 0:
		errors.append("night %d waits less than no time" % day)
	var waves: Array = one["waves"]
	# **Nothing at all, only when it says so** (task 0154): the calm night
	# after a boss is the one record allowed an empty list.
	if waves.is_empty() and not bool(one.get("calm", false)):
		errors.append("night %d sends nothing at all" % day)
	var open := Calendar.open_sides(day)
	for w in waves.size():
		if not (waves[w] is Array):
			errors.append("night %d wave %d is not a row" % [day, w + 1])
			continue
		var wave: Array = waves[w]
		if wave.size() < 3 or wave.size() > 4:
			errors.append(("night %d wave %d is not (enemy, count, spawn) with an "
				+ "optional delay") % [day, w + 1])
			continue
		if not ENEMIES.has(wave[0]):
			errors.append("night %d sends unknown enemy '%s'" % [day, wave[0]])
		if int(wave[1]) <= 0:
			errors.append("night %d has a wave of %d" % [day, wave[1]])
		if int(wave[2]) < 0 or int(wave[2]) >= SPAWNS.size():
			errors.append("night %d wave %d comes from spawn %d, and there are %d"
				% [day, w + 1, int(wave[2]), SPAWNS.size()])
		# **Only from the sides its season has open** (task 0157).
		elif not open.has(int(wave[2])):
			errors.append("night %d comes from side %d, which its season has not opened"
				% [day, int(wave[2])])
		if wave.size() > 3 and int(wave[3]) < 0:
			errors.append("night %d wave %d waits less than no time" % [day, w + 1])
	# **Sent inside the night** (task 0137): its schedule ends
	# `DAWN_MARGIN_TICKS` before dawn, so the last wave has time to arrive.
	var sent := Waves.schedule_ticks(one)
	if sent + DAWN_MARGIN_TICKS > NIGHT_TICKS:
		errors.append(("night %d takes %d ticks to send, which leaves less than "
			+ "DAWN_MARGIN_TICKS before dawn at %d") % [day, sent, NIGHT_TICKS])
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
			NIGHT_FILL_TICKS, DAY_START_MINUTE, DAY_END_MINUTE, DUSK_MINUTE,
			PASS_OUT_PREPARATION_TICKS,
			MAX_CATCH_UP_TICKS],
		"calendar": [SEASONS, SEASON_DAYS, FULL_MOON_DAYS,
			FULL_MOON_HORDE_PERCENT, FULL_MOON_REWARD_PERCENT, SEASON_BOSSES],
		"calm": CALM_NIGHT_GIFT,
		# **The night's weather** (task 0256).
		"night_events": [NIGHT_EVENTS, NIGHT_EVENT_LEVERS, NIGHT_EVENT_FIRST_SEASON],
		"house_tiers": HOUSE_TIERS,
		"day_economy": [DAY_TARGETS, DAY_FARM],
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
		# The peddler (task 0190).
		"season_stock": SEASON_STOCK,
		"animal_stall": [ANIMAL_PRICE, ANIMAL_STOCK, UPGRADE_STOCK],
		"stall_hours": [STALL_OPENS, STALL_CLOSES],
		"tutorial": TUTORIAL,
		"tips": [TIPS, TIP_MIN_SECONDS, TIP_SECONDS],
		"crops": CROPS,
		"no_growth_seasons": NO_GROWTH_SEASONS,
		"water": [WATER_CAN_CAPACITY],
		"tilled_grass_fades_days": TILLED_GRASS_FADES_DAYS,
		# Bone meal's morning (task 0222).
		"fertilised": [FERTILISED_EXTRA_DAYS],
		"power": [BASE_ENERGY, UNPOWERED_PERCENT],
		"livestock": LIVESTOCK,
		"livestock_sources": LIVESTOCK_SOURCES,
		"animal_feed": ANIMAL_FEED,
		"dig": [DIG_REACH, DIG_GIVES],
		"ammo": [EMPTY_RELOAD_PERCENT, EMPTY_DAMAGE_PERCENT],
		"groups": RESOURCE_GROUPS,
		"gathering": GATHERING,
		"fishing": FISHING,
		"fish_species": FISH_SPECIES,
		"fish_tiers": FISH_TIERS,
		"fish_conditions": FISH_CONDITIONS,
		"worm_in": WORM_IN,
		"baits": BAITS,
		"bait_effects": BAIT_EFFECTS,
		"any_of": ANY_OF,
		"recipes": RECIPES,
		"tools": TOOLS,
		"tool_area_offsets": TOOL_AREA_OFFSETS,
		"queue": [QUEUE_LENGTH],
		"aged": [AGED_MARGIN_PER_DAY],
		"buildings": BUILDINGS,
		"spray_shapes": SPRAY_SHAPES,
		"defences": DEFENCES,
		"pathing": [TERRAIN_COST, WIDEST_STEP],
		"repair": [REPAIR_COST_PER_HP, REPAIR_TICKS_PER_HP,
			HOUSE_REPAIR_PERCENT, REPAIR_PERCENT],
		"ability": ABILITY,
		"powers": POWERS,
		"hurt": [HURT_TICKS],
		"speeds": [SPEEDS, SKIP_MIN_HOUSE_PERCENT],
		"night_hud": [HOUSE_DANGER_PERCENT, WAVE_WARNING_TICKS],
		"enemies": ENEMIES,
		# Where a summoner's flock rises (task 0254).
		"summon_offsets": SUMMON_OFFSETS,
		# **The year's nights** (task 0270): the templates and the key nights.
		"nights": [SEASON_NIGHTS, KEY_NIGHTS],
		"wave_gap": [WAVE_GAP_TICKS, SPAWN_INTERVAL_TICKS],
		# **The nights past the year are balance too.** They are not in the
		# year's tables, so without this line every lever of the endless curve could be
		# turned without the data guard noticing - which is the one thing the
		# guard exists to stop.
		"endless": ENDLESS,
		"spawns": SPAWNS,
		# **The sides, by season** (task 0157).
		"sides": [SPAWN_SIDES, SIDES_BY_SEASON],
		"rewards": REWARDS,
		"defeat": [DEFEAT_LOSS_PERCENT, DEFEAT_KEEPS_MONEY,
			DEFEAT_KEEPS_TECH, TRAMPLE_REACH],
		# **What the night leaves lying about** (task 0221).
		"loot": [LOOT_PILE_CAP, BONES_EVERY, LOOT_REACH, LOOT_FADE_DAYS,
			MOON_STONES, MOON_STONE_ESSENCE],
		"tech": [TECH_BONUSES, TECH_TREE, TECH_REFUND_PERCENT],
		"levels": [TOWER_LEVELS, TOP_TOWER_LEVEL],
		# **Light** (task 0229): the porch's, a tower's reach in it, and a
		# short farm's lamp.
		"light": [PORCH_LIGHT_TILES, LIGHT_REACH_BONUS, LIGHT_SHORT_SHRINK],
	})
