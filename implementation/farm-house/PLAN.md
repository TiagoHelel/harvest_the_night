# Larger farm buildings and enterable farmhouse

User request, 2026-10-02: coherent building/person scale, another 25% increase
in usable growing area, and a furnished farmhouse interior to enter and explore.

1. Reuse exterior sheets at a larger integer scale. Align footprints, placement
   previews, doorway, windows and chimney; keep the farmer and viewport unchanged.
2. Extend the current 45x20 farm to 45x25 with 225 clear connected cells. Also
   extend the actual planting beds from 48 to 60 (+25%). Clear usable soil/grass
   after enlarged fixtures must exceed 125% of the preceding farm; bare grass
   remains building/circulation ground. Support v1 and v2 saves without losing
   plots, production or inventory.
3. Add a plain-data interior visit, deterministic movement and furniture collision.
   Interact at the porch to enter; walk to the interior door to exit. Preserve the
   farm position. Outdoor growing/production continue during visits. Return outside
   when the defence phase begins; retain pause, save/resume and zoom controls.
4. Generate and preserve one original modular interior sheet with imagegen.
   Register deterministic cuts/palette mapping in the existing art pipeline.
   Furnish with bed, kitchen, dining area, hearth, storage, rug and a plant.
5. Test acreage, save migrations, collisions, doorway transitions, live simulation,
   actual keyboard input, exterior placement and lighting. Inspect real native
   Godot renders indoors and outdoors. Record intentional map/state hash changes.

Code/docs in English; player-facing prompts in locale tables. Sprite queue remains
complete: this is a gameplay follow-up. Existing unrelated editor changes stay out
of the commit. No publishing, automation or push is requested.
