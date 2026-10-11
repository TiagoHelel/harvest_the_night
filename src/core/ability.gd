class_name Ability
extends RefCounted

## The buttons that change a night: a list of powers, the flare first.
##
## A flare: it goes off where the player is standing, hurts everything within a
## few tiles and leaves what survives walking at half speed for a few seconds.
## Then it is gone for most of a minute.
##
## ## Why a flare and not a gun
##
## `design.md`'s fourth pillar is explicit that the night is semi-idle - the
## player watches the defence they built do the work, and "pode eventualmente"
## step in. So the ability had to be one press with a long wait rather than a
## weapon, or the night stops being about the farm and starts being about
## aiming. One button, no target, a decision about **when**.
##
## The slow is the half that does the turning. Twenty-five damage kills a
## walker and dents a tank; five seconds of half speed is five seconds of every
## tower on the farm getting a free extra volley into the same crowd, which is
## worth far more than the damage and is why the numbers can stay small.
##
## ## It goes off where the player is
##
## No aiming, which means the decision is where to be standing when the wave
## arrives - and that is a decision the player makes with their feet, minutes
## earlier, rather than with a cursor in the moment.
##
## ## Every night starts with it charged, and the wait runs only at night
##
## Night one is fifty-four seconds long and the wait is eighty, so within a
## night the flare is one press - which is the shape the task asks for: it
## turns *a* losing wave, not every wave.
##
## The two rules together are what make that readable. If the wait ran by day
## it would be pure bookkeeping, because a day is longer than any cooldown. If
## it carried over instead, a player who flared the last wave of night three
## would start night four with a flare that is mysteriously not ready, and
## nothing on screen could explain why. So the night gives it back, and inside
## the night it costs what the lever says.
##
## ## A list of powers (task 0232)
##
## The flare is the first entry of a list. Each power has an id, its own wait,
## its own count and where it last went off, all under `state["ability"]`, and
## the same few functions ask and use any of them by id - so 0233's three
## powers are rows in `POWERS` and an effect each, not a second copy of the
## waiting and the aiming. **The flare keeps the keys it has had since task
## 0054** - `cooldown`, `flare`, `flare_ticks` and `flares` -
## because `state["ability"]` is folded into the determinism hash and renaming
## them would move it for nothing; `intent.ability` stays its press, and
## `GameData.ABILITY` its numbers, for the same reason.

## The flare's id: the first power, and the one `intent.ability` presses.
const FLARE := &"flare"

## **Every power and where it keeps itself in `state["ability"]`**: its wait
## (`cooldown`), how many have gone off (`used`), where the last one went
## (`at`) and how long that shows (`showing`); the lever in its numbers that
## says how long it shows (`lasts`), and the tree's bonus to its wait
## (`bonus`).
const POWERS := {
	FLARE: {"cooldown": "cooldown", "used": "flares", "at": "flare", "showing": "flare_ticks",
		"lasts": "flare_ticks", "bonus": "flare_percent"},
}

## The powers in a fixed order - the order the night HUD will show them, and
## the order every loop over them takes.
const ORDER: Array[StringName] = [FLARE]


## A new night, every power charged. Called from `Phases.begin_night()`,
## beside the barricade allowance that works the same way.
static func recharge(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		one[keys["cooldown"]] = 0
		one[keys["showing"]] = 0
		one[keys["at"]] = []


## Every power's mark goes out with the night. A flare's ticks only count down
## in the dark, so one set off in the last seconds of a night would otherwise
## burn over the farm all day. Called at dawn by `Enemies.withdraw()`; the
## charge is left to `recharge()`, which the next night calls anyway.
static func put_out(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		one[keys["showing"]] = 0
		one[keys["at"]] = []


static func initial() -> Dictionary:
	return {
		"ability": {
			# Ticks until it can be used again. Zero is ready.
			"cooldown": 0,
			# Where the last flare went off and how long the view should keep
			# drawing it. **In the state on purpose**: the same reasoning as
			# `hurt` in `Combat` - the view must not have to remember anything
			# the rules already know, and a flare the rules fired is a fact
			# about the run.
			"flare": [],
			"flare_ticks": 0,
			# How many have gone off, for the statistics of task 0069.
			"flares": 0,
		},
	}


# ------------------------------------------------------------------- asking

## Whether `id` names a power.
static func is_power(id: StringName) -> bool:
	return POWERS.has(id)


## A power's numbers: the flare's are `GameData.ABILITY`, byte for byte as
## they were. Empty for anything that is not a power.
static func numbers(id: StringName) -> Dictionary:
	return GameData.ABILITY if id == FLARE else {}


## Whether pressing this power now would do anything. False for an id that is
## not a power.
##
## Night only: there is nothing to slow at noon, and a flare that could be
## wasted by day is a trap rather than a decision.
static func ready(state: Dictionary, id: StringName) -> bool:
	return is_power(id) and int(state["phase"]) == Phases.NIGHT and cooldown_left(state, id) <= 0


## Ticks until this power can be used again; 0 for an id that is not a power.
static func cooldown_left(state: Dictionary, id: StringName) -> int:
	if not is_power(id):
		return 0
	return int((state["ability"] as Dictionary)[(POWERS[id] as Dictionary)["cooldown"]])


## The whole of a power's wait on this farm: its lever, with the tree's bonus
## to it - the flare's `flare_percent` - taken off.
static func full_cooldown(state: Dictionary, id: StringName) -> int:
	if not is_power(id):
		return 0
	return int(numbers(id)["cooldown_ticks"]) \
		* Tech.bonus(state, String((POWERS[id] as Dictionary)["bonus"]), 100) / 100


## How far through its wait a power is, as a percentage. A hundred is ready,
## and the HUD of task 0056 draws this as a ring. 0 for an id that is not a
## power.
static func charge_percent(state: Dictionary, id: StringName) -> int:
	if not is_power(id):
		return 0
	var full := full_cooldown(state, id)
	if full <= 0:
		return 100
	return mini((full - cooldown_left(state, id)) * 100 / full, 100)


## Where a power last went off while it still shows, or an empty array. For
## the view, and for `Light`.
static func aimed_at(state: Dictionary, id: StringName) -> Array:
	if not is_power(id):
		return []
	var one: Dictionary = state["ability"]
	var keys: Dictionary = POWERS[id]
	return [] if int(one[keys["showing"]]) <= 0 else (one[keys["at"]] as Array)


## How many ticks of a power's mark the view has left to draw.
static func showing(state: Dictionary, id: StringName) -> int:
	if not is_power(id):
		return 0
	return int((state["ability"] as Dictionary)[(POWERS[id] as Dictionary)["showing"]])


## How many times a power has gone off this run, for the statistics.
static func used(state: Dictionary, id: StringName) -> int:
	if not is_power(id):
		return 0
	return int((state["ability"] as Dictionary)[(POWERS[id] as Dictionary)["used"]])


## Where the guardian's cursor aims the powers (task 0135):
## `intent.ability_cell`, as a cell - `(-1, -1)` when nothing is aimed.
static func aim_of(state: Dictionary) -> Vector2i:
	var aimed: Array = (state["intent"] as Dictionary).get("ability_cell", [-1, -1])
	return Vector2i(int(aimed[0]), int(aimed[1]))


## Whether this one is walking slowly because of a flare.
static func is_slowed(state: Dictionary, id: int) -> bool:
	return int(Entities.get_one(state, id).get("slow", 0)) > 0


## What `ticks_per_tile` becomes for something that has been flared - or, given
## a `percent`, for something walking at that share of its speed (task 0228's
## garlic).
##
## `slow_percent` is **percent of normal speed**, so fifty percent doubles how
## long a tile takes. Written that way round because "half speed" is what a
## designer means and `ticks_per_tile` is the opposite of speed.
static func slowed_ticks(per_tile: int, percent: int = 0) -> int:
	var share := maxi(percent if percent > 0 else int(GameData.ABILITY["slow_percent"]), 1)
	return maxi(per_tile * 100 / share, per_tile + 1)


# -------------------------------------------------------------------- doing

## Set a power off **at `cell`** (task 0135's aim; `aim_of()` reads the
## cursor's). False when it is not a power, is not ready or is aimed at
## nowhere - off the farm, or `(-1, -1)` - and then nothing at all happened:
## no wait, no count, nothing in the state touched.
static func use(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if not ready(state, id):
		return false
	if not Grid.in_bounds(cell):
		return false

	var one: Dictionary = state["ability"]
	var keys: Dictionary = POWERS[id]
	one[keys["cooldown"]] = full_cooldown(state, id)
	one[keys["used"]] = int(one[keys["used"]]) + 1

	one[keys["at"]] = [cell.x, cell.y]
	one[keys["showing"]] = int(numbers(id)[keys["lasts"]])

	match id:
		FLARE:
			_flare(state, cell)
	return true


## **The flare's effect**: everything within `radius_tiles` of `cell`, by
## Chebyshev, slowed and hit.
static func _flare(state: Dictionary, centre: Vector2i) -> void:
	var damage := int(GameData.ABILITY["damage"])
	var radius := int(GameData.ABILITY["radius_tiles"])
	var slow := int(GameData.ABILITY["slow_ticks"])
	var kind := StringName(GameData.ABILITY["damage_type"])

	# `Entities.ids()` is sorted, so two zombies that die to the same flare
	# always die in the same order.
	for id in Entities.ids(state):
		var at := Entities.cell_of(state, id)
		if at.x < 0 or Grid.chebyshev(centre, at) > radius:
			continue
		# **Slowed before it is hit.** A flare that killed something and then
		# tried to slow the corpse would be reading a dictionary that is no
		# longer there, and the order is a rule rather than an accident.
		(Entities.get_one(state, id))["slow"] = slow
		Combat.hit(state, id, damage, kind)


## One tick of waiting, and of every power's mark fading.
##
## Called from `Sim._tick_night()` only: see the note at the top about the
## cooldown not running by day.
static func tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	# **`intent.ability` is the flare's press**, as it has been since task
	# 0054: the intent is in the state too. 0233's powers bring their own.
	if bool(intent.get("ability", false)):
		use(state, FLARE, aim_of(state))
	# **Consumed whether or not it worked.** A press that arrived on a tick
	# when the flare was still warm is a press that is gone; holding the key
	# through a cooldown and having it fire the instant it came back would be
	# the game playing itself.
	intent["ability"] = false

	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		if int(one[keys["cooldown"]]) > 0:
			one[keys["cooldown"]] = int(one[keys["cooldown"]]) - 1
		if int(one[keys["showing"]]) > 0:
			one[keys["showing"]] = int(one[keys["showing"]]) - 1
