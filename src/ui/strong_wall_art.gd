class_name StrongWallArt
extends RefCounted

## **The hardwood wall and the sandbags** (task 0231): the stone wall's level
## two and summer's sandbags, each a barrier family of sixteen masks whole and
## hurt and a wreck, at 16x32 standing on (8,28).
##
## **A043's art since task 0242**: the masks are composed by the importer from
## A043's modules (`joins.parts`, N, W, E, S, post), so the view finds every
## one by its runtime name as it does the wall's. This names them and gives
## the hotbar its picture of the sandbags. View only: what a wall stops is
## `Pathing`'s.

const HARDWOOD := "wall_2"
const SANDBAGS := "sandbag_wall"
const FAMILIES := [HARDWOOD, SANDBAGS]


## Every runtime name either family stands under: its 32 masks and its wreck.
static func names() -> Array:
	var out: Array = []
	for family in FAMILIES:
		out.append_array(JoinRecipe.names(family))
		out.append(wreck_of(family))
	return out


static func wreck_of(family: String) -> StringName:
	return StringName(family + "_wreck")


## The family a runtime name belongs to, or "".
static func family_of(id: StringName) -> String:
	for family in FAMILIES:
		if str(id) == str(wreck_of(family)) or int(JoinRecipe.parse(family, str(id))[0]) >= 0:
			return family
	return ""


## The art a runtime name wears. Null for a name that is neither family's.
static func texture(id: StringName) -> Texture2D:
	if family_of(id).is_empty():
		return null
	var path := path_of(id)
	return load(path) if ResourceLoader.exists(path) else null


## **The hotbar's picture of the sandbags**: a straight run, the post with a
## span either side. Null for anything else - the hardwood wall is an upgrade,
## not a slot.
static func icon(id: StringName) -> Texture2D:
	return texture(JoinRecipe.name_of(SANDBAGS, 10, false)) if str(id) == SANDBAGS else null


## Where A043 delivers a runtime name.
static func path_of(id: StringName) -> String:
	return "res://sprites/buildings/%s.png" % id
