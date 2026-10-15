class_name CrowArt
extends RefCounted

## **A crow** (task 0249): A048's flight, touchdown, peck and fall on its
## 32x24 canvas standing on (16,22), facing west as A048 draws it - the view
## mirrors it to face east - and its forecast head. Its shadow is the view's
## code (`WorldView`), never baked into a frame.
##
## **A048's art since task 0262**, loaded from the raster pipeline by its
## runtime path, for the callers that ask for an enemy by path
## (`WorldView.drawn_enemy`). View only: where a crow is is `Enemies`'.

const DIR := "res://sprites/enemies/"
const HEAD_PATH := "res://sprites/ui/head_crow.png"
## Every pose, by runtime name.
const POSES := [&"crow", &"crow_fly_0", &"crow_fly_1", &"crow_fly_2", &"crow_fly_3", &"crow_land_0",
	&"crow_peck_0", &"crow_peck_1", &"crow_peck_2", &"crow_death_0", &"crow_death_1", &"crow_death_2",
	&"crow_death_3"]


## A crow's pose `name`; null for anything else.
static func texture(name: StringName) -> Texture2D:
	return texture_at(DIR + str(name) + ".png")


## The same by the runtime path, the forecast head's included.
static func texture_at(path: String) -> Texture2D:
	var name := StringName(path.get_file().get_basename())
	if not (path == HEAD_PATH or (POSES.has(name) and path.get_base_dir() + "/" == DIR)):
		return null
	return load(path) if ResourceLoader.exists(path) else null
