class_name Player
extends RefCounted

## Somebody to be on the farm.
##
## Position lives in the state and moves on the tick, never on the frame, so
## that the same keys held for the same number of ticks put the player on the
## same cell on every machine. The view interpolates nothing: at 30Hz on a
## 16 pixel tile, a tick is under two pixels of movement and looks smooth
## without anybody lying about where the player is.
##
## ## Sub-tile position, in integers
##
## The player is not on a cell, they are somewhere inside one - walking has to
## feel continuous, and a farm where you hop from tile to tile is a board game.
## But floats accumulate error differently on different machines, and the
## determinism guard would start failing for reasons nobody could find.
##
## So position is measured in **`SUBTILE` units per tile**, as integers. All the
## smoothness, none of the drift.
##
## ## Intent
##
## The UI does not move the player. It writes what the player is asking for
## into `state["intent"]`, and the tick reads it - which is what lets the
## autoplayer of task 0067 drive the game by writing the same field, and what
## would let a replay re-drive it exactly.

## Units per tile. 64 gives movement fine enough that nobody can see the steps.
const SUBTILE := 64

## Which way the player is looking. Four, because that is how many ways the
## sprite will be drawn (task 0073); eight-way movement still resolves to one
## of these.
enum { SOUTH, WEST, NORTH, EAST }

const FACING_STEPS: Array[Vector2i] = [
	Vector2i(0, 1),         # SOUTH
	Vector2i(-1, 0),        # WEST
	Vector2i(0, -1),        # NORTH
	Vector2i(1, 0),         # EAST
]

## Diagonal movement, as a fraction of 256. A player holding two keys would
## otherwise cross the farm 41% faster than one holding one, which is the
## oldest bug in top-down movement.
const DIAGONAL_NUMERATOR := 181
const DIAGONAL_DENOMINATOR := 256


## The keys this subsystem owns. `State.create()` merges them in.
static func initial() -> Dictionary:
	# On the porch, south of the farmhouse, looking at the farm.
	var start := Vector2i(17, 7)
	return {
		"player": {
			"pos": [start.x * SUBTILE + SUBTILE / 2,
					start.y * SUBTILE + SUBTILE / 2],
			"facing": SOUTH,
			# What the player is in the middle of doing, or empty.
			# `{"verb": &"chop", "cell": [x, y], "left": n, "total": n}`
			"action": {},
		},
		# Which panel is up: `&""`, `&"shop"`, and later the workshop and the
		# tech tree. **Core owns this**, so "the player is shopping" is a fact
		# about the game rather than about a node - which is what lets the
		# autoplayer of task 0067 sell a day's wood with no window open.
		"open_panel": &"",
		# Written by the UI or the autoplayer, read by the tick, cleared by it.
		"intent": {
			"move": [0, 0],
			"interact": false,
			"cancel": false,
			# The night button, the N key and the autoplayer all write this.
			# **The HUD does not change the phase**; the tick does.
			"begin_night": false,
			# Build mode: the cell the player is pointing at, and what they
			# want done with it. `[-1, -1]` is "nowhere".
			"build_cell": [-1, -1],
			"build_place": false,
			"build_sell": false,
			# **Upgrading a tower in place**, task 0064. A third verb on the
			# same road: the UI says where and what, the rules decide.
			"build_upgrade": false,
			# The button on the result screen. Same road as every other input,
			# so the autoplayer of task 0067 can finish a night.
			"confirm_result": false,
			# **Held, not pressed**, and a separate field because the two mean
			# different things. `interact` is the edge: it starts a job, and
			# the job repeats itself from then on without the key being read
			# again. An instant verb has no job to repeat, so watering a row
			# off the edge alone watered exactly one tile - the first press -
			# and then nothing for the whole walk. This one is a level, like
			# `move`: written every frame, never consumed.
			"interact_held": false,
			# **The one button of task 0054.** An edge, like `interact`: a
			# flare is a decision about a moment, and a held key that fired
			# one the instant the cooldown ended would be the game deciding
			# for the player. `Ability.tick()` consumes it.
			"ability": false,
		},
	}


# ------------------------------------------------------------------ asking

## Where the player is, in whole cells - the tile their feet are on.
static func cell(state: Dictionary) -> Vector2i:
	var pos: Array = (state["player"] as Dictionary)["pos"]
	return Vector2i(int(pos[0]) / SUBTILE, int(pos[1]) / SUBTILE)


## Where the player is, in sub-tile units.
static func position(state: Dictionary) -> Vector2i:
	var pos: Array = (state["player"] as Dictionary)["pos"]
	return Vector2i(int(pos[0]), int(pos[1]))


static func facing(state: Dictionary) -> int:
	return int((state["player"] as Dictionary)["facing"])


## The cell the player would act on: the one they are facing, or the one they
## are standing on when what they face is off the farm or nothing to do.
##
## The fallback matters more than it looks: standing on a soil tile and
## pressing interact should plant, without having to shuffle until the facing
## points at the right square.
static func target(state: Dictionary) -> Vector2i:
	var here := cell(state)
	var ahead: Vector2i = here + FACING_STEPS[facing(state)]
	if Grid.in_bounds(ahead) and Interact.verb_at(state, ahead) != &"":
		return ahead
	if Interact.verb_at(state, here) != &"":
		return here
	return ahead if Grid.in_bounds(ahead) else here


static func is_busy(state: Dictionary) -> bool:
	return not ((state["player"] as Dictionary)["action"] as Dictionary).is_empty()


# ------------------------------------------------------------------ the tick

## One tick of being a person on a farm. Called from `Sim._tick_day()`.
static func tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	var move: Array = intent["move"]
	var dx := signi(int(move[0]))
	var dy := signi(int(move[1]))

	# **A panel takes the keys.** Walking away from a stall you are standing at
	# would be a way to shop while running, and cancel is how you leave.
	if StringName(state["open_panel"]) != &"":
		if bool(intent.get("cancel", false)):
			state["open_panel"] = &""
		intent["interact"] = false
		intent["cancel"] = false
		return

	# **Instant verbs happen on the tick, walking or not.** Watering a row is
	# meant to be one held key and a walk down it, and every verb below this
	# line stops the moment the player steps - right for a tree, wrong for a
	# watering can. A tile that has been watered stops offering the verb, so
	# holding the key across a row waters each tile exactly once.
	if bool(intent.get("interact", false)) \
			or bool(intent.get("interact_held", false)):
		_do_instant(state, target(state))

	if bool(intent.get("cancel", false)) or (dx != 0 or dy != 0):
		# Walking away gives up on whatever was being done. Half a tree does
		# not stay half chopped in some invisible ledger.
		_stop(state)

	if dx != 0 or dy != 0:
		_step(state, dx, dy)
	elif bool(intent.get("interact", false)) and not is_busy(state):
		_begin(state, target(state))

	_advance_action(state)

	# Intent is consumed, not remembered: a key held down is written again next
	# frame, and one that was let go stops mattering immediately.
	#
	# `interact_held` and `move` are not cleared, because they are levels
	# rather than edges - the UI writes what the keyboard is doing every frame,
	# and a level this tick cleared is a level the next tick has to rediscover.
	intent["interact"] = false
	intent["cancel"] = false


static func _step(state: Dictionary, dx: int, dy: int) -> void:
	var player: Dictionary = state["player"]
	var speed := GameData.PLAYER_SPEED
	if dx != 0 and dy != 0:
		speed = speed * DIAGONAL_NUMERATOR / DIAGONAL_DENOMINATOR

	player["facing"] = _facing_for(dx, dy, int(player["facing"]))

	# **One axis at a time**, so that walking into a wall at an angle slides
	# along it instead of stopping dead. Free, and it is the difference between
	# movement that feels good and movement that feels like furniture.
	_try_axis(state, Vector2i(dx * speed, 0))
	_try_axis(state, Vector2i(0, dy * speed))


static func _try_axis(state: Dictionary, delta: Vector2i) -> void:
	if delta == Vector2i.ZERO:
		return
	var player: Dictionary = state["player"]
	var pos: Array = player["pos"]
	var moved := Vector2i(int(pos[0]) + delta.x, int(pos[1]) + delta.y)

	var limit := Grid.WIDTH * SUBTILE - 1
	var limit_y := Grid.HEIGHT * SUBTILE - 1
	moved.x = clampi(moved.x, 0, limit)
	moved.y = clampi(moved.y, 0, limit_y)

	var into := Vector2i(moved.x / SUBTILE, moved.y / SUBTILE)
	if not Farm.walkable(state, into):
		return                      # the pond stops you; it does not swallow you
	pos[0] = moved.x
	pos[1] = moved.y


static func _facing_for(dx: int, dy: int, current: int) -> int:
	# Vertical wins a tie, because a sprite facing the camera reads better than
	# one in profile and a diagonal walk is mostly used to go up or down.
	if dy > 0:
		return SOUTH
	if dy < 0:
		return NORTH
	if dx < 0:
		return WEST
	if dx > 0:
		return EAST
	return current


# ------------------------------------------------------------------- doing

## An instant verb, done where the player is standing. Nothing is remembered:
## there is no action to interrupt and nothing to walk away from.
static func _do_instant(state: Dictionary, cell_target: Vector2i) -> void:
	var verb := Interact.verb_at(state, cell_target)
	if verb != &"" and Interact.is_instant(verb):
		Interact.complete(state, cell_target, verb)


static func _begin(state: Dictionary, cell_target: Vector2i) -> void:
	var verb := Interact.verb_at(state, cell_target)
	if verb == &"":
		return
	if Interact.is_instant(verb):
		return          # already done above, and it owns no action state
	var ticks := Interact.ticks_for(state, cell_target, verb)
	var player: Dictionary = state["player"]
	# Face what you are about to do, even if the target was the fallback.
	var here := cell(state)
	if cell_target != here:
		player["facing"] = _facing_for(
			signi(cell_target.x - here.x), signi(cell_target.y - here.y),
			int(player["facing"]))
	player["action"] = {
		"verb": verb,
		"cell": [cell_target.x, cell_target.y],
		"left": ticks,
		"total": ticks,
	}


static func _advance_action(state: Dictionary) -> void:
	var player: Dictionary = state["player"]
	var action: Dictionary = player["action"]
	if action.is_empty():
		return

	var at := Vector2i(int(action["cell"][0]), int(action["cell"][1]))
	# What you were doing has to still be there, and still be that. A tree that
	# somebody else's wave knocked over mid-swing is not still a tree.
	if Interact.verb_at(state, at) != action["verb"]:
		_stop(state)
		return

	action["left"] = int(action["left"]) - 1
	if int(action["left"]) > 0:
		return

	var verb: StringName = StringName(action["verb"])
	Interact.complete(state, at, verb)
	# Keep going on the same target while it still offers the same verb, so
	# chopping a tree is one held key rather than four presses - but only for
	# verbs that are work. A trade does not change what the stall offers, so
	# repeating it reopened the panel on the tick after it was closed.
	if Interact.repeats(verb) and Interact.verb_at(state, at) == verb:
		action["left"] = int(action["total"])
	else:
		_stop(state)


static func _stop(state: Dictionary) -> void:
	(state["player"] as Dictionary)["action"] = {}
