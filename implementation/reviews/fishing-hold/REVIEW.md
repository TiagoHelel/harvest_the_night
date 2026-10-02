# Fishing rod while waiting — 2026-10-02

After casting, the core clears the timed player action but retains the fishing
line. PlayerWork previously fell back to idle at that point. It now holds the
existing reel frame 0 throughout WAITING and BITING. No sprite source, runtime
PNG, viewport setting or fishing timer is changed. The cast and catch keep
their existing animation strips.

The bite reaction previously replaced an idle farmer's entire drawing. While
holding the rod, PlayerView displays only that reaction's existing source-owned
glyph above the farmer. The body keeps its rod, facing, ground pivot and shadow;
the glyph keeps the viewport clamp and does not mask the rod texture.

The cancellation regression also exposed an existing missing rule: Player.tick
stopped ordinary work on cancel or movement but left the fishing line active.
It now calls Fishing.give_up in that same branch, matching the documented rule.
Completion still leaves the line in the water until catch, miss or cancellation.

## Verification

```powershell
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
python tools/show_art.py --fishing-hold --out=implementation/reviews/fishing-hold/captures
python tools/show_art.py --work --check
python tools/show_art.py --reactions --check
```

The focused showcase completes real casts and advances Sim.tick to the bite for
all four facings. It checks the rod during every waiting tick, a long presentation
pause, state replacement/resume, the bite glyph, catch follow-through, cancel,
movement, a missed bite and removal of the pose at dusk. Rendering and observers
cannot mutate the complete simulation/save dictionary. North/south fishing retains
the existing side-on artwork; east mirrors the same reviewed west frame.

- Actual OpenGL renderer: 4,708 checks, zero failures; 12 unmodified 480x270
  captures covering waiting, bite and catch for every facing. See capture.log.
- Work regression, including the new fishing coverage: 12,081 checks, zero failures.
- Existing reaction regression: 690 checks, zero failures.
- Parse: 117 scripts, zero failures. Real input: 987 cases, zero failures.
- Headless core suite: passed with exit code 0. Its teardown reports five leaked
  ObjectDB instances and one resource still in use; captured in verify-focused.log.
- Sim hash 3960053733 and data hash 3913993875 remain unchanged.

Viewed native waiting/bite captures and nearest-enlarged matched crops in
inspection.png. fishing-frames-inspect.png records the existing cast/reel frames
used to select the rod-ready pose. No full export suite was rerun for this fix.
