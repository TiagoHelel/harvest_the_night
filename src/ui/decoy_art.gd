class_name DecoyArt
extends RefCounted

## **The decoy** (task 0224) and **the zombie bait** (task 0225), A037's art
## since task 0236: the straw dummy on its T-stake whole, hurt and wrecked,
## 16x32 standing on (8,28), and the rotting fish on the ground, 16x16 lying
## on (8,14) - Codex's approved frames through the raster pipeline. Until 0236
## they were drawn in code here; the drawing went when the art came, as
## `PlaceholderArt`'s rule says.

## The decoy's states, by runtime name.
const STATES := [&"decoy", &"decoy_hurt", &"decoy_wreck"]

## Everything of A037's on the ground, the bait with them.
const ART := [&"decoy", &"decoy_hurt", &"decoy_wreck", &"zombie_bait"]

## **The sway when it is struck** (task 0236): A037's three frames, the whole
## decoy's or the hurt one's, whoever bit it; then it stands as it was.
const SWAYS := {&"decoy": &"decoy_sway", &"decoy_hurt": &"decoy_hurt_sway"}
const SWAY_FRAMES := 3

## Where the runtime art of the ground pieces lives.
const DIR := "res://sprites/buildings/"


## The texture a state of the decoy, or the bait, wears. Null for a name that
## is not one of A037's.
static func texture(name: StringName) -> Texture2D:
	if not ART.has(name):
		return null
	var path := path_of(name)
	return load(path) if ResourceLoader.exists(path) else null


## Where A037 delivers a state.
static func path_of(name: StringName) -> String:
	return DIR + String(name) + ".png"


## Where one frame of a state's sway is.
static func sway_path(state: StringName, frame: int) -> String:
	return DIR + "%s_%d.png" % [SWAYS.get(state, &"decoy_sway"), frame]


## How long one frame of the sway shows: the delivery's own timing.
static func sway_seconds() -> float:
	return float(PlaceholderArt.frame(sway_path(&"decoy", 0)).get("seconds", 0.1))


## The frame of the sway `age` seconds after a bite, the whole decoy's or the
## hurt one's by `state` - or null, standing as it was, before the bite and
## once the last frame's time is up.
static func sway_texture(state: StringName, age: float) -> Texture2D:
	if not SWAYS.has(state) or age < 0.0:
		return null
	var frame := int(age / sway_seconds())
	if frame >= SWAY_FRAMES:
		return null
	var path := sway_path(state, frame)
	return load(path) if ResourceLoader.exists(path) else null
