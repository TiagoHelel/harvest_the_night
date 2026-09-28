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
    return rows, locales, bad


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
