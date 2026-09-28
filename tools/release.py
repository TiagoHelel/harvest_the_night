# -*- coding: utf-8 -*-
"""Build both of them, from one command.

    python tools/release.py              verify, stamp, export, measure
    python tools/release.py --skip-verify   for iterating on the packaging
    python tools/release.py --check      just the parts that need no export

Writes `build/windows/` and `build/web/`, and prints the one number that
decides whether a stranger waits for the Web build: what it weighs on the
wire, gzipped.

## It verifies first

A release built off a red suite is not a release, it is a mistake with a
filename. `tools/verify.py` runs first and nothing is exported if it fails.

## The pack is where this goes wrong

The task says so in as many words, and it is right: an export filter is a
string in a config file that nobody reads, and the day somebody adds a folder
it quietly ships. So the exclusions are **checked twice** - once against the
preset before exporting, and once against the pack that came out, by reading
the file names back out of it. The second one is the one that cannot be
fooled.

## The wire size, not the file size

A Web build is three files and a stranger downloads all of them. What matters
is what crosses the wire, which is the gzipped total, because every web server
worth the name serves them compressed. `WIRE_BUDGET` is what this game may
weigh, and going over it fails the build rather than printing a warning
somebody scrolls past.
"""
import gzip
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

GODOT = os.environ.get("GODOT", os.path.join(
    os.path.expanduser("~"), "Documents", "Godot",
    "Godot_v4.7.2-stable_win64_console.exe"))

PRESETS = os.path.join(ROOT, "export_presets.cfg")
BUILD = os.path.join(ROOT, "build")
BUILD_INFO = os.path.join(ROOT, "src", "core", "build_info.gd")

## What the Web build may weigh on the wire, gzipped, in bytes.
##
## **Thirteen megabytes, and it was measured before it was picked.** The first
## number here was eight, chosen because ten seconds of a typical connection
## is about that - and the first build came out at twelve. Nine and a half of
## those twelve are `index.wasm`, which is the Godot engine and not this game:
## a stock 4.7 web export cannot be smaller without building the engine from
## source with modules stripped, which is not a thing this backlog is doing.
##
## So the budget is the floor plus room for the game to grow, and it is
## honest about which is which. The number that actually catches a mistake in
## this repository is `PACK_BUDGET` below.
WIRE_BUDGET = 13 * 1024 * 1024

## What the game's own half may weigh, gzipped.
##
## **This is the one with teeth.** `index.pck` is everything this repository
## puts in the build - every sprite, sound, piece of music and script - and it
## is the only part anybody here can make worse. It came out at 2.31 MB, so
## three and a half is half again as much room as it needs and a long way
## under the day somebody checks in a forty megabyte WAV.
PACK_BUDGET = 3.5 * 1024 * 1024

## What must never be in the pack, whatever the filter says.
##
## These are the four the task names, and the reason it names them: they are
## the four that are large, are checked into the repository beside the game,
## and would each ship without anybody noticing.
FORBIDDEN = ["implementation/", "tools/", "docs/", "build/"]


def run(args, timeout=1800):
    try:
        done = subprocess.run(args, cwd=ROOT, capture_output=True, text=True,
                              timeout=timeout)
    except subprocess.TimeoutExpired:
        return 1, "timed out after %ds" % timeout
    return done.returncode, (done.stdout or "") + (done.stderr or "")


def templates_installed():
    base = os.path.join(os.environ.get("APPDATA", ""), "Godot",
                        "export_templates")
    return os.path.isdir(base) and any(os.scandir(base))


def presets():
    """[(name, platform, export_path, exclude_filter)] out of the config."""
    text = io.open(PRESETS, encoding="utf-8").read()
    out = []
    for block in text.split("[preset.")[1:]:
        if block.lstrip().startswith("0.options") or ".options" in \
                block.split("]")[0]:
            continue
        name = re.search(r'^name="([^"]*)"', block, re.M)
        platform = re.search(r'^platform="([^"]*)"', block, re.M)
        path = re.search(r'^export_path="([^"]*)"', block, re.M)
        exclude = re.search(r'^exclude_filter="([^"]*)"', block, re.M)
        if name and path:
            out.append((name.group(1),
                        platform.group(1) if platform else "",
                        path.group(1),
                        exclude.group(1) if exclude else ""))
    return out


def filters_are_sane():
    """Every preset excludes the four folders, before anything is exported.

    The cheap half of the check: it reads the config rather than the pack, so
    it runs with no export templates installed and catches the mistake at the
    moment somebody makes it.
    """
    bad = []
    for name, _platform, _path, exclude in presets():
        parts = [p.strip() for p in exclude.split(",")]
        for folder in FORBIDDEN:
            wanted = folder.rstrip("/") + "/*"
            if wanted not in parts:
                bad.append("%s does not exclude %s" % (name, wanted))
    return bad


def stamp(when):
    """Write the build date into `BuildInfo`, which the title screen shows."""
    text = io.open(BUILD_INFO, encoding="utf-8").read()
    fresh = re.sub(r'const BUILT := "[^"]*"', 'const BUILT := "%s"' % when,
                   text)
    if fresh == text:
        return False
    io.open(BUILD_INFO, "w", encoding="utf-8", newline="\n").write(fresh)
    return True


def today():
    import datetime
    return datetime.date.today().isoformat()


def pack_entries(path):
    """Every resource inside a `.pck`, as {path: md5}, out of its own table.

    Godot's pack format, version 4 - `GDPC`, the pack version, the three
    engine numbers, flags, the offset the files start at and **the offset the
    directory is at**, which since 4.4 is near the end of the file rather than
    after the header. Then a count and one entry per file: a length, a path,
    an offset, a size, an MD5 and a set of flags.

    The MD5 is what makes "the two builds are the same game" answerable
    without unpacking either of them.

    Getting the offsets wrong reads a count of nought, which is a pack that
    looks empty - and an empty pack passes every check about what is not in
    it. That is what happened on the first run of this tool, and it is why
    `pack_is_clean` refuses a pack with nothing in it.
    """
    import struct
    data = io.open(path, "rb").read()
    if data[:4] != b"GDPC":
        return None
    version, = struct.unpack_from("<I", data, 4)
    if version < 4:
        return None
    at, = struct.unpack_from("<Q", data, 32)   # where the directory is
    if at <= 0 or at >= len(data):
        return None
    count, = struct.unpack_from("<I", data, at)
    at += 4
    out = {}
    for _ in range(count):
        length, = struct.unpack_from("<I", data, at)
        at += 4
        name = data[at:at + length].rstrip(b"\x00").decode("utf-8")
        at += length + 16                      # offset and size
        out[name] = data[at:at + 16].hex()
        at += 16 + 4                           # md5, then per-file flags
    return out


def pack_names(path):
    entries = pack_entries(path)
    return None if entries is None else sorted(entries)


def pack_is_clean(path):
    """The half that cannot be fooled: what is actually in the pack."""
    names = pack_names(path)
    if names is None:
        return ["%s is not a pack this tool can read" % path]
    if not names:
        return ["%s reads as empty, which is this tool being wrong" % path]
    bad = []
    for name in names:
        short = name.replace("res://", "")
        for folder in FORBIDDEN:
            if short.startswith(folder):
                bad.append("%s shipped" % name)
        if short.endswith(".py") or short.endswith(".md"):
            bad.append("%s shipped" % name)
    return sorted(set(bad))[:10]


def wire_size(folder):
    """What the Web build weighs gzipped, and what each part of it weighs."""
    parts = []
    total = 0
    for name in sorted(os.listdir(folder)):
        full = os.path.join(folder, name)
        if not os.path.isfile(full):
            continue
        raw = io.open(full, "rb").read()
        packed = len(gzip.compress(raw, 9))
        parts.append((name, len(raw), packed))
        total += packed
    return total, parts


def human(n):
    return "%.2f MB" % (n / 1024.0 / 1024.0)


def main():
    args = sys.argv[1:]
    only_check = "--check" in args

    print("")
    print("HARVEST THE NIGHT - release")
    print("")

    bad = filters_are_sane()
    if bad:
        for line in bad:
            print("  FAIL  " + line)
        return 1
    print("  filters    every preset excludes %s" % ", ".join(FORBIDDEN))

    if only_check:
        print("")
        print("CHECKED  the parts that need no export templates")
        return 0

    if not templates_installed():
        print("")
        print("  Godot's export templates are not installed on this machine.")
        print("  They are a separate ~1GB download and nothing can be built")
        print("  without them. In the editor: Editor > Manage Export")
        print("  Templates > Download and Install.")
        print("")
        print("BLOCKED  no export templates")
        return 2

    if "--skip-verify" not in args:
        code, out = run([sys.executable, "tools/verify.py"])
        if code != 0:
            print(out[-2000:])
            print("STOPPED  the suite is red, so there is nothing to release")
            return 1
        print("  verify     PASS")

    # **A stale build directory ships stale files.** The web export writes
    # beside `index.html` rather than into a fresh folder, so yesterday's
    # pack would sit next to today's and be weighed with it. After the
    # verify, because the gate exports into here too.
    if os.path.isdir(BUILD):
        import shutil
        shutil.rmtree(BUILD)

    when = today()
    stamp(when)
    print("  stamped    %s" % when)

    for name, platform, path, _exclude in presets():
        dest = os.path.join(ROOT, *path.split("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        code, out = run([GODOT, "--headless", "--path", ROOT,
                         "--export-release", name, path])
        if code != 0 or not os.path.exists(dest):
            print("  FAIL  %s: %s" % (name, out.strip()[-300:]))
            return 1
        print("  built      %-16s %s" % (name, path))

        pack = dest if dest.endswith(".pck") else \
            os.path.splitext(dest)[0] + ".pck"
        if not os.path.exists(pack):
            pack = os.path.join(os.path.dirname(dest), "index.pck")
        if os.path.exists(pack):
            dirty = pack_is_clean(pack)
            if dirty:
                for line in dirty:
                    print("  FAIL  " + line)
                return 1
            print("  pack       %-16s nothing of the repository in it" % name)

    # **It boots.** Four hundred frames of the real exported binary with no
    # window, which loads the pack, runs every autoload, builds the title
    # scene and the backdrop farm behind it, and exits. It is not a full
    # night - the autoplayer is excluded from the pack on purpose - but it is
    # the difference between "the file was written" and "the file runs".
    exe = os.path.join(BUILD, "windows", "HarvestTheNight.exe")
    if os.path.exists(exe):
        code, out = run([exe, "--headless", "--quit-after", "400"],
                        timeout=180)
        noisy = [l for l in out.splitlines()
                 if "ERROR" in l or "SCRIPT ERROR" in l]
        if code != 0 or noisy:
            print("  FAIL  the windows build did not boot cleanly: %s"
                  % (noisy[0] if noisy else "exit %d" % code))
            return 1
        print("  boots      %-16s 400 frames, no errors" % "Windows Desktop")

    # **The two builds are the same game, file by file.** The determinism
    # hash is a property of the rules and the tables, and both of these
    # packs carry the same ones - which is checkable here, exactly, from the
    # MD5 the pack format already stores, and is not checkable at all from
    # inside a browser. So this is what "the two builds produce the same
    # hash" is answered with.
    here = os.path.join(BUILD, "windows", "HarvestTheNight.pck")
    there = os.path.join(BUILD, "web", "index.pck")
    if os.path.exists(here) and os.path.exists(there):
        a = pack_entries(here)
        b = pack_entries(there)
        differ = []
        for name in sorted(set(a) | set(b)):
            if a.get(name) != b.get(name):
                differ.append(name)
        rules = [n for n in differ if n.startswith("src/")]
        print("")
        print("  %-24s %d files, %d of them rules"
              % ("the windows pack", len(a),
                 len([n for n in a if n.startswith("src/")])))
        print("  %-24s %d files" % ("the web pack", len(b)))
        if rules:
            for name in rules[:10]:
                print("  FAIL  %s differs between the two builds" % name)
            return 1
        print("  %-24s every rule and every table identical"
              % "same game, both ways")
        if differ:
            print("  %-24s %d file(s) differ, none of them rules: %s"
                  % ("platform bits", len(differ), ", ".join(differ[:3])))

    web = os.path.join(BUILD, "web")
    if os.path.isdir(web):
        total, parts = wire_size(web)
        print("")
        print("  %-24s %10s %10s" % ("the web build", "on disk", "gzipped"))
        for name, raw, packed in parts:
            print("  %-24s %10s %10s" % (name, human(raw), human(packed)))
        print("  %-24s %10s %10s" % ("total on the wire", "", human(total)))
        print("  %-24s %10s %10s" % ("budget", "", human(WIRE_BUDGET)))
        pack = 0
        for name, _raw, packed in parts:
            if name.endswith(".pck"):
                pack = packed
        print("  %-24s %10s %10s" % ("the game's own half", "",
                                     human(pack)))
        print("  %-24s %10s %10s" % ("its budget", "", human(PACK_BUDGET)))
        if total > WIRE_BUDGET:
            print("")
            print("FAIL  the web build is %s over its budget"
                  % human(total - WIRE_BUDGET))
            return 1
        if pack > PACK_BUDGET:
            print("")
            print("FAIL  the game's own half is %s over its budget"
                  % human(pack - PACK_BUDGET))
            return 1

    print("")
    print("RELEASED  build/windows and build/web")
    return 0


if __name__ == "__main__":
    sys.exit(main())
