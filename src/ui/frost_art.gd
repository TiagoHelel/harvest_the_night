class_name FrostArt
extends RefCounted

## **The ice burst** (task 0251): A050's shatter where a frost zombie dies,
## four frames on 24x24 round (12,12), once - in the ice's keys, growing to
## its widest and fading.
##
## **A050's art since task 0264**, loaded from the raster pipeline by its
## runtime path; `PixelEffects` plays it as it plays the other bursts. The
## frost tint on a chilled tower stays code. View only: what the cold does is
## `Combat`'s.

## Where A050 delivers it.
const SHATTER_PATH := "res://sprites/effects/ice_shatter_%d.png"
const SHATTER_FRAMES := 4


## The burst's frame by its runtime path; null for anything that is not it.
static func texture_at(path: String) -> Texture2D:
	for i in SHATTER_FRAMES:
		if path == SHATTER_PATH % i:
			return load(path) if ResourceLoader.exists(path) else null
	return null
