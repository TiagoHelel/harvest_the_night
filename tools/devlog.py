# -*- coding: utf-8 -*-
"""The trailer clip and the devlog page, both made rather than written twice.

    python tools/devlog.py            capture, make the clip, write the page
    python tools/devlog.py --keep     reuse the frames already captured
    python tools/devlog.py --check    the page, without the capture

## The clip

Thirty seconds out of one seeded run: a day of farming, the light going over,
a night holding, and something coming down. `src/tools/shot.gd --trailer`
captures the frames and this assembles them.

**A GIF, because there is no encoder on this machine.** `ffmpeg` is not
installed and this tool does not install things. So it writes two outputs
from the same three hundred frames: `the-trailer.gif`, which a devlog page
can show on its own, and the numbered PNGs, which anybody with `ffmpeg` can
turn into an `.mp4` with the one line this prints. Saying which is missing
and how to finish it is better than a tool that quietly produces the second
best thing.

## The page

The done-when is that the devlog is **generated from
`implementation/PROGRESS.md` rather than written twice**, and that is meant
literally. The journal is nine thousand lines written while the thing was
being built, one entry per task, and everything below comes out of it:

- how long it took, and how many tasks - from the entry headings
- what was built, in order - the same
- **every time the determinism hash moved and why** - the journal records
  those deliberately, and they are the closest thing this project has to a
  list of the moments it changed its mind
- the findings - the sub-headings the journal uses for them

What is *not* generated is the framing: the pitch comes from `design.md`
section 20, what is deliberately absent comes from section 15, and the two
paragraphs of opinion at the top are in `docs/devlog/preamble.md` where a
person can edit them. A devlog with no opinion in it is a changelog.
"""
import io
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FRAMES = os.path.join(ROOT, "implementation", "shots", "trailer")
OUT = os.path.join(ROOT, "docs", "devlog")
PREAMBLE = os.path.join(OUT, "preamble.md")
PROGRESS = os.path.join(ROOT, "implementation", "PROGRESS.md")
DESIGN = os.path.join(ROOT, "design.md")
RELEASE = os.path.join(ROOT, "implementation", "RELEASE.md")
STORE = os.path.join(ROOT, "docs", "STORE.md")

## The clip's own numbers. They have to agree with `shot.gd`'s, and
## `headless_check` asserts that they do.
FPS = 10
SECONDS = 30

## How many colours the clip is flattened to. Measured: 256 is 3.93 MB, 128
## is 3.45 and 64 is 2.95, against 5.12 with none. 128 is where the saving
## stops being worth the risk of banding a night sky.
GIF_COLOURS = 128

## A journal sub-heading is a finding when it reads like one. Generated pages
## are only worth having when the rule that made them can be stated: these
## are the words this journal uses when something went wrong, and picking
## them out is what turns nine thousand lines into a page.
FINDING_WORDS = ["found", "wrong", "bug", "broke", "broken", "took two",
                 "missing", "did nothing", "on luck", "lied", "not run",
                 "owed", "placebo", "twice", "failed"]

## **Both of these are wider than they look like they need to be**, and
## both were widened after the first run of this reported eighty-seven of a
## hundred and nine entries and two of twelve hash moves without complaining.
##
## The journal is nine thousand lines written over a hundred and ten tasks
## and it does not have one voice. Twenty-two entries were written before
## the `- done <date>` suffix became the habit, and a hash move is written
## five different ways - `Sim`, `Sim hash`, `Data`, `Data hash`, `data hash`
## - sometimes in backticks and sometimes not. A parser that only knows the
## most recent shape reports a smaller, tidier project than the one that
## exists.
ENTRY = re.compile(
    r"^## (\d{4}) - (.+?)(?: - (done|blocked) (\d{4}-\d\d-\d\d))?$")
MOVED = re.compile(
    r"\b(sim|data)(?:\s+hash)?\s*`?(\d{6,})`?\s*->\s*`?(\d{6,})`?",
    re.IGNORECASE)


def run(command):
    done = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                          timeout=1800)
    return done.returncode, (done.stdout or "") + (done.stderr or "")


# ------------------------------------------------------------------ the clip

def capture():
    if os.path.isdir(FRAMES):
        shutil.rmtree(FRAMES)
    code, out = run([sys.executable, "tools/shot.py", "trailer", "--trailer"])
    if code != 0:
        return "the trailer would not capture:\n%s" % out[-1200:]
    return ""


def clip(where):
    """The GIF, and the line that would make an mp4 out of the same frames."""
    from PIL import Image
    names = sorted(f for f in os.listdir(FRAMES)
                   if f.startswith("trailer-") and f.endswith(".png"))
    if not names:
        return "", "there are no trailer frames to assemble"
    pictures = [Image.open(os.path.join(FRAMES, f)).convert("RGB")
                for f in names]

    # **One palette for all three hundred frames.** A frame of this game has
    # three and a half thousand distinct colours in it - the light ramp and
    # the lamps blend - so left alone every frame carries its own palette and
    # the file came out at 5.12 MB. A shared table of `GIF_COLOURS` is
    # 3.45 MB of the same thirty seconds, and the banding was looked for in
    # the result rather than assumed away: a dark night sky is where it would
    # show, and it does not.
    #
    # No dithering. Dither on pixel art is noise that moves between frames,
    # which is both uglier and bigger.
    shared = pictures[len(pictures) // 2].quantize(
        colors=GIF_COLOURS, method=Image.MEDIANCUT)
    flat = [one.quantize(palette=shared, dither=Image.NONE)
            for one in pictures]
    path = os.path.join(where, "the-trailer.gif")
    flat[0].save(path, save_all=True, append_images=flat[1:],
                 duration=int(1000 / FPS), loop=0, optimize=True)
    return path, ""


def ffmpeg_line():
    return ("ffmpeg -framerate %d -i \"%s/trailer-%%03d.png\""
            " -vf scale=960:-1:flags=neighbor -c:v libx264 -pix_fmt yuv420p"
            " the-trailer.mp4"
            % (FPS, os.path.relpath(FRAMES, ROOT).replace("\\", "/")))


# ------------------------------------------------------------- the journal

def entries():
    """[(id, title, state, date)] out of the journal's own headings."""
    out = []
    for line in io.open(PROGRESS, encoding="utf-8"):
        hit = ENTRY.match(line.strip())
        if hit:
            out.append((hit.group(1), hit.group(2),
                        hit.group(3) or "done", hit.group(4) or ""))
    return out


def tasks_done():
    """How many tasks the backlog says are finished.

    **The number this page has to match.** A generated page that silently
    describes four fifths of the project is worse than no page, because
    nothing about it looks wrong - so the count comes from somewhere that is
    not the journal, and the two have to agree."""
    folder = os.path.join(ROOT, "implementation", "prompts")
    if not os.path.isdir(folder):
        return 0
    count = 0
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".md"):
            continue
        text = io.open(os.path.join(folder, name), encoding="utf-8").read()
        if "**Status:** done" in text:
            count += 1
    return count


def hash_moves():
    """Every recorded move of either guard, with the entry it happened in."""
    out = []
    here = None
    for line in io.open(PROGRESS, encoding="utf-8"):
        hit = ENTRY.match(line.strip())
        if hit:
            here = (hit.group(1), hit.group(2))
            continue
        for which, was, now in MOVED.findall(line):
            if here:
                out.append((here[0], here[1], which, was, now))
    return out


def findings():
    """The journal's own sub-headings, where they read like a finding."""
    out = []
    here = None
    for line in io.open(PROGRESS, encoding="utf-8"):
        text = line.strip()
        hit = ENTRY.match(text)
        if hit:
            here = (hit.group(1), hit.group(2))
            continue
        if not text.startswith("### ") or here is None:
            continue
        said = text[4:].strip()
        low = said.lower()
        if any(word in low for word in FINDING_WORDS):
            out.append((here[0], here[1], said))
    return out


def english_pitch():
    """The English pitch, out of the store copy where a person wrote it.

    `design.md` is Portuguese - it is the original - so the English page
    quoting section 20 verbatim was an English devlog with a Portuguese
    pitch in the middle of it. Found by reading the page."""
    if not os.path.exists(STORE):
        return []
    text = io.open(STORE, encoding="utf-8").read()
    if "### The pitch" not in text:
        return []
    after = text.split("### The pitch", 1)[1]
    out = []
    for line in after.splitlines():
        if line.startswith("#"):
            break
        line = line.strip()
        if line:
            out.append(line)
    return out


def pitch():
    text = io.open(DESIGN, encoding="utf-8").read()
    if "# 20. Elevator Pitch" not in text:
        return []
    out = []
    for line in text.split("# 20. Elevator Pitch", 1)[1].splitlines():
        if line.startswith("#"):
            break
        line = line.strip()
        if line.startswith(">"):
            line = line[1:].strip()
            if line:
                out.append(line)
    return out


def not_in_the_mvp():
    """Section 15's list, as the design document wrote it."""
    text = io.open(DESIGN, encoding="utf-8").read()
    if "# 15. O que N" not in text:
        return []
    after = text.split("# 15. O que N", 1)[1]
    out = []
    for line in after.splitlines():
        if line.startswith("# 16"):
            break
        line = line.strip()
        if line.startswith("- "):
            out.append(line[2:].replace("❌", "").strip().rstrip(";"))
    return out


def known_issues():
    """The release checklist's list, which is the honest one."""
    if not os.path.exists(RELEASE):
        return []
    text = io.open(RELEASE, encoding="utf-8").read()
    if "## Known issues" not in text:
        return []
    after = text.split("## Known issues", 1)[1]
    out = []
    for block in after.split("\n- ")[1:]:
        if block.strip().startswith("#") or "## Rollback" in block:
            block = block.split("## Rollback")[0]
        one = " ".join(l.strip() for l in block.splitlines() if l.strip())
        if one:
            out.append(one.replace("**", ""))
        if "## Rollback" in after.split("\n- ")[0]:
            break
    return out[:8]


# ---------------------------------------------------------------- the page

def preamble(language):
    """The two paragraphs a person wrote, for the language asked for."""
    if not os.path.exists(PREAMBLE):
        return ""
    text = io.open(PREAMBLE, encoding="utf-8").read()
    mark = "## %s" % language
    if mark not in text:
        return ""
    after = text.split(mark, 1)[1]
    return after.split("\n## ")[0].strip()


def page(language, words):
    log = entries()
    moves = hash_moves()
    found = findings()
    days = sorted(set(d for _i, _t, _s, d in log))

    out = []
    out.append("# %s" % words["title"])
    out.append("")
    out.append("![%s](the-trailer.gif)" % words["clip_alt"])
    out.append("")
    out.append("*%s*" % words["clip_caption"])
    out.append("")
    body = preamble(language)
    if body:
        out.append(body)
        out.append("")

    out.append("## %s" % words["meant"])
    out.append("")
    said = english_pitch() if language == "English" else pitch()
    if not said:
        said = pitch()
    for line in said:
        out.append("> %s" % line)
        out.append(">")
    out.append("")

    out.append("## %s" % words["became"])
    out.append("")
    out.append(words["became_line"] % (len(log), len(days), days[0],
                                       days[-1]))
    out.append("")
    out.append("| # | %s | %s |" % (words["col_task"], words["col_day"]))
    out.append("|---|---|---|")
    for task_id, title, _state, when in log:
        out.append("| %s | %s | %s |" % (task_id, title, when))
    out.append("")

    out.append("## %s" % words["changed_mind"])
    out.append("")
    out.append(words["changed_mind_line"] % len(moves))
    out.append("")
    for task_id, title, which, was, now in moves:
        out.append("- **%s** (%s) - `%s` %s -> %s"
                   % (title, task_id, which.lower(), was, now))
    out.append("")

    out.append("## %s" % words["went_wrong"])
    out.append("")
    out.append(words["went_wrong_line"] % len(found))
    out.append("")
    for task_id, title, said in found:
        out.append("- **%s** - %s *(%s)*" % (task_id, said, title))
    out.append("")

    out.append("## %s" % words["not_in"])
    out.append("")
    out.append(words["not_in_line"])
    out.append("")
    for one in not_in_the_mvp():
        out.append("- %s" % one)
    out.append("")
    issues = known_issues()
    if issues:
        out.append(words["still_wrong"])
        out.append("")
        for one in issues:
            out.append("- %s" % one)
        out.append("")

    out.append("---")
    out.append("")
    out.append("*%s*" % words["generated"])
    return "\n".join(out) + "\n"


EN = {
    "title": "HARVEST THE NIGHT - a devlog",
    "clip_alt": "thirty seconds of the game",
    "clip_caption": "Thirty seconds, one seed: a day of farming, the light"
                    " going over, a night holding, and the fence coming"
                    " down.",
    "meant": "What it was meant to be",
    "became": "What it turned out to be",
    "became_line": "%d tasks over %d days, %s to %s. One at a time, each one"
                   " finished and checked before the next was started.",
    "col_task": "What was built",
    "col_day": "Finished",
    "changed_mind": "Every time the game changed underneath itself",
    "changed_mind_line": "Two hashes guard this project: one over the rules"
                         " and one over the balance tables. Between them they"
                         " moved %d times, and each one had to be written"
                         " down before it was accepted.",
    "went_wrong": "What went wrong",
    "went_wrong_line": "%d of them, taken out of the journal by the words it"
                       " uses when something did not work. This is the part"
                       " a devlog is for.",
    "not_in": "What is not in it",
    "not_in_line": "The design document's own list, written before any of it"
                   " existed, to protect the scope:",
    "still_wrong": "And what is still wrong, from the release checklist:",
    "generated": "Generated from implementation/PROGRESS.md by"
                 " tools/devlog.py. Editing this file by hand is editing"
                 " something that will be overwritten - the journal is the"
                 " source.",
}

PT = {
    "title": "HARVEST THE NIGHT - um devlog",
    "clip_alt": "trinta segundos do jogo",
    "clip_caption": "Trinta segundos, uma semente: um dia de fazenda, a luz"
                    " passando, uma noite aguentando, e a cerca caindo.",
    "meant": "O que era para ser",
    "became": "O que acabou sendo",
    "became_line": "%d tarefas em %d dias, de %s a %s. Uma de cada vez, cada"
                   " uma terminada e verificada antes de comecar a proxima.",
    "col_task": "O que foi feito",
    "col_day": "Terminado",
    "changed_mind": "Toda vez que o jogo mudou por baixo",
    "changed_mind_line": "Dois hashes protegem este projeto: um sobre as"
                         " regras e outro sobre as tabelas de balanceamento."
                         " Entre os dois eles se mexeram %d vezes, e cada uma"
                         " teve que ser escrita antes de ser aceita.",
    "went_wrong": "O que deu errado",
    "went_wrong_line": "%d coisas, tiradas do diario pelas palavras que ele"
                       " usa quando algo nao funcionou. E para isso que"
                       " serve um devlog.",
    "not_in": "O que nao tem",
    "not_in_line": "A lista do proprio documento de design, escrita antes de"
                   " qualquer coisa existir, para proteger o escopo:",
    "still_wrong": "E o que ainda esta errado, da lista de release:",
    "generated": "Gerado de implementation/PROGRESS.md por tools/devlog.py."
                 " Editar este arquivo a mao e editar algo que vai ser"
                 " sobrescrito - o diario e a fonte.",
}


def main():
    args = sys.argv[1:]
    print("")
    print("HARVEST THE NIGHT - devlog")
    print("")

    log = entries()
    done = tasks_done()
    if len(log) < 20:
        print("  FAIL  only %d entries in the journal - is it the right file?"
              % len(log))
        return 1
    if done and len(log) < done:
        print("  FAIL  the backlog says %d tasks are done and the journal"
              " gives up %d of them" % (done, len(log)))
        print("        a page that quietly describes part of the project is")
        print("        worse than no page. Widen the parser or fix the entry.")
        return 1
    print("  journal    %d entries against %d done, %d hash moves, %d"
          " findings" % (len(log), done, len(hash_moves()), len(findings())))

    if not os.path.isdir(OUT):
        os.makedirs(OUT)

    for name, language, words in [("index.md", "English", EN),
                                  ("index.pt_BR.md", "Portugues", PT)]:
        io.open(os.path.join(OUT, name), "w", encoding="utf-8",
                newline="\n").write(page(language, words))
        print("  page       %-16s %s" % (name, words["title"]))

    if "--check" in args:
        print("")
        print("CHECKED  the page, without the capture")
        return 0

    if "--keep" in args and os.path.isdir(FRAMES):
        print("  kept       the frames already captured (--keep)")
    else:
        trouble = capture()
        if trouble:
            print("  FAIL  " + trouble)
            return 1

    path, trouble = clip(OUT)
    if trouble:
        print("  FAIL  " + trouble)
        return 1
    size = os.path.getsize(path)
    print("  clip       the-trailer.gif  %d seconds at %dfps, %.2f MB"
          % (SECONDS, FPS, size / 1048576.0))
    print("")
    print("  no ffmpeg on this machine, so there is no .mp4. The frames are")
    print("  in %s and this makes one:"
          % os.path.relpath(FRAMES, ROOT).replace("\\", "/"))
    print("")
    print("      %s" % ffmpeg_line())
    print("")
    print("MADE  %s" % os.path.relpath(OUT, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
