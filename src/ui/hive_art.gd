class_name HiveArt
extends RefCounted

## **The bee swarm** (task 0226): A038's tiny looping cloud, hung on whatever
## a hive has stung for as long as the sting lasts - three frames on its 8x8
## canvas round (4,4), a tenth of a second each, round and round.
##
## **A038's art since task 0237**: the three frames are loaded from the
## raster pipeline, as the hive's own levels and states are (an authored
## tower, which needs nothing here). View only: the sting is `Combat`'s.

## The swarm's frames and where A038 delivers them.
const FRAMES := 3
const DIR := "res://sprites/effects/"


## The swarm's frame `index`, wrapped round the loop.
static func swarm(index: int) -> Texture2D:
	var path := path_of(posmod(index, FRAMES))
	return load(path) if ResourceLoader.exists(path) else null


## Where A038 delivers a frame of the swarm.
static func path_of(index: int) -> String:
	return DIR + "bee_swarm_%d.png" % index


## The frame to show `seconds` into the loop: A038's tenth of a second each,
## round and round, the last leading back to the first.
static func frame_at(seconds: float) -> int:
	var each := maxf(float(PlaceholderArt.frame(path_of(0)).get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % FRAMES
