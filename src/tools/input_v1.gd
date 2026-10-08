extends "res://src/tools/input_check.gd"

## The input paths of version 1.0: real clicks and real keys through the real
## scenes, with nobody in the room.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N cases, M failed`, and it exits non-zero when M is not zero.
##
## **Every case from task 0112 on lives here.** `input_check` holds the MVP's
## 61 cases (tasks 0011-0111) and was already spending some 74 of the 120
## seconds verify gives a script when the 1.0 backlog was queued. Nothing moved
## across: the old cases stay where they are and this file starts with one.
##
## ## How it shares the old harness
##
## **It extends `input_check.gd`** rather than copying it. Every tree helper -
## `open_scene`, `until`, `click_control`, `tap_key`, `hold_key`, `expect` and
## the rest - needs the running SceneTree and the scene this run opened, and an
## inherited method has both without being handed them. What is overridden is
## everything that counts: `_run()` calls only the cases below, `_finish()`
## compares against `V1_CASES` and prints this file's own last line, and the
## watchdog names this file. Each suite is its own process, so `passed`,
## `failed` and `_completed` are this run's alone - the two counters never
## meet. `V1_CASES` rather than `CASES` because GDScript will not let a class
## declare a constant its parent already has.
##
## A plain helper that does not need the tree is shared through `SuiteKit`
## (`src/tools/suite_kit.gd`), never copied.
##
## **Defences are put down by night.** From task 0132 the rules refuse to
## place, upgrade or sell a defence by day; a case that needs one does it in
## PREPARATION - the way task 0119 moves the old suites - never by day.
##
## The stall watchdog is the parent's `WATCHDOG_SECONDS` (20 s without an
## assert landing), and every `expect()` puts it back to zero.

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const V1_CASES := 2


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("input_v1: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: a case never finished - look at the last case named above")
	_finish()
	return true


func _run() -> void:
	await _case_0112_harness()
	await _case_0114_house_bar()
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < V1_CASES:
		failed += 1
		print("  FAIL  a case did not finish   %d of %d completed"
			% [_completed, V1_CASES])
	print("%d cases, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------- the cases

## 0112 - the harness itself: boot the game and press one real key.
func _case_0112_harness() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	expect(driver.running, "Main boots into a running day")

	# A direction the farmer is not already facing, so that turning to it can
	# only be the key's doing.
	var east := Player.facing(driver.state) != Player.EAST
	var key := KEY_D if east else KEY_A
	var want := Player.EAST if east else Player.WEST
	var tick := int(driver.state["tick"])
	await hold_key(key, 20)
	expect(Player.facing(driver.state) == want,
		"a real key press reaches the rules through the real scene",
		"facing %d, wanted %d" % [Player.facing(driver.state), want])
	expect(int(driver.state["tick"]) > tick, "and the world turned meanwhile",
		"tick %d, then %d" % [tick, int(driver.state["tick"])])
	await close_scene()
	_completed += 1


## 0114 - the night HUD's house bar measures the house the night started with.
func _case_0114_house_bar() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var night_hud: NightHud = require_control("NightHud")
	if driver == null or night_hud == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	(state["tech_owned"] as Array).append(&"stout timbers")
	var full := Phases.house_full(state)
	state["house_hp"] = full
	NightRoad.to_night(state)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT and night_hud.visible,
		"it is night and the night HUD is up")
	var house_text: Label = locate_control("HouseNumbers") as Label
	var house_bar: ColorRect = locate_control("HouseBar") as ColorRect
	expect(house_text != null and house_bar != null, "the house bar is there")
	if house_text == null or house_bar == null:
		await close_scene()
		_completed += 1
		return

	# **A 140 house reads 140/140, whole and calm.** Against the base 100 it
	# printed 140/100 and a bar clamped at full.
	expect(full == 140, "stout timbers makes the house 140", str(full))
	expect(house_text.text.contains("%d/%d" % [full, full]),
		"the HUD reads 140/140", house_text.text)
	# The danger pulse is the BAD variation and a red fill. **Not `r > g`**:
	# the calm DIM ink is a warm grey, so its red is already over its green.
	expect(house_text.theme_type_variation != UiKit.BAD
		and house_bar.color == UiKit.colour(UiKit.GOOD),
		"with no danger pulse", "%s, %s"
			% [house_text.theme_type_variation, house_bar.color])
	var whole := house_bar.size.x

	# **And 80 of 140 is in danger**, which against 100 it was not: 57
	# percent, under `HOUSE_DANGER_PERCENT`.
	state["house_hp"] = 80
	await frames(2)
	expect(house_text.text.contains("80/%d" % full), "80 of 140 says so",
		house_text.text)
	expect(house_text.theme_type_variation == UiKit.BAD,
		"and pulses red at 57 percent", str(house_text.theme_type_variation))
	expect(house_bar.size.x < whole * 0.6, "on a bar four sevenths long",
		"%f against %f" % [house_bar.size.x, whole])
	await close_scene()
	_completed += 1
