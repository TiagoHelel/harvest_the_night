class_name Ability
extends RefCounted

## The one button that changes a night.
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


## A new night, a charged flare. Called from `Phases.begin_night()`, beside
## the barricade allowance that works the same way.
static func recharge(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	one["cooldown"] = 0
	one["flare_ticks"] = 0
	one["flare"] = []


## The flare goes out with the night. Its ticks only count down in the dark,
## so one set off in the last seconds of a night would otherwise burn over the
## farm all day. Called at dawn by `Enemies.withdraw()`; the charge is left to
## `recharge()`, which the next night calls anyway.
static func put_out(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	one["flare_ticks"] = 0
	one["flare"] = []


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

## Whether pressing it now would do anything.
##
## Night only: there is nothing to slow at noon, and a flare that could be
## wasted by day is a trap rather than a decision.
static func ready(state: Dictionary) -> bool:
	return int(state["phase"]) == Phases.NIGHT and cooldown_left(state) <= 0


static func cooldown_left(state: Dictionary) -> int:
	return int((state["ability"] as Dictionary)["cooldown"])


## How far through the wait it is, as a percentage. A hundred is ready, and the
## HUD of task 0056 draws this as a ring.
static func charge_percent(state: Dictionary) -> int:
	var full := int(GameData.ABILITY["cooldown_ticks"]) \
		* Tech.bonus(state, "flare_percent", 100) / 100
	if full <= 0:
		return 100
	return mini((full - cooldown_left(state)) * 100 / full, 100)


## Where the last flare went off, or an empty array. For the view.
static func flare_at(state: Dictionary) -> Array:
	var one: Dictionary = state["ability"]
	return [] if int(one["flare_ticks"]) <= 0 else (one["flare"] as Array)


## How many ticks of flare the view has left to draw.
static func flare_ticks(state: Dictionary) -> int:
	return int((state["ability"] as Dictionary)["flare_ticks"])


static func flares_used(state: Dictionary) -> int:
	return int((state["ability"] as Dictionary)["flares"])


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

## Set one off **where it is aimed** (task 0135): `intent.ability_cell`, which
## the guardian's cursor writes. False when it was not ready or is aimed at
## nowhere - off the farm, or `[-1, -1]` - and then nothing at all happened:
## no cooldown, no count.
static func use(state: Dictionary) -> bool:
	if not ready(state):
		return false
	var aimed: Array = (state["intent"] as Dictionary).get("ability_cell", [-1, -1])
	var centre := Vector2i(int(aimed[0]), int(aimed[1]))
	if not Grid.in_bounds(centre):
		return false

	var one: Dictionary = state["ability"]
	one["cooldown"] = int(GameData.ABILITY["cooldown_ticks"]) \
		* Tech.bonus(state, "flare_percent", 100) / 100
	one["flares"] = int(one["flares"]) + 1

	one["flare"] = [centre.x, centre.y]
	one["flare_ticks"] = int(GameData.ABILITY["flare_ticks"])

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
	return true


## One tick of waiting, and of the flare fading.
##
## Called from `Sim._tick_night()` only: see the note at the top about the
## cooldown not running by day.
static func tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	if bool(intent.get("ability", false)):
		use(state)
	# **Consumed whether or not it worked.** A press that arrived on a tick
	# when the flare was still warm is a press that is gone; holding the key
	# through a cooldown and having it fire the instant it came back would be
	# the game playing itself.
	intent["ability"] = false

	var one: Dictionary = state["ability"]
	if int(one["cooldown"]) > 0:
		one["cooldown"] = int(one["cooldown"]) - 1
	if int(one["flare_ticks"]) > 0:
		one["flare_ticks"] = int(one["flare_ticks"]) - 1
