# -*- coding: utf-8 -*-
"""Synthesise the two pieces of music. Same rules as the sound effects.

    python tools/gen_music.py            write assets/music/
    python tools/gen_music.py --check    fail if anything is out of date
    python tools/gen_music.py --report   length, peak and the seam

The primitives come from `gen_sfx.py` - one synthesiser for the whole game,
so a change to the filters reaches everything. What is here is the arranging.

## The loop point has to be inaudible, and it is by construction

That is the done-when, and guessing at it would be silly when it can simply
be made true:

- **Every partial is snapped to a harmonic of the loop.** A sine at 146.83 Hz
  does not fit a whole number of times into ninety-six seconds, so it arrives
  back at the seam part-way through a cycle and steps. `snap()` moves it to
  the nearest frequency that *does* fit - at most a fifth of a hertz, which
  is inaudible, and then every sustained layer is exactly periodic.
- **Anything struck wraps round.** A note in the last bar whose tail runs
  past the end is written back over the beginning rather than truncated, so
  the decay that leaves the loop is the decay that enters it.

Between them there is no seam left to hear, and `headless_check` measures the
step at the join against the track's own average step rather than taking my
word for it.

## They share a motif

Task 0086's second requirement: the night has to be recognisably the same
farm. `MOTIF` is one list of scale degrees and both pieces play it - the day
in a major scale at a walking pace, the night in a minor one, half as often
and an octave down. The check asserts both arrangements read the same list,
because a shared motif that got copied into two lists is a shared motif until
somebody edits one of them.
"""
import io
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import gen_sfx as sfx                                # noqa: E402

RATE = sfx.RATE
OUT = os.path.join(ROOT, "assets", "music")

## Beats a minute, and the same for both pieces.
##
## **The night is not slower.** A crossfade between two tempos is a stumble,
## and the one moment these two ever meet is the moment the player switches
## reality. The night is sparser instead, which reads as slower without
## fighting the day on the way past.
BPM = 75

## Four beats to the bar. Eight-tenths of a second a beat at this tempo, which
## is exactly 17640 samples - so a bar is a whole number of samples and the
## loop can be a whole number of bars.
BEATS_PER_BAR = 4

## How long each piece is. **Ninety-six seconds rather than a round two
## minutes**: the loop is seamless, so nobody can tell a ninety-six second
## loop from a hundred-and-twenty second one, and the difference is two more
## megabytes of WAV in a repository whose source is two megabytes.
BARS = 30

## The urgent layer that arrives on the last wave. Six bars, which divides
## thirty exactly, so it can loop five times inside the night without ever
## drifting off the beat.
INTENSITY_BARS = 6

## Music sits under everything and never competes with a gunshot.
MUSIC_PEAK = 0.34

## The one the intensity layer may reach. Louder, because its whole job is to
## say that this is the last wave.
INTENSITY_PEAK = 0.44

## **The motif, as scale degrees.** One list, played by both pieces; see the
## module docstring. Zero is the root, seven is the octave.
MOTIF = [0, 2, 4, 2, 7, 4, 2, 0]

## Semitones above the root, for the two modes the pieces are in.
MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]

## D, low enough to sit under a game and high enough to have a tune in it.
ROOT_HZ = 146.83

## The chords under each piece, one to a bar, repeating. Degrees of the scale.
DAY_CHORDS = [0, 5, 3, 4]
NIGHT_CHORDS = [0, 5, 3, 6]


def beat_samples():
    return int(round(RATE * 60.0 / BPM))


def bar_samples():
    return beat_samples() * BEATS_PER_BAR


def hz_of(scale, degree, octaves=0):
    """A scale degree as a frequency, wrapping through octaves."""
    step = scale[degree % len(scale)] + 12 * (degree // len(scale) + octaves)
    return ROOT_HZ * (2.0 ** (step / 12.0))


def snap(hz, loop_length):
    """The nearest frequency that fits a whole number of times in the loop.

    **This is what makes a sustained layer loop without a click.** The move is
    at most half a cycle over the whole loop - a fifth of a hertz here - which
    nothing can hear, and in exchange the last sample runs into the first.
    """
    cycles = max(round(hz * loop_length / RATE), 1)
    return cycles * RATE / float(loop_length)


def wrapped(track, start, samples, level=1.0):
    """Write a sound into the loop, wrapping anything past the end.

    A note struck in the last bar has a tail, and truncating it is the other
    way a loop clicks. Writing it back over the beginning is what a loop
    actually is.
    """
    n = len(track)
    if n == 0:
        return
    for i, v in enumerate(samples):
        track[(start + i) % n] += v * level


def sustained(loop_length, hz, level, wobble_hz=0.0, wobble=0.0):
    """A held tone that is exactly periodic over the loop.

    The wobble is a slow amplitude drift, itself snapped to the loop, so a pad
    breathes instead of sitting still - and still lands where it started.
    """
    tuned = snap(hz, loop_length)
    out = [0.0] * loop_length
    step = 2.0 * math.pi * tuned / RATE
    if wobble_hz > 0.0:
        drift = snap(wobble_hz, loop_length)
        dstep = 2.0 * math.pi * drift / RATE
        for i in range(loop_length):
            out[i] = math.sin(step * i) * level * (
                1.0 - wobble + wobble * 0.5 * (1.0 + math.sin(dstep * i)))
    else:
        for i in range(loop_length):
            out[i] = math.sin(step * i) * level
    return out


def pluck(hz, ms, tau_ms, brightness=2400.0):
    """A soft struck note. The day's voice."""
    body = sfx.tone(hz, ms)
    second = sfx.gain(sfx.tone(hz * 2.0, ms), 0.3)
    air = sfx.gain(sfx.lowpass(sfx.noise(int(hz) % 9973 + 11, 18), brightness),
                   0.25)
    return sfx.decay(sfx.mix(body, second, air), tau_ms, 6.0)


def bell(hz, ms, tau_ms):
    """A colder, thinner note. The night's voice."""
    body = sfx.tone(hz, ms)
    fifth = sfx.gain(sfx.tone(hz * 1.5, ms), 0.22)
    high = sfx.gain(sfx.tone(hz * 3.0, ms), 0.12)
    return sfx.decay(sfx.mix(body, fifth, high), tau_ms, 12.0)


def thump(hz, ms, tau_ms):
    """Something low on the beat."""
    return sfx.decay(sfx.sweep(hz * 1.6, hz, ms, 0.4), tau_ms, 3.0)


# ----------------------------------------------------------------- the pieces

def farm():
    """**The day.** Warm, unhurried, and mostly not there.

    A pad, a bass note a bar, and the motif once every four bars. The gaps are
    the point: this plays for four minutes at a time behind a player deciding
    where to put a fence, and a tune that filled every bar would be a tune
    they turned off.
    """
    bar = bar_samples()
    beat = beat_samples()
    length = bar * BARS
    track = [0.0] * length

    # The pad: root, fifth and octave, breathing slowly.
    for hz, level in [(hz_of(MAJOR, 0, -1), 0.5),
                      (hz_of(MAJOR, 4, -1), 0.32),
                      (hz_of(MAJOR, 0), 0.22)]:
        layer = sustained(length, hz, level, wobble_hz=0.06, wobble=0.45)
        for i in range(length):
            track[i] += layer[i]

    # A bass note on the first beat of every bar, walking the chords.
    for b in range(BARS):
        degree = DAY_CHORDS[b % len(DAY_CHORDS)]
        wrapped(track, b * bar,
                thump(hz_of(MAJOR, degree, -2), 900, 300.0), 0.55)

    # **The motif, every fourth bar.** One note a half-beat under the walking
    # pace, so it reads as somebody humming rather than as a melody line.
    for b in range(0, BARS, 4):
        for i, degree in enumerate(MOTIF):
            at = b * bar + i * (beat // 2) + beat
            wrapped(track, at, pluck(hz_of(MAJOR, degree), 700, 210.0), 0.5)

    # And one high answer at the end of the phrase, which is the hook.
    for b in range(2, BARS, 8):
        wrapped(track, b * bar + beat * 2,
                pluck(hz_of(MAJOR, 4, 1), 1100, 420.0, 3600.0), 0.3)

    return track


def night():
    """**The night.** The same farm, colder and further away.

    Same motif, same grid, minor, an octave down and half as often. A drone
    instead of a pad, and a low pulse where the day has a walking bass - so
    that a player who has just switched reality hears the same shape and knows
    it is the same place.
    """
    bar = bar_samples()
    beat = beat_samples()
    length = bar * BARS
    track = [0.0] * length

    # A drone: root and minor third, with the fifth under it.
    for hz, level in [(hz_of(MINOR, 0, -2), 0.55),
                      (hz_of(MINOR, 0, -1), 0.3),
                      (hz_of(MINOR, 2, -1), 0.2)]:
        layer = sustained(length, hz, level, wobble_hz=0.04, wobble=0.55)
        for i in range(length):
            track[i] += layer[i]

    # A pulse on one and three, quiet enough to be a heartbeat.
    for b in range(BARS):
        degree = NIGHT_CHORDS[b % len(NIGHT_CHORDS)]
        wrapped(track, b * bar,
                thump(hz_of(MINOR, degree, -2), 1200, 420.0), 0.5)
        wrapped(track, b * bar + beat * 2,
                thump(hz_of(MINOR, degree, -2), 900, 260.0), 0.22)

    # **The motif, an octave down and one note a beat** - half the day's pace.
    # Every eighth bar, so most of the night is drone and pulse.
    for b in range(1, BARS, 8):
        for i, degree in enumerate(MOTIF):
            at = b * bar + i * beat
            wrapped(track, at, bell(hz_of(MINOR, degree, -1), 1400, 500.0),
                    0.34)

    return track


def intensity():
    """**The last wave.** Six bars that sit on top of the night.

    It is a layer, not a piece: it is mixed over `night` rather than replacing
    it, so the thing that changes when the last wave comes is that the night
    gets a pulse and a rising figure, not that the music stops and starts.
    """
    bar = bar_samples()
    beat = beat_samples()
    length = bar * INTENSITY_BARS
    track = [0.0] * length

    # Every beat, which is the whole trick: the night pulses twice a bar and
    # this pulses eight times.
    for b in range(INTENSITY_BARS):
        for k in range(BEATS_PER_BAR):
            level = 0.55 if k == 0 else 0.3
            wrapped(track, b * bar + k * beat,
                    thump(hz_of(MINOR, 0, -2), 520, 150.0), level)

    # The first three notes of the motif, climbing a bar at a time. Not the
    # whole phrase: this is meant to be unresolved.
    for b in range(INTENSITY_BARS):
        degree = MOTIF[b % 3]
        wrapped(track, b * bar + beat * 2,
                bell(hz_of(MINOR, degree, 0), 1100, 340.0), 0.3)

    # A held fifth over the top, snapped so the six bars loop cleanly too.
    top = sustained(length, hz_of(MINOR, 4, 0), 0.22,
                    wobble_hz=0.5, wobble=0.6)
    for i in range(length):
        track[i] += top[i]

    return track


## The three files, and what each may peak at.
PIECES = [
    ("farm", farm, MUSIC_PEAK),
    ("night", night, MUSIC_PEAK),
    ("night_intensity", intensity, INTENSITY_PEAK),
]


def render(recipe, peak):
    """**No `fade_out`.** These loop; a ramp at the end is a hole in the loop."""
    return sfx.normalise(recipe(), peak)


def everything():
    out = {}
    for name, recipe, peak in PIECES:
        out["%s.wav" % name] = sfx.wav_bytes(render(recipe, peak))
    return out


# ------------------------------------------------------------------ measuring

def seam(samples):
    """The step at the loop point, against the track's own average step.

    A click is a discontinuity, and a discontinuity is a step much bigger than
    the steps either side of it. Anything near one is inaudible; a truncated
    decay would be tens or hundreds.
    """
    if len(samples) < 3:
        return 0.0
    total = 0.0
    for i in range(1, len(samples)):
        total += abs(samples[i] - samples[i - 1])
    average = total / (len(samples) - 1)
    if average <= 0.0:
        return 0.0
    return abs(samples[0] - samples[-1]) / average


def report():
    print("  %-16s %7s %6s %6s %7s" % ("piece", "seconds", "peak", "rms",
                                       "seam"))
    for name, recipe, peak in PIECES:
        track = render(recipe, peak)
        seconds, hit, rms, _bright = sfx.measure(track)
        print("  %-16s %7.2f %6.2f %6.3f %7.2f"
              % (name, seconds, hit, rms, seam(track)))
    print("  %d bars at %d bpm, bar %d samples, loop %d samples"
          % (BARS, BPM, bar_samples(), bar_samples() * BARS))


def preview(folder):
    """What the done-whens need ears for.

    `_loop-seam.wav` runs the join past you six times: the last eight seconds
    of the farm loop, then its first eight, over and over. A click is obvious
    when it comes round that often, and impossible to be sure about listening
    to a loop once.

    `_crossfade.wav` is the farm giving way to the night over exactly the
    transition's length, which is read out of `game_data.gd` rather than
    typed here.
    """
    os.makedirs(folder, exist_ok=True)
    made = {}
    for name, recipe, peak in PIECES:
        made[name] = render(recipe, peak)
        io.open(os.path.join(folder, "%s.wav" % name), "wb").write(
            sfx.wav_bytes(made[name]))

    window = int(RATE * 8)
    seam_track = []
    for _ in range(6):
        seam_track += made["farm"][-window:] + made["farm"][:window]
    io.open(os.path.join(folder, "_loop-seam.wav"), "wb").write(
        sfx.wav_bytes(seam_track))

    seconds = _transition_seconds()
    lead = int(RATE * 6)
    fade = int(RATE * seconds)
    out = []
    for i in range(lead + fade + lead):
        if i < lead:
            out.append(made["farm"][i % len(made["farm"])])
        elif i < lead + fade:
            t = (i - lead) / float(max(fade, 1))
            a = made["farm"][i % len(made["farm"])]
            b = made["night"][(i - lead) % len(made["night"])]
            out.append(a * (1.0 - t) + b * t)
        else:
            out.append(made["night"][(i - lead) % len(made["night"])])
    io.open(os.path.join(folder, "_crossfade.wav"), "wb").write(
        sfx.wav_bytes(out))
    print("  preview: 3 pieces, 6 passes over the loop seam, and a "
          "%.1fs crossfade, in %s" % (seconds, folder))


def _transition_seconds():
    path = os.path.join(ROOT, "src", "core", "game_data.gd")
    for line in io.open(path, encoding="utf-8"):
        if line.startswith("const TRANSITION_SECONDS"):
            return float(line.split(":=")[1].split("#")[0].strip())
    raise SystemExit("gen_music: game_data.gd has no TRANSITION_SECONDS")


def main():
    args = sys.argv[1:]
    files = everything()

    if "--preview" in args:
        preview(args[args.index("--preview") + 1])
        return 0

    if "--report" in args:
        report()

    if "--check" in args:
        bad = []
        for name, data in sorted(files.items()):
            full = os.path.join(OUT, name)
            if not os.path.exists(full):
                bad.append("%s is missing" % name)
            elif io.open(full, "rb").read() != data:
                bad.append("%s does not match its recipe" % name)
        for name in sorted(os.listdir(OUT)) if os.path.isdir(OUT) else []:
            if name.endswith(".wav") and name not in files:
                bad.append("%s is not in PIECES" % name)
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/gen_music.py")
            return 1
        print("OK    %d pieces match their recipes" % len(files))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("music: %d pieces, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
