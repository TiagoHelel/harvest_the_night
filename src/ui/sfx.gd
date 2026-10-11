class_name Sfx
extends Node

## Watches the day happen and asks `Audio` for the noise it made.
##
## **The rules do not know sound exists.** `src/core/` records what happened
## and this reads it, exactly as `particles.gd` reads it to throw sparks. That
## is what keeps a volume slider out of the determinism hash, and it is why
## there is no `Audio.play()` anywhere in `src/core/`.
##
## ## How a finished verb is spotted from outside
##
## A working verb lives in `state["player"]["action"]` as
## `{verb, cell, left, total}`, and `left` falls by one every tick while
## `state["tick"]` rises by one. So **`left + tick` is the tick the cycle is
## due to finish on, and it does not move while the cycle runs.** That one
## invariant answers both awkward questions exactly:
##
## - The due tick jumping forward means a cycle finished and the verb went
##   round again - which is what chopping a tree is, twenty times over.
## - An action that vanished finished if the clock had reached its due tick,
##   and was **interrupted** if it had not. Walking away mid-swing is not a
##   sound, and without this it would be one.
##
## Guessing from "the action disappeared and `left` was small" would have been
## a fudge that failed at four times speed. This is arithmetic.
##
## ## What the action cannot see
##
## Watering is on `Interact.INSTANT`: it never creates an action, because a
## held key has to water a whole row as the player walks it. So it is spotted
## by counting watered plots instead. The bite has no verb at all - it is a
## window opening - and the sale is money arriving while the stall is open.
##
## ## The night, and why fifty zombies are not fifty groans
##
## A shot is a tower whose `reload` went **up**: it counts down, so a rise is
## the tick it fired on, read off the rules rather than guessed from a
## projectile. Impacts, deaths and wrecks are the edges `particles.gd`
## already watches, for the same reasons and with the same caveat - missing
## one costs a noise and nothing else.
##
## Groans are **per kind and not per body**. Fifty walkers do not groan fifty
## times; the walkers groan, now and then, from wherever the nearest one is.
## That is the whole of "fifty zombies do not turn into noise": the rate is
## fixed by how many *sorts* of thing are out there, which is at most five,
## and `input_check` asserts that ten times the crowd is not ten times the
## sound.

## Verb -> the sound it makes. A verb absent from here is deliberately silent:
## `repair` is the night's and belongs to task 0085, and asking for a sound
## that does not exist would put a warning in the log on every swing.
const VERB_SOUNDS := {
	&"chop": &"sfx/chop",
	&"mine": &"sfx/mine",
	&"till": &"sfx/till",
	&"plant": &"sfx/plant",
	&"harvest": &"sfx/harvest",
	&"collect": &"sfx/collect",
	# A pig's truffle dug up (task 0185): the collect sound until 0281.
	&"dig": &"sfx/collect",
	# Bone meal into the furrow (task 0222): the planting sound until 0281.
	&"fertilise": &"sfx/plant",
	&"craft": &"sfx/craft",
	&"trade": &"sfx/trade",
	# The shipping bin's lid (task 0189): the stall's sale until 0281.
	&"ship": &"sfx/sell",
	&"fish": &"sfx/cast",
	&"reel": &"sfx/reel",
}

const WATER_SOUND := &"sfx/water"
const BITE_SOUND := &"sfx/bite"
const SELL_SOUND := &"sfx/sell"

## What each defence sounds like when it goes off. A defence absent from here
## does not fire - a wall, a fence and a barricade are furniture.
const TOWER_SOUNDS := {
	&"gun_tower": &"sfx/shot_gun",
	&"auto_crossbow": &"sfx/shot_bolt",
	&"flame_tower": &"sfx/flame",
	&"mortar": &"sfx/mortar",
	&"mine": &"sfx/mine_blast",
	# The flame's hiss for a swarm leaving the hive (task 0226), until 0283
	# gives it a buzz.
	&"beehive": &"sfx/flame",
	# The mortar's thump for a pumpkin thrown (task 0227), until 0283 gives
	# the catapult its own.
	&"catapult": &"sfx/mortar",
}

## One voice each, so a crowd is a chord rather than a wall.
const ENEMY_SOUNDS := {
	&"walker": &"sfx/groan_walker",
	&"runner": &"sfx/groan_runner",
	&"tank": &"sfx/groan_tank",
	&"breaker": &"sfx/groan_breaker",
	&"giant": &"sfx/roar_giant",
	# **The walker's groan, borrowed** (task 0247) until 0284 gives the
	# spitter a voice of its own.
	&"spitter": &"sfx/groan_walker",
	# The runner's, a quick small voice, until 0284 gives the rat its own.
	&"rat": &"sfx/groan_runner",
	# The runner's too, until 0284 gives the crow its own.
	&"crow": &"sfx/groan_runner",
	# The breaker's, a dig at things, until 0284 gives the digger its own.
	&"digger": &"sfx/groan_breaker",
	# The tank's, a heavy cold voice, until 0284 gives the frost zombie its own.
	&"frost_zombie": &"sfx/groan_tank",
	# The walker's, until 0284 gives the wraith its own.
	&"wraith": &"sfx/groan_walker",
	# The Giant's roar, until 0284 gives the Harvester its engine.
	&"harvester": &"sfx/roar_giant",
	# The Giant's too, until 0284 gives the Scarecrow King its own.
	&"scarecrow_king": &"sfx/roar_giant",
	# The Giant's too, until 0284 gives the Winter Lord its own.
	&"winter_lord": &"sfx/roar_giant",
}

## **What a boss with no voice of its own roars with** (task 0246): the
## Giant's, until 0284 voices 0253-0255's bosses.
const BOSS_VOICE := &"sfx/roar_giant"

## The `Audio` script, **preloaded rather than named**. `verify.py` parses
## each file on its own with no autoloads registered, so `Audio.NOWHERE`
## would be an undeclared identifier there and the parse row would go red for
## a file that is perfectly correct at runtime. A preload is a resource path
## and always resolves.
const AudioScript := preload("res://src/app/audio.gd")

const IMPACT_SOUND := &"sfx/impact"
const DEATH_SOUND := &"sfx/death"
const BREAK_SOUND := &"sfx/wall_break"
const HOUSE_SOUND := &"sfx/house_hit"

## How often one sort of enemy is heard from, on average. Not a rule and not
## in `game_data.gd`: a groan changes nothing, and a number in there would
## move the data hash for a noise.
const GROAN_EVERY_SECONDS := 2.6

## The shortest gap between two of the same sound, in frames at sixty.
##
## A tower may fire as fast as it reloads, so its gap is nearly nothing. A
## groan that came round twice in half a second would be the same zombie
## clearing its throat, so its gap is long. The house has no gap at all:
## every hit it takes is one you are meant to count.
const SHOT_GAP := 3
const GROAN_GAP := 40
const IMPACT_GAP := 5
const DEATH_GAP := 8

var _state: Dictionary = {}

## The cycle being watched: what it is, where, and the tick it finishes on.
var _verb := &""
var _cell := Vector2i(-1, -1)
var _due := -1

var _was_biting := false
var _watered := -1
var _money := -1

## The night's memory: reload counters by cell, what was alive and how hurt,
## which occupants were standing, and the house.
var _reloads: Dictionary = {}
var _bodies: Dictionary = {}
var _standing: Dictionary = {}
var _house := -1

var _audio: Node = null


func show_state(state: Dictionary) -> void:
	_state = state
	# **Nothing is remembered across runs.** A new farm starting with the last
	# one's money on record would play a sale the first time the player sold
	# nothing at all.
	_verb = &""
	_cell = Vector2i(-1, -1)
	_due = -1
	_was_biting = false
	_watered = -1
	_money = -1
	_forget_the_night()


func _forget_the_night() -> void:
	_reloads.clear()
	_bodies.clear()
	_standing.clear()
	_house = -1


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	# The ears go where the farmer is, because that is where the camera is.
	if _audio != null:
		_audio.listen_at(_where_the_player_is())

	if int(_state["phase"]) != Phases.DAY:
		# The farm is asleep after dark and these verbs do not tick then. The
		# counters are reset so that coming back to the farm does not fire a
		# sale for every coin the night paid out.
		_verb = &""
		_due = -1
		_watered = -1
		_money = -1
		_watch_night(delta)
		return
	# And the night's memory goes the other way, so that a tower which fired
	# on the last tick of a wave does not fire again at dawn.
	_forget_the_night()
	_watch_action()
	_watch_water()
	_watch_fishing()
	_watch_money()


# ------------------------------------------------------------------ the verbs

func _watch_action() -> void:
	var player: Dictionary = _state["player"]
	var action: Dictionary = player["action"]
	var tick := int(_state["tick"])

	if action.is_empty():
		if _due >= 0 and tick >= _due:
			_play_verb(_verb)
		_verb = &""
		_cell = Vector2i(-1, -1)
		_due = -1
		return

	var verb := StringName(action["verb"])
	var at := Vector2i(int(action["cell"][0]), int(action["cell"][1]))
	var due := tick + int(action["left"])
	# The same verb on the same cell with its due tick pushed forward is the
	# one that repeated - a held key on a tree that is not down yet.
	if _due >= 0 and verb == _verb and at == _cell and due > _due:
		_play_verb(verb)
	_verb = verb
	_cell = at
	_due = due


func _play_verb(verb: StringName) -> void:
	if verb == &"" or not VERB_SOUNDS.has(verb):
		return
	_ask(VERB_SOUNDS[verb])


# ------------------------------------------------------------- the other three

## Watering, which has no action to watch because it is instant.
func _watch_water() -> void:
	var now := _watered_plots()
	if _watered >= 0 and now > _watered:
		_ask(WATER_SOUND)
	_watered = now


func _watered_plots() -> int:
	var n := 0
	# A count, so the order this comes out in cannot matter - which is the one
	# thing the house rule about unsorted dictionaries is protecting.
	for key in (_state["plots"] as Dictionary):
		if bool((_state["plots"][key] as Dictionary).get("watered", false)):
			n += 1
	return n


## The bite, which is a window opening rather than anything the player did.
func _watch_fishing() -> void:
	var biting := Fishing.is_biting(_state)
	if biting and not _was_biting:
		_ask(BITE_SOUND)
	_was_biting = biting


## A sale: money arriving while the stall is open. Buying spends rather than
## earns, so only the way up makes a noise.
func _watch_money() -> void:
	var now := Resources.amount(_state, GameData.MONEY)
	if _money >= 0 and now > _money and Shop.is_open(_state):
		_ask(SELL_SOUND)
	_money = now


func _ready() -> void:
	# **By path and never by name.** `verify.py` parses each script on its own
	# with no autoloads registered, so a bare `Audio.play(...)` is an
	# undeclared identifier there and the parse row goes red for a file that
	# is perfectly correct at runtime.
	_audio = get_node_or_null(^"/root/Audio")


# ------------------------------------------------------------------ the night

func _watch_night(delta: float) -> void:
	_watch_towers()
	_watch_bodies()
	_watch_structures()
	_watch_house()
	_watch_groans(delta)


## **A shot is a reload counter going up.** It counts down every tick, so the
## one tick it rises on is the tick the thing went off - the same reading
## `world_view.gd` uses to put a muzzle flash in the right frame.
func _watch_towers() -> void:
	var occupants: Dictionary = _state["occupants"]
	var now: Dictionary = {}
	# Cell indices, so these are integers and sort as integers.
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id := StringName(on["id"])
		if not TOWER_SOUNDS.has(id):
			continue
		var reload := int(on.get("reload", 0))
		now[idx] = reload
		if reload > int(_reloads.get(idx, reload)):
			_ask_at(TOWER_SOUNDS[id], _cell_middle(Grid.cell(int(idx))),
				SHOT_GAP)
	_reloads = now


## Impacts, deaths, and a boss announcing itself (any `is_boss`, task 0246).
func _watch_bodies() -> void:
	var now: Dictionary = {}
	for entity_id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(entity_id))
		if one.is_empty():
			continue
		var kind := StringName(one["kind"])
		var hurt := int(one.get("hurt", 0))
		var at := _body_middle(one)
		now[int(entity_id)] = [kind, hurt, at]

		var was: Variant = _bodies.get(int(entity_id), null)
		if was == null:
			# **Heard before it is seen.** `NOWHERE` rather than a position,
			# so the roar arrives at full volume from the far fence - which
			# is the requirement, and the only place the falloff is skipped
			# on purpose.
			if Combat.is_boss(kind):
				_ask_at(voice_of(kind), AudioScript.NOWHERE, 1)
			continue
		# On the rise, not for as long as it shows: `hurt` is a countdown and
		# reading it as a level emitted on every frame of it.
		if hurt > int((was as Array)[1]):
			_ask_at(IMPACT_SOUND, at, IMPACT_GAP)

	for gone in _bodies:
		if now.has(gone):
			continue
		var was_at: Vector2 = (_bodies[gone] as Array)[2]
		_ask_at(DEATH_SOUND, was_at, DEATH_GAP)
	_bodies = now


## Something the player built is no longer there.
func _watch_structures() -> void:
	var occupants: Dictionary = _state["occupants"]
	var now: Dictionary = {}
	var keys: Array = occupants.keys()
	keys.sort()             # cell indices, integers
	for idx in keys:
		var id := StringName((occupants[idx] as Dictionary)["id"])
		if GameData.DEFENCES.has(id):
			now[idx] = bool((GameData.DEFENCES[id] as Dictionary)
				.get("one_shot", false))
	if not _standing.is_empty():
		for gone in _standing:
			if now.has(gone):
				continue
			# **A mine that went off is not a wall that broke.** Task 0085
			# watched every defence vanish and sounded all of them as timber
			# - so the mine's own blast, which it drew a sound for, never
			# played once. A `one_shot` defence leaving the board is the one
			# going off; anything else leaving it has been knocked down.
			var was_a_trap := bool(_standing[gone])
			_ask_at(TOWER_SOUNDS[&"mine"] if was_a_trap else BREAK_SOUND,
				_cell_middle(Grid.cell(int(gone))), 1)
	_standing = now


## **The one that means you are losing.** No gap on it: every hit is one the
## player is meant to count.
func _watch_house() -> void:
	var hp := int(_state["house_hp"])
	if _house >= 0 and hp < _house:
		_ask_at(HOUSE_SOUND, _house_middle(), 1)
	_house = hp


## **Per kind, not per body.** However many are out there, the walkers are one
## voice and they are heard from now and again, from wherever the nearest one
## is standing.
func _watch_groans(delta: float) -> void:
	var nearest := nearest_by_kind()
	for kind in GameData.sorted_names(nearest.keys()):
		# A chance a frame rather than a timer, so two kinds that arrived
		# together do not groan in lockstep for the rest of the night.
		if randf() < delta / GROAN_EVERY_SECONDS:
			_ask_at(ENEMY_SOUNDS[kind], nearest[kind], GROAN_GAP)


## The closest of each sort of enemy, which is how many voices a crowd
## amounts to.
##
## **This is the whole of "fifty zombies do not turn into noise".** Fifty
## walkers are one entry, not fifty: the size of what this returns is capped
## by how many *sorts* of thing exist, which is four. Public so that
## `input_check` can ask the claim directly rather than counting noises over
## a stretch of frames and hoping the random draw cooperated.
func nearest_by_kind() -> Dictionary:
	var nearest: Dictionary = {}
	var ears := _where_the_player_is()
	for entity_id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(entity_id))
		if one.is_empty():
			continue
		var kind := StringName(one["kind"])
		if not ENEMY_SOUNDS.has(kind) or Combat.is_boss(kind):
			continue        # a boss announces itself and does not mutter
		var at := _body_middle(one)
		var best: Variant = nearest.get(kind, null)
		if best == null or ears.distance_to(at) < ears.distance_to(best):
			nearest[kind] = at
	return nearest


# ----------------------------------------------------------------- the places

func _where_the_player_is() -> Vector2:
	return _cell_middle(Player.cell(_state))


func _cell_middle(cell: Vector2i) -> Vector2:
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)


func _body_middle(one: Dictionary) -> Vector2:
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	return Vector2(float(one["pos"][0]), float(one["pos"][1])) * per


func _house_middle() -> Vector2:
	var cells := Farm.cells_with(_state, &"house")
	if cells.is_empty():
		return _where_the_player_is()
	return _cell_middle(cells[cells.size() / 2] as Vector2i)


# ------------------------------------------------------------------- the asks

func _ask(id: StringName) -> void:
	_ask_at(id, _where_the_player_is(), 1)


## The sounds that get the ambience out of their way.
##
## **The house is the whole reason ducking exists** - the done-when says the
## bed may never mask it. The Giant's roar is here too because it is meant to
## arrive over everything, and a wall going because it is the moment a player
## has to look up.
const DUCKS: Array = [HOUSE_SOUND, BREAK_SOUND]


func _ask_at(id: StringName, at: Vector2, gap: int) -> void:
	if _audio == null:
		return
	if _audio.play(id, at, gap) and _ducks(id):
		_audio.duck()


func _ducks(id: StringName) -> bool:
	if DUCKS.has(id):
		return true
	# **Any boss's voice ducks the rest** (task 0246), as the Giant's did.
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if Combat.is_boss(StringName(kind)) and voice_of(StringName(kind)) == id:
			return true
	return false


## **A kind's voice** (task 0246): its own in `ENEMY_SOUNDS`, a boss's the
## Giant's roar until it has one, and nothing for anything else.
static func voice_of(kind: StringName) -> StringName:
	if ENEMY_SOUNDS.has(kind):
		return ENEMY_SOUNDS[kind]
	return BOSS_VOICE if Combat.is_boss(kind) else &""
