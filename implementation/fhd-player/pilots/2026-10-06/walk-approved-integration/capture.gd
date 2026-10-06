extends "res://implementation/fhd-player/pilots/2026-10-06/farmer32-integration/capture.gd"

## Real-renderer FHD review of the final approved 2026-10-06 walking pack
## (walk-final-mirrored) in the game.
##
## The farmer half of the 32px review, unchanged in method: the production
## WorldView, PlayerView, Relight and Lighting at 1920x1080, driven by
## Player.tick. Idle, walk and run in all eight directions - each walk and run
## row with a ninth column, the step after phase 8, which must be phase 1
## again - then stand, set off, stop, turn, run and stop, by day and by night.
## Every crop is measured on the renderer (body height, lowest pixel against
## the contact) into renderer-report.json.
##
##     godot --path . --fixed-fps 60 --position -4000,-4000 --script \
##         res://implementation/fhd-player/pilots/2026-10-06/walk-approved-integration/capture.gd


func _run() -> void:
	CaptureSize.configure(root, true)
	_out = "res://implementation/shots/walk-approved-1080/"
	_walk_frames = 9
	await _setup()
	_capture = true
	_folder = _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	for night in [false, true]:
		await _locomotion(night)
		await _stop_start(night)
	_summarise()
	var file := FileAccess.open(_out + "renderer-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(_report, "  ") + "\n")
	file.close()
	print("APPROVED WALK FHD REVIEW: %d checks, %d failed, %d pictures" % [_checks, _failed, _pictures])
	quit(1 if _failed > 0 else 0)
