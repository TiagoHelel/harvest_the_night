"""Create missing art prompts from the production plan; never overwrite progress."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# id, slug, title, dependencies, likely files, generation brief, requirements, evidence
TASKS = [
    (1, "style-pilot", "Direction, scale and identity masters", [],
     "docs/reference-sheet.png; docs/sprites_sem_fundo.png; tools/palette.py; assets/art_source/masters/",
     "STYLE, PLAYER_MASTER, HOUSE, TREE, WALKER",
     "First resolve the pre-existing PNG byte-only baseline failures described in AUDIT.md: compare decoded pixels, regenerate from unchanged sources deliberately, review the encoding-only diff and obtain a full verifier PASS without changing hash baselines or disabling checks. Then generate a compact neutral-day style board and a night lighting study. Produce identity masters for the farmer, house, tree and walker. Compare their visible body sizes in a shared composition over 16 px cells. Preserve the farmer's identity, establish materials/palette and record the chosen native dimensions and pivots. The proposed dimensions in ART_DIRECTION.md are the starting point. Sources are references at this stage; runtime integration belongs to 0003. Freeze the accepted style in ART_DIRECTION.md and record raw-source hashes.",
     "Open baseline and reference next to the board. Farmer, house, tree and walker read as one game; no photoreal/painted character mismatch. Saved masters, source hashes, exact prompts and explicit scale decision exist. Mark art production done only after the masters actually exist."),
    (2, "raster-source-pipeline", "Raster source ownership and deterministic importer", [1],
     "tools/gen_sprites.py; tools/cut_sheet.py; tools/verify.py; assets/art_source/manifest.json; tools/import_art.py (new)",
     "Use approved 0001 masters; no new generation required",
     "Implement the PIPELINE.md manifest, source validation, explicit crop boxes, shared scaling, palette/alpha conversion, pivots and deterministic PNG output with --check. Add single-owner dispatch to legacy writers/checks and verification. Migrate the pilot assets and ALL affected derivatives together. Old terrain atlas, fixture slices and player cutter must not overwrite migrated art. Keep legacy checks for every unmigrated output. Generate matching view metadata instead of hand-copying dimensions. Preserve original source sheets.",
     "Rebuild twice with identical bytes. A changed accepted source fails --check until regenerated. A tampered migrated output fails; a tampered legacy output still fails. Missing source, duplicate owner, invalid crop and missing runtime frame fail. Restore deliberate corruption before closing. Full verify passes, sim/data hashes unchanged."),
    (3, "godot-pilot", "Playable pilot, pivots and depth sorting", [2],
     "src/ui/world_view.gd; src/ui/player_view.gd; scenes/World.tscn; src/tools/shot.gd; new visual showcase scene/tool",
     "Use 0001 masters",
     "Integrate the pilot farmer, house, tree and walker through manifest metadata. Move visual nodes to ground pivots, offset textures, audit nested Actors y-sorting and make multi-cell buildings render once per anchor or use validated overhang-aware slices. Make shadows, lamp positions, ghosts and highlights agree with unchanged logical cells. Add deterministic visual showcases for occlusion, bounds, silhouettes, crop stages, tower states and animation frames. Keep the unchanged farm playable while assets migrate.",
     "Fresh noon/dusk/wave captures beat the baseline in consistency. Walk farmer and enemies in front of and behind tree/house; no sorting reversal or duplicate house. Ghost base matches the build cell. Roof overhang works at map/camera edges. Review pilot at 480x270 before producing all families; verify/hash guards pass."),
    (4, "player-locomotion", "Player idle and walking in every direction", [3],
     "assets/art_source/player/; sprites/actors/; src/ui/player_frames.gd; src/ui/player_art.gd; src/ui/player_view.gd; tools/cut_sheet.py",
     "PLAYER_MASTER, PLAYER_STRIP",
     "Generate south/north/west idle strips (3 frames each) and walk strips (4 each), using the accepted farmer master. East may mirror west after checking handedness. Keep equal canvas/body scale and stable feet. Migrate all locomotion outputs from the legacy cutter, generate COUNT/CANVAS/FEET metadata, preserve runtime path coverage and bind state-driven facing. Document any final change from pilot dimensions.",
     "All four facings, stationary/diagonal movement and direction changes are inspected. Walk loop is smooth, feet don't drift, hat/body don't resize, east has no mirrored text. Missing frame cannot silently become idle. Native contact sheets and runtime sequences saved; verify/hash guards pass."),
    (5, "player-work", "Player farming, gathering and production actions", [4],
     "assets/art_source/player/; sprites/actors/; src/ui/player_art.gd; src/ui/player_frames.gd; src/ui/player_view.gd",
     "PLAYER_WORK",
     "Produce separate short cycles for chop, mine, till, plant, water, fish/cast, reel, harvest, carry, craft, trade/collect and repair. Start with four frames per action and declare any deliberate alias; do not quietly retain a one-frame craft placeholder. Keep tools inside the common canvas and match contact timing to existing action state. Side-on work can remain a documented choice; don't claim four-direction action art unless generated. Update VERBS and metadata without changing core verbs/timers.",
     "Each known verb triggers a purposeful matching animation in game. Axe/pick/tool contact is believable; fishing cast/reel and repair are distinguishable. Idle/walk interrupt correctly; action cancellation doesn't leave a tool pose stuck. Contact sheets cover every verb or explicitly reviewed alias; verify/hash guards pass."),
    (6, "player-reactions", "Player reactions and ground shadow", [5],
     "sprites/actors/react_*; sprites/actors/shadow.png; src/ui/player_art.gd; src/ui/player_view.gd",
     "PLAYER_REACTION",
     "Create the existing bang, question, note and heart reactions in the new style. Preserve existing reaction-state selection and idle-only behavior. Separate bubble/body layers if useful but keep paths/metadata consistent. Match the shadow to the new body and feet; no painted halo or double shadow. No new reaction rules.",
     "Crop-ready, hurt/night and destruction reactions are inspected through existing and showcase scenarios. Bubbles fit viewport and survive night lighting; work poses remain unobscured. Correct stable foot anchor and clean alpha; verify/hash guards pass."),
    (7, "terrain", "Quiet ground, paths and natural rock terrain", [3],
     "assets/art_source/terrain/; sprites/terrain/; tools/gen_sprites.py; src/ui/world_view.gd",
     "TERRAIN",
     "Replace grass and its four variants, soil, path, floor and rock terrain. Reduce repetitive speckles and brick-like rock pattern. Keep 16 px exact tiles, terrain enum order and atlas row contract or migrate generator and view together. Do not alter FARM_MAP or use decorative variants to change walkability. Keep low contrast under actors.",
     "Repeated 8x8 patches and full farm have no obvious seams or distracting tiling. Each material reads under day/dusk/night. Atlas check verifies every migrated tile and includes accepted sources. Native captures show actors clearly; verify/hash guards pass."),
    (8, "water-edges", "Water motion, banks and connected terrain edges", [7],
     "sprites/terrain/water*; sprites/terrain/edge_*; sprites/terrain/shore_*; tools/gen_sprites.py; src/ui/world_view.gd",
     "WATER",
     "Create three coherent water frames and coordinated bank/grass-to-soil/path edge art. Respect N=1/E=2/S=4/W=8 and all 16 masks. Inspect convex/concave corners and compound joins; add required corner metadata only in the view/import pipeline. Preserve atlas and nearest/no-mipmap import. The jetty should remain readable over water.",
     "All 16 masks, animation loop and representative corners are shown in the showcase. No edge popping, mismatched wave direction, gaps or swimming bank pixels. Water motion stays subtle at native size; actual farm captures and verify/hash guards pass."),
    (9, "props-animals", "Trees, rocks, resources and livestock", [8],
     "assets/art_source/props/; sprites/props/tree.png,stump.png,rock.png,seam.png,ore.png,cow.png,chicken.png; src/ui/world_view.gd",
     "TREE, RESOURCE_PROP, ANIMAL",
     "Finish full-canopy trees, cut stumps, rock/stone deposits, iron ore and current cow/chicken. Add controlled visual variations selected by cell in view code without consuming simulation RNG. Keep logical footprints and resource behavior unchanged. Use separate accepted masters per species/material; decorative movement is optional and view-only.",
     "Tree matches pilot, stump matches trunk, animals have recognizable species at native size. Resource types distinguishable without labels. Foreground/background overlap, density and harvest removal reviewed. No new collision clutter; verify/hash guards pass."),
    (10, "crops", "Three crops, four stages and watered soil", [8],
     "assets/art_source/crops/; sprites/crops/; src/ui/world_view.gd",
     "CROP",
     "Replace wheat/corn/carrot stages 0–3, tilled and tilled_wet. Species must differ in silhouette/color; stages progress clearly from seed to harvest. Preserve water readability beneath foliage. Mature corn may use taller canvas if anchor/layering is correct and neighboring beds remain legible. No growth/balance changes.",
     "A 3x4 stage matrix plus dry/wet soil and dense beds is inspected. Ready crops are readable without UI text; no misplaced crop after watering. No giant canopy hiding neighboring interactive cells. Dawn/day/night captures and verify/hash guards pass."),
    (11, "house", "Farmhouse as the visual landmark", [3, 9],
     "assets/art_source/buildings/house/; sprites/buildings/house*; src/ui/world_view.gd; src/ui/lighting.gd",
     "HOUSE",
     "Refine pilot house: terracotta roof with readable tile clusters, timber facade, door, chimney and warm windows. Keep the existing 3x3 logical footprint. Roof overhang and damaged appearance must use the agreed anchor pipeline, not nine duplicated buildings. Align window light sources with actual windows, and inspect low-health visual feedback without altering house HP.",
     "House is recognizable and larger than worker/props; one coherent roof at all camera positions. Windows align with glow, door ground contact matches occupied cells, front/behind overlap works. Whole/hurt/night states reviewed; verify/hash guards pass."),
    (12, "farm-buildings", "Workshop, kitchen, press, generator, shop and well", [11],
     "assets/art_source/buildings/; sprites/buildings/workshop*,kitchen*; sprites/props/press*,generator*,shop.png,well.png; src/ui/world_view.gd",
     "PRODUCTION_BUILDING, SHOP_WELL",
     "Create recognizable station masters, using tools/furnace for workshop, oven/cookware for kitchen, screw/lever for press, metal engine for generator and counter/awning for shop. Keep current 2x2 anchors and fixture footprints. Migrate quarter-based press/generator sources coherently. Add bounded cosmetic active/idle feedback only where state already exposes activity.",
     "Every station is identifiable by function and matches house materials/perspective. Whole stations render once without repeated fragments. Inactive, active and damaged states where applicable inspected; interaction targets remain correct. Day/night and verify/hash guards pass."),
    (13, "towers", "Four tower families at three authored levels", [12],
     "assets/art_source/defences/; sprites/buildings/gun_tower*,flame_tower*,mortar*,auto_crossbow*; tools/gen_sprites.py; src/ui/world_view.gd; src/ui/lighting.gd",
     "TOWER",
     "Produce gun, flame, mortar and automatic crossbow with level 1/2/3, hurt and fire states plus wrecks. The mine is handled in 0014. Levels change base reinforcement, mechanism and weapon form, not merely repeat post pixels. Keep common canvas/pivot per family; author muzzle positions as metadata. Disable legacy band-growth/flash/damage derivations only for migrated families with complete replacements. Existing mechanics and placement stay unchanged.",
     "Show each family/level/state in the showcase. L1 and L3 instantly distinguishable; functions differ in silhouette. Firing/damaged state paths resolve, projectile/glow origin matches muzzle, ghost base matches one cell. Mixed-defence night capture and verify/hash guards pass."),
    (14, "walls-traps", "Connected defences, barricades and mine", [13],
     "sprites/buildings/wall*,fence*,barricade*,mine*; src/ui/world_view.gd; assets/art_source/defences/",
     "WALL_TRAP",
     "Create coherent horizontal/vertical, corner/end/junction wall and fence variants selected from existing occupancy in the view. Produce barricade and armed/triggered mine visuals using existing trap state. Author hurt/wrecks that read as broken construction rather than pixel noise. Keep legal placement and pathing identical; avoid decorative posts suggesting blocked cells that remain open.",
     "Connected perimeter and all joins inspected. Hurt versus whole identifiable without bars; ruins lie on correct cells. Mine readability under actors/crops and build-preview route remain correct. No changed pathing hashes; full verify passes."),
    (15, "enemies", "Walker, runner, tank and breaker motion", [3, 13],
     "assets/art_source/enemies/; sprites/enemies/; src/ui/world_view.gd; generated animation metadata",
     "WALKER, ENEMY_STRIP",
     "Create four coherent enemy masters and short walk/attack/death strips (4/3/4 starting targets). Walker slouches, runner leans forward, tank has broad heavy mass, breaker has conspicuous arms/tool posture. Derive pose selection from existing state/position deltas in the view only. Replace two-frame row shifts with authored movement. Avoid adding attacks to core merely to play animation. Preserve current filenames through explicit aliases if migrating names.",
     "All four distinguishable as black silhouettes and in a dark mixed wave. Stable foot anchors; hit flash doesn't erase function. Attack selection reflects available core state, no invented attack timing. Death sources prepared for 0016 playback; motion sequences and verify/hash guards pass."),
    (16, "giant-deaths", "Giant wind-up and view-owned death playback", [15],
     "sprites/enemies/giant*; src/ui/world_view.gd; src/ui/particles.gd; visual animation metadata",
     "GIANT",
     "Create Giant master and walk/wind-up/slam/death sequences. Its telegraph must be recognizable before attack and agree with the existing target ring. Implement bounded view-owned death snapshots/pool for enemies removed by core, reusing the existing previous-frame observation approach where appropriate. Play death once, then expire. Trigger state changes only from existing observed data; never keep dead core entities alive for art.",
     "Boss visible at native size without hiding the target; wind-up distinct from walk. Ordinary and Giant deaths actually play once at the last correct position, don't loop or affect hits/pathing, and obey a hard pool cap. Showcase, boss/night capture, performance and verify/hash guards pass."),
    (17, "effects", "Combat and work effects in the same pixel language", [14, 16],
     "assets/art_source/effects/; src/ui/particles.gd; src/ui/world_view.gd; src/ui/juice.gd; src/ui/lighting.gd",
     "FX",
     "Create a small consistent set of muzzle flashes, impacts, flame/smoke, harvest dust, splashes and flare burst where raster forms improve readability. Keep effective low-cost procedural particles where they already match the style. Align emission to pivots/muzzles; share palette and bounded pools. Respect reduced motion/particle density. No new gameplay effects or damage changes.",
     "Busy wave, simultaneous deaths and work actions remain readable without a screen of glare. Fire stays warm at night, smoke stays subdued. Accessibility settings work and density changes leave simulation identical. Runtime perf and verify/hash guards pass."),
    (18, "icons-ui", "Resource icons and restrained UI surfaces", [10, 13],
     "assets/art_source/ui/; sprites/ui/; src/ui/ui_kit.gd; src/ui/day_hud.gd; src/ui/night_hud.gd",
     "ICON, UI_SURFACE",
     "Replace all 15 resource/tech icons from the actual inventory: wood, stone, iron, food, fish, oil, wheat, corn, carrot, meat, gunpowder, incendiary, money, energy and tech. Match world materials and optimize for actual display size. Refine existing panel/button/tab/check/slider surfaces without baking text into images or altering localization/layout scope. Preserve nine-patch margins, state contrast and accessibility focus visibility.",
     "All icons distinct at HUD scale and under both themes. Normal/hover/pressed/disabled/focus/tabs are distinguishable. Existing menus/tech/result/options fit English and pt-BR with no new clipping. Capture real screens, source checks and verify/hash guards pass."),
    (19, "lighting-unification", "Final shared palette and day/night atmosphere", [6, 8, 9, 10, 12, 17, 18],
     "tools/palette.py; src/ui/palette_data.gd; src/ui/relight.gdshader; src/ui/relight.gd; src/ui/lighting.gd; src/ui/transition.gd",
     "LIGHTING_STUDY (only if a reference study is needed)",
     "Tune existing dawn/day/dusk/night ramps against the reference and completed assets. Night must be blue/violet with deep but readable shadows and localized amber light. Audit brightness-based warm exemption: white clothes and crops shouldn't glow like fire. Align lamp/shadow/flash positions; avoid duplicate baked night sprites. Keep a11y controls, smooth reality switch and recognizable scene geometry.",
     "Paired same-farm day/night screenshots communicate a reality change with identical objects. Terrain, paths and enemies remain distinct; bloom does not erase walls/actors. Transition and low-light/accessibility settings reviewed. Palette source and generated data agree; verify/hash guards pass."),
    (20, "final-visual-gate", "Whole-game visual review and deliverable catalogue", [19],
     "implementation/sprites/PROGRESS.md; implementation/sprites/DELIVERY.md (new); src/tools/shot.gd; docs/PLAYTEST.md",
     "CORRECTION only for assets failing review",
     "Review the final farm, dense crop beds, all work verbs/facings, every structure/level/state, mixed waves, Giant, death playback, menus and accessibility settings. Fix remaining missing/fallback assets within the art scope. Check source-to-output ownership coverage and regenerate from a clean working tree without calling ImageGen. Produce a catalogue/contact sheets with native canvases, pivots, animation coverage, source links and known limits. Do not claim shipping based on one nice farm shot.",
     "Full python tools/verify.py including Windows/Web exports passes or documented environmental blockers remain blocked. Sim/data hashes unchanged from planning baseline. All visual contract criteria have concrete capture evidence. Final source regeneration changes no bytes; no required placeholders/missing textures or unreviewed aliases; delivery catalogue exists."),
]


def main():
    folder = ROOT / "prompts"
    folder.mkdir(parents=True, exist_ok=True)
    written = 0
    for tid, slug, title, deps, files, brief, requirements, evidence in TASKS:
        path = folder / f"{tid:04d}-{slug}.md"
        if path.exists():
            continue
        dependencies = ", ".join(f"{x:04d}" for x in deps) or "nothing"
        text = f"""# {tid:04d} - {title}

- **Status:** todo
- **Depends on:** {dependencies}
- **Likely files:** {files}
- **Generation briefs:** {brief}

## Goal and requirements

{requirements}

## Generation procedure

Use `generation/PROMPTS.md`: BASE plus the listed family brief, with the
actual asset ID, approved canvas, frame order and source/reference roles.
Use accepted masters as references. Keep raw accepted sources and exact prompts.
Where no generation is required, perform the specified integration/verification.

## Done when

{evidence}

- Every stated deliverable is saved and integrated where this task requires it.
- Source ownership and deterministic output checks pass.
- Required screenshots/animation sheets have been opened and reviewed.
- `python tools/verify.py` passes; sim/data hash baselines are unchanged.
- Append the journal with evidence, mark status using this queue's `task.py`,
  and stop after the task.

Follow `00-RUNNER-LOOP.md`, `ART_DIRECTION.md` and `PIPELINE.md`. Preserve
simulation, balance, map footprints, save formats and the owner's original art.
"""
        path.write_text(text, encoding="utf-8", newline="\n")
        written += 1
    print(f"{len(TASKS)} production tasks; {written} missing prompts created")


if __name__ == "__main__":
    main()
