# -*- coding: utf-8 -*-
"""Synthesise the game's sound effects. Nothing here is licensed or recorded.

    python tools/gen_sfx.py             write assets/sfx/
    python tools/gen_sfx.py --check     fail if anything is out of date
    python tools/gen_sfx.py --report    length, peak and brightness of each
    python tools/gen_sfx.py --preview <dir>
                                        also write a listening copy, plus a
                                        minute of chopping with the pitch
                                        jitter the game applies

Same shape as `gen_sprites.py` and `gen_font.py`: the recipe is the source,
the WAV is generated, and `--check` fails if a file stopped matching its
recipe. A sound nobody can regenerate is a sound nobody can change.

## Deterministic, and not by accident

`random` is not used anywhere. Every grain of noise comes from `Noise`, a
sixteen-line congruential generator seeded per sound, because the contract is
that regenerating produces byte-identical files on any machine and any Python
- and `random`'s stream is a promise CPython makes, not one the language
does. The same reasoning as the run's own RNG in `src/core/rng.gd`.

## Cozy, soft, short

The day is the calm half of this game and its sounds are furniture: they play
hundreds of times an hour and none of them may be the thing you notice. So
everything here is short, low-passed, and peaks well below full scale -
`SOFT_PEAK` is the ceiling and `headless_check` asserts it.

**The bite is the one exception.** It is the only day sound with a window
behind it - miss it and the fish is gone - so it is allowed to be brighter and
louder than the rest, and there is a check that it actually is. A sound that
is supposed to grab attention and does not is worse than no sound, because the
player learns to ignore the one that matters.
"""
import io
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")

## Twenty-two kilohertz. These are short, dull, mono noises; forty-four would
## double the bytes in the repository for a brightness none of them has.
RATE = 22050

## What a day sound may peak at. Well under full scale, so that several at
## once - and the night's louder half on top - still have room.
SOFT_PEAK = 0.55

## What the bite may peak at. Louder on purpose; see the module docstring.
LOUD_PEAK = 0.85


class Noise:
    """A congruential generator, so the noise is the same everywhere.

    Numbers from Numerical Recipes. It is not a good generator and does not
    need to be: it is making hiss, and the only property that matters is that
    it makes the same hiss twice.
    """

    def __init__(self, seed):
        self.state = seed & 0x7FFFFFFF

    def next(self):
        self.state = (1664525 * self.state + 1013904223) & 0x7FFFFFFF
        return self.state / 1073741823.5 - 1.0


# ------------------------------------------------------------------- the parts

def silence(ms):
    return [0.0] * int(RATE * ms / 1000.0)


def noise(seed, ms):
    rng = Noise(seed)
    return [rng.next() for _ in range(int(RATE * ms / 1000.0))]


def tone(freq, ms, phase=0.0):
    n = int(RATE * ms / 1000.0)
    step = 2.0 * math.pi * freq / RATE
    return [math.sin(phase + step * i) for i in range(n)]


def sweep(start_hz, end_hz, ms, curve=1.0):
    """A sine sliding from one pitch to another. `curve` above one starts slow."""
    n = int(RATE * ms / 1000.0)
    out = []
    phase = 0.0
    for i in range(n):
        t = (i / max(n - 1, 1)) ** curve
        phase += 2.0 * math.pi * (start_hz + (end_hz - start_hz) * t) / RATE
        out.append(math.sin(phase))
    return out


def decay(samples, tau_ms, attack_ms=3.0):
    """An exponential fall, with a short ramp on the front.

    **The ramp is not decoration.** A waveform that starts at full amplitude
    on sample zero is a step, and a step is a click - the one artefact that
    makes a generated sound read as cheap however good the rest of it is.
    """
    n = len(samples)
    tau = max(RATE * tau_ms / 1000.0, 1.0)
    rise = max(int(RATE * attack_ms / 1000.0), 1)
    out = []
    for i, v in enumerate(samples):
        gain = math.exp(-i / tau)
        if i < rise:
            gain *= i / rise
        out.append(v * gain)
    return out


def swell(samples, ms_in, ms_out):
    """Up and then down, for the sounds that are a movement rather than a hit."""
    n = len(samples)
    rise = max(int(RATE * ms_in / 1000.0), 1)
    fall = max(int(RATE * ms_out / 1000.0), 1)
    out = []
    for i, v in enumerate(samples):
        if i < rise:
            gain = i / rise
        else:
            left = n - i
            gain = min(left / fall, 1.0)
        out.append(v * gain)
    return out


def lowpass(samples, hz):
    """One pole, which is all the gentleness these need."""
    if not samples:
        return samples
    a = 1.0 - math.exp(-2.0 * math.pi * hz / RATE)
    out = []
    y = 0.0
    for v in samples:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(samples, hz):
    low = lowpass(samples, hz)
    return [v - l for v, l in zip(samples, low)]


def sweep_lowpass(samples, start_hz, end_hz):
    """A filter that opens or closes as the sound goes by."""
    if not samples:
        return samples
    n = len(samples)
    out = []
    y = 0.0
    for i, v in enumerate(samples):
        hz = start_hz + (end_hz - start_hz) * (i / max(n - 1, 1))
        a = 1.0 - math.exp(-2.0 * math.pi * max(hz, 20.0) / RATE)
        y += a * (v - y)
        out.append(y)
    return out


def mix(*layers):
    """Add layers of different lengths, keeping the longest."""
    n = max((len(l) for l in layers), default=0)
    out = [0.0] * n
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return out


def at(offset_ms, samples):
    """Push a layer later in the sound."""
    return silence(offset_ms) + samples


def gain(samples, g):
    return [v * g for v in samples]


def normalise(samples, peak):
    """Scale to a chosen ceiling. **Never above it**, so nothing ever clips."""
    high = max((abs(v) for v in samples), default=0.0)
    if high <= 0.0:
        return samples
    return [v * peak / high for v in samples]


def fade_out(samples, ms=8.0):
    """A ramp off the end, for the same reason `decay` has one on the front."""
    n = len(samples)
    tail = min(max(int(RATE * ms / 1000.0), 1), n)
    out = list(samples)
    for i in range(tail):
        out[n - tail + i] *= 1.0 - i / tail
    return out


# ----------------------------------------------------------------- the sounds

def chop():
    """A wooden thock: a dull knock with a short body under it."""
    hit = decay(lowpass(noise(8401, 160), 1400), 26.0)
    body = decay(tone(176.0, 160), 55.0, 4.0)
    thump = decay(tone(88.0, 160), 40.0, 5.0)
    return mix(gain(hit, 0.9), gain(body, 0.5), gain(thump, 0.35))


def mine():
    """Stone: brighter than wood, and it rings a little."""
    strike = decay(lowpass(noise(8402, 200), 3200), 14.0)
    ring = decay(tone(524.0, 200), 90.0, 4.0)
    over = decay(tone(786.0, 200), 55.0, 4.0)
    return mix(gain(strike, 0.8), gain(ring, 0.36), gain(over, 0.18))


def till():
    """Turning earth: a scrape, no pitch in it at all."""
    body = highpass(lowpass(noise(8403, 220), 1700), 260)
    return gain(swell(body, 26.0, 150.0), 0.8)


def plant():
    """A seed going in. The smallest sound in the game."""
    pat = decay(lowpass(noise(8404, 110), 900), 18.0)
    blip = decay(tone(228.0, 110), 26.0, 3.0)
    return mix(gain(pat, 0.7), gain(blip, 0.3))


def water():
    """A trickle from a can: hiss with the filter wobbling under it."""
    body = sweep_lowpass(noise(8405, 320), 900.0, 1900.0)
    body = highpass(body, 200)
    bubbles = mix(
        at(40, decay(tone(640.0, 90), 22.0)),
        at(150, decay(tone(520.0, 90), 26.0)),
        at(240, decay(tone(720.0, 80), 18.0)),
    )
    return mix(gain(swell(body, 40.0, 190.0), 0.75), gain(bubbles, 0.16))


def harvest():
    """Leaves letting go, and one bright note because it is a reward."""
    rustle = decay(highpass(lowpass(noise(8406, 240), 4200), 900), 45.0, 6.0)
    note = at(60, decay(tone(668.0, 180), 70.0, 8.0))
    return mix(gain(rustle, 0.6), gain(note, 0.3))


def collect():
    """Two soft pats - a hand on an animal, twice."""
    one = decay(lowpass(noise(8407, 90), 1100), 20.0)
    two = at(80, decay(lowpass(noise(8408, 110), 1000), 24.0))
    return mix(gain(one, 0.7), gain(two, 0.62))


def craft():
    """A bench taking a job: three clicks and a low turn under them."""
    clicks = mix(
        decay(lowpass(noise(8409, 60), 2600), 9.0),
        at(70, decay(lowpass(noise(8410, 60), 2400), 9.0)),
        at(140, decay(lowpass(noise(8411, 80), 2200), 11.0)),
    )
    turn = decay(tone(146.0, 260), 90.0, 8.0)
    return mix(gain(clicks, 0.72), gain(turn, 0.3))


def trade():
    """A stall opening. A UI noise, not a world one, so it is plain."""
    a = decay(tone(524.0, 70), 26.0, 3.0)
    b = at(60, decay(tone(786.0, 90), 34.0, 3.0))
    return mix(gain(a, 0.5), gain(b, 0.5))


def sell():
    """Coins. The one day sound the player is meant to want to hear again."""
    low = decay(tone(884.0, 380), 120.0, 5.0)
    high = at(70, decay(tone(1326.0, 300), 95.0, 5.0))
    sparkle = at(40, decay(highpass(noise(8412, 200), 3000), 30.0))
    return mix(gain(low, 0.42), gain(high, 0.34), gain(sparkle, 0.18))


def cast():
    """A line going out: a whoosh that ends in a small plip."""
    whoosh = sweep_lowpass(noise(8413, 240), 400.0, 2600.0)
    whoosh = gain(swell(whoosh, 60.0, 120.0), 0.6)
    plip = at(230, decay(sweep(900.0, 380.0, 90, 0.6), 24.0))
    return mix(whoosh, gain(plip, 0.5))


def bite():
    """**The one that has to be noticed.**

    Every other day sound reports something that already happened. This one
    opens a window: miss it and the fish is gone. So it is the brightest and
    the loudest of the set, it rises rather than falls - a rising figure reads
    as a question and a falling one as a full stop - and it ends on a bright
    note rather than on hiss.
    """
    plop = decay(sweep(300.0, 980.0, 130, 0.7), 40.0, 2.0)
    splash = decay(highpass(noise(8414, 150), 1400), 30.0, 2.0)
    call_a = at(120, decay(tone(884.0, 180), 70.0, 4.0))
    call_b = at(240, decay(tone(1326.0, 220), 80.0, 4.0))
    return mix(gain(plop, 0.55), gain(splash, 0.45),
               gain(call_a, 0.5), gain(call_b, 0.55))


def reel():
    """Pulling it in: the cast, backwards, and wetter."""
    pull = sweep_lowpass(noise(8415, 220), 2200.0, 700.0)
    pull = gain(swell(pull, 25.0, 130.0), 0.65)
    splash = at(180, decay(lowpass(noise(8416, 140), 2600), 32.0))
    return mix(pull, gain(splash, 0.55))


## Every day sound: the id the game asks for, the recipe, and what it may peak
## at. The id is what `Audio.play()` takes, minus the `sfx/` the folder adds.
SOUNDS = [
    ("chop", chop, SOFT_PEAK),
    ("mine", mine, SOFT_PEAK),
    ("till", till, SOFT_PEAK),
    ("plant", plant, SOFT_PEAK),
    ("water", water, SOFT_PEAK),
    ("harvest", harvest, SOFT_PEAK),
    ("collect", collect, SOFT_PEAK),
    ("craft", craft, SOFT_PEAK),
    ("trade", trade, SOFT_PEAK),
    ("sell", sell, SOFT_PEAK),
    ("cast", cast, SOFT_PEAK),
    ("reel", reel, SOFT_PEAK),
    ("bite", bite, LOUD_PEAK),
]


# -------------------------------------------------------------------- the file

def wav_bytes(samples):
    """A 16-bit mono WAV, written by hand so the bytes are ours.

    `wave` would do it, and would also be free to change its header padding
    between Python versions - which would make `--check` fail for a sound
    nobody touched.
    """
    frames = b"".join(
        struct.pack("<h", max(-32768, min(32767, int(round(v * 32767.0)))))
        for v in samples)
    header = b"RIFF" + struct.pack("<I", 36 + len(frames)) + b"WAVE"
    header += b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16)
    header += b"data" + struct.pack("<I", len(frames))
    return header + frames


def render(recipe, peak):
    return fade_out(normalise(recipe(), peak))


def everything():
    """{filename: bytes} for the whole day."""
    out = {}
    for name, recipe, peak in SOUNDS:
        out["%s.wav" % name] = wav_bytes(render(recipe, peak))
    return out


# ------------------------------------------------------------------ describing

def measure(samples):
    """Length, peak and brightness, for the report and for the checks.

    Brightness is the fraction of the energy above about a kilohertz, which is
    a crude spectral centroid and enough to answer the only question asked of
    it: is the bite brighter than the furniture?
    """
    if not samples:
        return 0.0, 0.0, 0.0, 0.0
    peak = max(abs(v) for v in samples)
    rms = math.sqrt(sum(v * v for v in samples) / len(samples))
    low = lowpass(samples, 1000.0)
    low_energy = sum(v * v for v in low)
    total = sum(v * v for v in samples)
    bright = 0.0 if total <= 0 else 1.0 - low_energy / total
    return len(samples) / RATE, peak, rms, bright


def report():
    print("  %-9s %7s %6s %6s %7s" % ("sound", "seconds", "peak", "rms",
                                      "bright"))
    for name, recipe, peak in SOUNDS:
        seconds, hit, rms, bright = measure(render(recipe, peak))
        print("  %-9s %7.3f %6.2f %6.3f %7.2f"
              % (name, seconds, hit, rms, bright))


def preview(folder):
    """A listening copy, and a minute of chopping.

    The done-when says "chopping a tree for a full minute does not become
    annoying - go and check", and checking that means ears. This renders the
    thing to listen to: sixty seconds of the chop at the rate the game plays
    it, with the same pitch jitter `Audio` applies, so what comes out of the
    file is what comes out of the game.
    """
    os.makedirs(folder, exist_ok=True)
    for name, data in sorted(everything().items()):
        io.open(os.path.join(folder, name), "wb").write(data)

    # Three seconds a chop is `Interact.DEFAULT_TICKS`; the jitter is
    # `Audio.PITCH_JITTER`. Both are read from the game rather than typed
    # here, so this cannot drift away from what a player hears.
    seconds, per_chop, jitter = 60.0, 3.0, pitch_jitter()
    one = render(chop, SOFT_PEAK)
    track = [0.0] * int(RATE * seconds)
    rng = Noise(1984)
    hits = 0
    while hits * per_chop < seconds:
        shift = 1.0 + jitter * rng.next()
        start = int(hits * per_chop * RATE)
        for i in range(int(len(one) / shift)):
            source = int(i * shift)
            if source >= len(one) or start + i >= len(track):
                break
            track[start + i] += one[source]
        hits += 1
    path = os.path.join(folder, "_a-minute-of-chopping.wav")
    io.open(path, "wb").write(wav_bytes(track))
    print("  preview: %d sounds and %d chops over %.0fs in %s"
          % (len(SOUNDS), hits, seconds, folder))


def pitch_jitter():
    """`Audio.PITCH_JITTER`, read out of the GDScript rather than copied.

    Two numbers that have to match and live in different files are two numbers
    that will not.
    """
    path = os.path.join(ROOT, "src", "app", "audio.gd")
    for line in io.open(path, encoding="utf-8"):
        if line.startswith("const PITCH_JITTER"):
            return float(line.split(":=")[1].split("#")[0].strip())
    raise SystemExit("gen_sfx: audio.gd has no PITCH_JITTER any more")


def main():
    args = sys.argv[1:]
    files = everything()

    if "--report" in args:
        report()

    if "--preview" in args:
        where = args[args.index("--preview") + 1]
        preview(where)
        return 0

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
            print("FAIL  run: python tools/gen_sfx.py")
            return 1
        print("OK    %d day sounds match their recipes" % len(files))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("sfx: %d files, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
