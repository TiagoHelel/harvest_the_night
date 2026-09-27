class_name BuildInfo
extends RefCounted

## Who this build is, for the boot screen, the debug overlay and crash reports.
##
## Node-free like everything else in `src/core/`: read it as
## `BuildInfo.VERSION`, never instance it. Task 0100 bakes the build date in at
## export time; until then `BUILT` is the date the version was last bumped.

const GAME_NAME := "HARVEST THE NIGHT"
const VERSION := "0.1.0"
const STAGE := "prototype"
const BUILT := "2026-09-27"


## "v0.1.0 prototype", for a corner of the screen.
static func short() -> String:
	return "v%s %s" % [VERSION, STAGE]


## The whole thing on one line, for a log or a crash report.
static func line() -> String:
	return "%s v%s (%s, built %s)" % [GAME_NAME, VERSION, STAGE, BUILT]
