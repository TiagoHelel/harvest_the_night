class_name Tutorial
extends RefCounted

## Day one teaches itself.
##
## `design.md` does not have a tutorial level and is not getting one. What it
## has is a first day on the same farm as every other day, with **seven short
## lines** that appear on the thing they are about and go away the moment you
## do it.
##
## ## It watches; it never gates
##
## Nothing in this file can stop the player doing anything. There is no "you
## must chop a tree before you may plant", no greyed button, no cage. A step is
## finished when the state says it happened, whether the player read the line
## or found it on their own - and a player who already knows the game will walk
## past all seven in about forty seconds without ever reading one.
##
## That is the difference between teaching and locking, and it is also why this
## is safe: **removing every prompt changes nothing about what is possible.**
## There is an assert for exactly that.
##
## ## Where it points
##
## A step names a cell, worked out from the farm - the nearest tree, the first
## bare plot, the workshop. `src/ui/` draws the line over that cell. A tutorial
## that put its text in a corner would be a manual; one that puts it on the
## tree is a label.
##
## ## The flag lives outside
##
## "Never shows twice" is `gameplay/tutorial_seen`, in `Settings`, which is a
## node and an autoload and therefore not something `src/core/` may touch.
## This file answers `is_finished()`; the screen decides whether to have asked
## in the first place.

## Nothing to show.
const NOWHERE := Vector2i(-1, -1)


static func initial() -> Dictionary:
	return {
		"tutorial": {
			# The ids that have been done, in the order they were done.
			"done": [],
		},
	}


# ------------------------------------------------------------------- asking

## Every step, in order. Data, so the count is checkable and the text is one
## place for task 0097 to translate.
static func steps() -> Array:
	return GameData.TUTORIAL


## Whether this step has been finished at some point.
static func is_done(state: Dictionary, id: StringName) -> bool:
	return ((state["tutorial"] as Dictionary)["done"] as Array).has(id)


## The step the player is on, or an empty Dictionary when there are none left.
static func current(state: Dictionary) -> Dictionary:
	for entry in steps():
		var step: Dictionary = entry
		if not is_done(state, StringName(step["id"])):
			return step
	return {}


static func is_finished(state: Dictionary) -> bool:
	return current(state).is_empty()


## How many are behind the player, for a "3 of 5" if anybody wants one.
static func progress(state: Dictionary) -> int:
	return ((state["tutorial"] as Dictionary)["done"] as Array).size()


## The cell the current line should be drawn over, or `NOWHERE`.
##
## Worked out from the farm rather than written in the table, because the
## nearest tree is not a fact about the tutorial, it is a fact about where the
## player is standing.
static func points_at(state: Dictionary) -> Vector2i:
	var step := current(state)
	if step.is_empty():
		return NOWHERE
	return _target_for(state, StringName(step["id"]))


static func _target_for(state: Dictionary, id: StringName) -> Vector2i:
	match id:
		&"chop":
			return _nearest(state, Farm.cells_with(state, &"tree"))
		&"plant":
			var bare: Array = []
			for found in Farm.cells_of(state, Farm.Terrain.SOIL):
				var cell: Vector2i = found
				if Farm.is_empty(state, cell) \
						and Farming.crop_on(state, cell) == &"":
					bare.append(cell)
			return _nearest(state, bare)
		&"water":
			# **Whichever water is nearest**, the pond included. Pointing at
			# the well alone put the arrow off the bottom of the screen on
			# a farm where the pond was four tiles away - seen in the shot,
			# not reasoned about.
			var wet: Array = Farm.cells_with(state, &"well")
			for found in Farm.cells_of(state, Farm.Terrain.WATER):
				wet.append(found)
			return _nearest(state, wet)
		&"sell":
			return _nearest(state, Farm.cells_with(state, &"shop"))
		&"craft":
			return _nearest(state, Farm.cells_with(state, &"workshop"))
		&"build":
			# The ground between the farm and where they come from.
			return _nearest(state, Farm.cells_with(state, &"house"))
		&"night":
			return _nearest(state, Farm.cells_with(state, &"house"))
	return NOWHERE


## Whichever of these the player is closest to. Ties go to the lowest cell
## index, so two trees the same distance away pick the same one every run.
static func _nearest(state: Dictionary, cells: Array) -> Vector2i:
	if cells.is_empty():
		return NOWHERE
	var here := Player.cell(state)
	var best := NOWHERE
	var best_distance := 1 << 30
	for found in cells:
		var cell: Vector2i = found
		var apart := absi(cell.x - here.x) + absi(cell.y - here.y)
		if apart < best_distance:
			best_distance = apart
			best = cell
	return best


# ------------------------------------------------------------------ the tick

## One tick of watching. Called from `Sim._tick_day()` and from the moment the
## night begins, because the last step is starting one.
##
## **It only ever adds to `done`.** A step cannot un-finish: chopping a tree
## and then selling the wood does not put the first line back on screen.
static func tick(state: Dictionary) -> void:
	# **Every step, not only the one on screen.** Checking just the current
	# one meant a player who built a tower while the game was still saying
	# "chop a tree" stayed stuck on the tree: four things learned and one line
	# of credit for them. The prompts are a suggested order, not a required
	# one, and a step is finished the moment its thing has happened - which is
	# the whole claim this file makes.
	# **Twice a second, not thirty times.** Each arm of `_happened()` asks
	# the farm a question and one of them walks all seven hundred cells
	# looking for a planted one; at thirty ticks a second that came to 222
	# microseconds of every day tick - **seventy-two percent of a day in
	# which nothing at all was happening** - for a system whose own job is to
	# notice, not to gate.
	#
	# A prompt that catches up within half a second is a prompt nobody can
	# tell from an instant one, and task 0067 needed the day to be cheap
	# enough to play a hundred runs of.
	var beat := int(state["tick"]) % GameData.TUTORIAL_CHECK_TICKS
	if beat != 0:
		return

	var done: Array = (state["tutorial"] as Dictionary)["done"]
	for entry in steps():
		var id := StringName((entry as Dictionary)["id"])
		if done.has(id):
			continue
		if _happened(state, id):
			done.append(id)


## Whether the thing this step is about has been done.
##
## One arm per step, the same shape as `Interact.complete()`. Each asks the
## state a question that is true however the player got there - which is what
## makes ignoring the prompts identical to following them.
static func _happened(state: Dictionary, id: StringName) -> bool:
	match id:
		&"chop":
			return Resources.amount(state, GameData.WOOD) \
				> int(GameData.STARTING_RESOURCES.get(GameData.WOOD, 0))
		&"plant":
			for found in Farm.cells_of(state, Farm.Terrain.SOIL):
				if Farming.crop_on(state, found) != &"":
					return true
			return false
		&"water":
			# **Carrying counts.** Walking to the well fills the can with no
			# keypress at all, so a player who has water in hand has found
			# the thing this line is about whether or not they have poured it
			# on anything yet.
			if Farming.water_carried(state) > 0:
				return true
			for found in Farm.cells_of(state, Farm.Terrain.SOIL):
				if Farming.is_watered(state, found):
					return true
			return false
		&"sell":
			# **More money than you started with**, which on day one can
			# only have come out of the stall.
			#
			# Two nearly-right versions came before this. "The stall is
			# open" cannot be seen at all: the shop stops the clock (task
			# 0039), so no tick happens while it is up. "The money
			# changed" is true the moment the player sows their first
			# seed, because a seed costs money - measured, by watching an
			# hour of ordinary play clear this line with nobody going
			# anywhere near the stall.
			return Resources.amount(state, GameData.MONEY) \
				> int(GameData.STARTING_RESOURCES.get(GameData.MONEY, 0))
		&"craft":
			if not (state["kits"] as Dictionary).is_empty():
				return true
			# Or anything at all on a bench, so queuing counts as learning it.
			return not (state["crafting"] as Dictionary).is_empty()
		&"build":
			for found in (state["occupants"] as Dictionary).keys():
				var on: Dictionary = (state["occupants"] as Dictionary)[found]
				if GameData.DEFENCES.has(StringName(on["id"])):
					return true
			return false
		&"night":
			return int(state["phase"]) != Phases.DAY
	return false
