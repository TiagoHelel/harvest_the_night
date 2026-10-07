class_name SuiteKit

## Plain helpers the test suites share.
##
## Task 0112 split the suites in two: `headless_check` / `input_check` hold
## every group and case up to task 0111, `headless_v1` / `input_v1` everything
## from 0112 on. A helper a new suite needs is **moved here, not copied**, so
## the two halves can never drift into two slightly different ideas of the same
## fixture. Only plain functions of their arguments live here: nothing that
## needs the running SceneTree, nothing that counts an assert.


## Put the farmer on a tile, for a check that needs them somewhere.
static func stand_the_farmer(state: Dictionary, cell: Vector2i) -> void:
	var mine: Dictionary = state["player"]
	mine["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]


## Where a cell of the first farm's yard is now.
##
## **The farmstead moved to the middle of the farm** (2026-10-06) and took the
## night's spawn points with it, 24 tiles east and 18 south, and the camera
## with the farmer standing on its porch. These fixtures were measured against
## the old yard - a tower so many tiles east of the house, a fence across the
## way in from the east - so they are written in those coordinates and moved by
## the same step: the same fight, on the same ground relative to the house and
## the horde.
static func moved(cell: Vector2i) -> Vector2i:
	return cell + GameData.PLAYER_START - Vector2i(16, 8)


## The first cell in reading order a defence could go on, skipping tilled
## soil; `(-1, -1)` when there is none.
static func any_buildable(state: Dictionary) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Farm.buildable(state, cell) and not Farming.is_tilled(state, cell):
			return cell
	return Vector2i(-1, -1)
