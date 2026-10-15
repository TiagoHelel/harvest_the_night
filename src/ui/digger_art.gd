class_name DiggerArt
extends RefCounted

## **A digger's mound** (task 0250): A049's `digger_mound` - what shows of a
## digger while it is under a fence, a barricade or the wire - on its 64x48
## canvas standing on (32,44), three frames round and round.
##
## **A049's art since task 0263**, loaded from the raster pipeline by its
## runtime path, for the callers that ask for an enemy by path
## (`WorldView.drawn_enemy`). The digger's other poses are the families' own,
## and its burrow and emergence `EnemyMotion`'s. View only: where a digger is
## is `Enemies`'.

## Where A049 delivers it.
const MOUND_PATH := "res://sprites/enemies/digger_mound_%d.png"
const MOUND_FRAMES := 3


## The mound's frame `index`, by its runtime path; null for anything that is
## not the mound.
static func texture_at(path: String) -> Texture2D:
	for i in MOUND_FRAMES:
		if path == MOUND_PATH % i:
			return load(path) if ResourceLoader.exists(path) else null
	return null
