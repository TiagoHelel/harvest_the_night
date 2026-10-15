class_name GarlicArt
extends RefCounted

## **The garlic braid** (task 0228): a stake with a braid of bulbs hanging from
## it, 16x24 standing on (8,20) as a barricade does, in its three states -
## fresh, wilted and spent - by `Garlic.state_of`.
##
## **A040's art since task 0239**, loaded from the raster pipeline. The view
## finds it by its runtime path as it does any building's; this is what the
## hotbar's icon asks. View only: what the garlic does is `Garlic`'s and
## `Pathing`'s.

## The states, by runtime name.
const STATES := [&"garlic_braid", &"garlic_braid_wilted", &"garlic_braid_spent"]
const DIR := "res://sprites/buildings/"


## The texture a state of the braid wears. Null for a name that is not one of
## the braid's.
static func texture(name: StringName) -> Texture2D:
	if not STATES.has(name):
		return null
	var path := path_of(name)
	return load(path) if ResourceLoader.exists(path) else null


## Where A040 delivers a state.
static func path_of(name: StringName) -> String:
	return DIR + str(name) + ".png"
