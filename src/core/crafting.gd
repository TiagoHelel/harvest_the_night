class_name Crafting
extends RefCounted

## Day resources becoming night structures.
##
## **The bridge the whole game rests on.** `design.md` pillar 3 is that a
## resource has two uses, and this is where the second one happens: wood and
## stone stop being things you sell and become a barricade that stands between
## a zombie and your house.
##
## ## Inputs are taken when an item starts, not when it is queued
##
## Queuing five barricades costs nothing at all. The wood goes in when an item
## reaches the front and begins, one at a time, which is the only arrangement
## that makes a queue honest:
##
## - **Queuing cannot bankrupt you.** Five items' worth of inputs taken up
##   front would make the queue a thing you dare not use.
## - **Cancelling something that has not started is free**, because nothing was
##   spent on it. Cancelling the item that is *running* costs the materials,
##   and that is what keeps stopping a decision rather than a free undo.
## - The ledger can never be asked for the same wood twice by two stations,
##   because each of them takes what it needs at the moment it needs it.
##
## A queue that could not be paid for simply waits: the item at the front
## retries every tick until the player brings back enough wood, rather than
## being thrown away for being early.
##
## ## A queue belongs to a station, not to the game
##
## `state["crafting"]` is keyed by the cell the station stands on, so the press
## and the kitchen need no new machinery and neither does a second workshop.
## Each entry holds a **list**: `queue[0]` is what is running and the rest are
## waiting. `QUEUE_LENGTH` is how many fit.
##
## ## Kits are not resources
##
## A barricade is not wood. It goes into `state["kits"]`, which build mode draws
## from, rather than into the ledger - a structure in the resource table would
## turn up in the shop's sell list and on the HUD, and it is neither of those
## things. A recipe whose output *is* a resource - oil, gunpowder, food - goes
## to the ledger instead, decided by what the output is rather than by which
## recipe made it.
##
## ## Days in a barrel
##
## Since task 0187 a recipe may take `days` instead of `ticks`: the keg's and
## the preserves jar's. Its batch is paid for when it starts, like any other,
## and then counted in mornings - `morning()`, from `Phases.begin_day` - and
## never by the tick, so a week of wine is seven mornings whatever the farmer
## does with the days between. `progress_at` answers in days for it.


## The station on this cell is gone. Drop its queue and its record.
##
## **The queue's inputs are not refunded.** They went in when the job started,
## the job is on the floor with the building, and a player who got their iron
## back out of a burning workshop would be being paid for losing it.
static func forget_cell(state: Dictionary, cell: Vector2i) -> void:
	var idx := Grid.index(cell)
	if idx < 0:
		return
	(state["crafting"] as Dictionary).erase(idx)
	# The record of what it ever made goes too, or the next station built on
	# this cell opens with somebody else's history in it.
	(state["produced"] as Dictionary).erase(idx)


static func initial() -> Dictionary:
	return {
		# {station cell index: {"recipe": id, "left": ticks, "total": ticks}}
		"crafting": {},
		# {structure id: how many are built and waiting to be placed}
		"kits": {},
		# **What each station has ever delivered**, by cell:
		# `{cell index: {"made": {recipe id: count}, "at": tick}}`.
		#
		# Kept apart from `crafting` because that entry is erased the moment a
		# queue empties, and "what happened while you were away" is a question
		# you ask precisely when the queue has finished. It only ever grows,
		# which makes it cheap: nothing scans it and nothing clears it.
		"produced": {},
		# **What each station makes when you press interact - one per station.**
		# It was a single id, which worked while the workshop was the only
		# station you could reach and broke the moment the press became
		# buildable: standing at a press with `barricade_kit` selected would
		# have made nothing and said nothing about why. Task 0037 puts a panel
		# in front of this and writes to the same place.
		"selected_recipe": _default_selection(),
	}


## The first recipe of every station that has one, in sorted order. Built from
## the table rather than written down, so a new station arrives selected.
static func _default_selection() -> Dictionary:
	var out := {}
	for id in GameData.sorted_names(GameData.RECIPES.keys()):
		var station: StringName = (GameData.RECIPES[id] as Dictionary)["station"]
		if not out.has(station):
			out[station] = id
	return out


# ------------------------------------------------------------------- asking


## Whether this is something that makes things.
static func is_station(id: StringName) -> bool:
	return not recipes_at(id).is_empty()


## What this station will make next.
static func selected_at(state: Dictionary, station: StringName) -> StringName:
	return StringName((state["selected_recipe"] as Dictionary).get(station, &""))


## Choose what a station makes. Refuses a recipe that station cannot make,
## rather than storing it and failing at the bench.
static func select_recipe(state: Dictionary, recipe_id: StringName) -> bool:
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	if recipe == null:
		return false
	var station: StringName = (recipe as Dictionary)["station"]
	(state["selected_recipe"] as Dictionary)[station] = recipe_id
	return true


## Start whatever the station on this cell is set to make.
##
## **The anchor, not the cell under the cursor.** A press is two by two, and
## four jobs running on four corners of one press would be four presses.
static func start_at(state: Dictionary, cell: Vector2i) -> bool:
	var id: StringName = Farm.occupant(state, cell).get("id", &"")
	if not is_station(id):
		return false
	return start(state, Building.anchor_of(state, cell),
		selected_at(state, id))

## **Days, not ticks** (task 0187): how many mornings this recipe takes, or 0
## for one timed by the tick at the bench.
static func days_of(recipe_id: StringName) -> int:
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	return 0 if recipe == null else int((recipe as Dictionary).get("days", 0))


## Every recipe a station can make, in a fixed order.
static func recipes_at(station: StringName) -> Array:
	var out: Array = []
	var ids := GameData.sorted_names(GameData.RECIPES.keys())
	for id in ids:
		if (GameData.RECIPES[id] as Dictionary)["station"] == station:
			out.append(id)
	return out


## Whether the player could start this now. **A recipe they cannot afford is
## shown and refused, never hidden**: a menu that grows as you get richer is a
## menu that teaches nothing about what to go and get.
## Whether this station will take another one of these.
##
## **Affording it is not asked here.** Queuing is free and the inputs are taken
## when the item reaches the front, so a player can line up five barricades and
## go and fetch the wood - which is the semi-idle promise of `design.md`
## section 13 rather than a trap for anybody who queues before gathering.
## Permanent tool upgrades also require their price and preceding tier at
## order time; ToolTiers refuses duplicate, unavailable or skipped tiers.
static func can_queue(state: Dictionary, cell: Vector2i,
		recipe_id: StringName) -> bool:
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	if recipe == null:
		return false
	var on := Farm.occupant(state, cell)
	if on.is_empty() or on["id"] != (recipe as Dictionary)["station"]:
		return false
	# **A wrecked machine takes nothing** (task 0187) until it is mended.
	if Building.is_wrecked(state, cell):
		return false
	return room_at(state, cell) > 0 and ToolTiers.why_not(state, recipe_id).is_empty()


## Whether the player could start this **now**, materials and all. What the
## panel greys a line on, and what `start()` still asks.
static func can_start(state: Dictionary, cell: Vector2i, recipe_id: StringName) -> bool:
	if busy(state, cell):
		return false
	if not can_queue(state, cell, recipe_id):
		return false
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	return Resources.can_afford(state, recipe["inputs"])


## What is short, for the tooltip that explains a greyed line.
static func missing(state: Dictionary, recipe_id: StringName) -> Dictionary:
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	if recipe == null:
		return {}
	return Resources.missing(state, (recipe as Dictionary)["inputs"])


## Whether anything is queued at this station, running or waiting.
static func busy(state: Dictionary, cell: Vector2i) -> bool:
	return not queue_at(state, cell).is_empty()


## The job at a station, or an empty Dictionary.
static func job(state: Dictionary, cell: Vector2i) -> Dictionary:
	return (state["crafting"] as Dictionary).get(Grid.index(cell), {})


## What is lined up at this station: `[0]` is running, the rest are waiting.
static func queue_at(state: Dictionary, cell: Vector2i) -> Array:
	var at := job(state, cell)
	return [] if at.is_empty() else (at["queue"] as Array)


## What this station is making right now, or `&""`.
static func making(state: Dictionary, cell: Vector2i) -> StringName:
	var lined_up := queue_at(state, cell)
	return &"" if lined_up.is_empty() else StringName(lined_up[0])


## How many more items this station will take.
static func room_at(state: Dictionary, cell: Vector2i) -> int:
	return maxi(GameData.QUEUE_LENGTH - queue_at(state, cell).size(), 0)


## Ticks left on the item at the front, and how many it started with. For the
## bar on the panel. Zero when nothing is running or nothing can be paid for.
## **Mornings**, for a batch that takes days (task 0187).
static func progress_at(state: Dictionary, cell: Vector2i) -> Array:
	var at := job(state, cell)
	if at.is_empty():
		return [0, 0]
	return [int(at["left"]), int(at["total"])]


## Whether the front item is waiting on materials rather than on time. What the
## panel says instead of a countdown.
static func is_stalled(state: Dictionary, cell: Vector2i) -> bool:
	var at := job(state, cell)
	return not at.is_empty() and int(at["total"]) <= 0


## How many of a structure are built and waiting to be placed.
static func kits(state: Dictionary, id: StringName) -> int:
	return int((state["kits"] as Dictionary).get(id, 0))


## Take one off the pile. Build mode calls this; it refuses rather than going
## negative, the same way the ledger does.
static func take_kit(state: Dictionary, id: StringName) -> bool:
	var all: Dictionary = state["kits"]
	var have := int(all.get(id, 0))
	if have <= 0:
		return false
	if have == 1:
		all.erase(id)
	else:
		all[id] = have - 1
	return true


# -------------------------------------------------------------------- doing

## Put one on the end of the queue. **Costs nothing.**
static func enqueue(state: Dictionary, cell: Vector2i,
		recipe_id: StringName) -> bool:
	if not can_queue(state, cell, recipe_id):
		return false
	var all: Dictionary = state["crafting"]
	var idx := Grid.index(cell)
	if not all.has(idx):
		all[idx] = {"queue": [], "left": 0, "total": 0}
	var at: Dictionary = all[idx]
	(at["queue"] as Array).append(recipe_id)
	if (at["queue"] as Array).size() == 1:
		_begin_front(state, at)
	return true


## Queue one. Kept under its old name because it is what `Interact` calls and
## what every test since task 0019 says.
static func start(state: Dictionary, cell: Vector2i, recipe_id: StringName) -> bool:
	return enqueue(state, cell, recipe_id)


## Take the item at `index` out of the queue. `0` is the one running.
##
## **What it costs depends on whether it started.** An item still waiting has
## had nothing spent on it, so removing it is free. The one at the front has
## the wood in it already and that wood does not come back - which is what
## keeps stopping a decision rather than a free undo.
static func cancel_at(state: Dictionary, cell: Vector2i, index: int) -> bool:
	var all: Dictionary = state["crafting"]
	var idx := Grid.index(cell)
	if not all.has(idx):
		return false
	var at: Dictionary = all[idx]
	var lined_up: Array = at["queue"]
	if index < 0 or index >= lined_up.size():
		return false

	lined_up.remove_at(index)
	if lined_up.is_empty():
		all.erase(idx)
		return true
	if index == 0:
		_begin_front(state, at)     # the next one steps up and pays its way
	return true


## Give up on whatever is running, leaving the rest of the queue alone.
static func cancel(state: Dictionary, cell: Vector2i) -> bool:
	return cancel_at(state, cell, 0)


## Throw the whole queue away. The running item's inputs are gone; the rest
## cost nothing and so give nothing back.
static func cancel_all(state: Dictionary, cell: Vector2i) -> bool:
	var all: Dictionary = state["crafting"]
	var idx := Grid.index(cell)
	if not all.has(idx):
		return false
	all.erase(idx)
	return true


## Start the item at the front, paying for it.
##
## **A front item that cannot be paid for waits.** `total` stays at zero, which
## is what `is_stalled()` reads, and every tick tries again - so a queue lined
## up before the wood was gathered picks itself up the moment the wood arrives
## rather than throwing the item away for being early.
static func _begin_front(state: Dictionary, at: Dictionary) -> void:
	var lined_up: Array = at["queue"]
	if lined_up.is_empty():
		at["left"] = 0
		at["total"] = 0
		return
	var recipe: Dictionary = GameData.RECIPES[StringName(lined_up[0])]
	if not Resources.pay(state, recipe["inputs"]):
		at["left"] = 0
		at["total"] = 0
		return
	# **A batch that takes days** (task 0187) is counted in mornings, and
	# neither steady hands nor a brownout touches it: a barrel ages at its
	# own pace.
	var days := days_of(StringName(lined_up[0]))
	if days > 0:
		at["left"] = days
		at["total"] = days
		return
	# The batch is costed when it starts. A brown-out half way through does not
	# lengthen work already committed - the corn is in the hopper.
	# **`craft_percent` was declared and read by nothing.** "Steady hands"
	# costs four points and says the workshop, press and kitchen work a
	# third faster; until task 0106's release checklist went looking for
	# claims it could not back up, it did nothing at all. The tech comes
	# off the recipe and the brownout is applied to what is left, which is
	# the order the two happen in: a faster bench still runs slow on a
	# short supply.
	var base := int(recipe["ticks"]) * 100 \
		/ maxi(Tech.bonus(state, "craft_percent", 100), 1)
	var ticks := maxi(Power.scaled_ticks(state, base), 1)
	at["left"] = ticks
	at["total"] = ticks


## One tick of everything on the farm making something. Called from
## `Sim._tick_day()`.
##
## It runs whether or not the player is looking at it - that is the semi-idle
## promise of `design.md` section 13, and it is why the queue of task 0037 is
## worth having.
static func tick(state: Dictionary) -> void:
	var all: Dictionary = state["crafting"]
	if all.is_empty():
		return

	# Sorted, so that two stations finishing on the same tick deliver in the
	# same order every run. **Plain `sort()` here and not `sorted_names()`**:
	# these keys are cell indices, and integers sort as integers.
	var keys: Array = all.keys()
	keys.sort()
	var emptied: Array = []
	for idx in keys:
		var at: Dictionary = all[idx]
		# **A wrecked machine stands still** (task 0187): no batch starts in
		# it and none ages until it is mended.
		if Building.is_wrecked(state, Grid.cell(int(idx))):
			continue

		# **A stalled front item retries.** `total` of zero means the inputs
		# were not there when it stepped up; every tick asks again, so a queue
		# lined up before the wood was gathered starts itself the moment the
		# wood arrives rather than being thrown away for being early.
		if int(at["total"]) <= 0:
			_begin_front(state, at)
			if int(at["total"]) <= 0:
				continue
			continue        # it starts this tick; the first of its ticks is next

		# **Days are the morning's** (task 0187): a batch in a barrel ages in
		# `morning()`, never by the tick.
		if days_of(StringName((at["queue"] as Array)[0])) > 0:
			continue

		at["left"] = int(at["left"]) - 1
		if int(at["left"]) > 0:
			continue
		if _finish_front(state, int(idx), at):
			emptied.append(idx)

	for idx in emptied:
		all.erase(idx)


## **A day for every batch that takes days** (task 0187), once each morning
## from `Phases.begin_day`. A batch on its last day is delivered, and the next
## in the queue steps up and pays: its first day is tomorrow's. A wrecked
## machine's batch waits, aging nothing, and one still waiting on its
## materials is the day's ticks' to start.
static func morning(state: Dictionary) -> void:
	var all: Dictionary = state["crafting"]
	var keys: Array = all.keys()
	keys.sort()
	var emptied: Array = []
	for idx in keys:
		var at: Dictionary = all[idx]
		var lined_up: Array = at["queue"]
		if lined_up.is_empty() or int(at["total"]) <= 0 \
				or days_of(StringName(lined_up[0])) <= 0 \
				or Building.is_wrecked(state, Grid.cell(int(idx))):
			continue
		at["left"] = int(at["left"]) - 1
		if int(at["left"]) > 0:
			continue
		if _finish_front(state, int(idx), at):
			emptied.append(idx)
	for idx in emptied:
		all.erase(idx)


## Off the front, delivered and written down, and the next one steps up and
## pays. True when that left the queue empty.
static func _finish_front(state: Dictionary, idx: int, at: Dictionary) -> bool:
	var lined_up: Array = at["queue"]
	var recipe_id := StringName(lined_up[0])
	lined_up.remove_at(0)
	_deliver(state, recipe_id)
	_record(state, Grid.cell(idx), recipe_id)
	if lined_up.is_empty():
		return true
	_begin_front(state, at)
	return false


## What a station has delivered in total, and on which tick it last did.
## Empty for a bench nobody has used.
static func produced_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	return (state["produced"] as Dictionary).get(Grid.index(cell), {})


## Everything a station has made, as `{recipe id: count}`.
static func made_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var log := produced_at(state, cell)
	return {} if log.is_empty() else (log["made"] as Dictionary)


## The tick this station last finished something, or -1.
static func last_delivery_at(state: Dictionary, cell: Vector2i) -> int:
	var log := produced_at(state, cell)
	return -1 if log.is_empty() else int(log["at"])


## Write down that this station finished one of these.
##
## **The record the panel reads to say what happened while you were elsewhere.**
## `design.md` section 13 promises you come back to something better; a bench
## that silently jumped from three queued to three kits in the pile would be
## the same event with none of the telling.
static func _record(state: Dictionary, cell: Vector2i,
		recipe_id: StringName) -> void:
	var all: Dictionary = state["produced"]
	var idx := Grid.index(cell)
	if not all.has(idx):
		all[idx] = {"made": {}, "at": -1}
	var log: Dictionary = all[idx]
	var made: Dictionary = log["made"]
	made[recipe_id] = int(made.get(recipe_id, 0)) + 1
	log["at"] = int(state["tick"])
	Events.add(state, &"craft_done", {
		"recipe": recipe_id, "cell": [cell.x, cell.y],
	})


## Put the output where it belongs: a resource in the ledger, a structure on
## the pile of things waiting to be placed.
static func _deliver(state: Dictionary, recipe_id: StringName) -> void:
	var output: Dictionary = (GameData.RECIPES[recipe_id] as Dictionary)["output"]
	var ids := GameData.sorted_names(output.keys())
	for id in ids:
		var n := int(output[id])
		if not GameData.tool_output(id).is_empty():
			ToolTiers.deliver(state, id)
		elif GameData.RESOURCES.has(id):
			Resources.add(state, id, n)
		else:
			var all: Dictionary = state["kits"]
			all[id] = int(all.get(id, 0)) + n
