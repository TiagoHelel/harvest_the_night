# -*- coding: utf-8 -*-
"""Everything that must pass before a backlog task counts as done.

    python tools/verify.py            full run
    python tools/verify.py --fast     skips the exports
    python tools/verify.py --accept   records a determinism hash that moved
    python tools/verify.py --hashes   only the parse check and the hash guard

Exit code 0 only when every check either passed or skipped.

**This is the bootstrap version.** The repository starts as a design document
and a reference image, so on day one almost everything here has nothing to run
against. A check whose target does not exist yet prints SKIP with the reason
instead of failing, which is what lets task 0001 run this command at all. Task
0005 fills in the determinism guard and hardens the rest; the shape below is
deliberately the shape that task expects to find.
"""
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Optional mirrored project with a dedicated user:// directory for destructive
# save/input fixtures. Resource sources still come from this repository.
PROJECT_PATH = os.environ.get("GODOT_PROJECT_PATH", ".")
GODOT = os.environ.get(
    "GODOT",
    "C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
    "Godot_v4.7.2-stable_win64_console.exe")

# One guard per question. SIM asks whether the rules still do the same thing
# from the same seed; DATA asks whether the design is still the design. A port
# that changes no behaviour moves neither. A balance pass moves DATA and says
# so in the journal. A new system that consumes randomness moves SIM.
GUARDS = [
    ("sim hash", r"^SIM (-?\d+)", "determinism_sim_hash.txt"),
    ("data hash", r"^DATA (-?\d+)", "determinism_data_hash.txt"),
]

# Budget on the development machine. Every row is timed and the total is
# printed, so the budget is a measurement rather than a hope.
BUDGET_S = 300

results = []            # (name, status, detail) where status is PASS/FAIL/SKIP
guards = []             # (name, old, new, moved)
_started = time.time()
_last = time.time()


def rel(*parts):
    return os.path.join(ROOT, *parts)


def run(cmd, timeout=600):
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                           timeout=timeout, shell=False,
                           encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return 127, "executable not found: %s" % cmd[0]
    except subprocess.TimeoutExpired:
        return 124, "timed out after %ds" % timeout
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def godot(args, timeout=600):
    return run([GODOT, "--path", PROJECT_PATH, *args], timeout=timeout)


def row(name, status, detail=""):
    """One line of the report, with what it cost.

    The seconds are the time since the previous row, printed so that a check
    that starts costing minutes shows up in the output rather than in
    somebody's patience."""
    global _last
    now = time.time()
    took, _last = now - _last, now
    results.append((name, status, detail))
    print("  %-28s %-4s %5.1fs%s" % (name, status, took,
                                     ("  " + detail) if detail else ""))
    return status != "FAIL"


def check(name, ok, detail=""):
    return row(name, "PASS" if ok else "FAIL", detail)


def skip(name, why):
    return row(name, "SKIP", why)


def tail(out, n=12):
    lines = [l for l in out.strip().splitlines() if l.strip()]
    return " | ".join(lines[-n:])[:400]


# ----------------------------------------------------------------- the checks

def check_python():
    """The backlog tooling itself has to import before anything else can."""
    bad = []
    for dirpath, dirnames, filenames in os.walk(rel("tools")):
        dirnames[:] = [d for d in dirnames if d != "__pycache__"]
        for f in sorted(filenames):
            if not f.endswith(".py"):
                continue
            p = os.path.join(dirpath, f)
            try:
                # compile() rather than py_compile: nothing is written, which
                # matters because os.devnull on Windows is `nul` and py_compile
                # refuses to treat it as an output file.
                compile(open(p, encoding="utf-8").read(), p, "exec")
            except Exception as e:
                bad.append("%s: %s" % (os.path.relpath(p, ROOT), e))
    return check("python tooling", not bad, "; ".join(bad)[:300])


def check_backlog():
    code, out = run([sys.executable, "tools/gen_backlog.py", "--index-only"])
    return check("backlog index", code == 0, tail(out, 3) if code else "")


def check_art_requests():
    """The Codex art queue (implementation/backlog): unique packs, a valid
    Status on each, and every pack named by the game task that integrates
    it - so an art task can never wait for a pack that does not exist."""
    if not os.path.exists(rel("implementation", "backlog", "assets.py")):
        return skip("art requests", "no art queue yet")
    code, out = run([sys.executable, "implementation/backlog/assets.py", "check"])
    return check("art requests", code == 0, tail(out, 3))


def check_godot_present():
    if not os.path.exists(rel("project.godot")):
        return skip("godot project", "no project.godot yet - task 0001")
    if not os.path.exists(GODOT):
        return check("godot project", False,
                     "Godot not at %s - set $GODOT" % GODOT)
    code, out = godot(["--headless", "--import"], timeout=300)
    # The importer is chatty even when it succeeds; only its failures are
    # worth a line in the report.
    return check("godot import", code == 0, "" if code == 0 else tail(out))


def check_sprites():
    """The PNGs still match the maps they came from.

    Art is build output: `tools/sprite_maps.py` is the source and `sprites/` is
    what falls out of it. Committing the output means a fresh clone runs with no
    build step, and it also means somebody can open a PNG in an editor and paint
    over it - after which the palette no longer owns that sprite and nobody
    finds out until a colour change leaves one thing the old green."""
    if not os.path.isdir(rel("sprites")):
        return skip("sprites", "nothing generated yet - task 0014")
    code, out = run([sys.executable, "tools/gen_sprites.py", "--check"])
    return check("sprites", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_font():
    """The font still matches the maps it came from.

    Same argument as `check_sprites()`: `tools/font_maps.py` is the source and
    `assets/fonts/` is what falls out of it. A letter painted over in an
    editor is a letter the maps no longer own."""
    if not os.path.exists(rel("tools/gen_font.py")):
        return skip("font", "no font generator yet - task 0080")
    code, out = run([sys.executable, "tools/gen_font.py", "--check"])
    return check("font", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_raster_art():
    """Accepted raster sources, ownership, frames and generated view metadata."""
    code, out = run([sys.executable, "tools/import_art.py", "--check"])
    return check("raster art", code == 0, tail(out, 4))


def check_art_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("ART SHOWCASE:")), tail(out, 4))
    return check("art placement", code == 0, verdict)


def check_visibility_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--visibility", "--check"])
    return check("camera/ambient", code == 0, next((s for s in out.splitlines() if s.startswith("VISIBILITY SHOWCASE:")), tail(out, 4)))


def check_player_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--locomotion", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("PLAYER SHOWCASE:")), tail(out, 4))
    return check("player locomotion", code == 0, verdict)


def check_player_fhd_sources():
    """The farmer's runtime walk is the reviewed blue cycle, pixel for pixel."""
    code, out = run([sys.executable, "implementation/fhd-player/pilots/2026-10-04/"
                     "palette-variants/promote_blue_walk.py", "--check"])
    return check("FHD player sources", code == 0, tail(out, 2))


def check_player_work():
    code, out = run([sys.executable, "tools/show_art.py", "--work", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("PLAYER WORK:")), tail(out, 4))
    return check("player work", code == 0, verdict)


def check_player_reactions():
    code, out = run([sys.executable, "tools/show_art.py", "--reactions", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("PLAYER REACTIONS:")), tail(out, 4))
    return check("player reactions", code == 0, verdict)


def check_terrain_art():
    code, out = run([sys.executable, "tools/check_terrain_art.py"])
    return check("terrain sources/atlas", code == 0, tail(out, 4))


def check_terrain_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--terrain", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("TERRAIN SHOWCASE:")), tail(out, 4))
    return check("terrain lighting", code == 0, verdict)


def check_water_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--water", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("WATER SHOWCASE:")), tail(out, 4))
    return check("water edges/corners", code == 0, verdict)


def check_prop_art():
    code, out = run([sys.executable, "tools/check_prop_art.py"])
    return check("prop sources/variants", code == 0, tail(out, 4))


def check_prop_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--props", "--check"])
    verdict = next((line for line in out.splitlines() if line.startswith("PROP SHOWCASE:")), tail(out, 4))
    return check("prop overlap/gathering", code == 0, verdict)


def check_crop_art():
    code, out = run([sys.executable, "tools/check_crop_art.py"])
    return check("crop sources/moisture", code == 0, next((s for s in out.splitlines() if s.startswith("OK:")), tail(out, 4)))


def check_crop_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--crops", "--check"])
    return check("crop placement/growth", code == 0, next((s for s in out.splitlines() if s.startswith("CROP SHOWCASE:")), tail(out, 4)))


def check_house_art():
    code, out = run([sys.executable, "tools/check_house_art.py"])
    return check("house sources/windows", code == 0, tail(out, 4))


def check_house_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--house", "--check"])
    return check("house HP/lighting", code == 0, next((s for s in out.splitlines() if s.startswith("HOUSE SHOWCASE:")), tail(out, 4)))


def check_house_visit():
    code, out = run([sys.executable, "tools/show_art.py", "--house-visit", "--check"])
    return check("farm/house visit", code == 0, next((s for s in out.splitlines() if s.startswith("FARM HOUSE:")), tail(out, 4)))


def check_station_art():
    code, out = run([sys.executable, "tools/check_station_art.py"])
    return check("station sources/quarters", code == 0, tail(out, 4))


def check_station_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--stations", "--check"])
    return check("station activity/placement", code == 0, next((s for s in out.splitlines() if s.startswith("STATION SHOWCASE:")), tail(out, 4)))


def check_tower_art():
    code, out = run([sys.executable, "tools/check_tower_art.py"])
    return check("tower sources/muzzles", code == 0, tail(out, 4))


def check_tower_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--towers", "--check"])
    return check("tower firing/wrecks", code == 0, next((s for s in out.splitlines() if s.startswith("TOWER SHOWCASE:")), tail(out, 4)))


def check_barrier_art():
    code, out = run([sys.executable, "tools/check_barrier_art.py"])
    return check("barrier joins/sources", code == 0, tail(out, 4))


def check_barrier_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--barriers", "--check"])
    return check("barrier damage/mines", code == 0, next((s for s in out.splitlines() if s.startswith("BARRIER SHOWCASE:")), tail(out, 4)))


def check_enemy_art():
    code, out = run([sys.executable, "tools/check_enemy_art.py"])
    return check("enemy sources/motion", code == 0, tail(out, 4))


def check_enemy_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--enemies", "--check"])
    return check("enemy movement/attacks", code == 0, next((s for s in out.splitlines() if s.startswith("ENEMY SHOWCASE:")), tail(out, 4)))


def check_giant_art():
    code, out = run([sys.executable, "tools/check_giant_art.py"])
    return check("giant sources/motion", code == 0, tail(out, 4))


def check_giant_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--giant", "--check"])
    return check("giant/death playback", code == 0, next((s for s in out.splitlines() if s.startswith("GIANT SHOWCASE:")), tail(out, 4)))


def check_effect_art():
    code, out = run([sys.executable, "tools/check_effect_art.py"])
    return check("effect sources/origins", code == 0, tail(out, 4))


def check_ui_art():
    code, out = run([sys.executable, "tools/check_ui_art.py"])
    return check("UI sources/native icons", code == 0, tail(out, 4))


def check_ui_art_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--ui", "--check"])
    return check("UI display/states", code == 0, next((s for s in out.splitlines() if s.startswith("UI ART SHOWCASE:")), tail(out, 4)))


def check_atmosphere_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--atmosphere", "--check"])
    return check("atmosphere/emission", code == 0, next((s for s in out.splitlines() if s.startswith("ATMOSPHERE SHOWCASE:")), tail(out, 4)))


def check_effect_showcase():
    code, out = run([sys.executable, "tools/show_art.py", "--effects", "--check"])
    return check("effect contacts/a11y", code == 0, next((s for s in out.splitlines() if s.startswith("EFFECT SHOWCASE:")), tail(out, 4)))


def check_logo():
    """The logo still matches the letters it was composed from.

    It is the game's own type at four times size, so a change to the font is
    a change to the wordmark - which is the point, and which only stays true
    if regenerating is checked."""
    if not os.path.exists(rel("tools/gen_logo.py")):
        return skip("logo", "no logo generator yet - task 0091")
    code, out = run([sys.executable, "tools/gen_logo.py", "--check"])
    return check("logo", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_sfx():
    """Every sound still matches the recipe it came from.

    Same argument as `check_sprites()` and `check_font()`: `tools/gen_sfx.py`
    is the source and `assets/sfx/` is what falls out of it. A WAV somebody
    dropped in from elsewhere is a sound nobody can regenerate, change or
    balance - and the whole point of synthesising them is that they are all
    one edit away."""
    if not os.path.exists(rel("tools/gen_sfx.py")):
        return skip("sfx", "no sound generator yet - task 0084")
    code, out = run([sys.executable, "tools/gen_sfx.py", "--check"])
    return check("sfx", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_perf():
    """The worst case, timed, against a budget and against yesterday.

    Slower than most rows because it is a measurement rather than a
    comparison - it plays night ten and times every system on it. Worth the
    seconds: a performance regression found by a player is a performance
    regression nobody can bisect."""
    if not os.path.exists(rel("tools", "perf.py")):
        return skip("perf", "no benchmark yet - task 0102")
    code, out = run([sys.executable, "tools/perf.py"])
    last = [l for l in out.strip().splitlines() if l.strip()]
    return check("perf", code == 0,
                 last[-1].strip() if last else "")


def check_playtest():
    """The log reader, against a log in the shape the game writes.

    Cheap - no Godot, no export - and it guards the one thing that rots
    here: a summariser reading a format the game stopped writing reports
    zeroes, and zeroes read like a finding."""
    if not os.path.exists(rel("tools", "playtest.py")):
        return skip("playtest", "no playtest build yet - task 0105")
    code, out = run([sys.executable, "tools/playtest.py", "--self-check"])
    last = [l for l in out.strip().splitlines() if l.strip()]
    return check("playtest", code == 0, last[-1].strip() if last else "")


def check_store():
    """The store copy against the design document, and the set's inputs.

    Not the pictures: making those means running the game five times and is
    a minute and a half, which is `python tools/gen_marketing.py`. What rots
    here is the words - the pitch is the game's own description of itself
    and it lives in `design.md`, and a page that drifted from it would be a
    page describing a game somebody decided not to make."""
    if not os.path.exists(rel("tools", "gen_marketing.py")):
        return skip("store", "no store assets yet - task 0107")
    code, out = run([sys.executable, "tools/gen_marketing.py", "--check"])
    last = [l for l in out.strip().splitlines() if l.strip()]
    return check("store", code == 0, last[-1].strip() if last else "")


def check_devlog():
    """The devlog page, regenerated from the journal.

    Not the clip: capturing thirty seconds of the game is a minute and a
    half, and that is `python tools/devlog.py`. What this catches is the
    page falling behind the journal it comes out of - and, because the tool
    counts the journal's entries against the backlog's finished tasks, a
    parser that has stopped recognising how somebody writes an entry."""
    if not os.path.exists(rel("tools", "devlog.py")):
        return skip("devlog", "no devlog yet - task 0108")
    code, out = run([sys.executable, "tools/devlog.py", "--check"])
    said = [l for l in out.splitlines() if l.strip().startswith("journal")]
    if code != 0:
        return check("devlog", False, tail(out, 3))
    return check("devlog", True, said[-1].strip() if said else "")


def check_icon():
    """One 16x16 drawing, at every size a platform asks for.

    The done-when is that the sixteen is recognisable, which is answered by
    the sixteen being the drawing: every other size is whole-number scaled
    from it, so there is no resampling to argue about and one file to change
    when the mark changes."""
    if not os.path.exists(rel("tools/gen_icon.py")):
        return skip("icon", "no icon generator yet - task 0099")
    code, out = run([sys.executable, "tools/gen_icon.py", "--check"])
    return check("icon", code == 0,
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_strings():
    """Every word the player reads, against the code and against the font.

    Four questions no amount of reading answers: a key the code asks for and
    the table has not got, a row nothing uses, a language with a cell missing,
    and - the one that matters most here - a Portuguese line wider than the
    control that draws it. `tools/i18n_check.py` measures that in the game's
    own glyph widths."""
    if not os.path.exists(rel("tools/i18n_check.py")):
        return skip("strings", "no translation table yet - task 0097")
    code, out = run([sys.executable, "tools/i18n_check.py"])
    return check("strings", code == 0,
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_music():
    """The two pieces still match the recipes they came from.

    A slower row than the others - it renders three minutes of audio to
    compare it - and worth it for the same reason as `check_sfx()`: a WAV
    nobody can regenerate is a WAV nobody can change."""
    if not os.path.exists(rel("tools/gen_music.py")):
        return skip("music", "no music generator yet - task 0086")
    code, out = run([sys.executable, "tools/gen_music.py", "--check"])
    return check("music", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_ambience():
    """The bed still matches the recipes it came from.

    Third generator, third folder, third bus - `gen_sfx` owns `assets/sfx`,
    `gen_music` owns `assets/music`, and this owns `assets/ambience`."""
    if not os.path.exists(rel("tools/gen_ambience.py")):
        return skip("ambience", "no ambience generator yet - task 0087")
    code, out = run([sys.executable, "tools/gen_ambience.py", "--check"])
    return check("ambience", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_player_art():
    """The cut frames still match the sheet they came from.

    Same argument as `check_sprites()`, one step further out: the sheet in
    `docs/` is the source and `sprites/actors/` is what falls out of it. Task
    0073 asks that re-running the cutting tool produce byte-identical PNGs,
    and this is where that is a fact rather than a hope.

    It **skips without Pillow** rather than failing. The cut PNGs are
    committed, so the game runs and the suite passes on a machine that has
    never installed it; only re-cutting needs it."""
    if not os.path.exists(rel("tools/cut_sheet.py")):
        return skip("player art", "no cutting tool yet - task 0073")
    try:
        import PIL                                   # noqa: F401
    except ImportError:
        return skip("player art", "needs Pillow to re-cut: "
                    "python -m pip install pillow")
    code, out = run([sys.executable, "tools/cut_sheet.py", "--check"])
    return check("player art", code == 0, tail(out, 6) if code else
                 out.strip().splitlines()[-1].strip() if out.strip() else "")


def check_core_is_pure():
    """src/core/ is node-free, clock-free and unseeded-random-free.

    This is the house rule the whole determinism guarantee rests on, so it is
    checked rather than remembered. A node in there would mean the rules could
    not run headless; a clock read or a bare randi() would mean two runs of the
    same seed diverge, and the hash guard would start failing for reasons
    nobody could find."""
    banned = [
        (re.compile(r"^\s*extends\s+Node"), "extends Node"),
        (re.compile(r"(?<![\w.])randi\s*\("), "randi()"),
        (re.compile(r"(?<![\w.])randf\s*\("), "randf()"),
        (re.compile(r"(?<![\w.])randi_range\s*\("), "randi_range()"),
        (re.compile(r"(?<![\w.])randf_range\s*\("), "randf_range()"),
        (re.compile(r"Time\."), "Time."),
        (re.compile(r"RandomNumberGenerator"), "RandomNumberGenerator"),
        (re.compile(r"OS\.")," OS."),
    ]
    bad = []
    core = rel("src", "core")
    if not os.path.isdir(core):
        return skip("core is pure", "no src/core/ yet")
    for f in sorted(os.listdir(core)):
        if not f.endswith(".gd"):
            continue
        for n, line in enumerate(open(os.path.join(core, f),
                                     encoding="utf-8"), 1):
            # A doc comment explaining the ban is not a violation of it.
            if line.lstrip().startswith("#"):
                continue
            for pattern, what in banned:
                if pattern.search(line):
                    bad.append("%s:%d %s" % (f, n, what))
    return check("core is pure", not bad, "; ".join(bad)[:300])


def check_scripts_parse():
    """Every .gd in the project, parsed, in one Godot process.

    `--import` does NOT do this: it imports resources and exits 0 with a script
    full of parse errors sitting next to it - measured, not assumed. Catching a
    parse error here means the tool scripts below never get the chance to
    half-run, which is the failure mode that hangs a loop.

    **This used to be `--check-only --script` once per file**, which is one
    whole Godot process per script: ninety-eight of them, ninety-five seconds,
    almost none of it compiling anything. `src/tools/parse_check.gd` does the
    same work in one process in eight, and task 0106 checked it against three
    planted errors - a syntax error, a bad declaration and a type error -
    before the loop was taken out. That is eighty-seven seconds off a suite
    that was twenty-two over its own budget."""
    if not os.path.exists(rel("project.godot")) or not os.path.exists(GODOT):
        return skip("script parse", "no project yet")
    if not os.path.exists(rel("src", "tools", "parse_check.gd")):
        return skip("script parse", "no parse check yet - task 0106")
    code, out = godot(["--headless", "--script",
                       "res://src/tools/parse_check.gd"], timeout=180)
    verdict = next((l for l in out.splitlines()
                    if l.startswith("PARSED ")), "")
    if code == 0:
        return check("script parse", True, verdict.strip())
    # Only the named files: the tool also prints a sentence explaining that
    # the list is longer than the mistake, and that sentence contains the
    # same words the filter is looking for.
    bad = [l.strip() for l in out.splitlines()
           if l.strip().startswith("res://")]
    return check("script parse", False,
                 "; ".join(bad)[:400] if bad else tail(out, 4))


# A Godot tool script that errors before its final quit() does not exit: the
# SceneTree keeps running with nothing left to do. Unattended, that hangs the
# backlog loop instead of failing it, which is strictly worse than a red line.
# Every script run is bounded, and the timeout reads as a FAIL.
SCRIPT_TIMEOUT_S = 120


def check_script(name, script, missing_note, args=(), pattern=None):
    """Run a Godot tool script, or skip when the backlog has not written it."""
    if not os.path.exists(rel("project.godot")):
        return skip(name, "no project yet")
    path = rel(*script.split("/"))
    if not os.path.exists(path):
        return skip(name, missing_note)
    code, out = godot(["--headless", "--script", "res://" + script,
                       *(["--", *args] if args else [])],
                      timeout=SCRIPT_TIMEOUT_S)
    if code == 124:
        return check(name, False, "hung - it never reached quit(). A script "
                                  "error leaves the SceneTree running.")
    if pattern:
        m = re.search(pattern, out)
        detail = m.group(0) if m else tail(out, 4)
        if code != 0:
            faults = [line.strip() for line in out.splitlines() if line.lstrip().startswith("FAIL ")]
            if faults:
                detail += "; " + "; ".join(faults[-3:])
    else:
        detail = "" if code == 0 else tail(out)
    return check(name, code == 0, detail)


def check_determinism(accept):
    """The hash guards.

    Each baseline is a file rather than a comment so that moving it is a diff
    somebody reviews, and the failure names the command that accepts it: a
    guard whose fix nobody can remember is a guard people switch off.

    One run of the scenario produces every number, so adding a guard costs a
    regex and a filename rather than another Godot launch."""
    script = "src/tools/determinism.gd"
    if not os.path.exists(rel("project.godot")):
        for name, _, _ in GUARDS:
            skip(name, "no project yet")
        return True
    if not os.path.exists(rel(*script.split("/"))):
        for name, _, _ in GUARDS:
            skip(name, "no determinism.gd yet - task 0005")
        return True

    code, out = godot(["--headless", "--script", "res://" + script],
                      timeout=SCRIPT_TIMEOUT_S)
    if code == 124:
        for name, _, _ in GUARDS:
            check(name, False, "the scenario hung - it never reached quit()")
        return False
    if code != 0:
        for name, _, _ in GUARDS:
            check(name, False, tail(out, 4))
        return False

    ok = True
    for name, pattern, filename in GUARDS:
        ok = guard_one(name, out, pattern, rel("tools", filename), accept) and ok
    return ok


def guard_one(name, out, pattern, path, accept):
    m = re.search(pattern, out, re.M)
    current = m.group(1) if m else ""
    expected = ""
    if os.path.exists(path):
        expected = open(path, encoding="utf-8").read().strip()
    moved = bool(expected) and bool(current) and current != expected
    if accept and current:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(current + "\n")
    guards.append((name, expected, current, moved))

    if not current:
        return check(name, False, "the scenario printed no number for it")
    if not expected:
        return check(name, bool(accept),
                     "recorded %s, the first baseline" % current if accept
                     else "no baseline yet: python tools/verify.py --accept")
    if accept:
        return check(name, True,
                     "recorded %s (was %s)" % (current, expected) if moved
                     else "%s unchanged" % current)
    return check(name, current == expected,
                 "%s unchanged" % current if current == expected
                 else "%s, expected %s - something moved. If on purpose: "
                      "python tools/verify.py --accept" % (current, expected))


def check_exports():
    if not os.path.exists(rel("export_presets.cfg")):
        return skip("exports", "no export_presets.cfg yet - task 0001")
    if not os.path.exists(GODOT):
        return skip("exports", "Godot not on this machine")
    presets = open(rel("export_presets.cfg"), encoding="utf-8").read()
    # Each preset names itself and says where it writes; take both from the
    # file rather than inventing a path, so the check exports exactly what a
    # release would.
    pairs = re.findall(r'^name="([^"]+)"[\s\S]*?^export_path="([^"]*)"',
                       presets, re.M)
    if not pairs:
        return skip("exports", "no presets configured")
    if not export_templates_installed():
        return skip("exports", "no export templates for this Godot - install "
                               "them from Editor > Manage Export Templates")
    bad = []
    for name, out_path in pairs:
        if not out_path:
            bad.append("%s: no export_path" % name)
            continue
        dest = rel(*out_path.split("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        # Release checks use the real project config, never the QA user folder.
        code, out = run([GODOT, "--path", ROOT, "--headless", "--export-release", name, dest],
                        timeout=900)
        if code != 0 or not os.path.exists(dest):
            bad.append("%s: %s" % (name, tail(out, 3)))
    return check("exports", not bad, "; ".join(bad)[:300])


def export_templates_installed():
    """Templates are a ~1GB download the engine does not ship with.

    Without them every export fails with the same unhelpful error, so the
    check says which button to press instead of pretending the build broke."""
    base = os.path.join(os.environ.get("APPDATA", ""), "Godot",
                        "export_templates")
    if not os.path.isdir(base):
        return False
    return any(os.scandir(base))


# ------------------------------------------------------------------- the run

def main():
    accept = "--accept" in sys.argv
    fast = "--fast" in sys.argv
    hashes_only = "--hashes" in sys.argv

    print("")
    print("HARVEST THE NIGHT - verify")
    print("  godot: %s" % ("found" if os.path.exists(GODOT) else "MISSING " + GODOT))
    print("")

    check_python()
    check_backlog()
    check_art_requests()
    check_godot_present()
    check_scripts_parse()
    check_core_is_pure()
    check_sprites()
    check_player_art()
    check_player_fhd_sources()
    check_raster_art()
    check_art_showcase()
    check_visibility_showcase()
    check_player_showcase()
    check_player_work()
    check_player_reactions()
    check_terrain_art()
    check_terrain_showcase()
    check_water_showcase()
    check_prop_art()
    check_prop_showcase()
    check_crop_art()
    check_crop_showcase()
    check_house_art()
    check_house_showcase()
    check_house_visit()
    check_station_art()
    check_station_showcase()
    check_tower_art()
    check_tower_showcase()
    check_barrier_art()
    check_barrier_showcase()
    check_enemy_art()
    check_enemy_showcase()
    check_giant_art()
    check_giant_showcase()
    check_effect_art()
    check_effect_showcase()
    check_ui_art()
    check_ui_art_showcase()
    check_atmosphere_showcase()
    check_font()
    check_logo()
    check_sfx()
    check_perf()
    check_icon()
    check_playtest()
    check_store()
    check_devlog()
    check_strings()
    check_music()
    check_ambience()

    if not hashes_only:
        check_script("headless_check", "src/tools/headless_check.gd",
                     "not written yet - task 0004",
                     pattern=r"\d+ asserts?, \d+ failed")
    check_determinism(accept)
    if not hashes_only:
        check_script("input_check", "src/tools/input_check.gd",
                     "not written yet - task 0011",
                     pattern=r"\d+ cases?, \d+ failed")
        if fast:
            skip("exports", "--fast")
        else:
            check_exports()

    failed = [r for r in results if r[1] == "FAIL"]
    skipped = [r for r in results if r[1] == "SKIP"]
    total = time.time() - _started

    print("")
    if guards and accept:
        for name, old, new, moved in guards:
            if moved:
                print("  guard %s moved: %s -> %s" % (name, old, new))
                print("  write both numbers in implementation/PROGRESS.md.")
    print("  %d passed, %d skipped, %d failed in %.0fs%s" % (
        len(results) - len(failed) - len(skipped), len(skipped), len(failed),
        total, "  (OVER BUDGET)" if total > BUDGET_S else ""))
    print("")
    print("FAIL" if failed else "PASS")
    for name, _, detail in failed:
        print("  %s: %s" % (name, detail))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
