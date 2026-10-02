# 0018 - Native resource icons and UI surfaces

Reviewed 2026-10-02 in Godot 4.7.1 at the actual 480x270 viewport, with
nearest-neighbor 3x copies for pixel inspection. Accepted the complete family.
Completed world/player/enemy/effect sprites were preserved.

The final staged audit also proves 75 raw-source, prompt, submitted-argument and
runtime-output files match their worktree bytes exactly. Earlier unrelated
capture files remain excluded from this commit.

## Requirements and evidence

| Requirement | Evidence and result |
| --- | --- |
| All 15 actual resources, consistent world materials | `generation/0018-plan.json` and fifteen `0018-*-call.json` records cover wood, stone, iron, food, fish, oil, wheat, corn, carrot, meat, gunpowder, incendiary, money, energy and tech. Fifteen actual built-in ImageGen calls, zero revisions. Every returned raw source is preserved byte-for-byte in `assets/art_source/ui/`. |
| Exact prompts, references and ownership | Each record preserves exact submitted arguments, UTF-8 prompt, source/reference/output SHA-256, crop, scale, anchor, canvas, pivot and selected outputs. Wood uses the reference sheet; subsequent icons also use the accepted wood master. `audit.py` checks the original tool-return bytes and exact request records. |
| Native icon readability | Thirty distinct cuts: full 16x16, maximum visible dimension 14; compact 10x10, maximum visible dimension 8. Both use the same master/crop with separately recorded scale. All are centered with transparent padding, binary alpha, approved palette, no baked text, shadows or enclosing boxes. Opened all raw sources and complete light/dark/checker sheets at native and exact nearest 3x. Shapes/materials remain distinct; compact gunpowder stays a subdued gray pile. Localized names remain beside icons. |
| Runtime integration | HUD resource/money/power rows, tech currency, inventory's complete ledger and shop quantity-one buttons use compact cuts with native pixels. The source fixture checks all opaque rendered icon pixels against their files under both themes. No sprite enlargement or project resolution change. |
| Button/tab/check/slider states | Existing deterministic code-owned UI maps are refined. Normal, hover, pressed, disabled and focused controls are visibly distinct. Selected tabs have a gold underline; disabled checks and slider grips use quiet authored textures. Checkbox/button focus retains the open light ring; slider keyboard focus uses the highlighted small grip. Real pointer hover and keyboard focus are exercised in captures, rather than a drawn imitation of controls. |
| Nine-patch margins and accessibility | Frames keep three-pixel margins and existing dimensions. Focus source remains open and visible; theme/source assertions pass. Normal and high-contrast text roles are preserved. Controls fit existing footprints. |
| English and pt-BR fit | Captures include both locales and both themes for menus, tech, result, all four options tabs, title/error states, inventory and buy/sell. Inventory's 252px ledger is centered at y=9 so its bottom stays inside 270px; localized names rebuild when locale revision changes. HUD money starts at x=144, after the long Portuguese dusk label. Day 99 and balance 1,000,024 fit before resource columns. No new clipping or HUD overlap. Existing untranslated legacy headings are outside this art task. |
| Core/art preservation | `scope-and-sources.json`: all 417 earlier raster entries and 1,184 protected prior core/art files are unchanged against `566a503`. Only the 15 legacy UI icons and ten UI surface outputs are replaced. Current ownership: 447 raster / 21 ASCII / zero player-sheet, 468 runtime PNGs. Simulation, palette, balance, save formats, grid and collisions are preserved. |
| Verification | Final `verify.log`: 51 passed, zero skipped/failed in 407s; 114 scripts parse, 6,613 rule assertions and 982 input cases; Windows/Web exports pass. Sim hash `1961000123`, data hash `407837701` unchanged. Raster reproduction: 447 outputs, zero writes. Native UI headless: 1,948 checks; actual renderer: 10,548 checks, zero failed. |

## Actual visual review

The accepted captures are `implementation/shots/sprites/0018/`: 40 gameplay/menu
views, 16 title/error views, and 36 actual UI fixtures. `capture-index.json`
maps all 92 native 480x270 images to `captures-00..91.png`, each pairing native
pixels above an exact nearest 3x image. All relevant screens were opened and
reviewed. Source alpha/material sheets and the complete icon families also pass.

After the final HUD money reflow, all 40 top bars were opened again using
`final-hud-strips-0..3.png`. For 35 captures, the rest of the image is exactly
unchanged; the five varying night captures were reopened in full, as were all
four wave views. `hud-reflow-diff.json` records the comparison. Shader/animation
timing changes pixels outside the HUD in those five captures; this is not a
claim of identical rendered worlds. Prior source/runtime sprite bytes are exact.

The UI fixture covers every resource, native 16/10px pixels, real focus/hover,
disabled grip, full inventory, both market tabs, daytime dusk and night power
visibility. Observers preserve complete serialized rule state. Menus and options
fit; the original title composition, animations and world sprites are retained.

## Corrections and limits

Visual review found and fixed three integration defects: the inventory extended
two pixels past the viewport; Godot used its large default disabled slider grip;
Portuguese dusk text overlapped the money group. These are layout/theme changes
using accepted images, with no repeated ImageGen calls. Initial fixture failures
from assertions placed inside incomplete loops were corrected. Failed logs and
pre-reflow captures remain as evidence; no old gate was disabled or hash accepted.

The full suite exceeds its soft 300s duration target. Performance checks still
pass: night tick 546us of 8,333us and path rebuild 4,264us of 33,333us. Icons are
cached and created at UI construction; ledger rebuilding is triggered by resource
or locale changes. No new per-frame icon allocation or GPU timing claim.

Task 0019 will evaluate day/dusk/night atmosphere with the existing sprites,
honoring the user's request not to regenerate completed art. Task 0020 remains
the final catalog and regression audit. This closes exactly task 0018.
