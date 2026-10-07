# assets/studio/

The studio's ident - **DEF4ULT STUDIO** - and nothing of this game's.

`assets/README.md` says everything under `assets/` is generated. This folder is
the one exception, on purpose: a studio ident belongs to the studio rather than
to the game it opens, so it is carried across byte for byte instead of being
redrawn or resynthesised here. It came from **WELCOME BACK, HERO**
(`one_room_dg`), which ported it from Overstack; the owner asked for this game
to open exactly the way that one does (2026-10-07).

| file | from WELCOME BACK, HERO | sha256 |
|---|---|---|
| `def4ult_studio.png` | `assets/logo/def4ult_studio.png` - the crest, 300x300, background keyed to alpha | `628a86e8818ec567a3fd04a194737b2045821dd06260dcf0d5101a22f6146675` |
| `ident_power.wav` | `assets/sfx/ui_confirm.wav` - the tube striking, 0.16 s | `1fe089d7b43756504f65444f54ddf44b34ffcf3ec5f4d871e780f3d44a52ff41` |
| `ident_sting.wav` | `assets/sfx/glass_forge.wav` - the core igniting, 0.57 s | `79bc238c9b9c006899e4541792ecaaf5335b8fe3c7e94db30656408f5a073689` |
| `one_room_pixel.fnt` | `assets/fonts/one_room_pixel.fnt` - the face the plate is set in | `8a1efc4b88d96be659e23ecceeddadf711b1d3160e74360451b0af32304fce13` |
| `one_room_pixel.png` | `assets/fonts/one_room_pixel.png` - its glyph atlas | `04ccb174dbb42703c38e222319f431abacf982bf7a532a17bef899a07dd4ff6f` |

All five are the studio's own work, released as CC0 there (`tools/origins_check.py`
and `assets/fonts/LICENSE.md` in that repository). The two sounds keep that
game's import settings - uncompressed PCM, no trim - rather than this game's
QOA default, so they are the same samples and not a re-encoding of them; the
crest keeps its texture settings too.

**The face is that game's, not this one's.** The ident sets DEF4ULT STUDIO and
PRESENTS in the font it was approved in; this game's `harvest_heading` is wider
and squarer, and the plate in it would be a different plate. Nothing else in
the game uses it.

`src/ui/studio_intro.gd` is the only reader. `headless_check` holds the hashes
above, so a "small fix" to any of these files is a deliberate act.
