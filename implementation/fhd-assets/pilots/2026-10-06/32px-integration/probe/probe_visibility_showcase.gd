extends "res://src/tools/visibility_showcase.gd"

## Binding probe: the unchanged visibility_showcase plus a once-a-frame look at
## which inventory textures are alive. See probe_common.gd.

const PROBE := preload("res://implementation/fhd-assets/pilots/2026-10-06/32px-integration/probe/probe_common.gd")


func _process(_delta: float) -> bool:
	PROBE.poll("visibility")
	return false
