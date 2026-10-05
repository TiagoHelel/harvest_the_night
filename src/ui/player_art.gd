class_name PlayerArt
extends RefCounted

## Which drawing the farmer is doing right now.
##
## **The core state decides and this reads it.** `Player.facing()` says which
## way they are looking and `Player.action()` says what they are doing; this
## turns that pair into an animation name, a frame count and a speed. The view
## never guesses from the position, which is what would make a farmer chop at
## a tree they had already walked away from.
##
## ## Locomotion has eight directions
##
## The reviewed blue walk (2026-10-05) is drawn in all eight, so a diagonal
## walk shows the diagonal drawing. Which one comes from the direction held,
## `heading`; the rules still resolve it onto four facings, and the drawing
## never disagrees with them (`direction()`). Standing still holds a pose of
## the same walk, and running plays the same cycle faster - neither has art of
## its own yet. Existing work strips remain west-facing and mirror only when
## facing east.
##
## ## The speeds are data
##
## Task 0073 asks for frame counts and speeds to be data. The counts are
## `PlayerFrames.COUNT`, generated from sheet/raster recipes so nothing counts
## files by hand. Authored speeds come from the manifest; legacy speeds are
## below. They are **not** in `game_data.gd`, for the
## reason task 0039 gives about the light: a purely visual number in the data
## hash means a balance-neutral tweak fails the guard.

const DIR := "res://sprites/actors/"
const BLINK_SECONDS := [3.2, 0.1, 0.16]

## A held direction, as the suffix of the drawing that walks that way.
const HEADINGS := {
	Vector2i(0, 1): &"south",
	Vector2i(0, -1): &"north",
	Vector2i(-1, 0): &"west",
	Vector2i(1, 0): &"east",
	Vector2i(1, 1): &"south_east",
	Vector2i(-1, 1): &"south_west",
	Vector2i(1, -1): &"north_east",
	Vector2i(-1, -1): &"north_west",
}

## Seconds a frame lasts while running: the walk's 0.1, played half again as
## fast. The run key is presentation only, so this is not in `game_data.gd`.
const RUN_FRAME_SECONDS := 0.07

## Seconds a frame lasts, per animation. A swing is quick, a stand is slow.
const SECONDS := {
	&"walk_south": 0.13,
	&"walk_north": 0.13,
	&"walk_west": 0.13,
	&"idle_south": 0.55,
	&"idle_north": 0.55,
	&"idle_west": 0.55,
	&"chop": 0.11,
	&"mine": 0.13,
	&"till": 0.12,
	&"plant": 0.15,
	&"water": 0.14,
	&"fish": 0.20,
	&"craft": 0.20,
	&"harvest": 0.20,
	&"carry": 0.20,
}

## Every verb the rules have, and the drawing it plays.
##
## Each core verb has its own authored four-frame strip. Carry is a separate
## view cue for a nearby station finishing production, not a new core verb.
const VERBS := {
	&"chop": &"chop",
	&"mine": &"mine",
	&"till": &"till",
	&"plant": &"plant",
	&"harvest": &"harvest",
	&"water": &"water",
	&"fish": &"fish",
	&"reel": &"reel",
	&"collect": &"collect",
	&"craft": &"craft",
	&"trade": &"trade",
	&"repair": &"repair",
}

const COSMETIC := {&"carry": &"carry"}

## The facings, in `Player`'s enum order, as the suffix the sheet has art for
## and whether that art has to be mirrored.
const FACINGS := [
	[&"south", false],      # SOUTH
	[&"west", false],       # WEST
	[&"north", false],      # NORTH
	[&"east", false],       # EAST - registered right-facing locomotion
]


## What to draw: {"name", "frames", "seconds", "flip"}.
##
## `verb` is empty when the player is not working. `moving` is whether they
## are walking, which only matters when they are not. `heading` is the last
## direction held, eight ways; zero draws the plain facing.
static func pose(facing: int, moving: bool, verb: StringName, running: bool = false,
		heading: Vector2i = Vector2i.ZERO) -> Dictionary:
	var side: Array = FACINGS[clampi(facing, 0, FACINGS.size() - 1)]
	var flip: bool = side[1]

	var name: StringName = &""
	var seconds := 0.0
	if verb != &"" and VERBS.has(verb):
		name = VERBS[verb]
		flip = facing == Player.EAST
	elif COSMETIC.has(verb):
		name = COSMETIC[verb]
		flip = facing == Player.EAST
	elif moving:
		name = StringName("walk_%s" % direction(facing, heading))
		if running:
			seconds = RUN_FRAME_SECONDS
	else:
		name = StringName("idle_%s" % direction(facing, heading))

	# A missing binding/count is a source error, never a disguised idle pose.
	if not PlayerFrames.COUNT.has(name):
		push_error("No registered player animation: %s" % name)

	return {
		"name": name,
		"frames": int(PlayerFrames.COUNT.get(name, 0)),
		"seconds": seconds if seconds > 0.0
			else float(PlayerFrames.SECONDS.get(name, SECONDS.get(name, 0.2))),
		"flip": flip,
	}


## Which of the eight drawings `heading` is - but only while it agrees with
## the facing the rules hold. A chop that turned the farmer to face its tree
## outranks the diagonal they walked in on.
static func direction(facing: int, heading: Vector2i) -> StringName:
	var step := Vector2i(signi(heading.x), signi(heading.y))
	if step != Vector2i.ZERO and Player.facing_for(step.x, step.y, facing) == facing:
		return HEADINGS[step]
	return FACINGS[clampi(facing, 0, FACINGS.size() - 1)][0]


## Which frame of that pose, at this many seconds in. Loops.
static func frame_at(pose_data: Dictionary, seconds: float) -> int:
	# The closed-eye drawing is a brief blink, not one third of idle time.
	# Preserve the authored poses; leave the eyes open between blinks.
	if String(pose_data.get("name", &"")).begins_with("idle_"):
		var phase := fposmod(maxf(seconds, 0.0), BLINK_SECONDS[0] + BLINK_SECONDS[1] + BLINK_SECONDS[2])
		return 0 if phase < BLINK_SECONDS[0] else (1 if phase < BLINK_SECONDS[0] + BLINK_SECONDS[1] else 2)
	var frames := maxi(int(pose_data["frames"]), 1)
	var each := maxf(float(pose_data["seconds"]), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % frames


static func frame_seconds(pose_data: Dictionary, frame: int) -> float:
	if String(pose_data.get("name", &"")).begins_with("idle_"):
		return float(BLINK_SECONDS[frame % BLINK_SECONDS.size()])
	return float(pose_data["seconds"])


## Which reaction frame's glyph to draw, or `&""`.
##
## **Only over an idle pose.** A farmer mid-swing with a music note over
## their head is two things happening at once and reads as neither; a farmer
## who has stopped and looked up is the beat this is for. So a reaction waits
## for the work to finish, and if the bubble runs out first it is simply not
## shown - which is right, because the moment it was about has passed.
##
## Only the glyph is drawn: the reaction frames show the previous farmer, so
## `PlayerView` keeps the farmer standing the way they stand and puts that
## frame's source-owned glyph beside their head.
static func reaction_pose(name: StringName, kind: StringName) -> StringName:
	if kind == &"" or not String(name).begins_with("idle_"):
		return &""
	var wanted := StringName("react_%s" % kind)
	return wanted if PlayerFrames.COUNT.has(wanted) else &""


## The texture path for one frame.
static func texture_path(name: StringName, frame: int) -> String:
	return "%s%s_%d.png" % [DIR, name, frame]


## Every verb the rules can put on the player, so a test can walk them.
static func known_verbs() -> Array:
	return GameData.sorted_names(VERBS.keys())
