# assets/

Everything that is not a sprite: fonts, sound, music and the UI theme.

Sound comes from `tools/gen_sfx.py` (tasks 0084-0085), music from
`tools/gen_music.py` (task 0086) and the font from `tools/gen_font.py`
(task 0080). Like the sprites, all of it is generated: do not hand-author WAVs.

**`studio/` is the one exception.** It holds the DEF4ULT STUDIO ident - the
crest, its two sounds and the face of its plate - carried byte for byte from
WELCOME BACK, HERO, because a studio ident belongs to the studio and is not
redrawn per game. Its README says where each file came from; nothing outside
`src/ui/studio_intro.gd` reads it.
