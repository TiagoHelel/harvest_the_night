# 0019 — Shared atmosphere review

Accepted 2026-10-02. This is a view integration task with **zero ImageGen calls,
zero new masters and zero replaced runtime sprites**. Existing reference art and
accepted families suffice; LIGHTING_STUDY is optional. No project resolution,
grid, collision, simulation, save or balance change.

## Criteria and evidence

| Criterion | Result and saved evidence |
| --- | --- |
| Same farm changes reality | `implementation/shots/sprites/0019/atmosphere/farm_{dawn,day,dusk,night}.png` use one fixed seed, map and actor positions, without simulation advance. Cool dawn, neutral day, warm dusk and blue/violet night retain recognizable terrain, paths, buildings and four enemy silhouettes. |
| Materials do not emit light | All 42 colours are probed by the actual renderer in `atmosphere/palette_{day,night}.png` and `palette-measurements.json`. Ordinary bone material changes from `#ede0c7` to `#6164b3` (luma about .882 to .424). Clothing, crops, trees and pale stone now receive ambient night light. Source colours are unchanged. |
| Local warm emission | Existing muzzle, flame and flare frames and hot procedural sparks render above relight through the same bounded pool. Smoke and impacts receive ambient light; ground dust and splash remain below actors. `material_emission_{day,night}.png`, the seven-family effect fixture and actual core-pixel assertions verify semantic placement and camera transform. No brightness-based material exemption remains in game ramps. |
| Windows and bloom | Five measured windows have normal-blend 2x2 warm cores with existing small additive halos. Actual renderer checks all five core colours, including removal with lamps off. Warm light does not flatten the house roof, walls or neighboring actors. `window_cores_{steady,off}.png` and the farm night views cover it. |
| Smooth reality switch | Five steps in each direction, interrupted reversal and skipped transition are reviewed. Pivot metadata finds the three daytime animals and eight waking towers. Opacity follows displayed nightness; reversal preserves all five ramp uniforms and animal opacity. Tower pulse is limited to 1.45. Settings and complete state bytes are preserved. |
| Accessibility | Quality 0/1/2, lamps off, reduced flashing/density and skip transition are captured. Terrain and paths remain distinguishable with lamps off. English/pt-BR standard noon/dusk/wave/result/tech views are reviewed in both normal and high contrast. |
| Source ownership and determinism | Audit against `303f38b`: 1,312 protected files, all 468 runtime PNGs, all 447 raster manifest entries, all previous source/prompt records and 42 COLOURS values preserved. `scope-and-sources.json` contains hashes. Full raster check reproduces 447 outputs with zero writes; 21 legacy ASCII outputs also match. |
| Palette agreement | `tools/palette.py` remains authoritative. Only ramps change; `gen_sprites.py` writes matching generated palette data while preserving all image outputs. Night tint is (.36,.40,.82), lift (.04,.035,.105), saturation .76. Dusk and night warm_keep=1 disables the entire brightness exemption, including its soft edge. |

## Verification

`verify-complete.log` is the final full run after the reversal and fixture
observer corrections: **52 passed, zero skipped/failed in 405s** on Godot 4.7.1.
115 scripts parse, 6,646 rule assertions and 982 input cases pass; Windows/Web
exports pass. Sim hash `1961000123` and data hash `407837701` are unchanged.
The 300s soft duration target is exceeded without a failed verification gate.
Night tick 544us/8,333us and path rebuild 4,183us/33,333us pass.

The headless atmosphere gate has 198 checks; the AMD Compatibility renderer
capture run has 300; both have zero failures. The effects fixture retains
2,997 headless and 3,156 actual-renderer checks with zero failures. Its 100
burning actors use at most 24 raster slots and the same 420 shared limit;
view update p95 is 532us against 16,000us. This measures CPU view work, not GPU
fragment time. Headless verification alone cannot establish shader appearance;
the captured renderer probes and opened native images provide that evidence.

The initial `verify.log` failure is retained: five old assertions expected
brightness-exempt cloth, rims and sparks. They were replaced with material
ambient-light and actual warm-family-parent/texture checks, rather than disabled.
`verify-final.log` records an earlier 52-pass run; `verify-complete.log` is
authoritative for the final code. No hash baseline was accepted or moved.

## Actual visual review and limitations

Opened every relevant final capture at native **480x270** and nearest 3x:
27 atmosphere views, 37 effect views and 20 standard scene/locale/theme views,
84 total. `capture-index.json` maps the originals to `captures-00..90.png`;
seven index gaps correspond to separately retained pre-change diagnostics.

The initial 64-view review caught stale manual observers in transition capture
steps. The fixture now refreshes lamps and Transition after phase changes.
`observer-refresh-diff.json` proves 52 of those images pixel-identical after
recapture; all 12 changed transition/skip views were reopened, as were all 20
new standard captures. Dawn lamps now turn off and animal fades/reversal match
the displayed ramp. The fixture restores non-persistent settings on exit and
never instantiates Main or writes a profile.

The four final farm photographs are the controlled same-object comparison.
`before/` contains seven older diagnostic images; enemy arrangement differs
from the final fixture, so they are not a controlled day/night pair. Standard
shots retain their existing simulation settling and frozen observers; they
show endpoint ambient light, HUD and battle composition. The atmosphere fixture
is the evidence for animal fading, observer transitions and exact window cores.
Standard Portuguese result/tech views contain pre-existing untranslated labels;
their bounds remain readable, and this task does not change localization content.

No new source-alpha or sprite-frame candidate exists in this task. Prior accepted
binary alpha, silhouettes, contacts, sources and animations remain byte-exact and
their family gates continue passing. The final end-to-end art audit is task 0020.
