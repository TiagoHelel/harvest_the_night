# -*- coding: utf-8 -*-
"""Synthesise the bed under everything. Same rules as the rest of the sound.

    python tools/gen_ambience.py            write assets/ambience/
    python tools/gen_ambience.py --check    fail if anything is out of date
    python tools/gen_ambience.py --report   length, peak and the seam

Three generators, three folders, three buses: `gen_sfx` makes `assets/sfx`
for the SFX bus, `gen_music` makes `assets/music` for the Music bus, and this
makes `assets/ambience` for the Ambience one. The primitives all come from
`gen_sfx` - one synthesiser for the whole game.

## Two short beds and a handful of things that happen

The obvious way to build ambience is two more minute-and-a-half loops, and it
would have cost eight more megabytes and still been a loop. **A bed of
filtered noise can be sixteen seconds** and nobody will ever notice, because
there is no tune in it to recognise; what makes a farm sound alive is the
bird that calls every now and then, and a bird on a sixteen-second loop is
the one thing you *would* notice.

So the beds are short and continuous, and everything with a shape to it is a
one-shot the controller fires at intervals it picks. That also gives the
positional requirement for nothing: a lap of water played **at the pond**
goes through the same falloff as a gunshot, so it is louder when you are
standing next to it, and no new machinery was needed to say so.

## Looping noise

A pad can be made to loop by snapping its partials to harmonics of the loop,
which is what `gen_music` does. Noise has no partials to snap. The answer is
older and simpler: render a little more than a loop's worth and **crossfade
the overhang back over the beginning**, so the end is already becoming the
start by the time it gets there. `seamless()` does that, and the same
ninety-ninth-percentile measure task 0086 used says whether it worked.
"""
import io
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import gen_sfx as sfx                                # noqa: E402

RATE = sfx.RATE
OUT = os.path.join(ROOT, "assets", "ambience")

## How long a bed is. Long enough that the filter movement does not pulse,
## short enough that two of them are under two megabytes.
BED_SECONDS = 16.0

## How much of the end is folded back over the beginning to close the loop.
## A second and a half: long enough that the crossfade itself is inaudible in
## noise, short enough to leave most of the bed untouched.
OVERLAP_SECONDS = 1.5

## **The bed is the quietest thing in the game.** It is under everything, all
## the time, and the moment a player notices it they will turn it off.
BED_PEAK = 0.22

## The things that happen. Louder than the bed, because they are meant to be
## heard - but still well under the effects.
TOUCH_PEAK = 0.34


def seamless(samples, loop_length, overlap):
    """Close a loop by folding its overhang back over its beginning."""
    out = list(samples[:loop_length])
    for i in range(min(overlap, loop_length, len(samples) - loop_length)):
        t = i / float(overlap)
        out[i] = out[i] * t + samples[loop_length + i] * (1.0 - t)
    return out


def bed(seed, low_hz, high_hz, breath_hz, hiss_hz, hiss_level):
    """A continuous bed: moving air, with a slow swell under it."""
    loop = int(RATE * BED_SECONDS)
    overlap = int(RATE * OVERLAP_SECONDS)
    ms = (loop + overlap) * 1000.0 / RATE

    # The body: noise through a filter that opens and closes slowly. Done as
    # two passes at fixed cutoffs blended by a slow sine, which is cheaper
    # than moving a filter and sounds the same at this speed.
    raw = sfx.noise(seed, ms)
    dark = sfx.lowpass(raw, low_hz)
    bright = sfx.lowpass(raw, high_hz)
    body = []
    step = 2.0 * math.pi * breath_hz / RATE
    for i in range(len(dark)):
        t = 0.5 * (1.0 + math.sin(step * i))
        body.append(dark[i] * (1.0 - t) + bright[i] * t)

    # A thin hiss on top, so the bed has some air in it rather than being a
    # rumble. Very quiet: this is the part that would become tiring.
    hiss = sfx.gain(sfx.highpass(sfx.noise(seed + 7, ms), hiss_hz), hiss_level)
    return seamless(sfx.mix(body, hiss), loop, overlap)


# -------------------------------------------------------------------- the beds

def day_bed():
    """Warm, open air. What a field sounds like when nothing is happening."""
    return bed(9101, 380.0, 1400.0, 0.11, 3400.0, 0.18)


def night_bed():
    """Colder, lower and emptier. The same field with the warmth taken out."""
    return bed(9102, 190.0, 700.0, 0.07, 4200.0, 0.10)


# ------------------------------------------------------------- what happens

def _chirp(seed, hz, ms, wobble, repeats, gap_ms):
    """A bird: a short warble, two or three times over."""
    out = []
    for n in range(repeats):
        note = sfx.sweep(hz * (1.0 - wobble), hz * (1.0 + wobble), ms, 0.6)
        second = sfx.gain(sfx.sweep(hz * 2.0, hz * 1.8, ms, 0.6), 0.2)
        air = sfx.gain(sfx.highpass(sfx.noise(seed + n, ms), 2600.0), 0.1)
        one = sfx.decay(sfx.mix(note, second, air), ms * 0.45, 8.0)
        out = sfx.mix(out, sfx.at(int(n * gap_ms), one))
    return out


def bird_high():
    return _chirp(9110, 2600.0, 90, 0.14, 3, 130)


def bird_low():
    return _chirp(9111, 1500.0, 130, 0.10, 2, 200)


def bird_trill():
    return _chirp(9112, 2050.0, 60, 0.22, 5, 85)


def water_lap():
    """The pond against its edge. Soft, and the reason falloff exists here."""
    body = sfx.lowpass(sfx.noise(9120, 420), 900.0)
    swell = sfx.swell(body, 90.0, 260.0)
    plip = sfx.at(210, sfx.decay(sfx.sweep(620.0, 300.0, 100, 0.6), 30.0))
    return sfx.mix(sfx.gain(swell, 0.8), sfx.gain(plip, 0.35))


def breeze():
    """A gust through leaves. The one that makes a still farm feel outdoors."""
    body = sfx.sweep_lowpass(sfx.noise(9121, 1500), 500.0, 2600.0)
    return sfx.swell(body, 380.0, 820.0)


def cricket():
    """Night. Three dry ticks, high and close."""
    out = []
    for n in range(3):
        tick = sfx.decay(sfx.highpass(sfx.noise(9130 + n, 40), 3600.0),
                         7.0, 1.0)
        ring = sfx.gain(sfx.decay(sfx.tone(4400.0, 40), 6.0, 1.0), 0.4)
        out = sfx.mix(out, sfx.at(int(n * 70), sfx.mix(tick, ring)))
    return out


def owl():
    """Two low hoots, a long way off."""
    one = sfx.decay(sfx.sweep(420.0, 380.0, 280, 1.2), 110.0, 40.0)
    two = sfx.at(420, sfx.decay(sfx.sweep(400.0, 350.0, 320, 1.2), 130.0,
                                45.0))
    return sfx.mix(sfx.gain(one, 0.7), sfx.gain(two, 0.6))


def far_groan():
    """Something out past the fence.

    **Not the same file as the night's groans.** Those report a zombie you can
    do something about; this is atmosphere, and it is duller and longer so
    that nobody ever mistakes one for the other.
    """
    voice = sfx.sweep(120.0, 86.0, 1100, 1.1)
    breath = sfx.lowpass(sfx.noise(9140, 1100), 380.0)
    return sfx.swell(sfx.mix(sfx.gain(voice, 0.55), sfx.gain(breath, 0.5)),
                     320.0, 560.0)


def wind_gust():
    """Night wind, with an edge on it that the day's breeze has not."""
    body = sfx.sweep_lowpass(sfx.noise(9141, 1900), 900.0, 320.0)
    whistle = sfx.gain(sfx.decay(sfx.sweep(760.0, 620.0, 1900, 1.4),
                                 700.0, 300.0), 0.18)
    return sfx.swell(sfx.mix(body, whistle), 480.0, 900.0)


## Every file, with what it may peak at. The id the game asks for is the name
## with `ambience/` in front of it.
BEDS = [
    ("day_bed", day_bed, BED_PEAK),
    ("night_bed", night_bed, BED_PEAK),
]

TOUCHES = [
    ("bird_high", bird_high, TOUCH_PEAK),
    ("bird_low", bird_low, TOUCH_PEAK),
    ("bird_trill", bird_trill, TOUCH_PEAK),
    ("water_lap", water_lap, TOUCH_PEAK),
    ("breeze", breeze, TOUCH_PEAK),
    ("cricket", cricket, TOUCH_PEAK),
    ("owl", owl, TOUCH_PEAK),
    ("far_groan", far_groan, TOUCH_PEAK),
    ("wind_gust", wind_gust, TOUCH_PEAK),
]

SOUNDS = BEDS + TOUCHES


def render(name, recipe, peak):
    """**A bed is not faded out and a touch is.** One loops, one does not."""
    track = sfx.normalise(recipe(), peak)
    for bed_name, _r, _p in BEDS:
        if bed_name == name:
            return track
    return sfx.fade_out(track)


def everything():
    out = {}
    for name, recipe, peak in SOUNDS:
        out["%s.wav" % name] = sfx.wav_bytes(render(name, recipe, peak))
    return out


def report():
    print("  %-11s %7s %6s %6s %7s" % ("sound", "seconds", "peak", "rms",
                                       "seam"))
    for name, recipe, peak in SOUNDS:
        track = render(name, recipe, peak)
        seconds, hit, rms, _b = sfx.measure(track)
        joins = ""
        for bed_name, _r, _p in BEDS:
            if bed_name == name:
                joins = "%.2f" % _seam_ratio(track)
        print("  %-11s %7.3f %6.2f %6.3f %7s"
              % (name, seconds, hit, rms, joins))


def _seam_ratio(track):
    """The join against the track's own steps, as task 0086 measures it."""
    steps = sorted(abs(track[i] - track[i - 1]) for i in range(1, len(track)))
    p99 = steps[min(int(len(steps) * 0.99), len(steps) - 1)]
    return abs(track[0] - track[-1]) / max(p99, 1e-9)


def preview(folder):
    """A minute of standing still, by day and by night.

    The done-when is that standing on the farm for a minute is pleasant and
    not empty, and there is no measurement that answers it. This renders the
    thing to listen to: the bed looped, with touches fired at the same gaps
    the game picks and attenuated by the same falloff, from the sort of
    distances the farm actually puts them at.

    Every number here is read out of the GDScript rather than typed, so what
    comes out of the file is what comes out of the game.
    """
    os.makedirs(folder, exist_ok=True)
    made = {}
    for name, recipe, peak in SOUNDS:
        made[name] = render(name, recipe, peak)
        io.open(os.path.join(folder, "%s.wav" % name), "wb").write(
            sfx.wav_bytes(made[name]))

    low = sfx.gd_number("src/ui/ambience.gd", "GAP_LOW")
    high = sfx.gd_number("src/ui/ambience.gd", "GAP_HIGH")
    near = sfx.gd_number("src/app/audio.gd", "NEAR")
    earshot = sfx.gd_number("src/app/audio.gd", "EARSHOT")
    floor = sfx.gd_number("src/app/audio.gd", "FAR_FLOOR")

    def falloff(distance):
        if distance <= near:
            return 1.0
        if distance >= earshot:
            return floor
        return 1.0 - (1.0 - floor) * (distance - near) / (earshot - near)

    # How far off each sort of thing tends to be. A bird is in a tree across
    # the field, the pond is a walk away, something past the fence is past
    # the fence.
    distances = {
        "bird_high": 180.0, "bird_low": 240.0, "bird_trill": 150.0,
        "water_lap": 200.0, "breeze": 0.0, "cricket": 60.0,
        "owl": 300.0, "wind_gust": 0.0, "far_groan": 460.0,
    }

    for half, bed_name, touches in [
            ("day", "day_bed", [n for n, _r, _p in TOUCHES
                                if n.startswith("bird") or n in
                                ("breeze", "water_lap")]),
            ("night", "night_bed", ["cricket", "owl", "wind_gust",
                                    "far_groan"])]:
        seconds = 60.0
        length = int(RATE * seconds)
        loop = made[bed_name]
        track = [loop[i % len(loop)] for i in range(length)]
        rng = sfx.Noise(8701 if half == "day" else 8702)
        when = low
        picked = 0
        while when < seconds - 2.0:
            name = touches[int(abs(rng.next()) * len(touches)) % len(touches)]
            one = made[name]
            level = falloff(distances.get(name, 0.0))
            start = int(when * RATE)
            for i, v in enumerate(one):
                if start + i >= length:
                    break
                track[start + i] += v * level
            when += low + (high - low) * abs(rng.next())
            picked += 1
        io.open(os.path.join(folder, "_a-minute-of-%s.wav" % half),
                "wb").write(sfx.wav_bytes(track))
        print("  %s: %d touches over %.0fs" % (half, picked, seconds))
    print("  preview: %d files in %s" % (len(SOUNDS) + 2, folder))


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
                bad.append("%s is not in SOUNDS" % name)
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/gen_ambience.py")
            return 1
        print("OK    %d ambience files match their recipes (%d beds, %d touches)"
              % (len(files), len(BEDS), len(TOUCHES)))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("ambience: %d files, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
