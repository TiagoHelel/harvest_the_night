# sprites/

**Generated, never hand-authored.** Every PNG here comes out of
`tools/gen_sprites.py`, which renders the ASCII maps in `tools/sprite_maps.py`
against the one palette in `tools/palette.py`.

```bash
python tools/gen_sprites.py          # write them
python tools/gen_sprites.py --check   # fail if one was edited by hand
```

They are committed so a fresh clone runs with no build step. `verify.py` checks
them on every task: a PNG that no longer matches its map is a PNG somebody
painted over, and a painted-over sprite stops following the palette the moment
the palette moves.

To change a sprite, change its map. Running the generator twice produces
byte-identical files, so a diff here is always a deliberate one.

16x16 for tiles and props, 16x24 for actors, transparent background, imported
with nearest-neighbour filtering and no mipmaps.
