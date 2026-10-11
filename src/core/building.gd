class_name Building
extends RefCounted

## Putting things on the farm, and taking them off again.
##
## ## What a structure costs, and the two ways to pay
##
## `GameData.DEFENCES[id]["cost"]` is the price, full stop. There are two ways
## to pay it:
##
## - **On the spot.** The materials come out of the ledger as it is placed.
## - **In advance.** The workshop turns the same materials into a kit, and
##   placing spends the kit instead.
##
## A kit is that cost already paid, which is why the recipe's inputs and the
## structure's cost are the same numbers and `GameData.validate()` insists on
## it. Banking kits during the day is how a player puts a wall up at night,
## when there is nothing to gather and no time to gather it.
##
## ## The phase decides what may go down
##
## **The plan's decision 4** (task 0132): the day earns and the night spends.
## A defence goes down, up a level or back to the ledger only in the build
## step and the night, by the guardian's cursor; a production building only
## by day. The barricade is still the cheap, temporary, limited one - its
## `lifetime_ticks` and `per_night_limit` are its identity, not a licence to
## go down at night that the others lack.
##
## ## Build mode is a state
##
## Like the shop panel, it lives in `state["build"]` so that the autoplayer of
## task 0067 can build a farm without a mouse, and so that "what is selected"
## survives a save.


static func initial() -> Dictionary:
	return {
		# Cells with something on them that takes itself away. Almost always
		# empty; see `expire()`.
		"expiring": [],
		"build": {
			"active": false,
			"selected": &"",
			# **How many of each thing have gone down tonight.**
			# `{id: count}`, cleared when a night begins.
			#
			# `per_night_limit` has been in `DEFENCES` since the table was
			# written and nothing read it - the barricade could be thrown down
			# as fast as the wood held out, which is a wall you rebuild rather
			# than an emergency answer. Task 0047 is where the number starts
			# meaning something.
			"placed_tonight": {},
		},
	}


# ------------------------------------------------------------------- asking

## Everything that could go on the farm right now, in a fixed order.
##
## **Everything, not only what is affordable.** A palette that grew as you got
## richer would teach nothing about what to go and get; the panel greys what
## cannot be paid for and says why.
static func catalogue(state: Dictionary) -> Array:
	var out: Array = []
	for id in placeable_ids():
		if allowed_in_phase(state, id):
			out.append(id)
	return out


## Everything that can be put on the farm: the defences, and since task 0032
## the production buildings too.
##
## **Two tables and one placer.** A press is not a tower and its entry lives
## with the other buildings, but "can I put this here, can I pay for it, what
## does it cost to take up again" is the same question for both - and the day
## build mode had a second code path for buildings is the day the two answers
## start disagreeing.
##
## **The defences in the order the year hands them out** (task 0224), each
## season's by name: spring's eight, then summer's decoy. A defence a later
## season adds goes on the end of the hotbar, so the slots and keys a player
## learnt in spring do not move under them.
static func placeable_ids() -> Array:
	var names := GameData.sorted_names(GameData.DEFENCES.keys())
	var defences: Array = []
	for season in GameData.SEASONS:
		for id in names:
			if GameData.defence_season(GameData.DEFENCES[id]) == season:
				defences.append(id)
	return defences + GameData.sorted_names(GameData.BUILDINGS.keys())


## **Walked over, never a wall** (task 0178): a structure that declares it -
## the sprinklers - is crossed by the flow field at its ground's cost, the
## way a trap is, and is nothing a breaker comes for. The farmer still walks
## round it, as round anything built.
static func walked_over(id: StringName) -> bool:
	var entry: Variant = entry_of(id)
	return entry != null and bool((entry as Dictionary).get("walked_over", false))


## **Wrecked, never lost** (task 0186): whether this stands at 0 HP instead
## of coming down - the coop and the barn (`wrecks`). Its hit points are one
## count over its whole footprint (`set_shared_hp`).
static func wrecks(id: StringName) -> bool:
	var entry: Variant = entry_of(id)
	return entry != null and bool((entry as Dictionary).get("wrecks", false))


## Whether the thing on this cell is standing wrecked.
static func is_wrecked(state: Dictionary, cell: Vector2i) -> bool:
	var on := Farm.occupant(state, cell)
	return not on.is_empty() and wrecks(StringName(on["id"])) and int(on.get("hp", 0)) <= 0


## Give every cell of the building on this cell the same hit points, and mark
## it wrecked at 0 - one building, one count, wherever it was bitten or mended.
static func set_shared_hp(state: Dictionary, cell: Vector2i, hp: int) -> void:
	for part in parts_at(state, cell):
		var on := Farm.occupant(state, part)
		on["hp"] = hp
		if hp <= 0:
			on["wrecked"] = true
		else:
			on.erase("wrecked")


## Whether this waters the plots round it each morning (task 0178).
static func sprays(id: StringName) -> bool:
	var entry: Variant = entry_of(id)
	return entry != null and (entry as Dictionary).has("spray")


## The entry for anything placeable, from whichever table holds it.
static func entry_of(id: StringName) -> Variant:
	if GameData.DEFENCES.has(id):
		return GameData.DEFENCES[id]
	if GameData.BUILDINGS.has(id):
		return GameData.BUILDINGS[id]
	return null


# ------------------------------------------------------------- the levels

## What level the thing on this cell is. One is as built.
static func level_at(state: Dictionary, cell: Vector2i) -> int:
	return maxi(int(Farm.occupant(state, cell).get("level", 1)), 1)


## The table entry for what is standing here, **with its level laid over it**.
##
## The one place a level means anything. A level three gun tower is the gun
## tower's own row with three numbers changed, so everything that reads a
## tower - what it hits for, how far it sees, how long it reloads - gets the
## upgraded answer without knowing levels exist.
static func entry_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return {}
	var base: Variant = entry_of(StringName(on["id"]))
	if base == null:
		return {}
	var level := maxi(int(on.get("level", 1)), 1)
	if level <= 1:
		return base
	var out: Dictionary = (base as Dictionary).duplicate(true)
	for step in _levels_of(StringName(on["id"])).slice(0, level - 1):
		for key in GameData.sorted_names(((step as Dictionary)["gives"]
			as Dictionary).keys()):
			out[key] = ((step as Dictionary)["gives"] as Dictionary)[key]
	return out


## The upgrade steps a tower has, or an empty list for something that has none.
static func _levels_of(id: StringName) -> Array:
	return GameData.TOWER_LEVELS.get(id, [])


## What upgrading this cell one level would cost, the tree's discount applied.
static func upgrade_cost(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return {}
	var steps := _levels_of(StringName(on["id"]))
	var level := level_at(state, cell)
	if level - 1 >= steps.size():
		return {}
	var cost: Dictionary = (steps[level - 1] as Dictionary)["cost"]
	# **`tower_cost_percent`, read at last.** Task 0063 handed this number
	# out and nothing asked for it, because `cost_of()` has no state to ask
	# with. An upgrade does.
	var percent := Tech.bonus(state, "tower_cost_percent", 100)
	var out := {}
	for res in GameData.sorted_names(cost.keys()):
		out[res] = maxi(int(cost[res]) * percent / 100, 1)
	return out


## What the tree node for the next level is, or `&""`.
static func upgrade_needs(state: Dictionary, cell: Vector2i) -> StringName:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return &""
	var steps := _levels_of(StringName(on["id"]))
	var level := level_at(state, cell)
	if level - 1 >= steps.size():
		return &""
	return StringName((steps[level - 1] as Dictionary)["needs"])


## Why this cell cannot be upgraded. An empty Array when it can.
##
## **A key and its arguments, not a sentence.** Task 0110: the rules say what
## is wrong and `src/ui/names.gd` says it in whatever language is up. The ids
## in it go in raw - `&"gun_tower"`, not "gun tower" - because the view is
## the half that knows what a player calls things.
static func why_not_upgrade(state: Dictionary, cell: Vector2i) -> Array:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return [&"WHY_NOTHING_THERE"]
	if _levels_of(StringName(on["id"])).is_empty():
		return [&"WHY_NO_UPGRADE", StringName(on["id"])]
	if level_at(state, cell) >= GameData.TOP_TOWER_LEVEL:
		return [&"WHY_TOP_LEVEL"]
	# **The phase's rule, and nothing more** (task 0132): a defence goes up a
	# level in the build step or mid-wave - the plan (4.3) lets upgrades go
	# on while they are coming - and never by day.
	var wrong := why_not_now(state, StringName(on["id"]))
	if not wrong.is_empty():
		return wrong
	var needs := upgrade_needs(state, cell)
	if needs != &"" and not Tech.owns(state, needs):
		return [&"WHY_NEEDS_TECH", needs]
	if not Resources.can_afford(state, upgrade_cost(state, cell)):
		return [&"WHY_SHORT",
			Resources.missing(state, upgrade_cost(state, cell))]
	return []


static func can_upgrade(state: Dictionary, cell: Vector2i) -> bool:
	return why_not_upgrade(state, cell).is_empty()


## Upgrade the tower on this cell. False and nothing spent when it will not go.
##
## **Hit points carry proportionally.** A tower at half health that becomes a
## level three with more of them is still at half health: upgrading is not a
## repair, and a player who could mend a wall by upgrading it would never mend
## anything again.
static func upgrade(state: Dictionary, cell: Vector2i) -> bool:
	if not can_upgrade(state, cell):
		return false
	if not Resources.pay(state, upgrade_cost(state, cell)):
		return false

	var on := Farm.occupant(state, cell)
	var was_full := int(entry_at(state, cell).get("hp", 1))
	var share := int(on.get("hp", was_full)) * 100 / maxi(was_full, 1)

	on["level"] = level_at(state, cell) + 1
	var now_full := int(entry_at(state, cell).get("hp", 1))
	on["hp"] = maxi(now_full * share / 100, 1)
	# A tower whose range or shape changed is a different tower to the
	# targeting code, and the field has an opinion about occupants.
	Farm.touch(state)
	return true


static func is_placeable(id: StringName) -> bool:
	return entry_of(id) != null


static func cost_of(id: StringName) -> Dictionary:
	var entry: Variant = entry_of(id)
	return {} if entry == null else (entry as Dictionary)["cost"]


## How many tiles it covers. Towers are one; a press is two by two.
static func size_of(id: StringName) -> Vector2i:
	if id == &"house":
		return GameData.HOUSE_SIZE
	if id == &"shop":
		return GameData.SHOP_SIZE
	# Map props over more than one cell (task 0156): the hardwood stump.
	if GameData.MAP_PROP_SIZES.has(id):
		return GameData.MAP_PROP_SIZES[id]
	var entry: Variant = entry_of(id)
	if entry == null:
		return Vector2i.ONE
	return (entry as Dictionary).get("size", Vector2i.ONE)


## Every cell a thing of this size would cover, anchored at its top left.
##
## The farmhouse has worked this way since the map was drawn - nine cells each
## holding `{"id": "house"}` - so a multi-tile building is not a new idea here,
## only a placeable one. Each cell also carries the anchor, so that four cells
## of press are one press and not four.
static func footprint(id: StringName, origin: Vector2i) -> Array:
	var size := size_of(id)
	var out: Array = []
	for dy in size.y:
		for dx in size.x:
			out.append(origin + Vector2i(dx, dy))
	return out


## Which cell of a multi-tile building is the one that owns it. Jobs, hit
## points and selling all key off this, so standing at either half of a press
## is standing at the same press.
static func anchor_of(state: Dictionary, cell: Vector2i) -> Vector2i:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return cell
	var at: Variant = on.get("anchor", null)
	if at == null:
		return cell
	var pair: Array = at
	return Vector2i(int(pair[0]), int(pair[1]))


## Actual occupied cells also support protected, compact legacy save structures.
static func parts_at(state: Dictionary, cell: Vector2i) -> Array[Vector2i]:
	var on := Farm.occupant(state, cell)
	var id: StringName = on.get("id", &"")
	if on.is_empty():
		return []
	if size_of(id) == Vector2i.ONE:
		return [cell]
	var anchor := on.get("anchor", []) as Array
	var parts: Array[Vector2i] = []
	for idx in state["occupants"]:
		var other: Dictionary = state["occupants"][idx]
		if other.get("id", &"") == id and other.get("anchor", []) == anchor:
			parts.append(Grid.cell(int(idx)))
	parts.sort_custom(func(a: Vector2i, b: Vector2i): return Grid.index(a) < Grid.index(b))
	return parts


static func bounds_at(state: Dictionary, cell: Vector2i) -> Rect2i:
	var bounds := Rect2i()
	for part in parts_at(state, cell):
		bounds = Rect2i(part, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.merge(Rect2i(part, Vector2i.ONE))
	return bounds


## How many more of this may go down tonight. A big number for anything with
## no limit, so callers do not have to know which is which.
static func left_tonight(state: Dictionary, id: StringName) -> int:
	var entry: Variant = entry_of(id)
	if entry == null:
		return 0
	var limit := int((entry as Dictionary).get("per_night_limit", 0))
	if limit > 0:
		limit += Tech.bonus(state, "barricade_bonus", 0)
	if limit <= 0:
		return 1 << 30          # no limit declared, so no limit applied
	return maxi(limit - placed_tonight(state, id), 0)


## How many of this have gone down since the night began.
static func placed_tonight(state: Dictionary, id: StringName) -> int:
	return int((((state["build"] as Dictionary)["placed_tonight"])
		as Dictionary).get(id, 0))


## A new night, a fresh allowance. Called from `Phases.begin_night()`.
static func forget_tonight(state: Dictionary) -> void:
	(state["build"] as Dictionary)["placed_tonight"] = {}


## **The waves wind the barricades' clocks** (task 0132): everything put down
## in the build step with a `lifetime` starts to expire now. Called by
## `Phases.begin_night`; cells in index order, as everything here is.
static func start_lifetimes(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		if on.has("lifetime") and not on.has("expires"):
			on["expires"] = int(state["tick"]) + int(on["lifetime"])
			on.erase("lifetime")
			_will_expire(state, Grid.cell(int(idx)))


## Whether the phase lets this go down, up or back at all (task 0132): a
## defence in the build step and the night, a production building by day.
static func allowed_in_phase(state: Dictionary, id: StringName) -> bool:
	var phase := int(state["phase"])
	if GameData.DEFENCES.has(id):
		return phase == Phases.PREPARATION or phase == Phases.NIGHT
	if GameData.BUILDINGS.has(id):
		return phase == Phases.DAY
	return false


## The refusal for the wrong half of the day, or empty: a defence by day is
## "only at night", a building after dark is "not after dark".
static func why_not_now(state: Dictionary, id: StringName) -> Array:
	if allowed_in_phase(state, id):
		return []
	return [&"WHY_ONLY_AT_NIGHT"] if GameData.DEFENCES.has(id) else [&"WHY_NOT_AT_NIGHT"]


## Whether it can be paid for, by kit or by ledger.
static func affordable(state: Dictionary, id: StringName) -> bool:
	if Crafting.kits(state, id) > 0:
		return true
	return Resources.can_afford(state, cost_of(id))


static func can_place(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	return why_not(state, id, cell).is_empty()


## Why it will not go there, for the red ghost and the tooltip. An empty
## Array when it will. See `why_not_upgrade` for the shape.
static func why_not(state: Dictionary, id: StringName, cell: Vector2i) -> Array:
	if House.inside(state):
		return [&"WHY_ON_THE_HOUSE"]
	if not is_placeable(id):
		return [&"WHY_NOTHING_SELECTED"]
	var wrong := why_not_now(state, id)
	if not wrong.is_empty():
		return wrong
	# **The allowance, before the money.** Being told "you have used your five"
	# is a different sentence from "you are short two wood", and the first one
	# is the one that is true.
	if Traps.is_trap(id) and Traps.room_for(state, id) <= 0:
		return [&"WHY_TRAP_LIMIT",
			int((entry_of(id) as Dictionary).get("armed_limit", 0))]
	if left_tonight(state, id) <= 0:
		return [&"WHY_NIGHT_LIMIT",
			int((entry_of(id) as Dictionary).get("per_night_limit", 0))]
	# **Every cell it would cover**, not only the one under the cursor. A press
	# hanging half off the farm is the bug this stops.
	for at in footprint(id, cell):
		var terrain_reason := Farm.why_not_buildable(state, at)
		if not terrain_reason.is_empty():
			return terrain_reason
	# **A sprinkler is not planted over** (task 0178): it goes on bare
	# ground or turned earth, never on a crop it would have to uproot.
	if sprays(id) and Farming.crop_on(state, cell) != &"":
		return [&"WHY_ON_A_CROP"]
	if not affordable(state, id):
		return [&"WHY_SHORT", Resources.missing(state, cost_of(id))]
	return []


## What selling the thing on this cell would give back. Empty when there is
## nothing there, or when it is not the player's to sell.
static func refund_for(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_placeable(on["id"]):
		return {}
	return refund_for_cost(cost_of(on["id"]))


## What a given price gives back. Separate from the cell so that the rule can
## be checked against every structure at once rather than one at a time.
static func refund_for_cost(cost: Dictionary) -> Dictionary:
	var back := {}
	var keys := GameData.sorted_names(cost.keys())
	for res in keys:
		# **Rounded down**, so the round trip is always a loss. Rounding up on
		# a cheap structure would make place-and-sell a money printer, which is
		# the sort of thing nobody finds until somebody does.
		var n := int(floor(float(cost[res]) * GameData.SELL_BACK_FRACTION))
		if n > 0:
			back[res] = n
	return back


# -------------------------------------------------------------------- doing

## Put it down. Pays with a kit if there is one, and out of the ledger if not.
static func place(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if not can_place(state, id, cell):
		return false

	# The kit first: it is the cost already paid, and a player who banked one
	# during the day meant to use it.
	if not Crafting.take_kit(state, id):
		if not Resources.pay(state, cost_of(id)):
			return false

	var entry: Dictionary = entry_of(id)
	var occupant := {"id": id, "hp": int(entry.get("hp", 1))}
	if entry.has("lifetime_ticks"):
		if int(state["phase"]) == Phases.NIGHT:
			occupant["expires"] = int(state["tick"]) + int(entry["lifetime_ticks"])
			_will_expire(state, cell)
		else:
			# **Put down before the waves, it lasts from the waves** (task
			# 0132): the build step has no clock to spend it on after 0136,
			# and a barricade that rotted while the player was still deciding
			# would be section 13's bug back. `start_lifetimes` winds it.
			occupant["lifetime"] = int(entry["lifetime_ticks"])

	# Counted the moment it goes down, not when it comes up: a barricade that
	# was chewed through still used one of tonight's five.
	var tally: Dictionary = (state["build"] as Dictionary)["placed_tonight"]
	tally[id] = int(tally.get(id, 0)) + 1
	# **And the run's tally beside the night's**, for the reason
	# `Combat._kill()` gives: `placed_tonight` is cleared every morning
	# because it exists to cap barricades, so nothing knew how many walls a
	# run had ever built until task 0069 asked.
	Stats.built(state, id)

	var cells := footprint(id, cell)
	if cells.size() > 1:
		occupant["anchor"] = [cell.x, cell.y]
	# **A cell with a sprinkler is not a plot** (task 0178): turned earth
	# under one is given back to the ground, so nothing counts it a bed.
	if sprays(id):
		(state["plots"] as Dictionary).erase(Grid.index(cell))
	for at in cells:
		if not Farm.place(state, at, occupant):
			# Half a press is worse than none. Take back whatever went down.
			for done in cells:
				if done == at:
					break
				Farm.remove(state, done)
			Resources.gain(state, cost_of(id))
			return false
	# **A coop or a barn takes its kind in** (task 0183): the map's loose
	# animals that live there, and any whose home was lost.
	if Livestock.is_home(id):
		Livestock.move_in(state, cell)
	return true


## Why the thing on this cell cannot be sold now, or empty: nothing that is
## the player's, or the wrong half of the day for it (task 0132).
static func why_not_sell(state: Dictionary, cell: Vector2i) -> Array:
	var id: StringName = Farm.occupant(state, cell).get("id", &"")
	if not is_placeable(id):
		return [&"WHY_NOTHING_THERE"]
	# **Not out from under its animals** (task 0183): a coop with hens in
	# it stays up.
	if Livestock.is_home(id) and not Livestock.residents(state, cell).is_empty():
		return [&"WHY_HOME_IN_USE"]
	return why_not_now(state, id)


## Take it back up for a fraction of what it cost. Returns what came back.
static func sell(state: Dictionary, cell: Vector2i) -> Dictionary:
	var id: StringName = Farm.occupant(state, cell).get("id", &"")
	if not why_not_sell(state, cell).is_empty():
		return {}
	var back := refund_for(state, cell)
	# Selling any tile of a building sells the building, and takes every tile
	# of it with it.
	var removed := false
	var owned_parts := parts_at(state, cell)
	for part in owned_parts:
		if Farm.occupant(state, part).get("id", &"") == id:
			removed = Farm.remove(state, part) or removed
	if not removed:
		return {}
	Resources.gain(state, back)
	return back


# ------------------------------------------------------------------ the mode

static func is_active(state: Dictionary) -> bool:
	return bool((state["build"] as Dictionary)["active"])


static func selected(state: Dictionary) -> StringName:
	return StringName((state["build"] as Dictionary)["selected"])


static func set_active(state: Dictionary, active: bool) -> void:
	if active and House.inside(state):
		return
	var build: Dictionary = state["build"]
	build["active"] = active
	if not active:
		build["selected"] = &""
	elif build["selected"] == &"":
		var options := catalogue(state)
		build["selected"] = options[0] if not options.is_empty() else &""


## One tick of build mode. Called from every phase that allows building.
##
## The UI writes where the player is pointing and what they asked for; this
## decides. Same road as every other input, so the autoplayer of task 0067
## builds a farm by writing three fields.
static func tick(state: Dictionary) -> void:
	expire(state)

	var intent: Dictionary = state["intent"]
	var place_asked := bool(intent.get("build_place", false))
	var sell_asked := bool(intent.get("build_sell", false))
	var upgrade_asked := bool(intent.get("build_upgrade", false))
	intent["build_place"] = false
	intent["build_sell"] = false
	intent["build_upgrade"] = false
	_mend_from_the_night(state)
	if House.inside(state):
		return
	if not (place_asked or sell_asked or upgrade_asked):
		return

	var at: Array = intent.get("build_cell", [-1, -1])
	var cell := Vector2i(int(at[0]), int(at[1]))
	if not Grid.in_bounds(cell):
		return

	if upgrade_asked:
		upgrade(state, cell)
		return
	if sell_asked:
		sell(state, cell)
		return
	if is_active(state):
		place(state, selected(state), cell)


## **Mending at night without the farmer** (task 0129): he is in bed, so the
## night HUD's REPAIR writes `intent.repair_cell` and this spends it - in
## the build step and the night only, all the ledger will pay for, through
## the same `Repair` road his verb used. An edge: read once, then cleared.
## Interim until 0134's cursor repairs anything it points at.
static func _mend_from_the_night(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	var asked: Array = intent.get("repair_cell", [-1, -1])
	intent["repair_cell"] = [-1, -1]
	var phase := int(state["phase"])
	if phase != Phases.PREPARATION and phase != Phases.NIGHT:
		return
	var cell := Vector2i(int(asked[0]), int(asked[1]))
	if Grid.in_bounds(cell) and Repair.can_mend(state, cell):
		Repair.apply_all(state, cell)


## Anything with a lifetime takes itself away when it runs out.
##
## The barricade is the only one today, and it is what stops it quietly
## becoming a cheaper wall.
static func expire(state: Dictionary) -> void:
	# **Only the things that can expire are looked at.** This used to copy
	# and sort every occupant on the farm - a hundred and ten keys - once a
	# tick, to find the barricades among them: twenty-nine microseconds of
	# every tick of a day on which nothing had been built at all. Task 0067
	# needed a hundred runs of ten nights and found it.
	var waiting: Array = state["expiring"]
	if waiting.is_empty():
		return
	var occupants: Dictionary = state["occupants"]
	var now := int(state["tick"])
	var gone: Array = []
	var left: Array = []
	for idx in waiting:
		var on: Variant = occupants.get(idx, null)
		if on == null or not (on as Dictionary).has("expires"):
			continue        # sold, chewed through, or never had one
		if now >= int((on as Dictionary)["expires"]):
			gone.append(idx)
		else:
			left.append(idx)
	state["expiring"] = left
	for idx in gone:
		occupants.erase(idx)
	if not gone.is_empty():
		state["grid_version"] = int(state["grid_version"]) + 1


## Remember that this cell has something on it with a lifetime.
static func _will_expire(state: Dictionary, cell: Vector2i) -> void:
	var idx := Grid.index(cell)
	if idx >= 0 and not (state["expiring"] as Array).has(idx):
		(state["expiring"] as Array).append(idx)


static func select(state: Dictionary, id: StringName) -> void:
	if not is_placeable(id):
		return
	var build: Dictionary = state["build"]
	build["selected"] = id
	build["active"] = true
