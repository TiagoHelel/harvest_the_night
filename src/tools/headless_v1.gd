extends SceneTree

## The rules of version 1.0, asserted with no window.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N asserts, M failed`, and it exits non-zero when M is not zero.
##
## **Every group from task 0112 on lives here.** `headless_check` holds the
## MVP's 103 groups (tasks 0002-0111) and was already spending some 74 of the
## 120 seconds verify gives a script when the 1.0 backlog was queued, with
## some 180 tasks still to come. Nothing moved across: the old groups stay
## where they are and this file starts empty, so a new rule never has to choose
## between being tested and the suite finishing.
##
## A plain helper a group here needs is **moved into `SuiteKit`**
## (`src/tools/suite_kit.gd`), never copied out of `headless_check`, so the two
## halves keep one idea of each fixture.
##
## **Defences are put down by night.** From task 0132 the rules refuse to
## place, upgrade or sell a defence by day; a group that needs one handles it
## in PREPARATION (`Phases.begin_preparation`) - the way task 0119 moves the
## old suites - never by day.
##
## ## Failing rather than hanging
##
## The same three guards as `headless_check`, for the same reason - GDScript
## has no exceptions, so a group that dies half way returns to its caller and
## the file would otherwise reach the end with a clean `0 failed`:
##
## 1. Each group increments `_completed` **as its last statement**, and
##    `_finish()` fails when fewer groups finished than `GROUPS` says exist.
## 2. `_process()` is a watchdog for an `_initialize()` that never returned.
## 3. `verify.py` bounds the whole run with a timeout.

## How long to wait before deciding `_initialize()` is never coming back.
const WATCHDOG_SECONDS := 5.0

## How many `_task_NNNN_*` groups `_run()` is expected to finish.
## **Adding a group means bumping this.**
const GROUPS := 1

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
var _elapsed := 0.0


func _initialize() -> void:
	_run()
	_finish()


## Reached only when `_initialize()` did not return - which in practice means a
## parse error in a script this one depends on, so `_run()` never started.
func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("headless_v1: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: _initialize() never returned. Something it depends on ",
		"failed to parse - run: godot --headless --path . --check-only ",
		"--script res://src/tools/headless_v1.gd")
	_finish()
	return true


func _run() -> void:
	_task_0112_digest()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < GROUPS:
		failed += 1
		print("  FAIL  a check group did not finish   %d of %d completed"
			% [_completed, GROUPS])
	print("%d asserts, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


## One assertion. A failure prints the values, because "false" on its own has
## never once been enough to fix anything.
func expect(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL  ", what, "  ", detail)


# ------------------------------------------------------------------ the groups

## 0112 - every table in `GameData` is either in the data hash or says why not.
func _task_0112_digest() -> void:
	# **The DATA guard only sees what `digest()` names.** A table added to
	# `game_data.gd` and not to the digest can be rebalanced with the guard
	# perfectly quiet - which is the one thing it exists to stop, and the
	# 1.0 backlog adds dozens of tables. So the file is read as text, every
	# top-level `const` whose value is an Array or Dictionary literal is
	# collected, and each one must be named in `digest()` or exempted here
	# with a reason. Scalar consts are not this group's business.
	var exempt := {
		"TARGETING": "derived enum list: the names DEFENCES entries pick from",
		"SHAPES": "derived enum list: the names DEFENCES entries pick from",
		"AIMS": "derived enum list: the names DEFENCES entries pick from",
		"DAMAGE_TYPES": "derived enum list: the names DEFENCES entries pick from",
		"NEIGHBOUR_STEPS": "geometry helper: the four steps of a grid, not design",
	}
	var source := FileAccess.get_file_as_string("res://src/core/game_data.gd")
	var at := source.find("\nstatic func digest()")
	expect(not source.is_empty(), "game_data.gd is there to read")
	expect(at >= 0, "and it has a digest()")
	if source.is_empty() or at < 0:
		_completed += 1
		return

	# The body of `digest()`: everything indented under it, comments cut,
	# because "they are not in `NIGHTS`" is not `NIGHTS` being hashed.
	var body := ""
	for line in source.substr(at + 1).split("\n").slice(1):
		if not line.is_empty() and not line.begins_with("\t") \
				and not line.begins_with(" "):
			break
		var comment := line.find("#")
		body += (line.substr(0, comment) if comment >= 0 else line) + "\n"

	var table := RegEx.create_from_string(
		"^const\\s+([A-Z][A-Z0-9_]*)\\s*(?::[^=]*)?=\\s*[\\[{]")
	var tables: Array = []
	for line in source.split("\n"):
		var m := table.search(line)
		if m != null:
			tables.append(m.get_string(1))
	# The reader itself, checked on tables it must find: an untyped
	# Dictionary, an untyped Array and a typed one.
	for known in ["CROPS", "NIGHTS", "NEIGHBOUR_STEPS"]:
		expect(tables.has(known), "the reader finds %s" % known, str(tables))

	var missing: Array = []
	for name in tables:
		if exempt.has(name):
			continue
		var named := RegEx.create_from_string("\\b%s\\b" % name)
		if named.search(body) == null:
			missing.append(name)
	expect(missing.is_empty(),
		"every table const is in GameData.digest() or exempted with a reason",
		"not hashed: %s" % ", ".join(missing))

	# And the exemptions do not rot: each still names a table, and one that
	# has since joined the digest has no business being excused from it.
	for name in exempt:
		expect(tables.has(name), "exemption %s still names a table" % name)
		expect(RegEx.create_from_string("\\b%s\\b" % name).search(body) == null,
			"exemption %s is not also in the digest" % name)
	_completed += 1
