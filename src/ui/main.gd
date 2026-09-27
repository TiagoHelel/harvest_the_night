extends Control

## The boot screen.
##
## It exists to prove the project runs and to say which build is running. Task
## 0091 replaces it with the title screen and task 0092 puts a router in front
## of both; until then this is the whole game.

@onready var _title: Label = %Title
@onready var _version: Label = %Version
@onready var _pitch: Label = %Pitch


func _ready() -> void:
	_title.text = BuildInfo.GAME_NAME
	_version.text = BuildInfo.short()
	_pitch.text = "the farm is the fortress"
	print(BuildInfo.line())
