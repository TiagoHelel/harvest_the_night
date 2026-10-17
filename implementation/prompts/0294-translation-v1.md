# 0294 - Every new word in Portuguese

- **Phase:** 17 - Ship 1.0
- **Status:** done
- **Depends on:** 0287, 0293, 0291, 0292
- **Likely files:** assets/locale/strings.csv, tools/i18n_check.py, src/ui/names.gd, src/tools/headless_v1.gd

## Goal

Portuguese is the owner's language and most of the audience's. Every line 1.0 added gets read again as a whole: one name for each thing, sentences that agree in gender and number, and nothing running off its button.

## Requirements

- Read every row added since 0112 (`git log -p -- assets/locale/strings.csv` from 0112's commit on) in both languages, then on screen. The journal lists every pt_BR change with the before and the after
- One name per thing, and the plan's: its names become a glossary in `tools/i18n_check.py` (key to expected pt_BR, compared without case) that fails a row which drifts - the seasons, Lua Cheia, Lua de Sangue, neblina, chuva, essência, caixa de envio, mascate, banca, guardião, COMEÇAR, the crops of §3.1, the fish of §3.2, the machines of §3.5, the defences of §5, the enemies and bosses of §6, ossos, farinha de osso, pedras da lua
- Three MVP names disagree with the plan today: `DEF_FLAME_TOWER` 'torre de fogo' (plan: lança-chamas), `ENEMY_BREAKER` 'quebrador' (destruidor) and `ENEMY_TANK` 'brutamontes' (tanque). The plan wins unless the journal records the owner choosing otherwise; the plurals and every sentence that uses them move with them
- Counted names have plurals: every enemy, fish, crop and item a line counts (the forecast's '34 andarilhos', the morning report, the fish book) has its `.other` row in both languages - the bare key is the singular, and a `.one` row exists only where the counted singular differs from the name, as `I18n.plural` documents
- Agreement: a pt_BR line that puts a name into a sentence agrees with it ('a Colheitadeira caiu', 'o Gigante caiu'). Where one template cannot agree with every name, rewrite it so the name stands alone ('Caiu: %s') rather than adding gender data to the rules
- Widths: every row added since 0112 that is drawn in a fixed control (HUD label, button, hotbar tooltip, option row) and still has `width` 0 - which means unchecked - is measured and given its real width. `python tools/i18n_check.py --report` names the widest lines, and the widest pt_BR ones are looked at on screen. `i18n_check` already refuses a glyph the font lacks; look at the accented ones in use (ã, õ, ç, ê, á, and capitals on buttons such as COMEÇAR) at 1920x1080 too
- `Names.KEYS` covers every id 1.0 added and `Names.NOTES` every tech node (already asserted); `ITEM_TECH` reads essence / essência (0219's rename, the id stays `tech`) and the glossary holds it there. Text only: neither hash moves

## Done when

- [ ] `python tools/i18n_check.py` passes with the glossary enforced, and fails when one glossary row is changed by hand (tried once, reverted, said in the journal)
- [ ] `_task_0294_names` in `src/tools/headless_v1.gd`: every id in `CROPS`, `RESOURCES`, `DEFENCES`, `ENEMIES`, `BUILDINGS`, `RECIPES`, `TECH_TREE` and the fish species of 0179 has a `Names.KEYS` key whose row is non-empty in `en` and in `pt_BR` read straight from the table (no English fallback, no key printed as itself), and its pt_BR text differs from its English one unless the glossary marks the word as the same in both
- [ ] pt_BR captures at 1920x1080 of both HUDs, the forecast, the hotbar, the morning report, the fish book, the collections and every options page (`python tools/shot.py 0294 --fhd --pt_BR` and `capture_menus.gd -- --out=res://implementation/shots/0294/ --pt_BR`), opened one by one: no clipped, overlapping or English word
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
