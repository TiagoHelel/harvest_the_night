class_name TarpArt
extends RefCounted

## **The day's tarps** (task 0223): the covers the defences sleep under, at
## A044's three footprints - a tower's 32x48 on (16,44), the tall one-cell
## defences' 16x32 on (8,28) and the short ones' 16x24 on (8,20) - whole,
## torn over a hurt defence, and the two unveil frames the wake plays over
## the defence: the canvas yanked up, then a bundle flying off.
##
## **A044's art since task 0243**, loaded from the raster pipeline. View only:
## nothing reads one back.

## Where a tarp is, at the change (`Transition.tarp_stage`): on, the two
## unveil frames, off.
enum { COVERED, YANK, AWAY, OFF }

const DIR := "res://sprites/buildings/"


## The texture a footprint's tarp wears in a stage. `hurt` asks for the torn
## cover. Null for `OFF`.
static func texture(footprint: StringName, stage: int, hurt: bool = false) -> Texture2D:
	if stage == OFF:
		return null
	var path := path_of(footprint, stage, hurt)
	return load(path) if ResourceLoader.exists(path) else null


## The runtime path a stage of a footprint's tarp lives at (A044's names).
static func path_of(footprint: StringName, stage: int, hurt: bool = false) -> String:
	match stage:
		YANK:
			return DIR + "%s_unveil_0.png" % footprint
		AWAY:
			return DIR + "%s_unveil_1.png" % footprint
	return DIR + ("%s_hurt.png" % footprint if hurt else "%s.png" % footprint)


## A footprint's canvas and pivot, off its art's metadata.
static func canvas(footprint: StringName) -> Vector2i:
	return PlaceholderArt.frame(path_of(footprint, COVERED)).get("canvas", Vector2i(16, 16))


static func pivot(footprint: StringName) -> Vector2i:
	return PlaceholderArt.frame(path_of(footprint, COVERED)).get("pivot", Vector2i(8, 16))
