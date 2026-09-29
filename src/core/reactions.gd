class_name Reactions
extends RefCounted

## The little bubble over the farmer's head, for the two or three moments the
## game already has.
##
## ## It is a fact in the state, and it is still decoration
##
## Those sound like opposites and are not. It is **in the state** so that the
## autoplayer, a replay and a screenshot all see the same bubble at the same
## tick - a view that invented them from frame to frame would show a different
## one every time the frame rate moved, which is the bug task 0090 wrote the
## event log to avoid. It is **decoration** because nothing reads it: no rule
## branches on it, no number depends on it, and `headless_check` greps
## `src/core/` to keep that true.
##
## Which is why `State.hash_of` skips it. Task 0109's done-when is that
## turning every reaction off leaves the determinism hash unchanged, and the
## honest way to get that is not to be careful - it is for the hash never to
## have looked.
##
## ## Four, and only where the game already has a moment
##
## A bite on the line, a crop coming ready near enough to see, something of
## yours coming down, and the night arriving. The sheet has a heart and a
## star and a lightbulb as well and they are not used, because a reaction
## invented for a moment the game does not have is a moment the game does not
## have with a bubble over it.
##
## **Nothing during a wave except damage.** A farmer with a music note over
## their head while the house burns is the wrong game, so at night the only
## reaction that can be raised is the one about something being destroyed -
## and the `!` on the tick the night arrives, which is the boundary rather
## than the fight.

## Every bubble the sheet gives us a frame for. The view is checked against
## this list, so a kind with no drawing is a failing row rather than a farmer
## who vanishes.
const KINDS: Array = [&"bang", &"question", &"note", &"heart"]

## Which beats which, when two things happen on the same tick. Damage first:
## the one reaction that is allowed to interrupt is the one about losing
## something.
const ORDER: Array = [&"question", &"bang", &"note", &"heart"]


static func initial() -> Dictionary:
	return {
		# `{"kind": StringName, "left": ticks, "seen": tick}` - `seen` is how
		# far through the event log this has read, so one crop coming ready
		# is one bubble and not one a tick until it is harvested.
		"reaction": {"kind": &"", "left": 0, "seen": 0},
	}


## What is over the farmer's head right now, or `&""`.
static func now(state: Dictionary) -> StringName:
	var mine: Dictionary = state.get("reaction", {})
	if int(mine.get("left", 0)) <= 0:
		return &""
	return StringName(mine.get("kind", &""))


## How many ticks it has left, for a view that wants to fade it.
static func left(state: Dictionary) -> int:
	return int((state.get("reaction", {}) as Dictionary).get("left", 0))


## Put one up. Refuses a kind nothing can draw, and refuses to interrupt a
## reaction that outranks it.
static func show(state: Dictionary, kind: StringName) -> void:
	if not GameData.REACTIONS_ON or not KINDS.has(kind):
		return
	var mine: Dictionary = state["reaction"]
	var up := now(state)
	if up != &"" and ORDER.find(up) <= ORDER.find(kind):
		return
	mine["kind"] = kind
	mine["left"] = int(GameData.REACTION_TICKS)


## One tick: count the current one down, then see whether the game just did
## something worth a face.
##
## **Last in `Sim.tick()`**, so that everything it reads has already happened
## this tick - a bubble about a crop that comes ready later in the same tick
## would be a tick late for one frame and nobody would ever notice it was
## wrong.
static func tick(state: Dictionary) -> void:
	var mine: Dictionary = state["reaction"]
	if int(mine.get("left", 0)) > 0:
		mine["left"] = int(mine["left"]) - 1
		if int(mine["left"]) <= 0:
			mine["kind"] = &""
	if not GameData.REACTIONS_ON:
		return

	var night := int(state.get("phase", -1)) == Phases.NIGHT

	# **A bite is a state, not an event.** `Fishing` has no event for it, and
	# giving it one to feed a bubble would be the rules learning about the
	# view - so this watches the flag the way the HUD does.
	if not night and Fishing.is_biting(state):
		show(state, &"bang")

	var seen := int(mine.get("seen", 0))
	var latest := seen
	for one in Events.since(state, seen):
		var entry: Dictionary = one
		var at := int(entry.get("tick", 0))
		latest = maxi(latest, at + 1)
		match StringName(entry.get("kind", &"?")):
			&"structure_lost":
				# The exception: this one is allowed during a wave, because
				# it is the wave.
				show(state, &"question")
			&"night_began":
				show(state, &"bang")
			&"crop_ready":
				if not night and _near(state, entry):
					show(state, &"note")
	mine["seen"] = latest


## Whether a cell the event names is close enough for the farmer to have
## noticed it. A crop coming ready on the far side of the farm is not a thing
## somebody standing at the pond can see.
static func _near(state: Dictionary, entry: Dictionary) -> bool:
	var where: Variant = entry.get("cell", null)
	if not (where is Array) or (where as Array).size() < 2:
		return false
	var cell := Vector2i(int(where[0]), int(where[1]))
	var here := Player.cell(state)
	return absi(cell.x - here.x) + absi(cell.y - here.y) \
		<= int(GameData.REACTION_NEAR)
