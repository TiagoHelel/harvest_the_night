# New farmer: one walk-down approval pilot

The user approved `../character-r1` and requested one complete walking movement
for review before the eight-direction set or game integration. The selected
movement is walk-down: eight unique poses, 10 fps, one 800 ms cycle.

## Concepts read from sprite_generator

External project: `C:/Users/Helel/Documents/repos/sprite_generator`.
Read `welcome_back_hero/hero-generation-plan.md`, `mage_leg_guide.py`,
`ranger_right_leg_guide.py`, `prepare_ranger_transition.py`,
`ranger_tracking_preview.py`, and the Ranger walk-left recoloring prompt under
`welcome_back_hero/revisions/2026-10-04-v2/ranger/walk/left/prompt.txt`.

- Prepare a standing orientation reference before animating each direction.
  The approved front pose already supplies down; do not rotate an animated frame.
- Identify complete anatomical legs with distinct colors attached to fixed hips.
  Screen-left is anatomical right/red; screen-right is anatomical left/cyan.
- Contact, weight transfer, passing and reaching phases repeat with opposite legs.
- Restore original garment materials after verifying the diagnostic gait.
- Check the normal-speed loop and individual poses; unique files are insufficient.

`create_guide.py` creates an anatomy diagram only. All character artwork and
creative poses come from built-in ImageGen, with exact prompts retained here.
The external project's 36px character target is not copied: this pilot evaluates
a 64px-tall farmer displayed at integer 2x (128px) on an FHD screen. An enlarged
view is included separately. Final runtime scale remains subject to approval.

## Next stages after this pilot is approved

1. Establish standing rotations: up, left, right, down-left, down-right,
   up-left and up-right, matching the accepted front height and proportions.
2. Animate each approved orientation with the same eight-phase gait and leg
   ownership; no blind rotation of the down strip and no diagonal tilt shortcut.
3. Review equal-scale idle/walk loops before changing runtime assets.

Only walk-down is produced in this task. No running, activities, clothing-layer
system, world remodel or runtime replacement is included in this approval pilot.
