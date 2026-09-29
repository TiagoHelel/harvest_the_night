# -*- coding: utf-8 -*-
"""What a folder of playtest logs actually says.

    python tools/playtest.py                  the logs on this machine
    python tools/playtest.py <folder>         a folder of them somebody sent
    python tools/playtest.py --self-check     that the reader still reads

A session log is written by a playtest build - `Playtest` in
`src/app/playtest.gd` - and is a plain text file a tester can read before
they decide to send it. This reads a folder of them and answers the four
questions a playtest is for.

## The questions, and why these four

**Did they get to the night at all?** The whole premise is that the farm turns
into a tower defence; somebody who quit on day one never saw the game. This is
the number that decides whether anything else in the report matters.

**How long was day one?** `design.md` wants a day to be a few minutes, and a
first day that takes twenty is a tutorial that is not working. The median
matters more than the mean here: one tester who went to make a cup of tea
should not move the answer.

**Where did the runs end?** Lost on night three, quit from the pause menu on
day two, and closed the window without doing either are three different
problems. The third one is the worst and the easiest to miss, because it
leaves a session with no ending in it at all.

**Where are the notes?** Every `F1` is a tester saying "here". A pile of them
in the same minute of the same night is the single most useful thing in the
folder, and it is invisible unless somebody lines the sessions up.

## It reads what the game writes, and nothing else

No parsing of anything clever: the log's own lines, in the shape
`  m:ss  what happened`. If the format moves, this stops recognising lines
rather than silently reporting zeroes, which is what `--self-check` is for -
it runs the reader over a log written out here and fails if the questions
come back empty.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## Where a Windows build keeps them. Named so the summary can say where it
## looked when it finds nothing, which is the commonest way this is run.
DEFAULT = os.path.join(os.environ.get("APPDATA", ""), "Godot",
                       "app_userdata", "HARVEST THE NIGHT", "playtest")

LINE = re.compile(r"^\s*(\d+):(\d\d)\s\s(.*)$")
HEADER = re.compile(r"^(build|seed|began)\s+(.*)$")


def read(path):
    """One session as a dictionary of what happened in it."""
    with io.open(path, encoding="utf-8", errors="replace") as f:
        text = f.read()

    out = {"path": path, "name": os.path.basename(path), "build": "",
           "seed": "", "began": "", "lines": [], "notes": [],
           "nights_won": 0, "nights_reached": 0, "ending": "",
           "day_one": None, "built": "", "seconds": 0}

    for line in text.splitlines():
        head = HEADER.match(line)
        if head and not out[head.group(1)]:
            out[head.group(1)] = head.group(2).strip()
            continue
        hit = LINE.match(line)
        if not hit:
            continue
        at = int(hit.group(1)) * 60 + int(hit.group(2))
        what = hit.group(3).strip()
        out["lines"].append((at, what))
        out["seconds"] = max(out["seconds"], at)

        if what.startswith("NOTE "):
            out["notes"].append((at, what))
        elif what.startswith("night ") and what.endswith(" began"):
            out["nights_reached"] = max(out["nights_reached"],
                                        _number_in(what))
        elif what.startswith("night ") and what.endswith(" won"):
            out["nights_won"] = max(out["nights_won"], _number_in(what))
        elif what.startswith("day 2 began") and out["day_one"] is None:
            out["day_one"] = at
        elif what.startswith("the run ended: "):
            out["ending"] = what[len("the run ended: "):]
        elif what.startswith("built "):
            out["built"] = what

    # **A session with no ending is a finding, not a gap in the data.** The
    # window was closed, the machine went to sleep, or the game went down
    # without getting as far as writing a line about it.
    if not out["ending"]:
        ended = [w for _a, w in out["lines"] if w.startswith("session ended")]
        out["ending"] = (ended[-1][len("session ended: "):] if ended
                         else "nothing - the session just stops")
    return out


def _number_in(text):
    found = re.search(r"\d+", text)
    return int(found.group(0)) if found else 0


def sessions_in(folder):
    if not os.path.isdir(folder):
        return []
    found = []
    for name in sorted(os.listdir(folder)):
        if name.endswith(".log"):
            found.append(read(os.path.join(folder, name)))
    return found


def median(values):
    if not values:
        return None
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) / 2.0


def clock(seconds):
    if seconds is None:
        return "-"
    return "%d:%02d" % (int(seconds) // 60, int(seconds) % 60)


def report(folder):
    found = sessions_in(folder)
    print("")
    print("HARVEST THE NIGHT - playtest")
    print("")
    print("  %s" % folder)
    if not found:
        print("")
        print("  no session logs here. A playtest build writes one per run;")
        print("  `python tools/release.py --playtest` makes such a build.")
        return 1

    print("  %d session%s" % (len(found), "" if len(found) == 1 else "s"))
    print("")
    print("  %-20s %6s %6s %6s  %s"
          % ("session", "for", "night", "notes", "ended"))
    for one in found:
        print("  %-20s %6s %6d %6d  %s"
              % (_short(one["name"]), clock(one["seconds"]),
                 one["nights_reached"], len(one["notes"]),
                 one["ending"][:36]))

    # ------------------------------------------------ the four questions
    reached = [s for s in found if s["nights_reached"] >= 1]
    print("")
    print("  DID THEY GET TO A NIGHT AT ALL")
    print("    %d of %d reached night one" % (len(reached), len(found)))
    if len(reached) < len(found):
        for one in found:
            if one["nights_reached"] < 1:
                print("      %s stopped in the day, after %s"
                      % (one["name"], clock(one["seconds"])))

    days = [s["day_one"] for s in found if s["day_one"] is not None]
    print("")
    print("  HOW LONG WAS DAY ONE")
    if days:
        print("    median %s, from %s to %s, over %d of them"
              % (clock(median(days)), clock(min(days)), clock(max(days)),
                 len(days)))
    else:
        print("    nobody finished a first day")

    print("")
    print("  WHERE DID THE RUNS END")
    endings = {}
    for one in found:
        endings[one["ending"]] = endings.get(one["ending"], 0) + 1
    for why in sorted(endings, key=lambda k: (-endings[k], k)):
        print("    %2d  %s" % (endings[why], why))

    print("")
    print("  WHERE ARE THE NOTES")
    notes = []
    for one in found:
        for at, what in one["notes"]:
            notes.append((at, one["name"], what))
    notes.sort()
    if not notes:
        print("    none left. Either nothing went wrong or nobody knew "
              "about the key.")
    for at, name, what in notes:
        near = _what_was_happening(found, name, at)
        print("    %6s  %-20s %s" % (clock(at), _short(name), near))

    print("")
    deepest = max(s["nights_won"] for s in found)
    print("  the furthest anybody got is night %d won" % deepest)
    return 0


def _short(name):
    """The stamp, without the word `session` in front of it twenty times.

    Read off a real report: at full length the column was truncated mid
    extension and every row began with the same eight characters, which is
    twenty per cent of the width spent saying nothing."""
    out = name
    if out.startswith("session-"):
        out = out[len("session-"):]
    if out.endswith(".log"):
        out = out[:-len(".log")]
    return out[:20]


def _what_was_happening(found, name, at):
    """The last thing the log said before a note, which is what it is about."""
    for one in found:
        if one["name"] != name:
            continue
        before = [w for a, w in one["lines"] if a <= at
                  and not w.startswith("NOTE ")]
        return before[-1].strip() if before else "right at the start"
    return ""


def self_check():
    """The reader, over a log in the shape the game writes.

    **Not a fixture invented here.** The lines below are copied from a log
    `Playtest` produced, so this fails when the game's format moves - which
    is the whole failure this is for: a summariser that quietly reports
    zeroes is worse than one that crashes."""
    import tempfile
    body = "\n".join([
        "HARVEST THE NIGHT - playtest log",
        "build   HARVEST THE NIGHT v0.1.0 (prototype, built 2026-09-28)",
        "seed    20260927",
        "began   2026-09-28 21:04",
        "",
        "  0:00  the run began",
        "  0:00  day 1 began",
        "  2:14  NOTE 1 - the tester marked this moment",
        "  3:02  they sent for the night",
        "  3:20  night 1 began",
        "  4:55  night 1 won",
        "  5:01  day 2 began",
        "  9:40  night 2 began",
        " 11:02  NOTE 2 - the tester marked this moment",
        " 12:30  the run ended: the house fell on night 2",
        " 12:30  session ended: the house fell on night 2",
        "",
    ])
    folder = tempfile.mkdtemp(prefix="htn-playtest-")
    path = os.path.join(folder, "session-20260928-210411.log")
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(body)

    one = read(path)
    bad = []
    if one["seed"] != "20260927":
        bad.append("the seed did not come back: %r" % one["seed"])
    if one["nights_reached"] != 2:
        bad.append("nights reached read as %d, not 2" % one["nights_reached"])
    if one["nights_won"] != 1:
        bad.append("nights won read as %d, not 1" % one["nights_won"])
    if one["day_one"] != 5 * 60 + 1:
        bad.append("day one read as %s, not 5:01" % clock(one["day_one"]))
    if len(one["notes"]) != 2:
        bad.append("%d notes, not 2" % len(one["notes"]))
    if one["ending"] != "the house fell on night 2":
        bad.append("the ending read as %r" % one["ending"])
    if one["seconds"] != 12 * 60 + 30:
        bad.append("the length read as %s" % clock(one["seconds"]))

    # A session with nothing closing it is the finding it is supposed to be.
    open_path = os.path.join(folder, "session-20260928-220000.log")
    with io.open(open_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("seed    7\n\n  0:00  the run began\n  1:00  day 1 began\n")
    stopped = read(open_path)
    if "just stops" not in stopped["ending"]:
        bad.append("a session with no ending read as %r" % stopped["ending"])
    if stopped["nights_reached"] != 0:
        bad.append("a session that saw no night read as %d"
                   % stopped["nights_reached"])

    print("")
    print("HARVEST THE NIGHT - playtest reader")
    print("")
    for line in bad:
        print("  FAIL  " + line)
    if bad:
        print("FAIL  the reader and the log format disagree")
        return 1
    print("OK    the reader reads what the game writes")
    return 0


def main():
    args = [a for a in sys.argv[1:] if a]
    if "--self-check" in args:
        return self_check()
    folder = args[0] if args else DEFAULT
    return report(folder)


if __name__ == "__main__":
    sys.exit(main())
