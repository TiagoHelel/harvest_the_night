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
## **Less the money** (task 0234): a defence's cost has a `MONEY` share, and a
## kit is its materials only (`materials_of`). Placing from a kit still
## charges the money (`money_of`), so the day's purse pays for every defence
## however it was made.
##
## ## The calendar opens the arsenal
##
## A defence goes down from the season it opens in (task 0234, `unlocked`):
## summer's flamethrower is refused all spring with the season's name, and
## Year 2 keeps every one.
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
## **The defences in the order the year hands them out** (task 0224), and
## within a season from the cheapest (task 0234: `price_of`, the name for a
## tie). A defence a later season adds goes after the earlier seasons', so
## the slots and keys a player learnt in spring do not move under them.
static func placeable_ids() -> Array:
	if _order.is_empty():
		var names := GameData.sorted_names(GameData.DEFENCES.keys())
		for season in GameData.SEASONS:
			var these: Array = []
			for id in names:
				if GameData.defence_season(GameData.DEFENCES[id]) == season:
					these.append(id)
			these.sort_custom(func(a: StringName, b: StringName) -> bool:
				return price_of(a) < price_of(b) or (price_of(a) == price_of(b) and String(a) < String(b)))
			_order.append_array(these)
		_order.append_array(GameData.sorted_names(GameData.BUILDINGS.keys()))
	return _order.duplicate()


## `placeable_ids()`, worked out once: the tables are constants, and the
## hotbar asks every frame.
static var _order: Array = []


## **The season a defence opens in** (task 0234), 0 for spring to 3 for
## winter. A production building has none, and answers spring.
static func season_of(id: StringName) -> int:
	if not GameData.DEFENCES.has(id):
		return 0
	return maxi(GameData.SEASONS.find(GameData.defence_season(GameData.DEFENCES[id])), 0)


## **Whether the calendar has opened it** (task 0234): a defence from its
## season on, and every one from Year 2 - `Calendar.season_reached`, the
## tree's own gate. A production building always.
static func unlocked(state: Dictionary, id: StringName) -> bool:
	return Calendar.season_reached(state, season_of(id))


## **The money share of its price** (task 0234): what placing it charges, off
## a kit as much as off the ledger.
static func money_of(id: StringName) -> int:
	return int(cost_of(id).get(GameData.MONEY, 0))


## Its price less the money: what a kit is made of (task 0234).
static func materials_of(id: StringName) -> Dictionary:
	var out: Dictionary = cost_of(id).duplicate()
	out.erase(GameData.MONEY)
	return out


## **What it costs somebody who has only money** (task 0234): its money, and
## its materials at what the stall charges for them - a group such as the fish
## at its cheapest kind. The measure 0194 set the day's money against; the
## hotbar's order and the table in `implementation/BALANCE.md`.
static func price_of(id: StringName) -> int:
	var cost := cost_of(id)
	var out := 0
	for res in GameData.sorted_names(cost.keys()):
		if res == GameData.MONEY:
			out += int(cost[res])
			continue
		var each: StringName = GameData.pay_order(res)[0] if GameData.is_any_of(res) else res
		out += Shop.buy_price(each) * int(cost[res])
	return out


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


## **One number of an occupant at its level** (task 0231): its row's, with
## every step up to its level laid over it as `entry_at()` lays them - without
## a cell to look up or a row to copy, for the field, which prices every
## occupant on every rebuild, and for the view. `missing` when neither says.
static func levelled_stat(on: Dictionary, key: String, missing: int = 0) -> int:
	var entry: Variant = entry_of(StringName(on.get("id", &"")))
	if entry == null:
		return missing
	var value := int((entry as Dictionary).get(key, missing))
	var steps := _levels_of(StringName(on["id"]))
	for step in steps.slice(0, maxi(int(on.get("level", 1)) - 1, 0)):
		value = int(((step as Dictionary)["gives"] as Dictionary).get(key, value))
	return value


## **What the thing on this cell is made of** (task 0231): its row's price,
## and the price of every level that rebuilt it (`rebuilds`) - the hardwood a
## wall was rebuilt in is in its walls, where the gunpowder that bought a
## tower's level three is not (0113). What mending it takes a share of.
static func made_of(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return {}
	var entry: Variant = entry_of(StringName(on["id"]))
	if entry == null:
		return {}
	var out: Dictionary = ((entry as Dictionary).get("cost", {}) as Dictionary).duplicate()
	var steps := _levels_of(StringName(on["id"]))
	for step in steps.slice(0, maxi(int(on.get("level", 1)) - 1, 0)):
		if not bool((step as Dictionary).get("rebuilds", false)):
			continue
		var paid: Dictionary = (step as Dictionary)["cost"]
		for res in GameData.sorted_names(paid.keys()):
			out[res] = int(out.get(res, 0)) + int(paid[res])
	return out


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
	var steps := _levels_of(StringName(on["id"]))
	if steps.is_empty():
		return [&"WHY_NO_UPGRADE", StringName(on["id"])]
	var level := level_at(state, cell)
	if level >= GameData.TOP_TOWER_LEVEL:
		return [&"WHY_TOP_LEVEL"]
	# **A family stops at its last row** (task 0226). The hive has one step,
	# and a check against `TOP_TOWER_LEVEL` alone let it go up again into a
	# level with no row - free, since `upgrade_cost` has nothing to say past
	# the table - and the same for any family with fewer rows than three.
	if level > steps.size():
		return [&"WHY_LAST_LEVEL"]
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
	# **The tree's spare stakes are the barricade's** (task 0225): its nodes
	# say "barricades", and the bait - the other thing with a nightly
	# allowance - is rationed by the fish, not by the stakes.
	if limit > 0 and id == &"barricade":
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


## Whether it can be paid for, by kit or by ledger. **A kit still wants its
## money** (task 0234): it is the materials paid early, never the purse.
static func affordable(state: Dictionary, id: StringName) -> bool:
	if Crafting.kits(state, id) > 0:
		return Resources.can_afford(state, {GameData.MONEY: money_of(id)})
	if kit_only(id):
		return false
	return Resources.can_afford(state, cost_of(id))


## What placing it would charge now: the money alone when a kit is banked,
## the whole price when not (task 0234).
static func charge_for(state: Dictionary, id: StringName) -> Dictionary:
	if Crafting.kits(state, id) > 0:
		return {GameData.MONEY: money_of(id)} if money_of(id) > 0 else {}
	return cost_of(id)


## **Down from a kit only** (task 0225): the zombie bait, whose cost is the fish
## a recipe pays from any species and the ledger never holds.
static func kit_only(id: StringName) -> bool:
	var entry: Variant = entry_of(id)
	return entry != null and bool((entry as Dictionary).get("kit_only", false))


## The station whose recipe makes this one's kit, first by name, or `&""`.
static func kit_station(id: StringName) -> StringName:
	for recipe_id in GameData.sorted_names(GameData.RECIPES.keys()):
		var recipe: Dictionary = GameData.RECIPES[recipe_id]
		if (recipe["output"] as Dictionary).has(id):
			return StringName(recipe["station"])
	return &""


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
	# **Not before its season** (task 0234), asked before the allowance and
	# the price, neither of which matters yet - as the tree asks it.
	if not unlocked(state, id):
		return [&"WHY_NOT_YET_SEASON", StringName(GameData.SEASONS[season_of(id)])]
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
		if kit_only(id) and Crafting.kits(state, id) <= 0:
			return [&"WHY_KIT_ONLY", kit_station(id)]
		return [&"WHY_SHORT", Resources.missing(state, charge_for(state, id))]
	return []


## What selling the thing on this cell would give back. Empty when there is
## nothing there, or when it is not the player's to sell.
static func refund_for(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_placeable(on["id"]):
		return {}
	# **A spent braid gives nothing back** (task 0228): its garlic is used up.
	if Garlic.repels(StringName(on["id"])) and Garlic.state_of(on) == Garlic.SPENT:
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

## Put it down. Pays with a kit if there is one, and out of the ledger if not
## - the money share out of the ledger either way (task 0234).
static func place(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if not can_place(state, id, cell):
		return false

	# The kit first: it is the materials already paid, and a player who banked
	# one during the day meant to use it. A thing from a kit only has no other
	# way. Then what is left to pay: the money, or the whole price.
	var paid := charge_for(state, id)
	var from_kit := Crafting.take_kit(state, id)
	if not from_kit and kit_only(id):
		return false
	if not Resources.pay(state, paid):
		if from_kit:
			Crafting.bank_kit(state, id)
		return false

	var entry: Dictionary = entry_of(id)
	var occupant := {"id": id, "hp": int(entry.get("hp", 1))}
	# **Garlic hung mid-wave is in its first night already** (task 0228); one
	# hung in the build step starts counting at the waves (`Garlic.wear`).
	if Garlic.repels(id) and int(state["phase"]) == Phases.NIGHT:
		occupant["nights"] = 1
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
			# What was paid comes back, and the kit with it.
			Resources.gain(state, paid)
			if from_kit:
				Crafting.bank_kit(state, id)
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
	# **Thrown stays thrown** (task 0225): a bait's price is fish of any kind,
	# and the ledger has no such thing to give back.
	if kit_only(id):
		return [&"WHY_THROWN"]
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
