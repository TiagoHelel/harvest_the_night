# -*- coding: utf-8 -*-
"""Check the string table against the code and against the font.

    python tools/i18n_check.py            report and fail on anything wrong
    python tools/i18n_check.py --report   the widest lines per language

Four questions, and none of them can be answered by reading:

- **Is every key the code asks for in the table?** A missing key renders as
  its own name, which is better than a blank label and still a bug.
- **Is every row in the table asked for?** A key nothing uses is a line a
  translator spent time on for nothing, and it hides the ones that matter.
- **Does every row have every language?** An empty cell falls back to English,
  which is a Portuguese screen with an English word on it.
- **Does it fit?** This is the one that cannot be done by eye. The `width`
  column is how many pixels the control that draws a key gives it, and the
  text is measured in the game's own font - the same glyph widths
  `gen_font.py` writes into the `.fnt` - so a Portuguese line that would run
  off the end of its button fails here rather than in front of a player.

A fifth, thrown in because it costs nothing: both languages have to use the
same format specifiers. `%d` in English and nothing in Portuguese is a line
that silently loses its number.

And a sixth (task 0294): **one name per thing, and the plan's.** `GLOSSARY`
holds the Portuguese `docs/PLANO-DO-JOGO.md` gives each thing - the
seasons, the events, the crops, fish, machines, defences, enemies and
bosses - and a row that drifts from it fails, compared without case. A
rename is a change here first, and the plan's word wins unless the journal
records the owner choosing another.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import gen_font                                       # noqa: E402

TABLE = os.path.join(ROOT, "assets", "locale", "strings.csv")
# `src/core/` is in the list for one reason: the tutorial steps name a
# key each. The rules hold no words, but they do hold which words.
CODE = [os.path.join(ROOT, "src", "ui"), os.path.join(ROOT, "src", "app"),
        os.path.join(ROOT, "src", "core")]

## A key, wherever it appears: `I18n.t(&"X")`, a table of them, anything.
##
## **Every key has a prefix**, and that is what tells one from the other
## `StringName`s in this codebase - `&"SFX"` is a bus and `&"move_up"` is an
## action. A key is capitals with at least one underscore in it, and the rule
## is kept by the keys being named after the screen they are on.
KEY_IN_CODE = re.compile(
    r'&"([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+(?:\.(?:one|other))?)"')

## What a plural key looks like in the table.
PLURAL = re.compile(r'^(.*)\.(one|other)$')

SPECIFIER = re.compile(r'%[-+ #0-9.]*[a-zA-Z%]')

## **The plan's names** (task 0294): key -> the pt_BR it must read, without
## case. From `docs/PLANO-DO-JOGO.md`: the calendar and its events (section
## 2), the crops (3.1), the fish (3.2), the machines (3.5), the stall and the
## shipping bin (3.6), the powers (4.4), START (4.2), the night's leftovers
## (4.6), the defences (5), the enemies and bosses (6) and essence (7).
GLOSSARY = {
    # The year and its nights.
    "SEASON_SPRING": "primavera", "SEASON_SUMMER": "verão",
    "SEASON_AUTUMN": "outono", "SEASON_WINTER": "inverno",
    "FCAST_FULL_MOON": "lua cheia", "RES_ESSENCE_FULL_MOON": "lua cheia",
    "FCAST_BLOOD_MOON": "lua de sangue", "RES_ESSENCE_BLOOD_MOON": "lua de sangue",
    "FCAST_FOG": "neblina", "FCAST_RAIN": "chuva",
    "NHUD_START": "começar",
    # What the night leaves and pays.
    "ITEM_TECH": "essência", "ITEM_TECH.other": "essência",
    "ITEM_BONES": "ossos", "ITEM_BONES.other": "ossos",
    "ITEM_BONE_MEAL": "farinha de osso",
    "ITEM_MOON_STONE": "pedra da lua", "ITEM_MOON_STONE.other": "pedras da lua",
    # Selling.
    "FIX_SHIPPING_BIN": "caixa de envio", "SHIP_TITLE": "caixa de envio",
    "SHOP_TITLE": "banca",
    # The crops.
    "ITEM_CARROT": "cenoura", "ITEM_POTATO": "batata", "ITEM_GARLIC": "alho",
    "ITEM_STRAWBERRY": "morango", "ITEM_CORN": "milho", "ITEM_PEPPER": "pimenta",
    "ITEM_SUNFLOWER": "girassol", "ITEM_MELON": "melancia", "ITEM_WHEAT": "trigo",
    "ITEM_PUMPKIN": "abóbora", "ITEM_GRAPE": "uva", "ITEM_BEET": "beterraba",
    # The fish the plan names.
    "ITEM_CARP": "carpa", "ITEM_PERCH": "perca", "ITEM_CATFISH": "bagre",
    "ITEM_TILAPIA": "tilápia", "ITEM_TROUT": "truta", "ITEM_PIKE": "lúcio",
    "ITEM_EEL": "enguia", "ITEM_DORADO": "dourado", "ITEM_SALMON": "salmão",
    "ITEM_STURGEON": "esturjão", "ITEM_OLD_CATFISH": "velho bagre",
    "ITEM_GOLDEN_QUEEN": "rainha dourada", "ITEM_GHOST_PIKE": "lúcio fantasma",
    "ITEM_ICE_STURGEON": "esturjão de gelo",
    # The machines.
    "BLD_WORKSHOP": "oficina", "BLD_PRESS": "prensa", "BLD_KITCHEN": "cozinha",
    "BLD_GENERATOR": "gerador", "BLD_KEG": "barril", "BLD_PRESERVES_JAR": "conserva",
    "BLD_DAIRY": "laticínios", "BLD_LOOM": "tear", "BLD_MILL": "moinho",
    # The powers.
    "POWER_FARM_BELL": "sino da fazenda", "POWER_CALL_DOG": "chamar o cão",
    "POWER_EMERGENCY_REPAIR": "conserto de emergência",
    # The defences.
    "DEF_GUN_TOWER": "torre de tiro", "DEF_AUTO_CROSSBOW": "besta automática",
    "DEF_MINE": "mina", "DEF_FENCE": "cerca", "DEF_BARRICADE": "barricada",
    "DEF_WALL": "muro", "DEF_FLAME_TOWER": "lança-chamas", "DEF_DECOY": "espantalho",
    "DEF_BEEHIVE": "colmeia", "DEF_MORTAR": "morteiro",
    "DEF_CATAPULT": "catapulta de abóbora", "DEF_GARLIC_BRAID": "réstia de alho",
    "DEF_SEARCHLIGHT": "holofote", "DEF_ELECTRIC_FENCE": "cerca elétrica",
    # The enemies - one of the rat swarm is a rat - and the bosses.
    "ENEMY_WALKER": "andarilho", "ENEMY_WALKER.other": "andarilhos",
    "ENEMY_RUNNER": "corredor", "ENEMY_RUNNER.other": "corredores",
    "ENEMY_TANK": "tanque", "ENEMY_TANK.other": "tanques",
    "ENEMY_BREAKER": "destruidor", "ENEMY_BREAKER.other": "destruidores",
    "ENEMY_SPITTER": "cuspidor", "ENEMY_SPITTER.other": "cuspidores",
    "ENEMY_RAT": "rato", "ENEMY_RAT.other": "ratos",
    "ENEMY_CROW": "corvo", "ENEMY_CROW.other": "corvos",
    "ENEMY_DIGGER": "escavador", "ENEMY_DIGGER.other": "escavadores",
    "ENEMY_FROST_ZOMBIE": "zumbi de gelo", "ENEMY_FROST_ZOMBIE.other": "zumbis de gelo",
    "ENEMY_WRAITH": "assombração", "ENEMY_WRAITH.other": "assombrações",
    "ENEMY_GIANT": "gigante", "ENEMY_HARVESTER": "colheitadeira",
    "ENEMY_SCARECROW_KING": "rei espantalho",
    "ENEMY_WINTER_LORD": "senhor do inverno",
}

## **Names the same in both languages, on purpose** (task 0294). A thing's
## pt_BR name that reads as its English one is a name nobody translated -
## `_task_0294_names` fails it - unless it is listed here. None is, today.
SAME_IN_BOTH = []


def read_table():
    """[(key, width, {locale: text})], in file order."""
    rows = []
    with io.open(TABLE, encoding="utf-8", newline="") as f:
        import csv
        reader = csv.reader(f)
        columns = next(reader)
        locales = [c.strip() for c in columns[2:]]
        for row in reader:
            if not row or not row[0].strip():
                continue
            key = row[0].strip()
            width = int(row[1]) if row[1].strip().isdigit() else 0
            texts = {}
            for i, locale in enumerate(locales):
                texts[locale] = row[2 + i] if 2 + i < len(row) else ""
            rows.append((key, width, texts))
    return rows, locales


def keys_in_code():
    """{key: [where it was seen]}"""
    found = {}
    for folder in CODE:
        for name in sorted(os.listdir(folder)):
            if not name.endswith(".gd"):
                continue
            path = os.path.join(folder, name)
            with io.open(path, encoding="utf-8") as f:
                for n, line in enumerate(f, 1):
                    if line.strip().startswith("#"):
                        continue
                    for key in KEY_IN_CODE.findall(line):
                        found.setdefault(key, []).append("%s:%d" % (name, n))
    return found


def width_of(text, widths):
    """How wide a line is in the game's font, in pixels."""
    if text == "":
        return 0
    total = 0
    for ch in text:
        if ch not in widths:
            return -1                    # a glyph the font does not have
        total += widths[ch][1]
    return total + gen_font.TRACKING * (len(text) - 1)


def check():
    rows, locales = read_table()
    widths = gen_font.measure(gen_font.every_glyph())
    used = keys_in_code()
    in_table = set(key for key, _, _ in rows)
    bad = []

    seen = set()
    for key, _, _ in rows:
        if key in seen:
            bad.append("%s is in the table twice" % key)
        seen.add(key)

    # A plural pair is asked for by its stem.
    asked = set(used)
    for key in list(asked):
        asked.add(key + ".one")
        asked.add(key + ".other")

    for key in sorted(used):
        if key in in_table:
            continue
        if key + ".one" in in_table and key + ".other" in in_table:
            continue
        bad.append("%s is used at %s and is not in the table"
                   % (key, used[key][0]))

    for key, _, _ in rows:
        stem = PLURAL.match(key)
        plain = stem.group(1) if stem else key
        if key not in used and plain not in used:
            bad.append("%s is in the table and nothing uses it" % key)

    for key, width, texts in rows:
        english = texts.get("en", "")
        for locale in locales:
            text = texts.get(locale, "")
            if text.strip() == "":
                bad.append("%s has no %s" % (key, locale))
                continue
            if SPECIFIER.findall(text) != SPECIFIER.findall(english):
                bad.append("%s: %s has %s and en has %s"
                           % (key, locale, SPECIFIER.findall(text),
                              SPECIFIER.findall(english)))
            drawn = width_of(text, widths)
            if drawn < 0:
                bad.append("%s: %s uses a glyph the font does not have"
                           % (key, locale))
            elif width > 0 and drawn > width:
                bad.append("%s: %s is %dpx and its control gives it %d"
                           % (key, locale, drawn, width))
    bad.extend(glossary_drift(rows))
    return rows, locales, bad


def glossary_drift(rows):
    """Every glossary row that is missing or reads other than the plan."""
    texts = dict((key, t.get("pt_BR", "")) for key, _, t in rows)
    out = []
    for key in sorted(GLOSSARY):
        if key not in texts:
            out.append("%s is in the glossary and not in the table" % key)
        elif texts[key].strip().lower() != GLOSSARY[key].lower():
            out.append("%s reads '%s' in pt_BR and the glossary says '%s'"
                       % (key, texts[key], GLOSSARY[key]))
    return out


def report():
    rows, locales = read_table()
    widths = gen_font.measure(gen_font.every_glyph())
    print("  %-28s %5s %s" % ("key", "gives", "  ".join(
        "%-8s" % l for l in locales)))
    worst = []
    for key, width, texts in rows:
        if width <= 0:
            continue
        drawn = [width_of(texts.get(l, ""), widths) for l in locales]
        worst.append((max(drawn) - width, key, width, drawn))
    worst.sort(reverse=True)
    for slack, key, width, drawn in worst[:20]:
        print("  %-28s %5d %s   %s" % (key, width,
                                       "  ".join("%8d" % d for d in drawn),
                                       "TIGHT" if slack > -8 else ""))


def main():
    args = sys.argv[1:]
    if "--report" in args:
        report()
        return 0
    rows, locales, bad = check()
    if bad:
        for line in bad[:40]:
            print("  " + line)
        if len(bad) > 40:
            print("  ... and %d more" % (len(bad) - 40))
        print("FAIL  the string table and the code disagree")
        return 1
    print("OK    %d keys in %d languages, all of them fit"
          % (len(rows), len(locales)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
