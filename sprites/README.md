# sprites/

**Generated, never hand-authored.** Everything here comes out of
`tools/gen_sprites.py`, which turns ASCII maps plus the shared palette into
PNGs (task 0014).

To change a sprite, edit its map and regenerate. Running the generator twice
produces byte-identical files, so a diff here is always a deliberate one.

16x16 for tiles and props, 16x24 for actors, transparent background,
nearest-neighbour import with no mipmaps.
