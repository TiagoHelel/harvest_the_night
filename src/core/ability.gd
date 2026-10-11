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
##
## ## Three more (task 0233; the plan's 4.4)
##
## For a night going wrong, each aimed with the guardian's cursor, each with
## its own wait (`GameData.POWERS`), each unlocked by a node of the survival
## branch a season from summer - the flare needs none:
## - **the farm bell** stops every zombie on the farm for two seconds, on the
##   count the electric fence's shock writes (`Enemies.stun()`); a boss for
##   half. It rings at the house, wherever it is aimed;
## - **the dog** runs from the porch to the aimed cell and bites the zombie
##   nearest it, after a delay worked out from the run - no chance in it. The
##   run and the bite are the view's;
## - **the emergency repair** puts a share of the aimed structure's levelled
##   hit points back at once, free (`Repair.restore()`). Not the house, and
##   never rubble: aimed at nothing it can mend, it is refused and spends
##   nothing.
## `intent.power` is their press, by id.

## The flare's id: the first power, and the one `intent.ability` presses.
const FLARE := &"flare"
## Task 0233's, which `intent.power` presses by id.
const FARM_BELL := &"farm_bell"
const CALL_DOG := &"call_dog"
const EMERGENCY_REPAIR := &"emergency_repair"

## **Every power and where it keeps itself in `state["ability"]`**: its wait
## (`cooldown`), how many have gone off (`used`), where the last one went
## (`at`) and how long that shows (`showing`); the lever in its numbers that
## says how long it shows (`lasts` - none for the dog, whose run decides), the
## tree's bonus to its wait (`bonus` - the flare's alone) and the tree's key
## that gives it (`unlock` - none for the flare, everybody's from the first
## night).
const POWERS := {
	FLARE: {"cooldown": "cooldown", "used": "flares", "at": "flare", "showing": "flare_ticks",
		"lasts": "flare_ticks", "bonus": "flare_percent", "unlock": ""},
	FARM_BELL: {"cooldown": "bell_cooldown", "used": "bells", "at": "bell", "showing": "bell_ticks",
		"lasts": "show_ticks", "bonus": "", "unlock": "farm_bell_bonus"},
	CALL_DOG: {"cooldown": "dog_cooldown", "used": "dogs", "at": "dog", "showing": "dog_ticks",
		"lasts": "", "bonus": "", "unlock": "call_dog_bonus"},
	EMERGENCY_REPAIR: {"cooldown": "repair_cooldown", "used": "repairs", "at": "repair",
		"showing": "repair_ticks", "lasts": "show_ticks", "bonus": "", "unlock": "emergency_repair_bonus"},
}

## The powers in a fixed order - the order the night HUD shows them, and the
## order every loop over them takes.
const ORDER: Array[StringName] = [FLARE, FARM_BELL, CALL_DOG, EMERGENCY_REPAIR]


## A new night, every power charged and the dog home. Called from
## `Phases.begin_night()`, beside the barricade allowance that works the same
## way.
static func recharge(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		one[keys["cooldown"]] = 0
		one[keys["showing"]] = 0
		one[keys["at"]] = []
	one["dog_due"] = 0


## Every power's mark goes out with the night, and a dog still running is
## home. A flare's ticks only count down in the dark, so one set off in the
## last seconds of a night would otherwise burn over the farm all day. Called
## at dawn by `Enemies.withdraw()`; the charge is left to `recharge()`, which
## the next night calls anyway.
static func put_out(state: Dictionary) -> void:
	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		one[keys["showing"]] = 0
		one[keys["at"]] = []
	one["dog_due"] = 0


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
			# **The other powers** (task 0233), each with the same four: its
			# wait, where it last went, how long that shows and its count.
			"bell_cooldown": 0,
			"bell": [],
			"bell_ticks": 0,
			"bells": 0,
			"dog_cooldown": 0,
			"dog": [],
			"dog_ticks": 0,
			"dogs": 0,
			# Ticks until the dog's bite lands, 0 when it is not running out.
			"dog_due": 0,
			"repair_cooldown": 0,
			"repair": [],
			"repair_ticks": 0,
			"repairs": 0,
		},
	}


# ------------------------------------------------------------------- asking

## Whether `id` names a power.
static func is_power(id: StringName) -> bool:
	return POWERS.has(id)


## A power's numbers: the flare's are `GameData.ABILITY`, byte for byte as
## they were; the others' `GameData.POWERS`. Empty for anything that is not a
## power.
static func numbers(id: StringName) -> Dictionary:
	if id == FLARE:
		return GameData.ABILITY
	return GameData.POWERS.get(id, {})


## The tree's node that gives a power - its `unlock` key in the node's
## `gives` - or `&""`: the flare is everybody's from the first night.
static func node_of(id: StringName) -> StringName:
	var unlock := String((POWERS.get(id, {}) as Dictionary).get("unlock", ""))
	if unlock.is_empty():
		return &""
	for row in GameData.TECH_TREE:
		if ((row as Dictionary)["gives"] as Dictionary).has(unlock):
			return StringName((row as Dictionary)["id"])
	return &""


## Whether this run has the power: the flare always, the others once their
## node is bought.
static func unlocked(state: Dictionary, id: StringName) -> bool:
	if not is_power(id):
		return false
	var unlock := String((POWERS[id] as Dictionary)["unlock"])
	return unlock.is_empty() or Tech.bonus(state, unlock, 0) > 0


## Whether pressing this power now would do anything. False for an id that is
## not a power, and for one the tree has not given.
##
## Night only: there is nothing to slow at noon, and a flare that could be
## wasted by day is a trap rather than a decision.
static func ready(state: Dictionary, id: StringName) -> bool:
	return unlocked(state, id) and int(state["phase"]) == Phases.NIGHT \
		and cooldown_left(state, id) <= 0


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
	var bonus := String((POWERS[id] as Dictionary)["bonus"])
	var percent := Tech.bonus(state, bonus, 100) if not bonus.is_empty() else 100
	return int(numbers(id)["cooldown_ticks"]) * percent / 100


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


## Whether a power aimed at `cell` has something to work on there. Only the
## emergency repair asks: a standing, hurt structure that is not the house
## (`repair_target()`). The others go off anywhere on the farm.
static func can_target(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if id == EMERGENCY_REPAIR:
		return repair_target(state, cell).x >= 0
	return true


## **What the emergency repair mends at `cell`**: the anchor of a structure
## standing there - one of the player's, with hit points left and some
## missing - or `(-1, -1)`. Not the house, and never rubble, which is nothing
## standing at all.
static func repair_target(state: Dictionary, cell: Vector2i) -> Vector2i:
	if not Grid.in_bounds(cell) or Farm.occupant(state, cell).is_empty():
		return Vector2i(-1, -1)
	var anchor := Building.anchor_of(state, cell)
	var on := Farm.occupant(state, anchor)
	var id := StringName(on.get("id", &""))
	if id == Repair.HOUSE or Building.entry_of(id) == null or int(on.get("hp", 0)) <= 0 \
			or Repair.damage_at(state, anchor) <= 0:
		return Vector2i(-1, -1)
	return anchor


## **How long the dog takes to reach `cell`** from the porch, in ticks: its
## run, `ticks_per_tile` a tile by Manhattan, and never less than one.
static func dog_delay(state: Dictionary, cell: Vector2i) -> int:
	var run := Grid.manhattan(House.porch(state), cell)
	return maxi(run * int(numbers(CALL_DOG)["ticks_per_tile"]), 1)


## **Whom the dog bites**: the zombie nearest `cell` within its
## `radius_tiles` - Chebyshev, as the flare reaches - the nearer by Manhattan
## on a tie, the lower id after that. 0 when there is none.
static func dog_target(state: Dictionary, cell: Vector2i) -> int:
	var radius := int(numbers(CALL_DOG)["radius_tiles"])
	var best := 0
	var best_far := [1 << 30, 1 << 30]
	for id in Entities.ids(state):
		var at := Entities.cell_of(state, id)
		if at.x < 0 or Grid.chebyshev(cell, at) > radius:
			continue
		# **It cannot reach the air** (task 0249): a crow it can bite is a
		# crow on the field - nor under a fence (task 0250).
		if not Enemies.in_reach(state, id, false):
			continue
		var far := [Grid.chebyshev(cell, at), Grid.manhattan(cell, at)]
		if int(far[0]) < int(best_far[0]) or (int(far[0]) == int(best_far[0]) and int(far[1]) < int(best_far[1])):
			best = id
			best_far = far
	return best


## Ticks until the dog's bite lands; 0 when it is not running out.
static func dog_due(state: Dictionary) -> int:
	return int((state["ability"] as Dictionary)["dog_due"])


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
## cursor's). False when it is not a power, the tree has not given it, it is
## not ready, it is aimed at nowhere - off the farm, or `(-1, -1)` - or at
## nothing it can work on (`can_target()`), and then nothing at all happened:
## no wait, no count, nothing in the state touched.
static func use(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if not ready(state, id):
		return false
	if not Grid.in_bounds(cell) or not can_target(state, id, cell):
		return false

	var one: Dictionary = state["ability"]
	var keys: Dictionary = POWERS[id]
	one[keys["cooldown"]] = full_cooldown(state, id)
	one[keys["used"]] = int(one[keys["used"]]) + 1

	one[keys["at"]] = [cell.x, cell.y]
	one[keys["showing"]] = int(numbers(id).get(keys["lasts"], 0))

	match id:
		FLARE:
			_flare(state, cell)
		FARM_BELL:
			_ring(state)
		CALL_DOG:
			_send_dog(state, cell)
		EMERGENCY_REPAIR:
			_mend(state, cell)
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
		# A flare's burst reaches the air (task 0249), never under a fence
		# (task 0250).
		if Enemies.underground(state, id):
			continue
		# **Slowed before it is hit.** A flare that killed something and then
		# tried to slow the corpse would be reading a dictionary that is no
		# longer there, and the order is a rule rather than an accident.
		(Entities.get_one(state, id))["slow"] = slow
		Combat.hit(state, id, damage, kind)


## **The farm bell's effect**: every zombie on the farm stopped for
## `stun_ticks`, a boss for its `boss_stun_percent` of them - none at 0.
static func _ring(state: Dictionary) -> void:
	var bell := numbers(FARM_BELL)
	var ticks := int(bell["stun_ticks"])
	var boss := ticks * int(bell["boss_stun_percent"]) / 100
	for id in Entities.ids(state):
		var kind := StringName(Entities.get_one(state, id)["kind"])
		var is_boss := bool((GameData.ENEMIES[kind] as Dictionary).get("is_boss", false))
		Enemies.stun(state, id, boss if is_boss else ticks)


## **The dog sets off**: its bite falls due when its run reaches the cell,
## and its mark shows for the run there, the bite and the run back.
static func _send_dog(state: Dictionary, cell: Vector2i) -> void:
	var one: Dictionary = state["ability"]
	var delay := dog_delay(state, cell)
	one["dog_due"] = delay
	one["dog_ticks"] = delay * 2 + int(numbers(CALL_DOG)["bite_ticks"])


## **The bite lands** on whoever is nearest the cell it was sent to now that
## it is there - nobody, if the cell has emptied.
static func _dog_bite(state: Dictionary) -> void:
	var aimed: Array = (state["ability"] as Dictionary)["dog"]
	if aimed.size() < 2:
		return
	var target := dog_target(state, Vector2i(int(aimed[0]), int(aimed[1])))
	if target == 0:
		return
	var dog := numbers(CALL_DOG)
	Combat.hit(state, target, int(dog["damage"]), StringName(dog["damage_type"]))


## **The emergency repair's effect**: its share of the structure's levelled
## hit points back, free, through the road mending takes (`Repair.restore()`).
## Its mark goes on the structure's anchor.
static func _mend(state: Dictionary, cell: Vector2i) -> void:
	var anchor := repair_target(state, cell)
	var share := Repair.full_hp_at(state, anchor) * int(numbers(EMERGENCY_REPAIR)["restore_percent"]) / 100
	Repair.restore(state, anchor, maxi(share, 1))
	(state["ability"] as Dictionary)["repair"] = [anchor.x, anchor.y]


## One tick of waiting, of every power's mark fading and of the dog running.
##
## Called from `Sim._tick_night()` only: see the note at the top about the
## cooldown not running by day.
static func tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	# **`intent.ability` is the flare's press**, as it has been since task
	# 0054: the intent is in the state too. 0233's powers have `intent.power`.
	if bool(intent.get("ability", false)):
		use(state, FLARE, aim_of(state))
	# **Consumed whether or not it worked.** A press that arrived on a tick
	# when the flare was still warm is a press that is gone; holding the key
	# through a cooldown and having it fire the instant it came back would be
	# the game playing itself.
	intent["ability"] = false
	var pressed := StringName(intent.get("power", &""))
	if pressed != &"":
		use(state, pressed, aim_of(state))
	intent["power"] = &""

	var one: Dictionary = state["ability"]
	for id in ORDER:
		var keys: Dictionary = POWERS[id]
		if int(one[keys["cooldown"]]) > 0:
			one[keys["cooldown"]] = int(one[keys["cooldown"]]) - 1
		if int(one[keys["showing"]]) > 0:
			one[keys["showing"]] = int(one[keys["showing"]]) - 1
	# **The dog's run**: the bite lands on the tick it gets there.
	if int(one["dog_due"]) > 0:
		one["dog_due"] = int(one["dog_due"]) - 1
		if int(one["dog_due"]) == 0:
			_dog_bite(state)
