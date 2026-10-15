class_name RatArt
extends RefCounted

## **A rat** (task 0248): A047's master, scurry, bite and death on its 24x16
## canvas standing on (12,14), facing west as A047 draws it - the view mirrors
## it to face east - and its forecast head.
##
## **A047's art since task 0261**, loaded from the raster pipeline by its
## runtime path, for the callers that ask for an enemy by path
## (`WorldView.drawn_enemy`). View only: where a rat is is `Enemies`'.

## Where A047 delivers them.
const DIR := "res://sprites/enemies/"
const HEAD_PATH := "res://sprites/ui/head_rat.png"
## Every pose, by runtime name.
const POSES := [&"rat", &"rat_walk_0", &"rat_walk_1", &"rat_walk_2", &"rat_walk_3",
	&"rat_attack_0", &"rat_attack_1", &"rat_attack_2", &"rat_death_0", &"rat_death_1", &"rat_death_2"]


## A rat's pose `name`; null for anything else.
static func texture(name: StringName) -> Texture2D:
	return texture_at(DIR + str(name) + ".png")


## The same by the runtime path, the forecast head's included.
static func texture_at(path: String) -> Texture2D:
	var name := StringName(path.get_file().get_basename())
	if not (path == HEAD_PATH or (POSES.has(name) and path.get_base_dir() + "/" == DIR)):
		return null
	return load(path) if ResourceLoader.exists(path) else null
