class_name ElectricFenceArt
extends RefCounted

## **The electric fence** (task 0230): the wooden fence's sixteen masks, whole
## and hurt, and its wreck, at 16x32 standing on (8,28); and the zap where a
## shock lands, three frames on 12x12 round (6,6).
##
## **A042's art since task 0241**: the masks are composed by the importer from
## A042's modules (`joins.parts`, N, W, E, S, post), so the view finds every
## one by its runtime name as it does the wooden fence's. This names them,
## gives the hotbar its picture and the view its zap. View only: the shock is
## `Combat`'s.

const ID := &"electric_fence"
const WRECK := &"electric_fence_wreck"
const ZAP_PATH := "res://sprites/effects/zap_%d.png"
const ZAP_FRAMES := 3


## Every runtime name the fence stands under: the sixteen masks whole - mask
## 0 is the bare `electric_fence` - the sixteen hurt, and the wreck.
static func names() -> Array:
	var out: Array = JoinRecipe.names(str(ID))
	out.append(WRECK)
	return out


## The runtime name of a mask, whole or hurt: what `WorldView._barrier_name()`
## asks for.
static func name_of(mask: int, hurt: bool) -> StringName:
	return JoinRecipe.name_of(str(ID), mask, hurt)


## The art a runtime name wears. Null for a name that is not the fence's.
static func texture(id: StringName) -> Texture2D:
	if not str(id).begins_with(str(ID)):
		return null
	var path := path_of(id)
	return load(path) if ResourceLoader.exists(path) else null


## **The hotbar's picture of it**: a straight run - the post with a span
## either side - which reads as a fence where the bare post reads as a stick.
## Null for anything else.
static func icon(id: StringName) -> Texture2D:
	return texture(name_of(10, false)) if id == ID else null


## Where A042 delivers a runtime name.
static func path_of(id: StringName) -> String:
	return "res://sprites/buildings/%s.png" % id


## The zap's frame `index`, or null past its last.
static func zap(index: int) -> Texture2D:
	if index < 0 or index >= ZAP_FRAMES:
		return null
	var path := ZAP_PATH % index
	return load(path) if ResourceLoader.exists(path) else null


## How long a zap frame shows, and where it is held.
static func zap_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(ZAP_PATH % 0).get("seconds", 0.065)), 0.01)


static func zap_pivot() -> Vector2i:
	return PlaceholderArt.frame(ZAP_PATH % 0).get("pivot", Vector2i(6, 6))
