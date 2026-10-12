class_name Weather
extends RefCounted

## **The night's weather** (task 0256; the plan's "Eventos que mudam a
## noite"): some nights are foggy and some rain, and both are known at dusk -
## the forecast names them - so they change what the farmer builds rather than
## punish a player for not guessing. `GameData.NIGHT_EVENTS` says how often and
## what each does:
##
## - **Fog**: a tower in the dark reaches `fog_reach_penalty` tiles less,
##   never under one; a tower on a lit cell (`Light.is_lit`) does not - the
##   searchlight cancels it (`Towers.reach_of`).
## - **Rain**: fire - a `DAMAGE_FIRE` hit and a burn's tick - deals
##   `rain_fire_percent` of itself (`damped`), and a hive's sting is never
##   fire; the mud takes `rain_mud_percent` off a walker's speed, by the one
##   rule every slow follows (`Enemies.slowed_ticks`). A flyer is over it.
## - **Blood Moon** (task 0257): from autumn on, a rare red night. Every body
##   that comes is an elite with `blood_moon_hp_percent` of its hit points
##   (`Entities.spawn`, `elite_hp`) - a boss never - and a won Blood Moon
##   pays `blood_moon_essence` on its own line (`Tech.would_pay`). **Never on
##   a boss night**, where an elite boss is another balance problem, **nor on
##   a Full Moon**: that is already the season's big night, and an elite one
##   would stack two spikes on a single night - half as many again, each half
##   as tough again - and put a white moon and a red one side by side in the
##   forecast. The roll that would have made one there makes a plain night.
##
## ## A function of the date, never of the run
##
## `event(seed, date)` is the one answer every reader takes - the forecast,
## the towers, the walking, the fire, and later the night on screen. It is
## rolled from a stream of the run's seed and the calendar date
## (`Calendar.date`, which 0153's hold keeps on a boss's night until it
## falls), mixed the way `Endless._stream_for` deals a generated night and
## salted so it is never that night's own stream - and never `state["rng"]`,
## so asking it a thousand times moves nothing. It keeps nothing either: no
## State key, so a save cannot disagree with it.
##
## **At most one event a night**, and none on the first night of the game or
## a calm night (`Calendar.is_calm`).
##
## **Asked once per system tick**: `Towers.tick`, `Enemies.tick` and
## `Combat.tick` each ask `tonight()` once and hand the answer down, so a
## swarm does not pay for it a body at a time.

const NONE := &""
const FOG := &"fog"
const RAIN := &"rain"
const BLOOD_MOON := &"blood_moon"

## Every event a night can roll, in the order the roll meets them - the rows
## of `GameData.NIGHT_EVENTS`, which `check_night_events` holds to this list.
## **The Blood Moon last** (task 0257), so the fog and the rain kept every
## night they had before it rose.
const EVENTS: Array = [FOG, RAIN, BLOOD_MOON]

## Mixed into the night's stream, so the weather of a night is never the wave
## table's draw for it.
const STREAM_SALT := 0x2545F491


## The event of the night of `date` in a run started on `seed_value`: `FOG`,
## `RAIN`, `BLOOD_MOON` or `NONE`.
##
## One draw from 0 to 99 against the season's shares, taken in `EVENTS`
## order: a spring roll of 7 with fog at 10 is fog, one of 25 with rain at 20
## after it is rain, and one of 30 or more is a plain night. **A key night of
## the year may pin it or forbid it** (task 0270): its `event`, read instead
## of the roll.
static func event(seed_value: int, date: int) -> StringName:
	return event_in(GameData.KEY_NIGHTS, seed_value, date)


## `event`, asked against the key nights handed in (task 0270) - the year's,
## or a copy a test pins, the way `GameData.check_nights` takes its tables.
static func event_in(key_nights: Dictionary, seed_value: int, date: int) -> StringName:
	if date <= 1 or Calendar.is_calm(date):
		return NONE
	# **The pin**, Year 1's alone: `check_nights` holds it to this
	# function's rules - nothing before its event's first season, no Blood
	# Moon on the moon's own nights - so it is read as it is written.
	var key: Dictionary = key_nights.get(date, {}) if date <= Calendar.year_days() else {}
	if key.has("event"):
		return StringName(key["event"])
	var season := Calendar.season_id(date)
	var rng := Rng.create(Endless._stream_for(seed_value, date) ^ STREAM_SALT)
	var roll := Rng.int_between(rng, 0, 99)
	var below := 0
	for kind in EVENTS:
		var row: Dictionary = GameData.NIGHT_EVENTS.get(kind, {})
		below += int((row.get("weights", {}) as Dictionary).get(season, 0))
		if roll < below:
			# **Never on the moon's own nights** (task 0257): a roll for a
			# Blood Moon on a boss night or a Full Moon is a plain night.
			if kind == BLOOD_MOON and (Calendar.is_boss_night(date) or Calendar.is_full_moon(date)):
				return NONE
			return kind
	return NONE


## Tonight's event: the one for today's date (`Calendar.date`), which is the
## night the build step opens on.
static func tonight(state: Dictionary) -> StringName:
	return event(int(state["seed"]), Calendar.date(state))


## How many tiles a tower in the dark loses to tonight's weather: the fog's
## `fog_reach_penalty`, nothing on any other night.
static func reach_penalty(weather: StringName) -> int:
	if weather != FOG:
		return 0
	return int((GameData.NIGHT_EVENTS[FOG] as Dictionary)["fog_reach_penalty"])


## **What a hit deals in tonight's weather**: fire in the rain - a
## `DAMAGE_FIRE` hit, or a burn's tick - `rain_fire_percent` of itself, never
## under one; anything else, and any hit on another night, all of itself. A
## hive's sting is `DAMAGE_STING`, never fire.
static func damped(amount: int, type: StringName, weather: StringName) -> int:
	if weather != RAIN or type != GameData.DAMAGE_FIRE or amount <= 0:
		return amount
	return maxi(amount * int((GameData.NIGHT_EVENTS[RAIN] as Dictionary)["rain_fire_percent"]) / 100, 1)


## **An elite's hit points** (task 0257): `hp` at the Blood Moon's
## `blood_moon_hp_percent`, rounded down.
static func elite_hp(hp: int) -> int:
	return hp * int((GameData.NIGHT_EVENTS[BLOOD_MOON] as Dictionary)["blood_moon_hp_percent"]) / 100


## The share of a walker's speed tonight's mud takes off, in percent: the
## rain's `rain_mud_percent`, nothing on any other night.
static func mud_percent(weather: StringName) -> int:
	if weather != RAIN:
		return 0
	return int((GameData.NIGHT_EVENTS[RAIN] as Dictionary)["rain_mud_percent"])
