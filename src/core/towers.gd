class_name Towers
extends RefCounted

## The first thing that fights for you.
##
## A tower reloads, picks a target, and puts something in the air. It does none
## of that during the day: `Sim` only calls this from the night, which is the
## whole of "a tower is furniture until the sun goes down".
##
## ## Targeting is a rule, not an accident
##
## **Nearest to the house, ties broken by the lower entity id.** Not nearest to
## the tower - the thing about to reach the farmhouse is the thing worth
## shooting, and a tower that fired at whatever wandered closest to itself
## would let the leader through while it plinked at the back of the queue.
##
## The tie-break is the id because that is the one ordering in the game that
## cannot depend on how a Dictionary felt like iterating. Two runs of the same
## seed fire at the same target on the same tick, and `headless_check` checks
## it rather than hoping.
##
## ## Things travel
##
## A shot is a projectile with a speed, not an instant subtraction. `design.md`
## section 13 wants a night the player watches to find out whether their plan
## worked, and a plan whose outcome resolves invisibly is a spreadsheet.
##
## A projectile chases the id it was fired at. If that id dies first the shot
## is wasted, which is correct and is what task 0026 turns into a rule about
## not over-committing.


static func initial() -> Dictionary:
	return {
		"projectiles": [],
		"next_projectile_id": 1,
		# The cells that shoot, and the `grid_version` that list was made for.
		# **Rebuilt only when the farm changes**: scanning a hundred and ten
		# occupants every tick to find the four towers among them was most of
		# what a quiet tick cost.
		"tower_cells": [],
		"tower_version": -1,
	}


## The cells that shoot, refreshed when the farm has changed under them.
static func _towers(state: Dictionary) -> Array:
	if int(state["tower_version"]) != int(state["grid_version"]):
		state["tower_cells"] = _find_towers(state)
		state["tower_version"] = int(state["grid_version"])
	return state["tower_cells"]


static func _find_towers(state: Dictionary) -> Array:
	var out: Array = []
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var entry: Variant = GameData.DEFENCES.get(
			(occupants[idx] as Dictionary)["id"], null)
		if entry != null and (entry as Dictionary).has("reload_ticks"):
			out.append(int(idx))
	return out


# ------------------------------------------------------------------ the tick

## One tick of everything that shoots. Called from `Sim._tick_night()` only.
static func tick(state: Dictionary) -> void:
	_advance_projectiles(state)

	# **Nothing to shoot at costs nothing.** A farm covered in towers on a
	# quiet tick should not walk the whole grid to find that out.
	if Entities.count(state) == 0:
		_cool_down(state)
		return

	var occupants: Dictionary = state["occupants"]
	for idx in _towers(state):
		var tower: Dictionary = occupants[idx]
		var entry: Dictionary = GameData.DEFENCES[tower["id"]]

		var reload := int(tower.get("reload", 0))
		if reload > 0:
			tower["reload"] = reload - 1
			continue

		var cell := Grid.cell(int(idx))
		var target := _acquire(state, cell, entry)
		if target == 0:
			continue

		# **A round comes out of the pool, or the shot is a bad one.** Not a
		# silent tower: `design.md` does not do punishment mechanics, and a
		# tower that stopped is a tower the player stops looking at.
		var armed := Ammo.spend(state, tower["id"])
		_fire(state, cell, tower["id"], entry, target, armed)

		# **Asked fresh after every shot**, so a generator running dry part way
		# through a night slows the guns from the next shot rather than from the
		# next night. The same is true of the pool running out.
		var reload_ticks := int(entry["reload_ticks"])
		if not armed:
			reload_ticks = Ammo.weak_reload(reload_ticks)
		tower["reload"] = Power.scaled_ticks(state, reload_ticks)


## Reload everything, without looking for targets. What a quiet tick costs.
static func _cool_down(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	for idx in _towers(state):
		var tower: Dictionary = occupants[idx]
		var reload := int(tower.get("reload", 0))
		if reload > 0:
			tower["reload"] = reload - 1


# ----------------------------------------------------------------- targeting

## The id this tower should shoot, or 0 for nothing in range.
## Pick something to shoot, the way this tower says it picks.
##
## **The declaration decides, not the id.** Before task 0042 every tower did
## the same thing - nearest the house - because that was the only thing the
## code did. It still is what they all declare, which is why this port moved
## no behaviour; what changed is that a mortar wanting the thickest part of
## the crowd is now one word in a table rather than a branch in here.
static func _acquire(state: Dictionary, from: Vector2i, entry: Dictionary) -> int:
	var reach := int(entry.get("range", 0))
	if reach <= 0:
		return 0
	var minimum := int(entry.get("min_range", 0))
	var house := Farm.house_centre(state)
	var how := StringName(entry.get("targeting",
		GameData.TARGET_CLOSEST_TO_HOUSE))

	var best := 0
	var best_threat := 1 << 30
	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var distance := Grid.chebyshev(from, cell)
		if distance > reach or distance < minimum:
			continue
		# **Not what is already accounted for.** Without this a line of towers
		# all fires at the leader, most of those shots land on a corpse, and
		# the wave behind walks past untouched - which looks exactly like the
		# towers being too weak, and is not.
		if not Combat.worth_shooting(state, id):
			continue
		# **Lower is better, whatever "better" means to this tower.** One
		# comparison for every way of aiming, so adding a sixth is a line in
		# `_threat_of` and nothing else.
		var threat := _threat_of(state, how, id, cell, from, house)
		# The lower entity id breaks a tie. `Entities.ids()` is sorted, so the
		# first one found at a given score is already the lowest id and `<`
		# rather than `<=` keeps it.
		if threat < best_threat:
			best_threat = threat
			best = id
	return best


## How much this tower wants to shoot that one. Lower wins.
##
## `closest_to_house` is the original and the default: the thing nearest the
## thing being defended. The others exist because the towers of tasks 0043 to
## 0045 will want them, and because writing them now is four lines while
## writing them later is four branches.
static func _threat_of(state: Dictionary, how: StringName, id: int,
		cell: Vector2i, from: Vector2i, house: Vector2i) -> int:
	match how:
		GameData.TARGET_NEAREST:
			return Grid.chebyshev(from, cell)
		GameData.TARGET_WEAKEST:
			return Entities.get_one(state, id).get("hp", 0)
		GameData.TARGET_STRONGEST:
			return -int(Entities.get_one(state, id).get("hp", 0))
	return Grid.manhattan(cell, house)


## Ask what a given declaration would shoot from a given cell.
##
## **The seam that makes a declaration testable without building one.** A test
## for "strongest picks the healthiest" should not have to put a tower on the
## farm, pay for it and wait for a reload; it should be able to hand the rules
## an entry and get an answer.
static func acquire_for(state: Dictionary, from: Vector2i,
		entry: Dictionary) -> int:
	return _acquire(state, from, entry)


## Land one shot of this declaration on this target, now.
##
## The same seam for the other half: what a shape does when it arrives, asked
## directly rather than by waiting for a projectile to fly.
static func land_for_test(state: Dictionary, entry: Dictionary,
		target: int) -> void:
	_land(state, {
		"damage": int(entry.get("damage", 1)),
		"type": StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT)),
		"shape": StringName(entry.get("shape", GameData.SHAPE_SINGLE)),
		"splash_tiles": int(entry.get("splash_tiles", 1)),
		"splash_falloff_percent": int(entry.get("splash_falloff_percent", 100)),
	}, target)


## What a tower would shoot right now, for the threat overlay of task 0158 and
## for tests that would rather ask than infer.
static func target_of(state: Dictionary, cell: Vector2i) -> int:
	var tower := Farm.occupant(state, cell)
	if tower.is_empty():
		return 0
	var entry: Variant = GameData.DEFENCES.get(tower["id"], null)
	if entry == null or not (entry as Dictionary).has("reload_ticks"):
		return 0
	return _acquire(state, cell, entry as Dictionary)


# --------------------------------------------------------------- projectiles

## `armed` is whether a round was paid for. An unarmed shot is the tower doing
## the best it can with what is in the hopper: a third of the damage, plain
## impact, and none of what made it special - a mortar that cannot reach for
## powder is lobbing a rock.
static func _fire(state: Dictionary, from: Vector2i, kind: StringName,
		entry: Dictionary, target: int, armed: bool = true) -> void:
	var tiles_per_second := float(entry.get("projectile_tiles_per_second", 12))
	var speed := int(tiles_per_second * float(Player.SUBTILE)
		/ float(GameData.TICK_HZ))

	var id := int(state["next_projectile_id"])
	state["next_projectile_id"] = id + 1
	(state["projectiles"] as Array).append({
		"id": id,
		"from": kind,
		"pos": [from.x * Player.SUBTILE + Player.SUBTILE / 2,
				from.y * Player.SUBTILE + Player.SUBTILE / 2],
		"target": target,
		"damage": int(entry.get("damage", 1)) if armed 			else Ammo.weak_damage(int(entry.get("damage", 1))),
		"type": StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT)) 			if armed else GameData.DAMAGE_IMPACT,
		"armed": armed,
		# **The shot carries its shape**, because it lands after the tower has
		# finished thinking about it - and, at night nine, possibly after the
		# tower has come down. An unarmed shot is a plain one whatever the
		# tower normally does: a mortar that cannot reach for powder is
		# throwing a rock, and a rock does not splash.
		"shape": StringName(entry.get("shape", GameData.SHAPE_SINGLE)) 			if armed else GameData.SHAPE_SINGLE,
		"splash_tiles": int(entry.get("splash_tiles", 1)),
		"splash_falloff_percent": int(entry.get("splash_falloff_percent",
			int(float(entry.get("splash_falloff", 1.0)) * 100.0))),
		"speed": maxi(speed, 1),
	})


static func _advance_projectiles(state: Dictionary) -> void:
	var flying: Array = state["projectiles"]
	if flying.is_empty():
		return

	var landed: Array = []
	for shot in flying:
		var target := int(shot["target"])
		if not Entities.alive(state, target):
			# The thing it was chasing died first. The shot is wasted, which is
			# what stops a queue of projectiles all claiming the same kill.
			landed.append(shot)
			continue

		var to := Entities.position(state, target)
		var at := Vector2i(int(shot["pos"][0]), int(shot["pos"][1]))
		var step := int(shot["speed"])
		var delta := to - at
		var distance := absi(delta.x) + absi(delta.y)

		if distance <= step:
			_land(state, shot, target)
			landed.append(shot)
			continue

		# Integer movement along the line, the same way the player moves: no
		# floats, so two machines agree about where a bullet is.
		shot["pos"][0] = at.x + delta.x * step / distance
		shot["pos"][1] = at.y + delta.y * step / distance

	for shot in landed:
		flying.erase(shot)


## A shot arrives. **What it does when it gets there is the shape it carries**,
## not the tower it came from - the tower is long since irrelevant and may not
## even be standing.
static func _land(state: Dictionary, shot: Dictionary, target: int) -> void:
	var damage := int(shot["damage"])
	var kind := StringName(shot["type"])
	if StringName(shot.get("shape", GameData.SHAPE_SINGLE)) 			!= GameData.SHAPE_SPLASH:
		Combat.hit(state, target, damage, kind)
		return

	# Everything within the radius, full damage at the middle falling to
	# `splash_falloff` of it at the edge. Sorted by entity id, because two
	# machines have to kill the same one first.
	var middle := Entities.cell_of(state, target)
	var radius := maxi(int(shot.get("splash_tiles", 1)), 1)
	var edge := int(shot.get("splash_falloff_percent", 100))
	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var apart := Grid.chebyshev(middle, cell)
		if apart > radius:
			continue
		# Integer throughout: full in the middle, `edge` percent at the rim,
		# straight line between.
		var share := 100 - (100 - edge) * apart / radius
		Combat.hit(state, id, maxi(damage * share / 100, 1), kind)


## How many shots are in the air, for the debug overlay and the perf budget.
static func in_flight(state: Dictionary) -> int:
	return (state["projectiles"] as Array).size()


## Every tower on the farm, in cell order.
static func cells(state: Dictionary) -> Array:
	var out: Array = []
	for idx in _towers(state):
		out.append(Grid.cell(int(idx)))
	return out
