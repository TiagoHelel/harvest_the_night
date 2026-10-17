# -*- coding: utf-8 -*-
"""What a folder of playtest logs actually says.

    python tools/playtest.py                  the logs on this machine
    python tools/playtest.py <folder>         a folder of them somebody sent
    python tools/playtest.py --self-check     that the reader still reads

A session log is written by a playtest build - `Playtest` in
`src/app/playtest.gd` - and is a plain text file a tester can read before
they decide to send it. This reads a folder of them and answers 1.0's
questions (task 0295), not the MVP's ten nights'.

## The questions

**Did they get to the first night?** The whole premise is that the farm turns
into a tower defence; somebody who quit on the first day never saw the game.

**How long was Spring 1?** The plan wants eight to ten real minutes for the
day and three to five for its night. The median, so one tester who went to
make a cup of tea does not move the answer.

**Bed or pass-out, night by night.** Going to bed is the night's switch
(0127), and passing out at 02:00 costs the build step (0128). A tester who
never finds the bed is a finding.

**How long did the build step run?** It waits for START (0136), so its
length is the tester's own.

**How far into the year, and how many nights lost a season?** The plan's
target is two to four lost before winter; a lost night is a setback inside
the run, not its end.

**Where did the runs end, and where are the notes?** Every `F1` is a tester
saying "here"; a pile of them in the same minute of the same night is the
most useful thing in the folder.

## It reads what the game writes, and nothing else

The log's own lines, in the shape `  m:ss  what happened`. If the format
moves, this stops recognising lines rather than silently reporting zeroes,
which is what `--self-check` is for: it reads a 1.0 log written out here and
fails if any question comes back empty.
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
DAY = re.compile(r"^(Spring|Summer|Autumn|Winter) (\d+)(?: of year (\d+))? began \(date (\d+)\)$")
BED = re.compile(r"^went to bed at (\d\d:\d\d)$")
START = re.compile(r"^START after (\d+):(\d\d) of building$")
NIGHT = re.compile(r"^night (\d+) (began|won|lost)")

SEASONS = ["spring", "summer", "autumn", "winter"]
SEASON_DAYS = 14

## The plan's numbers the answers are read against.
SPRING_1_DAY = (8 * 60, 10 * 60)
SPRING_1_NIGHT = (3 * 60, 5 * 60)
LOST_BEFORE_WINTER = (2, 4)


def season_of(date):
    """The season a calendar date falls in, any year."""
    return SEASONS[((max(date, 1) - 1) % (SEASON_DAYS * 4)) // SEASON_DAYS]


def read(path):
    """One session as a dictionary of what happened in it."""
    with io.open(path, encoding="utf-8", errors="replace") as f:
        text = f.read()

    out = {"path": path, "name": os.path.basename(path), "build": "",
           "seed": "", "began": "", "lines": [], "notes": [],
           "nights_won": 0, "nights_reached": 0, "furthest": 0,
           "ending": "", "built": "", "seconds": 0,
           "spring_1_day": None, "spring_1_night": None,
           "bedtimes": [], "builds": [], "lost": [], "got_away": []}
    began_at = {}
    spring_1_at = None
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

        day = DAY.match(what)
        bed = BED.match(what)
        start = START.match(what)
        night = NIGHT.match(what)
        if what.startswith("NOTE "):
            out["notes"].append((at, what))
        elif day:
            date = int(day.group(4))
            out["furthest"] = max(out["furthest"], date)
            if date == 1 and spring_1_at is None:
                spring_1_at = at
        elif bed:
            out["bedtimes"].append(bed.group(1))
            if spring_1_at is not None and out["spring_1_day"] is None:
                out["spring_1_day"] = at - spring_1_at
        elif what == "passed out at 02:00":
            out["bedtimes"].append("passed out")
            if spring_1_at is not None and out["spring_1_day"] is None:
                out["spring_1_day"] = at - spring_1_at
        elif start:
            out["builds"].append(int(start.group(1)) * 60 + int(start.group(2)))
        elif night:
            n = int(night.group(1))
            if night.group(2) == "began":
                out["nights_reached"] = max(out["nights_reached"], n)
                began_at.setdefault(n, at)
            else:
                if night.group(2) == "won":
                    out["nights_won"] += 1
                else:
                    out["lost"].append(n)
                if n == 1 and out["spring_1_night"] is None and 1 in began_at:
                    out["spring_1_night"] = at - began_at[1]
        elif "the boss got away" in what:
            out["got_away"].append(what)
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


def against(value, band):
    """Where a number sits against the plan's band."""
    if value is None:
        return ""
    if value < band[0]:
        return "under the plan's %s-%s" % (clock(band[0]), clock(band[1]))
    if value > band[1]:
        return "over the plan's %s-%s" % (clock(band[0]), clock(band[1]))
    return "inside the plan's %s-%s" % (clock(band[0]), clock(band[1]))


def answers(found):
    """Every question's answer as text, in order - empty when it has none."""
    out = []
    reached = [s for s in found if s["nights_reached"] >= 1]
    out.append(("DID THEY GET TO THE FIRST NIGHT",
                ["%d of %d reached night 1" % (len(reached), len(found))]
                + ["  %s stopped in the day, after %s" % (s["name"], clock(s["seconds"]))
                   for s in found if s["nights_reached"] < 1]))

    days = [s["spring_1_day"] for s in found if s["spring_1_day"] is not None]
    nights = [s["spring_1_night"] for s in found if s["spring_1_night"] is not None]
    lines = []
    if days:
        lines.append("the day: median %s, from %s to %s, over %d - %s"
                     % (clock(median(days)), clock(min(days)), clock(max(days)),
                        len(days), against(median(days), SPRING_1_DAY)))
    if nights:
        lines.append("the night: median %s, from %s to %s, over %d - %s"
                     % (clock(median(nights)), clock(min(nights)), clock(max(nights)),
                        len(nights), against(median(nights), SPRING_1_NIGHT)))
    out.append(("HOW LONG WAS SPRING 1, IN REAL MINUTES", lines))

    lines = []
    for one in found:
        if one["bedtimes"]:
            beds = len([b for b in one["bedtimes"] if b != "passed out"])
            lines.append("%s: %d to bed, %d passed out - %s"
                         % (_short(one["name"]), beds, len(one["bedtimes"]) - beds,
                            ", ".join(one["bedtimes"][:10])
                            + (" ..." if len(one["bedtimes"]) > 10 else "")))
    out.append(("BED OR PASS-OUT, NIGHT BY NIGHT", lines))

    builds = [b for s in found for b in s["builds"]]
    out.append(("HOW LONG THE BUILD STEP RAN",
                ["median %s, from %s to %s, over %d nights"
                 % (clock(median(builds)), clock(min(builds)), clock(max(builds)),
                    len(builds))] if builds else []))

    lines = []
    for one in found:
        if one["furthest"] < 1:
            continue
        lost = dict((s, 0) for s in SEASONS)
        for n in one["lost"]:
            lost[season_of(n)] += 1
        before = lost["spring"] + lost["summer"] + lost["autumn"]
        lines.append("%s: reached date %d (%s); lost %s - %d before winter, %s"
                     % (_short(one["name"]), one["furthest"], season_of(one["furthest"]),
                        ", ".join("%s %d" % (s, lost[s]) for s in SEASONS), before,
                        "inside the plan's 2-4" if LOST_BEFORE_WINTER[0] <= before
                        <= LOST_BEFORE_WINTER[1] else "the plan wants 2-4"))
        for what in one["got_away"]:
            lines.append("  %s" % what)
    out.append(("HOW FAR INTO THE YEAR, AND NIGHTS LOST A SEASON", lines))

    endings = {}
    for one in found:
        endings[one["ending"]] = endings.get(one["ending"], 0) + 1
    out.append(("WHERE DID THE RUNS END",
                ["%2d  %s" % (endings[why], why)
                 for why in sorted(endings, key=lambda k: (-endings[k], k))]))

    notes = []
    for one in found:
        for at, what in one["notes"]:
            notes.append((at, one["name"], what))
    notes.sort()
    lines = ["%6s  %-20s %s" % (clock(at), _short(name), _what_was_happening(found, name, at))
             for at, name, what in notes]
    if not lines:
        lines = ["none left. Either nothing went wrong or nobody knew about the key."]
    out.append(("WHERE ARE THE NOTES", lines))
    return out


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
          % ("session", "for", "date", "notes", "ended"))
    for one in found:
        print("  %-20s %6s %6d %6d  %s"
              % (_short(one["name"]), clock(one["seconds"]),
                 one["furthest"], len(one["notes"]), one["ending"][:36]))
    for question, lines in answers(found):
        print("")
        print("  " + question)
        for line in lines or ["nothing in these logs answers it"]:
            print("    " + line)
    print("")
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


## **A 1.0 log, in the shape `Playtest` writes** (task 0295): its lines are
## the ones `_task_0295_playtest_log` asserts the game writes, so this fails
## when the game's format moves - a summariser that quietly reports zeroes
## is worse than one that crashes.
SAMPLE = "\n".join([
    "HARVEST THE NIGHT - playtest log",
    "build   HARVEST THE NIGHT v0.1.0 (prototype, built 2026-10-16)",
    "seed    20261016",
    "began   2026-10-16 21:04",
    "",
    "  0:00  the run began",
    "  0:00  Spring 1 began (date 1)",
    "  0:00    the day is theirs",
    "  4:12  NOTE 1 - the tester marked this moment",
    "  9:02  went to bed at 21:40",
    "  9:50  START after 0:48 of building",
    "  9:50  night 1 began",
    "  9:50    wave 1 of 3 - 4 walker",
    " 13:31    dawn - 0 walked off",
    " 13:31  night 1 won at dawn",
    " 13:31    the report is on the screen",
    " 13:40  Spring 1 ended - built gun_tower x1",
    " 13:40  Spring 2 began (date 2)",
    " 21:10  passed out at 02:00",
    " 21:40  START after 0:30 of building",
    " 21:40  night 2 began",
    " 23:02  NOTE 2 - the tester marked this moment",
    " 24:15  night 2 lost - the house fell",
    " 24:20  Spring 2 ended - built gun_tower x1, wall x4",
    " 24:20  Spring 3 began (date 3)",
    " 30:00  the run ended: the player left from the pause menu",
    " 30:00    reached night 3 - Spring 3, 3 days lived, tick 99000",
    " 30:00  session ended: the player left from the pause menu",
    "",
])


def self_check():
    """The reader, over a 1.0 log in the shape the game writes."""
    import tempfile
    folder = tempfile.mkdtemp(prefix="htn-playtest-")
    path = os.path.join(folder, "session-20261016-210411.log")
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(SAMPLE)

    one = read(path)
    bad = []
    if one["seed"] != "20261016":
        bad.append("the seed did not come back: %r" % one["seed"])
    if one["nights_reached"] != 2:
        bad.append("nights reached read as %d, not 2" % one["nights_reached"])
    if one["furthest"] != 3:
        bad.append("the furthest date read as %d, not 3" % one["furthest"])
    if one["spring_1_day"] != 9 * 60 + 2:
        bad.append("Spring 1's day read as %s, not 9:02" % clock(one["spring_1_day"]))
    if one["spring_1_night"] != 3 * 60 + 41:
        bad.append("Spring 1's night read as %s, not 3:41" % clock(one["spring_1_night"]))
    if one["bedtimes"] != ["21:40", "passed out"]:
        bad.append("the bedtimes read as %r" % one["bedtimes"])
    if one["builds"] != [48, 30]:
        bad.append("the build steps read as %r" % one["builds"])
    if one["lost"] != [2]:
        bad.append("the lost nights read as %r" % one["lost"])
    if len(one["notes"]) != 2:
        bad.append("%d notes, not 2" % len(one["notes"]))
    if one["ending"] != "the player left from the pause menu":
        bad.append("the ending read as %r" % one["ending"])
    empty = [q for q, lines in answers([one]) if not lines]
    if empty:
        bad.append("no answer to: %s" % ", ".join(empty))

    # A session with nothing closing it is the finding it is supposed to be.
    open_path = os.path.join(folder, "session-20261016-220000.log")
    with io.open(open_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("seed    7\n\n  0:00  the run began\n  1:00  Spring 1 began (date 1)\n")
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
    print("OK    the reader answers 1.0's questions from what the game writes")
    return 0


def main():
    args = [a for a in sys.argv[1:] if a]
    if "--self-check" in args:
        return self_check()
    folder = args[0] if args else DEFAULT
    return report(folder)


if __name__ == "__main__":
    sys.exit(main())
