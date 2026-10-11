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
##
## ## A tower looks near itself
##
## Until task 0218 every tower looked at every zombie on the farm to find the
## few in its reach, every tick it was loaded. A swarm of a few hundred made
## that the night's whole cost. Now the crowd is filed once a tick into
## squares of `CROWD_BUCKET` cells (`_crowd()`), and a tower looks only in the
## squares its reach touches. It measures each one there exactly as before
## and breaks a tie by the lower id, so it picks what the whole farm's scan
## picked - `headless_v1` holds the two to the same answer for every way of
## aiming.

## The side of one square of the crowd's filing, in cells. **Not a lever**:
## it changes how fast a tower finds its target, never which one it finds.
const CROWD_BUCKET := 4


static func initial() -> Dictionary:
	# `shots_fired` is merged in below; it lives here so that `State.create()`
	# adopts it with the rest of the tower state.
	return {
		"projectiles": [],
		"next_projectile_id": 1,
		# Every shot any tower has fired, whatever shape it was.
		"shots_fired": 0,
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

	# **Filed once, after the shots in the air have landed.** Nothing walks or
	# arrives while the towers fire, so the filing stays true for the whole
	# loop; one killed since is passed over, as the full scan passes it over.
	var crowd := _crowd(state)
	var occupants: Dictionary = state["occupants"]
	for idx in _towers(state):
		var tower: Dictionary = occupants[idx]
		var cell_of_it := Grid.cell(int(idx))
		# **The levelled entry**, so a Torre Automatica is the gun tower's
		# own row with its three numbers changed and nothing here knows.
		var entry: Dictionary = Building.entry_at(state, cell_of_it)

		var reload := int(tower.get("reload", 0))
		if reload > 0:
			tower["reload"] = reload - 1
			continue

		var cell := cell_of_it
		# **Bees spread** (task 0226): a hive stings one not yet stung while
		# there is one in reach - a sting is refreshed, never stacked, so a
		# second on the same one is a second wasted - and tops one up only
		# when there is not.
		var spreads := StringName(entry.get("shape", GameData.SHAPE_SINGLE)) == GameData.SHAPE_STING
		var target := _acquire(state, cell, entry, [], crowd, spreads)
		if target == 0 and spreads:
			target = _acquire(state, cell, entry, [], crowd)
		if target == 0:
			continue

		# **A round comes out of the pool, or the shot is a bad one.** Not a
		# silent tower: `design.md` does not do punishment mechanics, and a
		# tower that stopped is a tower the player stops looking at.
		var armed := _load(state, tower, entry)
		# **Every shot, whatever shape it is.** Three of the four shapes fire
		# nothing that flies - a cone and a line land at once - so counting
		# projectiles stopped meaning "did it shoot" the moment the
		# flamethrower worked. Task 0033's power assert was reading zero from
		# a wall of crossbows that were firing perfectly well.
		state["shots_fired"] = int(state.get("shots_fired", 0)) + 1
		# **How many things it shoots at once.** `targets` has been in the
		# table since it was written and nothing read it; it is what a level
		# three tower gets, and it is the whole of the word "automatic" -
		# a behaviour rather than a bigger number.
		#
		# Each extra target is acquired with the ones already taken excluded,
		# so a tower with two barrels does not put both into the same zombie.
		var barrels := maxi(int(entry.get("targets", 1)), 1)
		var taken: Array = [target]
		while taken.size() < barrels:
			var another := _acquire(state, cell, entry, taken, crowd, spreads)
			if another == 0 and spreads:
				another = _acquire(state, cell, entry, taken, crowd)
			if another == 0:
				break
			taken.append(another)
		for at in taken:
			match StringName(entry.get("shape", GameData.SHAPE_SINGLE)):
				GameData.SHAPE_CONE:
					_burn_cone(state, cell, entry, int(at), armed)
				GameData.SHAPE_LINE:
					_pierce_line(state, cell, entry, int(at), armed)
				GameData.SHAPE_STING:
					_sting(state, tower, entry, int(at), armed)
				_:
					_fire(state, cell, tower["id"], entry, int(at), armed)

		# **Asked fresh after every shot**, so a generator running dry part way
		# through a night slows the guns from the next shot rather than from the
		# next night. The same is true of the pool running out.
		# The tree oils the works, if it has been bought.
		var reload_ticks := int(entry["reload_ticks"]) \
			* Tech.bonus(state, "tower_reload_percent", 100) / 100
		if not armed:
			reload_ticks = Ammo.weak_reload(reload_ticks)
		# **Bees run on no generator** (task 0226): a tower that draws no
		# power is not slowed when the farm is short of it. Every tower before
		# the hive draws some, so this is the hive's alone.
		tower["reload"] = reload_ticks if int(entry.get("energy_draw", 0)) <= 0 \
			else Power.scaled_ticks(state, reload_ticks)
		# The round burns for the whole wait until the next shot: this one
		# covers `reload + 1` ticks of firing, the tick it fired on included.
		if armed and tower.has("ammo_lit"):
			tower["ammo_lit"] = maxi(int(tower["ammo_lit"])
				- int(tower["reload"]) - 1, 0)


## A round out of the pool for one shot, or false for a bad one.
##
## **Most towers pay a round a shot. A flamethrower pays a round per
## `ammo_every_ticks` of firing** (task 0116): its table said two seconds of
## flame to a round from the day it was written, nothing read it, and a cone
## twice a second went through twenty rounds where it should have burnt five.
## What is left of the lit round is a countdown on the occupant itself -
## per-tower bookkeeping that changes no shape on the farm, so no
## `Farm.touch()` - and a save from before it has no such key and simply
## lights its next round.
static func _load(state: Dictionary, tower: Dictionary,
		entry: Dictionary) -> bool:
	var every := int(entry.get("ammo_every_ticks", 0))
	if every <= 0:
		return Ammo.spend(state, tower["id"])
	if int(tower.get("ammo_lit", 0)) > 0:
		return true
	if not Ammo.spend(state, tower["id"]):
		return false
	tower["ammo_lit"] = every
	return true


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
## What a tower hits for tonight, and how far it sees.
##
## **One place each**, because the tree, the empty pool and the table all have
## an opinion and four copies of that arithmetic would be four chances for
## them to disagree.
static func damage_of(state: Dictionary, entry: Dictionary,
		armed: bool = true) -> int:
	var damage := int(entry.get("damage", 1)) \
		* Tech.bonus(state, "tower_damage_percent", 100) / 100
	return damage if armed else Ammo.weak_damage(damage)


##
## **And where it stands** (task 0229): a tower whose own cell is lit
## (`Light.is_lit`) sees `LIGHT_REACH_BONUS` further.
static func reach_of(state: Dictionary, entry: Dictionary, cell: Vector2i) -> int:
	var reach := int(entry.get("range", 0))
	if reach <= 0:
		return 0
	reach += Tech.bonus(state, "tower_range_bonus", 0)
	if Light.is_lit(state, cell):
		reach += GameData.LIGHT_REACH_BONUS
	return reach


## `crowd` is `_crowd()`'s filing for this tick, or empty for a look at the
## whole farm - which is what `acquire_for()` and `target_of()` take.
##
## `unstung` passes over everything a hive has already stung (task 0226).
static func _acquire(state: Dictionary, from: Vector2i, entry: Dictionary,
		skip: Array = [], crowd: Dictionary = {}, unstung: bool = false) -> int:
	var reach := reach_of(state, entry, from)
	if reach <= 0:
		return 0
	var minimum := int(entry.get("min_range", 0))
	var house := Farm.house_centre(state)
	var how := StringName(entry.get("targeting",
		GameData.TARGET_CLOSEST_TO_HOUSE))

	var best := 0
	var best_threat := 1 << 30
	# **Whether it reaches the air** (task 0249): what does not, never picks
	# a flyer in it.
	var up := bool(entry.get("hits_flying", false))
	var near: Array = Entities.ids(state) if crowd.is_empty() \
		else _near(crowd, from, reach)
	var stung: Dictionary = state["stung"]
	for id in near:
		# Already being shot at by this tower's other barrel.
		if skip.has(id):
			continue
		if unstung and stung.has(id):
			continue
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var distance := Grid.chebyshev(from, cell)
		if distance > reach or distance < minimum:
			continue
		if not up and Enemies.airborne(state, id):
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
		# **The lower entity id breaks a tie**, asked outright. The whole
		# farm's ids come lowest first and the crowd's squares do not, and
		# the rule cannot depend on which of the two did the looking.
		if threat < best_threat or (threat == best_threat and id < best):
			best_threat = threat
			best = id
	return best


## **The crowd, filed by where it stands** (task 0218): every live entity's
## id in the square of `CROWD_BUCKET` cells its cell is in, lowest id first
## within a square. A local of one `tick()`, never kept in the state.
static func _crowd(state: Dictionary) -> Dictionary:
	var across := (Grid.WIDTH + CROWD_BUCKET - 1) / CROWD_BUCKET
	var down := (Grid.HEIGHT + CROWD_BUCKET - 1) / CROWD_BUCKET
	var squares := {}
	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, int(id))
		# The full scan passes over the same ones.
		if cell.x < 0:
			continue
		# Off the farm's edge counts as the edge's square, where a tower whose
		# reach crosses the edge still looks.
		var at := clampi(cell.y / CROWD_BUCKET, 0, down - 1) * across \
			+ mini(cell.x / CROWD_BUCKET, across - 1)
		if squares.has(at):
			(squares[at] as Array).append(id)
		else:
			squares[at] = [id]
	return {"across": across, "squares": squares}


## Every id in the squares a reach of `reach` round `from` touches: everybody
## in reach and some who are not, whom `_acquire()` measures and passes over.
static func _near(crowd: Dictionary, from: Vector2i, reach: int) -> Array:
	var across := int(crowd["across"])
	var squares: Dictionary = crowd["squares"]
	var left := clampi(from.x - reach, 0, Grid.WIDTH - 1) / CROWD_BUCKET
	var right := clampi(from.x + reach, 0, Grid.WIDTH - 1) / CROWD_BUCKET
	var top := clampi(from.y - reach, 0, Grid.HEIGHT - 1) / CROWD_BUCKET
	var bottom := clampi(from.y + reach, 0, Grid.HEIGHT - 1) / CROWD_BUCKET
	var out: Array = []
	for row in range(top, bottom + 1):
		for column in range(left, right + 1):
			var here: Variant = squares.get(row * across + column, null)
			if here != null:
				out.append_array(here)
	return out


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
		entry: Dictionary, skip: Array = []) -> int:
	return _acquire(state, from, entry, skip)


## The same question **asked the way `tick()` asks it**, through the crowd's
## squares (task 0218): the seam that holds the squares to `acquire_for()`'s
## look at the whole farm.
static func acquire_nearby_for(state: Dictionary, from: Vector2i,
		entry: Dictionary, skip: Array = []) -> int:
	return _acquire(state, from, entry, skip, _crowd(state))


## Land one shot of this declaration on this target, now.
##
## The same seam for the other half: what a shape does when it arrives, asked
## directly rather than by waiting for a projectile to fly.
static func land_for_test(state: Dictionary, entry: Dictionary,
		target: int) -> void:
	_land_at(state, {
		"damage": damage_of(state, entry),
		"type": StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT)),
		"shape": StringName(entry.get("shape", GameData.SHAPE_SINGLE)),
		"splash_tiles": int(entry.get("splash_tiles", 1)),
		"splash_falloff_percent": int(entry.get("splash_falloff_percent", 100)),
	}, Entities.cell_of(state, target), target)


## Land one shell of this declaration **on a cell**, now.
##
## The splash seam. `land_for_test()` above lands on whoever was being chased,
## which is what a guided shot does; a mortar shell lands on a patch of dirt
## and everything near it finds out.
static func land_at_for_test(state: Dictionary, entry: Dictionary,
		cell: Vector2i) -> void:
	_land_at(state, {
		"damage": damage_of(state, entry),
		"type": StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT)),
		"shape": StringName(entry.get("shape", GameData.SHAPE_SINGLE)),
		"splash_tiles": int(entry.get("splash_tiles", 1)),
		"splash_falloff_percent": int(entry.get("splash_falloff_percent", 100)),
	}, cell)


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

	# The cell it is aimed at, taken **now**. This is the whole of "lands
	# where it was aimed, not where it ended up".
	var aimed := Entities.cell_of(state, target)
	if aimed.x < 0:
		aimed = from

	var id := int(state["next_projectile_id"])
	state["next_projectile_id"] = id + 1
	(state["projectiles"] as Array).append({
		"id": id,
		"from": kind,
		"pos": [from.x * Player.SUBTILE + Player.SUBTILE / 2,
				from.y * Player.SUBTILE + Player.SUBTILE / 2],
		"target": target,
		"damage": damage_of(state, entry, armed),
		"type": StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT)) 			if armed else GameData.DAMAGE_IMPACT,
		"armed": armed,
		# **The shot carries its shape**, because it lands after the tower has
		# finished thinking about it - and, at night nine, possibly after the
		# tower has come down. An unarmed shot is a plain one whatever the
		# tower normally does: a mortar that cannot reach for powder is
		# throwing a rock, and a rock does not splash.
		"shape": StringName(entry.get("shape", GameData.SHAPE_SINGLE)) 			if armed else GameData.SHAPE_SINGLE,
		"splash_tiles": int(entry.get("splash_tiles", 1)),
		"splash_falloff_percent": int(entry.get("splash_falloff_percent", 100)),
		"speed": maxi(speed, 1),
		# **Where it is going, and how long it has.** A guided shot ignores
		# both and chases `target`; a ballistic one was aimed at a place and
		# arrives there whether or not anything is still standing on it.
		"aim": StringName(entry.get("aim", GameData.AIM_GUIDED)),
		"to": [aimed.x, aimed.y],
		"left": int(entry.get("flight_ticks", 0)),
	})


static func _advance_projectiles(state: Dictionary) -> void:
	var flying: Array = state["projectiles"]
	if flying.is_empty():
		return

	var landed: Array = []
	for shot in flying:
		# **A shell in the air does not care what happened to anybody.** It
		# counts down and lands on the cell it was aimed at - which is what
		# lets a zombie walk out of it, and what makes standing still in front
		# of a mortar a mistake.
		if StringName(shot.get("aim", GameData.AIM_GUIDED)) 				== GameData.AIM_BALLISTIC:
			shot["left"] = int(shot["left"]) - 1
			if int(shot["left"]) <= 0:
				# **The target goes along**, for the one ballistic shot that
				# is not a splash: an empty mortar's rock (task 0116). It
				# used to land on its cell with nobody to hit, so a mortar
				# out of powder was a silent tower - which 0035 says out of
				# ammunition must never be. A splash ignores it.
				_land_at(state, shot, Vector2i(int(shot["to"][0]),
					int(shot["to"][1])), int(shot.get("target", 0)))
				landed.append(shot)
			else:
				_carry_towards(shot, Vector2i(int(shot["to"][0]),
					int(shot["to"][1])) * Player.SUBTILE
					+ Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2))
			continue

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
			_land_at(state, shot, Entities.cell_of(state, target), target)
			landed.append(shot)
			continue

		# Integer movement along the line, the same way the player moves: no
		# floats, so two machines agree about where a bullet is.
		shot["pos"][0] = at.x + delta.x * step / distance
		shot["pos"][1] = at.y + delta.y * step / distance

	for shot in landed:
		flying.erase(shot)


## Everything standing on the straight line to the target, in order, until the
## bolt has been through `pierce` of them.
##
## **The order is the whole feature.** A bolt that hit the far one first and
## the near one last would be the same total damage arranged so that standing
## in a queue did not matter - and standing in a queue is exactly what the
## crossbow punishes.
##
## Like the cone it lands at once: a bolt crosses its whole range in a third of
## a second, and chasing it down the line would be bookkeeping for something
## the player reads as instantaneous.
##
## Integer throughout, and the same two products as the cone - the dot for "in
## front of the tower", the cross for "on the line rather than beside it".
static func _pierce_line(state: Dictionary, from: Vector2i,
		entry: Dictionary, target: int, armed: bool) -> void:
	var aim := Entities.cell_of(state, target) - from
	if aim == Vector2i.ZERO:
		return
	var reach := reach_of(state, entry, from)
	var damage := damage_of(state, entry, armed)
	var falloff := int(entry.get("pierce_falloff_percent", 0))
	var most := maxi(int(entry.get("pierce", 1)), 1)
	var kind := StringName(entry.get("damage_type", GameData.DAMAGE_IMPACT))
	var up := bool(entry.get("hits_flying", false))

	# Everything on the line, nearest first. `Entities.ids()` is sorted, so two
	# standing the same distance away are always taken in the same order.
	var queue: Array = []
	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, id)
		if cell.x < 0 or Grid.chebyshev(from, cell) > reach:
			continue
		var to := cell - from
		if to.x * aim.x + to.y * aim.y <= 0:
			continue        # behind the tower
		if not up and Enemies.airborne(state, id):
			continue        # over the line, not on it (task 0249)
		# **A line one tile wide.** The cross product is the perpendicular
		# distance times the aim's length, so comparing it against the aim's
		# length squared asks "within about a tile of the line" with no square
		# root and nothing dividing before it multiplies.
		if absi(to.x * aim.y - to.y * aim.x) * 2 > aim.length_squared():
			continue        # beside the line, not on it
		queue.append([Grid.chebyshev(from, cell), id])
	queue.sort()

	var through := 0
	for pair in queue:
		if through >= most:
			break
		# **A share of the original**, not of what is left. Taking a fifth off
		# what remains is 5, 4, 3.2, 2.56 and an integer mess that floors out
		# after three; taking it off the original is 5, 4, 3, 2, 1, which is a
		# curve a player can count.
		var share := maxi(100 - falloff * through, 0)
		var dealt := damage * share / 100
		if dealt <= 0:
			break           # the bolt has nothing left to give
		Combat.hit(state, int((pair as Array)[1]), dealt, kind)
		through += 1


## Fire the line of a given declaration, now, at a given target. The seam the
## other shapes have.
static func pierce_line_for_test(state: Dictionary, from: Vector2i,
		entry: Dictionary, target: int, armed: bool) -> void:
	_pierce_line(state, from, entry, target, armed)


## Everything in the wedge between this tower and what it is aiming at.
##
## **Nothing is thrown.** A flamethrower reaches its whole range instantly, so
## there is no projectile to chase a target that has already moved - which is
## also why the cone is the one shape that cannot miss.
##
## The wedge is integer arithmetic throughout: for each thing in range, how far
## along the aim it is and how far off to the side, and it is in if the side is
## within `cone_spread_permille` thousandths of a tile per tile along. That is
## the tangent of the half-angle, worked out once at boot by
## `GameData.check_defences()` and never in here.
static func _burn_cone(state: Dictionary, from: Vector2i, entry: Dictionary,
		target: int, armed: bool) -> void:
	var aim := Entities.cell_of(state, target) - from
	if aim == Vector2i.ZERO:
		aim = Vector2i(1, 0)
	# **The tree's reach and damage, like every other shape** (task 0116).
	# The raw table numbers were read here while `_acquire` used `reach_of`,
	# so with 'long barrels' the tower picked a target a tile past its own
	# cone, spent a round and burnt nobody - and 'true sights' never reached
	# the flame at all.
	var reach := reach_of(state, entry, from)
	var spread := int(entry.get("cone_spread_permille", 0))
	# A pilot light when unarmed: the weak shot of task 0035.
	var damage := damage_of(state, entry, armed)
	# **The burn is not scaled by the tree.** 'true sights' makes every tower
	# *hit* a fifth harder; the burning afterwards is the fire's own number,
	# and at 2, 3 and 4 a fifth more rounds back to the same integer anyway.
	var burn := int(entry.get("burn_damage", 0))
	var burn_ticks := int(entry.get("burn_ticks", 0))
	var up := bool(entry.get("hits_flying", false))
	if not armed:
		# No fire at all: what makes a flamethrower a flamethrower is the
		# thing it cannot do without rounds.
		burn = 0

	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var to := cell - from
		if Grid.chebyshev(from, cell) > reach:
			continue
		# **In front, not behind.** The dot product against the aim, which is
		# negative for anything the tower has its back to.
		var along := to.x * aim.x + to.y * aim.y
		if along <= 0:
			continue
		# The perpendicular distance, times the aim's length so that both
		# sides of the comparison are in the same units and no division
		# happens before the multiply.
		var across := absi(to.x * aim.y - to.y * aim.x)
		if across * 1000 > along * spread:
			continue
		# Over the flame, not in it (task 0249).
		if not up and Enemies.airborne(state, id):
			continue

		Combat.hit(state, id, damage,
			StringName(entry.get("damage_type", GameData.DAMAGE_FIRE)))
		if burn > 0 and burn_ticks > 0:
			Combat.set_alight(state, id, burn, burn_ticks)


## Fire the cone of a given declaration, now, at a given target.
##
## The same kind of seam as `acquire_for()` and `land_for_test()`: a test for
## "a crowd in the wedge all takes it" should be able to ask the rules rather
## than build a farm and wait for a reload.
static func burn_cone_for_test(state: Dictionary, from: Vector2i,
		entry: Dictionary, target: int, armed: bool) -> void:
	_burn_cone(state, from, entry, target, armed)


## A shot arrives. **What it does when it gets there is the shape it carries**,
## not the tower it came from - the tower is long since irrelevant and may not
## even be standing.
## Move a shell along, so the view has somewhere to draw it. Nothing about the
## damage depends on this: a ballistic shot lands on its tick wherever the
## marker has got to.
static func _carry_towards(shot: Dictionary, to: Vector2i) -> void:
	var at := Vector2i(int(shot["pos"][0]), int(shot["pos"][1]))
	var left := maxi(int(shot["left"]), 1)
	shot["pos"][0] = at.x + (to.x - at.x) / left
	shot["pos"][1] = at.y + (to.y - at.y) / left


## A shot arrives **at a cell**. What it does there is the shape it carries,
## not the tower it came from - the tower is long since irrelevant and may not
## even be standing.
##
## `target` is who it was chasing, and is only used by `single`: a guided shot
## hits what it followed. A splash does not need one, which is why a shell can
## land on an empty patch of dirt and still be a mortar shell.
##
## **An empty mortar's rock hits the one it was thrown at**, if that one is
## still alive, wherever it has walked to - not whoever is on the aimed cell.
## Task 0116 decided it on the numbers: a shell flies 45 ticks and a walker
## crosses a tile in 20, so the aimed cell is two tiles behind it on landing
## and a rock that only hit the cell would almost never hit anything. The
## view already reads a landed shot as landing on its `target` (`Juice`).
static func _land_at(state: Dictionary, shot: Dictionary, middle: Vector2i,
		target: int = 0) -> void:
	var damage := int(shot["damage"])
	var kind := StringName(shot["type"])
	if StringName(shot.get("shape", GameData.SHAPE_SINGLE)) \
			!= GameData.SHAPE_SPLASH:
		if target != 0 and Entities.alive(state, target):
			Combat.hit(state, target, damage, kind)
		return

	# Everything within the radius, full damage at the middle falling to
	# `splash_falloff_percent` of it at the edge. Sorted by entity id, because
	# two machines have to kill the same one first.
	var radius := maxi(int(shot.get("splash_tiles", 1)), 1)
	var edge := int(shot.get("splash_falloff_percent", 100))
	# **A burst on the ground misses the air** (task 0249), unless what threw
	# it reaches the air - asked of the tower it came from, which the shot
	# names, so no shot carries a new key.
	var up := bool((GameData.DEFENCES.get(StringName(shot.get("from", &"")), {})
		as Dictionary).get("hits_flying", false))
	for id in Entities.ids(state):
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var apart := Grid.chebyshev(middle, cell)
		if apart > radius:
			continue
		if not up and Enemies.airborne(state, id):
			continue
		# Integer throughout: full in the middle, `edge` percent at the rim,
		# straight line between.
		var share := 100 - (100 - edge) * apart / radius
		Combat.hit(state, id, maxi(damage * share / 100, 1), kind)


# ------------------------------------------------------------------ the hives

## **A sting** (task 0226): the bees are on it at once, and it hurts every
## second for `sting_ticks` - `Combat.sting()`, refreshed and never stacked -
## for the hive's damage and its sunflowers' share (`sting_of`).
static func _sting(state: Dictionary, hive: Dictionary, entry: Dictionary,
		target: int, armed: bool) -> void:
	Combat.sting(state, target, sting_of(state, hive, entry, armed),
		int(entry.get("sting_ticks", 0)))


## **What a hive's sting hurts for, a second** (task 0226): the levelled
## damage with the tree's share, and one more for every `flowers_per_sting`
## of the sunflowers it was fed at `begin_night`, up to `most_flowers`. A
## hive put down since has not been fed, and stings for the damage alone.
static func sting_of(state: Dictionary, hive: Dictionary, entry: Dictionary,
		armed: bool = true) -> int:
	var per := maxi(int(entry.get("flowers_per_sting", 0)), 1)
	var flowers := mini(int(hive.get("flowers", 0)), int(entry.get("most_flowers", 0)))
	return damage_of(state, entry, armed) + flowers / per


## **Every hive fed for the night** (task 0226), once, from
## `Phases.begin_night`: the sunflowers growing within its `flower_reach`,
## and - where fewer grow than it can use, as in autumn and winter - up to
## `stock_flowers` more from the store, in whole stings' worth only, so none
## is eaten for nothing. Hives in cell order, so two short of the store share
## it the same way on every machine; a sunflower in reach of two counts for
## both. Written on the occupant as `flowers`: bookkeeping that changes no
## shape on the farm, so no `Farm.touch()`.
static func feed_hives(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	for idx in _towers(state):
		var hive: Dictionary = occupants[idx]
		var cell := Grid.cell(int(idx))
		var entry: Dictionary = Building.entry_at(state, cell)
		if StringName(entry.get("shape", GameData.SHAPE_SINGLE)) != GameData.SHAPE_STING:
			continue
		var most := int(entry.get("most_flowers", 0))
		var per := maxi(int(entry.get("flowers_per_sting", 0)), 1)
		var growing := growing_flowers(state, cell, int(entry.get("flower_reach", 0)))
		var eaten := 0
		if growing < most:
			var could := mini(mini(int(entry.get("stock_flowers", 0)), most - growing),
				Resources.amount(state, GameData.SUNFLOWER))
			eaten = maxi((growing + could) / per * per - growing, 0)
			if eaten > 0:
				Resources.pay(state, {GameData.SUNFLOWER: eaten})
		hive["flowers"] = mini(growing + eaten, most)


## The sunflowers growing within `reach` tiles of `cell`, a square as a
## tower's reach is: every plot sown with one (`Farming.crop_on`), ripe or not.
static func growing_flowers(state: Dictionary, cell: Vector2i, reach: int) -> int:
	var count := 0
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var at := cell + Vector2i(dx, dy)
			if Grid.in_bounds(at) and Farming.crop_on(state, at) == GameData.SUNFLOWER:
				count += 1
	return count


## How many shots every tower on the farm has fired, ever.
##
## **What a test should ask**, rather than counting what is in the air: a cone
## and a line put nothing there, and a guided shot that resolves inside one
## tick is never seen either.
static func shots_fired(state: Dictionary) -> int:
	return int(state.get("shots_fired", 0))


## How many shots are in the air, for the debug overlay and the perf budget.
static func in_flight(state: Dictionary) -> int:
	return (state["projectiles"] as Array).size()


## Every tower on the farm, in cell order.
static func cells(state: Dictionary) -> Array:
	var out: Array = []
	for idx in _towers(state):
		out.append(Grid.cell(int(idx)))
	return out
