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

**And the moments are not furniture** (task 0281). Going to bed, waking at
06:00, passing out at 02:00, the morning's payout, the stall's bell and a
tool handed over happen once or twice a day rather than hundreds of times an
hour, so `MOMENT_SOUNDS` may run longer and a touch louder than the
furniture - and stays under the alarm. The bite is still the one day sound
built to grab you.

## The night is the other half, and it is louder

Task 0085 adds the defences, the enemies and the four things that happen to
them. It is deliberately harsher: `design.md` promises two realities on the
same tiles, and a player with their eyes shut should know which one they are
in. Above the night sits one more tier - **the house being hit is the loudest
sound in the game**, because it is the only one that means you are losing.

Each enemy gets its **own** voice rather than a shared groan, because "fifty
zombies do not turn into noise" is a done-when and five voices at five
pitches is most of how it is met. The rest is in `Audio`: a distance falloff
and a minimum gap between two plays of the same sound.
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

## What the night peaks at. **The loud half of the game**: a shot has to cut
## through a wave, and the design document's two realities are meant to feel
## different before you have looked at the screen.
NIGHT_PEAK = 0.70

## **The guardian's night** (task 0283): the START horn, the four powers, the
## dog and the defences that are not guns. Under the weapons' `NIGHT_PEAK`:
## they mark what the cursor did or what a defence is doing, and the shots
## and the house stay the things that cut through. The cursor's own hand -
## place, upgrade, repair, sell - is quieter still, at `SOFT_PEAK`.
GUARDIAN_PEAK = 0.62

## **The wraith's whisper** (task 0284): heard with no position, so it says
## they are out and not where - and quiet, because it is the one voice that
## gives nothing away.
WHISPER_PEAK = 0.45

## The Giant, which is allowed to be bigger than everything except the alarm.
GIANT_PEAK = 0.88

## **What a moment may peak at** (task 0281): going to bed, waking, passing
## out, the morning's payout, the stall's bell and a tool handed over. These
## happen once or twice a day, not hundreds of times an hour, so they are
## allowed to be longer than the furniture and a touch above it - and stay
## well under the alarm, which `headless_v1` asserts.
MOMENT_PEAK = 0.60

## **What the fishing bar's tick may peak at** (task 0282). It comes round
## once a sweep while the bar runs, so it sits under the rest of the
## furniture: a cue, not an event.
TICK_PEAK = 0.35

## What a menu sound may peak at: the quietest tier in the game. These are heard
## every time a selection moves, and a menu that clicks louder than an axe on a
## tree is a menu somebody turns the sound off for.
UI_PEAK = 0.30

## **The house being hit, which is the loudest sound in the game.** It is the
## only one that means you are losing, and `headless_check` asserts that
## nothing else reaches it.
ALARM_PEAK = 0.95


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


# ----------------------------------------------------- the new day (task 0281)
#
# Every verb 0165-0195 added borrowed a file to keep `_task_0084_day_sounds`
# green; these are their own. All of them are furniture - short, soft, under
# the bite - except the moments further down.

def dig():
    """A pig's truffle dug up: two scoops of soil and a little pop as it comes
    free. The collect sound's two pats were a hand on an animal; this is a
    snout in the ground."""
    scoop_a = decay(lowpass(noise(8601, 140), 1300), 30.0, 4.0)
    scoop_b = at(110, decay(lowpass(noise(8602, 150), 1200), 34.0, 4.0))
    pop = at(230, decay(sweep(260.0, 520.0, 90, 0.6), 22.0, 2.0))
    return mix(gain(scoop_a, 0.7), gain(scoop_b, 0.65), gain(pop, 0.35))


def ship():
    """The shipping bin: the lid lifted on its hinge, the goods dropped in, the
    lid down. Not the stall's coins - nothing is paid until dawn."""
    creak = decay(sweep(240.0, 180.0, 120, 0.8), 50.0, 10.0)
    drop = at(110, decay(lowpass(noise(8603, 120), 1600), 26.0, 2.0))
    thunk = at(250, decay(tone(118.0, 150), 40.0, 3.0))
    knock = at(250, decay(lowpass(noise(8604, 100), 900), 18.0, 1.0))
    return mix(gain(creak, 0.3), gain(drop, 0.6), gain(thunk, 0.55),
               gain(knock, 0.5))


def fertilise():
    """Bone meal over a furrow: a dry sprinkle of grains, then the soft pat
    of the hand pressing it in."""
    sprinkle = swell(highpass(lowpass(noise(8605, 260), 5200), 2000),
                     20.0, 180.0)
    grains = mix(*[at(30 + 45 * k,
                      decay(highpass(noise(8606 + k, 40), 2600), 6.0, 1.0))
                   for k in range(4)])
    pat = at(200, decay(lowpass(noise(8611, 110), 900), 18.0))
    return mix(gain(sprinkle, 0.35), gain(grains, 0.4), gain(pat, 0.6))


def _ore(seed, ring_hz, ring_tau, over_gain, strike_hz, ms):
    """`mine`'s strike and ring, retuned: the cliff's metals ring, stone
    barely does."""
    strike = decay(lowpass(noise(seed, ms), strike_hz), 14.0)
    ring = decay(tone(ring_hz, ms), ring_tau, 4.0)
    over = decay(tone(ring_hz * 1.5, ms), ring_tau * 0.6, 4.0)
    return mix(gain(strike, 0.8), gain(ring, 0.36), gain(over, over_gain))


def mine_copper():
    """Copper: a warmer ring than stone, lower and longer."""
    return _ore(8612, 392.0, 120.0, 0.2, 2800, 260)


def mine_coal():
    """Coal: it crumbles rather than rings - a soft crunch with almost no
    note in it."""
    crunch = decay(lowpass(noise(8613, 220), 1800), 22.0)
    grit = at(60, decay(lowpass(noise(8614, 160), 2400), 30.0))
    note = decay(tone(262.0, 200), 40.0, 4.0)
    return mix(gain(crunch, 0.8), gain(grit, 0.5), gain(note, 0.12))


def mine_gold():
    """Gold: the brightest strike on the cliff, a high clear ring - a reward
    as much as a rock."""
    return _ore(8615, 784.0, 140.0, 0.28, 4200, 320)


def keg():
    """A keg taking its fruit: a knock on the staves and a glug inside."""
    knock = decay(lowpass(noise(8616, 120), 900), 20.0, 1.0)
    staves = decay(tone(132.0, 200), 60.0, 3.0)
    glug = mix(at(130, decay(sweep(220.0, 340.0, 80, 0.8), 26.0, 4.0)),
               at(220, decay(sweep(180.0, 300.0, 90, 0.8), 28.0, 4.0)))
    return mix(gain(knock, 0.6), gain(staves, 0.45), gain(glug, 0.45))


def preserves_jar():
    """A jar: glass touching glass, then the lid turned down."""
    clink = decay(tone(1568.0, 160), 40.0, 1.0)
    clink_over = decay(tone(2350.0, 160), 28.0, 1.0)
    twist = at(150, swell(highpass(lowpass(noise(8617, 200), 3000), 800),
                          30.0, 120.0))
    return mix(gain(clink, 0.4), gain(clink_over, 0.22), gain(twist, 0.4))


def dairy():
    """A churn: milk sloshing against the wood, there and back."""
    there = swell(sweep_lowpass(noise(8618, 180), 500.0, 1400.0), 40.0, 110.0)
    back = at(190, swell(sweep_lowpass(noise(8619, 200), 1400.0, 500.0),
                         40.0, 130.0))
    body = decay(tone(98.0, 380), 140.0, 20.0)
    return mix(gain(there, 0.6), gain(back, 0.6), gain(body, 0.3))


def loom():
    """A loom: the shuttle across and the beater home - clack, clack, clack."""
    clacks = mix(decay(lowpass(noise(8620, 70), 2200), 10.0, 1.0),
                 at(150, decay(lowpass(noise(8621, 70), 2000), 10.0, 1.0)),
                 at(300, decay(lowpass(noise(8622, 90), 1800), 12.0, 1.0)))
    shuttle = at(30, swell(highpass(lowpass(noise(8623, 110), 2600), 700),
                           20.0, 70.0))
    frame = decay(tone(196.0, 380), 120.0, 6.0)
    return mix(gain(clacks, 0.75), gain(shuttle, 0.35), gain(frame, 0.2))


def mill():
    """A millstone: stone on stone, a low grinding turn."""
    grind = swell(lowpass(noise(8624, 420), 700), 60.0, 160.0)
    rumble = swell(sweep(70.0, 82.0, 420, 1.0), 60.0, 160.0)
    grit = mix(*[at(60 + 90 * k,
                    decay(highpass(noise(8625 + k, 40), 1500), 8.0, 1.0))
                 for k in range(4)])
    return mix(gain(grind, 0.7), gain(rumble, 0.45), gain(grit, 0.2))


def anvil():
    """A tool upgrade at the smith's: one ring off an anvil - metal on metal,
    an inharmonic partial over it, which is what stops it being a bell."""
    strike = decay(highpass(noise(8629, 60), 2500), 6.0, 0.5)
    ring = decay(tone(1046.0, 420), 160.0, 1.0)
    partial = decay(tone(2793.0, 420), 70.0, 1.0)
    low = decay(tone(523.0, 420), 120.0, 1.0)
    return mix(gain(strike, 0.6), gain(ring, 0.4), gain(partial, 0.22),
               gain(low, 0.2))


# ------------------------------------------------- the bar (task 0282)
#
# 0180's minigame, by ear. All furniture: the bite opens the window and these
# only follow it, so it stays the loudest and longest day sound.

def fish_tick():
    """The marker entering the green: a small dry tick - the moment to press.
    The cue is the green, not the turn at an end of the bar, which would be a
    metronome that says nothing about the fish."""
    click = decay(highpass(noise(8701, 40), 2400), 4.0, 0.5)
    pip = decay(tone(1760.0, 40), 8.0, 0.5)
    return mix(gain(click, 0.6), gain(pip, 0.5))


def fish_hit():
    """A press in the green: the line goes taut - a plucked tug that rises."""
    twang = decay(sweep(330.0, 560.0, 140, 0.5), 50.0, 1.5)
    over = decay(sweep(660.0, 1120.0, 140, 0.5), 30.0, 1.5)
    wet = decay(highpass(noise(8702, 90), 1800), 18.0, 1.0)
    return mix(gain(twang, 0.6), gain(over, 0.25), gain(wet, 0.3))


def fish_miss():
    """A press outside it: slack line, a dull plunk that falls."""
    plunk = decay(sweep(300.0, 150.0, 180, 0.6), 50.0, 2.0)
    slack = decay(lowpass(noise(8703, 140), 900), 30.0, 3.0)
    return mix(gain(plunk, 0.55), gain(slack, 0.45))


def fish_catch():
    """The fish out of the water and in the hand: a wet slap, a flop, and two
    rising notes - the reward, as the harvest's one note is."""
    slap = decay(lowpass(noise(8704, 120), 2400), 16.0, 1.0)
    flop = at(110, decay(lowpass(noise(8705, 100), 1600), 20.0, 1.0))
    low = at(60, decay(tone(784.0, 200), 70.0, 4.0))
    high = at(170, decay(tone(1175.0, 240), 80.0, 4.0))
    return mix(gain(slap, 0.6), gain(flop, 0.45), gain(low, 0.3),
               gain(high, 0.32))


# ------------------------------------------------- the moments (task 0281)
#
# Once or twice a day each, so they are allowed to be longer than the
# furniture, and `MOMENT_PEAK` - under the alarm, which stays the loudest.

def bed():
    """Under the blanket: cloth drawn up, and a long breath out."""
    cloth = swell(highpass(lowpass(noise(8630, 520), 2600), 300), 120.0, 300.0)
    sigh = at(300, swell(lowpass(noise(8631, 600), 600), 120.0, 420.0))
    hum = at(320, swell(sweep(196.0, 147.0, 560, 0.8), 160.0, 380.0))
    return mix(gain(cloth, 0.55), gain(sigh, 0.45), gain(hum, 0.18))


def wake():
    """06:00: a stretch - a breath in that rises, and a small bright note for
    the day starting."""
    breath = swell(sweep_lowpass(noise(8632, 560), 400.0, 1500.0), 220.0, 220.0)
    rise = swell(sweep(220.0, 330.0, 520, 1.2), 200.0, 200.0)
    note = at(500, decay(tone(659.0, 300), 110.0, 10.0))
    return mix(gain(breath, 0.5), gain(rise, 0.22), gain(note, 0.25))


def pass_out():
    """02:00 and he drops where he stands: a body on the ground, a last
    breath out. Falling, where the bed's sigh is lying down."""
    thud = decay(sweep(140.0, 50.0, 300, 0.5), 80.0, 2.0)
    ground = decay(lowpass(noise(8633, 220), 700), 40.0, 1.0)
    breath = at(220, swell(lowpass(noise(8634, 420), 500), 60.0, 300.0))
    return mix(gain(thud, 0.8), gain(ground, 0.6), gain(breath, 0.25))


def payout():
    """The bin paid at dawn: a purse's worth of coins at once - **one sound
    for the whole sale**, never one a coin, and not the stall's two-note sale."""
    coins = mix(*[at(ms, decay(tone(hz, 260), 70.0, 2.0))
                  for ms, hz in [(0, 1326.0), (70, 1580.0), (130, 1180.0),
                                 (200, 1770.0), (290, 1490.0)]])
    jingle = at(20, decay(highpass(noise(8635, 420), 3200), 90.0, 4.0))
    return mix(gain(coins, 0.3), gain(jingle, 0.2))


def stall_bell():
    """The peddler's handbell, rung twice: his hours begin, or they end."""
    def ring(ms):
        return at(ms, mix(decay(tone(1318.0, 620), 220.0, 1.0),
                          gain(decay(tone(3302.0, 620), 90.0, 1.0), 0.4),
                          gain(decay(tone(2093.0, 620), 150.0, 1.0), 0.3)))
    return mix(ring(0), ring(260))


def tool_ready():
    """The upgraded tool handed over in the morning: a bright, clean ting -
    the anvil's work, finished."""
    ting = decay(tone(1760.0, 640), 200.0, 1.0)
    over = decay(tone(3520.0, 640), 110.0, 1.0)
    shimmer = at(30, decay(highpass(noise(8636, 300), 4000), 60.0, 2.0))
    return mix(gain(ting, 0.6), gain(over, 0.25), gain(shimmer, 0.12))


# ------------------------------------------------------------- the defences

def shot_gun():
    """A rifle crack. Short, hard, and the loudest thing on the farm bar one."""
    crack = decay(highpass(noise(8501, 140), 700), 11.0, 1.0)
    body = decay(lowpass(noise(8502, 140), 1800), 26.0, 1.0)
    thump = decay(sweep(190.0, 70.0, 120, 0.5), 32.0, 2.0)
    return mix(gain(crack, 0.85), gain(body, 0.5), gain(thump, 0.45))


def shot_bolt():
    """A crossbow: the string, then the air. No powder in it at all."""
    string = decay(sweep(900.0, 320.0, 90, 0.5), 18.0, 1.5)
    air = decay(highpass(lowpass(noise(8503, 130), 5200), 1800), 24.0, 2.0)
    return mix(gain(string, 0.6), gain(air, 0.55))


def flame():
    """A flamethrower: no transient worth the name, all breath."""
    body = sweep_lowpass(noise(8504, 420), 600.0, 2400.0)
    body = highpass(body, 220)
    roar = decay(lowpass(noise(8505, 420), 420), 260.0, 40.0)
    return mix(gain(swell(body, 70.0, 220.0), 0.8), gain(roar, 0.45))


def mortar():
    """A mortar: the thump you feel, then the whistle going away."""
    thump = decay(sweep(150.0, 44.0, 220, 0.4), 70.0, 3.0)
    blast = decay(lowpass(noise(8506, 200), 900), 40.0, 2.0)
    whistle = at(120, decay(sweep(1500.0, 900.0, 260, 1.4), 110.0, 30.0))
    return mix(gain(thump, 0.8), gain(blast, 0.5), gain(whistle, 0.22))


def mine_blast():
    """A mine going off under something. All bottom end and grit."""
    boom = decay(sweep(210.0, 38.0, 380, 0.35), 95.0, 1.5)
    grit = decay(lowpass(noise(8507, 260), 2400), 50.0, 1.0)
    return mix(gain(boom, 0.85), gain(grit, 0.55))


# ------------------------------------------------- the guardian (task 0283)
#
# The night is played through the cursor. Its hand is furniture-quiet; the
# horn, the powers and the defences that do not shoot sit under the guns.

def place():
    """A defence set down by the cursor: wood on the ground and a peg in."""
    knock = decay(lowpass(noise(8801, 140), 1200), 22.0, 1.0)
    body = decay(tone(147.0, 200), 60.0, 3.0)
    peg = at(90, decay(highpass(noise(8802, 50), 1800), 8.0, 0.5))
    return mix(gain(knock, 0.7), gain(body, 0.4), gain(peg, 0.45))


def upgrade():
    """A level up: a ratchet's three clicks and two notes rising a fifth."""
    clicks = mix(*[at(40 * k, decay(highpass(noise(8803 + k, 40), 2200),
                                    5.0, 0.5)) for k in range(3)])
    low = at(110, decay(tone(523.0, 200), 70.0, 3.0))
    high = at(190, decay(tone(784.0, 220), 80.0, 3.0))
    return mix(gain(clicks, 0.5), gain(low, 0.35), gain(high, 0.38))


def mend():
    """A repair: three taps of a hammer on a nail, the last one home."""
    taps = mix(*[at(110 * k, decay(mix(gain(tone(880.0 - 60 * k, 60), 0.5),
                                       lowpass(noise(8806 + k, 60), 2600)),
                                   12.0, 0.5)) for k in range(3)])
    return gain(taps, 0.8)


def sell_back():
    """A defence taken back: a pull and the money coming home, falling -
    the build undone, not the stall's bright sale."""
    pull = decay(lowpass(noise(8809, 120), 900), 26.0, 2.0)
    a = at(40, decay(tone(1175.0, 160), 50.0, 2.0))
    b = at(120, decay(tone(880.0, 200), 60.0, 2.0))
    return mix(gain(pull, 0.5), gain(a, 0.35), gain(b, 0.35))


def horn():
    """**START**: a low horn call, a fifth and back - once a night, heard
    everywhere, the waves on their way."""
    a = swell(mix(tone(147.0, 520), gain(tone(294.0, 520), 0.3),
                  gain(tone(441.0, 520), 0.12)), 60.0, 160.0)
    b = at(420, swell(mix(tone(220.0, 640), gain(tone(440.0, 640), 0.3),
                          gain(tone(660.0, 640), 0.12)), 60.0, 300.0))
    breath = swell(lowpass(noise(8810, 1060), 500), 80.0, 300.0)
    return mix(lowpass(mix(a, b), 1600.0), gain(breath, 0.12))


def power_flare():
    """The flare: a whoosh going up, the pop, and the crackle of it burning."""
    whoosh = sweep_lowpass(noise(8811, 260), 600.0, 3600.0)
    whoosh = swell(highpass(whoosh, 300), 60.0, 80.0)
    pop = at(240, decay(lowpass(noise(8812, 120), 2400), 16.0, 0.5))
    crackle = at(260, mix(*[at(45 * k, decay(highpass(noise(8813 + k, 30),
                                                      2600), 4.0, 0.5))
                            for k in range(7)]))
    return mix(gain(whoosh, 0.5), gain(pop, 0.8), gain(crackle, 0.4))


def farm_bell():
    """The farm bell: one big clang that stops every zombie on the farm -
    low, wide and long, heard everywhere."""
    def partial(hz, tau, g):
        return gain(decay(tone(hz, 1200), tau, 1.0), g)
    clang = decay(highpass(noise(8820, 60), 1500), 8.0, 0.5)
    return mix(gain(clang, 0.4), partial(392.0, 420.0, 0.6),
               partial(787.0, 300.0, 0.3), partial(1068.0, 200.0, 0.2),
               partial(1560.0, 140.0, 0.12))


def dog_bark():
    """The dog called: two barks, the second higher."""
    def bark(seed, hz):
        voice = decay(sweep(hz, hz * 0.7, 130, 0.6), 40.0, 2.0)
        rasp = decay(lowpass(noise(seed, 130), 2000), 30.0, 2.0)
        return mix(gain(voice, 0.6), gain(rasp, 0.5))
    return mix(bark(8821, 420.0), at(200, bark(8822, 520.0)))


def dog_bite():
    """The bite landing: a snarl and the snap of the jaws."""
    snarl = swell(mix(lowpass(noise(8823, 220), 900),
                      gain(sweep(160.0, 210.0, 220, 1.0), 0.4)), 30.0, 80.0)
    snap = at(200, decay(highpass(noise(8824, 60), 1600), 6.0, 0.5))
    return mix(gain(snarl, 0.6), gain(snap, 0.8))


def power_mend():
    """The emergency repair: a warm rising shimmer, and the work done at once."""
    shimmer = mix(*[at(60 * k, decay(tone(523.0 * (1.0 + 0.25 * k), 300),
                                     120.0, 4.0)) for k in range(4)])
    knock = at(260, decay(lowpass(noise(8825, 120), 1400), 20.0, 1.0))
    return mix(gain(shimmer, 0.3), gain(knock, 0.5))


def straw():
    """The decoy bitten: a straw rustle and a dull thump of stuffing."""
    rustle = swell(highpass(lowpass(noise(8826, 220), 4200), 1200), 15.0, 150.0)
    thump = decay(lowpass(noise(8827, 120), 500), 26.0, 2.0)
    return mix(gain(rustle, 0.6), gain(thump, 0.5))


def buzz():
    """A beehive's swarm: a buzzing chord with a wobble in it - per kind, from
    the nearest stinging hive, so ten hives are one swarm."""
    n = int(RATE * 0.6)
    out = []
    for i in range(n):
        t = i / RATE
        wobble = 1.0 + 0.35 * math.sin(2.0 * math.pi * 11.0 * t)
        v = (math.sin(2.0 * math.pi * 220.0 * t) * 0.5
             + math.sin(2.0 * math.pi * 227.0 * t) * 0.4
             + math.sin(2.0 * math.pi * 441.0 * t) * 0.25)
        out.append(v * wobble)
    return swell(lowpass(mix(out, gain(noise(8828, 600), 0.2)), 2200.0),
                 80.0, 200.0)


def catapult():
    """The catapult: the arm's creak and the thunk of it hitting its stop."""
    creak = decay(sweep(260.0, 200.0, 140, 0.8), 60.0, 8.0)
    thunk = at(110, decay(lowpass(noise(8829, 160), 700), 30.0, 1.0))
    wood = at(110, decay(tone(110.0, 220), 70.0, 3.0))
    return mix(gain(creak, 0.3), gain(thunk, 0.7), gain(wood, 0.5))


def splat():
    """A pumpkin landing: a wet burst and the pieces."""
    burst = decay(lowpass(noise(8830, 200), 1800), 30.0, 1.0)
    low = decay(sweep(180.0, 70.0, 160, 0.5), 40.0, 1.0)
    bits = mix(*[at(60 + 50 * k, decay(lowpass(noise(8831 + k, 50), 2200),
                                       8.0, 0.5)) for k in range(3)])
    return mix(gain(burst, 0.7), gain(low, 0.5), gain(bits, 0.3))


def hum():
    """The searchlight's hum: mains and its harmonics, swelling in and out -
    per kind, from the nearest lit lamp."""
    body = mix(tone(60.0, 900), gain(tone(120.0, 900), 0.6),
               gain(tone(180.0, 900), 0.3), gain(tone(240.0, 900), 0.15))
    fizz = gain(highpass(noise(8834, 900), 3000), 0.04)
    return swell(mix(body, fizz), 250.0, 350.0)


def zap():
    """The electric fence biting back: a crackle and a sharp buzz."""
    crackle = mix(*[at(25 * k, decay(highpass(noise(8835 + k, 30), 3000),
                                     3.0, 0.3)) for k in range(6)])
    buzz_ = decay(mix(tone(240.0, 260), gain(tone(480.0, 260), 0.5),
                      gain(tone(720.0, 260), 0.3)), 80.0, 1.0)
    return mix(gain(crackle, 0.6), gain(buzz_, 0.4))


# -------------------------------------------------------------- the enemies

def _groan(seed, low_hz, high_hz, ms, rasp_hz, curve=1.0):
    """One voice. Five of these at five pitches is most of the done-when.

    A groan is a pitch wandering downward with noise dragged along under it -
    a sine alone reads as a machine, and noise alone reads as wind.
    """
    voice = sweep(low_hz, high_hz, ms, curve)
    breath = lowpass(noise(seed, ms), rasp_hz)
    both = mix(gain(voice, 0.7), gain(breath, 0.45))
    return swell(both, ms * 0.18, ms * 0.55)


def groan_walker():
    """The common one, and therefore the one that must not grate."""
    return _groan(8510, 190.0, 132.0, 620, 900)


def groan_runner():
    """Higher and shorter: something in a hurry."""
    return _groan(8511, 330.0, 268.0, 360, 1600)


def groan_tank():
    """The bottom of the register, and slow with it."""
    return _groan(8512, 104.0, 74.0, 900, 520)


def groan_breaker():
    """Mid, with more grit than voice - it is here to chew through a wall."""
    return _groan(8513, 240.0, 168.0, 520, 2200)


def roar_giant():
    """**Heard before it is seen.**

    The lowest and longest thing in the game and the only enemy sound that
    ignores the distance falloff, because the whole point of it is that it
    reaches you from the far fence. It *rises* where every other groan falls,
    which is what makes it read as something arriving rather than something
    dying.
    """
    body = sweep(58.0, 96.0, 1400, 1.3)
    growl = sweep(29.0, 48.0, 1400, 1.3)
    breath = lowpass(noise(8514, 1400), 700)
    both = mix(gain(body, 0.62), gain(growl, 0.4), gain(breath, 0.32))
    return swell(both, 260.0, 520.0)


# ------------------------------------------- the new enemies (task 0284)
#
# A voice each, so a night heard with your eyes shut still says what is
# coming, and the things they do that a player has to know about.

def voice_spitter():
    """The spitter: a wet gurgle in the throat, saving it up."""
    gurgle = sweep_lowpass(noise(8901, 520), 500.0, 1400.0)
    bubbles = mix(*[at(60 + 70 * k, decay(sweep(260.0 + 30 * k, 180.0, 60, 0.6),
                                          18.0, 2.0)) for k in range(6)])
    voice = sweep(170.0, 140.0, 520, 1.0)
    return swell(mix(gain(gurgle, 0.5), gain(bubbles, 0.35), gain(voice, 0.4)),
                 80.0, 220.0)


def spit():
    """A glob leaving: a hawk in the throat and the air it goes through."""
    hawk = decay(lowpass(noise(8902, 120), 1600), 30.0, 3.0)
    flight = at(80, swell(highpass(lowpass(noise(8903, 160), 3200), 900),
                          20.0, 100.0))
    return mix(gain(hawk, 0.7), gain(flight, 0.4))


def spit_splat():
    """A glob landing on a tower: a wet slap, and it sizzles."""
    slap = decay(lowpass(noise(8904, 120), 2200), 16.0, 0.5)
    sizzle = at(40, swell(highpass(noise(8905, 260), 3500), 20.0, 200.0))
    return mix(gain(slap, 0.7), gain(sizzle, 0.35))


def squeak():
    """A rat: two quick squeaks - one voice for the whole swarm."""
    a = decay(sweep(2400.0, 3100.0, 70, 0.5), 22.0, 2.0)
    b = at(110, decay(sweep(2600.0, 3400.0, 80, 0.5), 24.0, 2.0))
    scuffle = decay(highpass(lowpass(noise(8906, 240), 4000), 1500), 60.0, 4.0)
    return mix(gain(a, 0.5), gain(b, 0.5), gain(scuffle, 0.25))


def caw():
    """A crow: a caw over the beat of its wings."""
    call = swell(mix(sweep(820.0, 600.0, 260, 0.8),
                     gain(sweep(1640.0, 1200.0, 260, 0.8), 0.5),
                     gain(lowpass(noise(8907, 260), 2600), 0.6)), 20.0, 120.0)
    wings = mix(*[at(300 + 70 * k, decay(lowpass(noise(8908 + k, 50), 700),
                                         10.0, 2.0)) for k in range(3)])
    return mix(gain(call, 0.6), gain(wings, 0.5))


def rumble():
    """A digger under the ground: earth moving, low and slow."""
    earth = swell(lowpass(noise(8911, 720), 260), 160.0, 260.0)
    grind = swell(sweep(48.0, 62.0, 720, 1.0), 160.0, 260.0)
    return mix(gain(earth, 0.8), gain(grind, 0.5))


def burst():
    """A digger surfacing: the ground breaking open and the clods falling."""
    crack = decay(lowpass(noise(8912, 160), 1400), 26.0, 1.0)
    thump = decay(sweep(140.0, 60.0, 180, 0.5), 50.0, 1.0)
    clods = mix(*[at(90 + 60 * k, decay(lowpass(noise(8913 + k, 60), 1600),
                                        10.0, 0.5)) for k in range(4)])
    return mix(gain(crack, 0.6), gain(thump, 0.6), gain(clods, 0.4))


def voice_frost():
    """The frost zombie: a moan with frost in it, thin and cold."""
    moan = sweep(260.0, 200.0, 680, 1.0)
    breath = highpass(lowpass(noise(8917, 680), 4200), 1800)
    glint = mix(*[at(150 + 160 * k, decay(tone(2093.0 + 210 * k, 120), 40.0, 2.0))
                  for k in range(3)])
    return swell(mix(gain(moan, 0.5), gain(breath, 0.3), gain(glint, 0.15)),
                 120.0, 360.0)


def shatter():
    """A frost zombie dying: ice breaking into pieces."""
    crack = decay(highpass(noise(8920, 100), 2400), 10.0, 0.5)
    shards = mix(*[at(30 + 45 * k, decay(tone(2600.0 + 380 * (k % 4), 140), 30.0, 0.5))
                   for k in range(7)])
    return mix(gain(crack, 0.6), gain(shards, 0.3))


def crackle():
    """Frost on a tower: a dry crackle spreading over it."""
    return mix(*[at(30 * k, decay(highpass(noise(8921 + k, 40), 3200), 5.0, 0.5))
                 for k in range(8)])


def whisper():
    """The wraith: a breath of a voice, no pitch, from nowhere."""
    air = sweep_lowpass(noise(8930, 820), 2400.0, 5200.0)
    air = highpass(air, 1500)
    wobble = sweep_lowpass(noise(8931, 820), 5200.0, 2400.0)
    return swell(mix(gain(air, 0.6), gain(highpass(wobble, 1500), 0.4)),
                 240.0, 360.0)


def charge():
    """The Harvester winding up its charge: the engine revving, rising."""
    rev = sweep(70.0, 190.0, 620, 1.4)
    teeth = sweep(140.0, 380.0, 620, 1.4)
    clatter = lowpass(noise(8932, 620), 1400)
    return swell(mix(gain(rev, 0.6), gain(teeth, 0.25), gain(clatter, 0.35)),
                 80.0, 120.0)


def crunch():
    """A wall going under the Harvester: crushed, not broken."""
    crush = decay(lowpass(noise(8933, 320), 1100), 70.0, 1.0)
    bend = decay(sweep(200.0, 70.0, 300, 0.6), 80.0, 1.0)
    bits = mix(*[at(60 + 50 * k, decay(lowpass(noise(8934 + k, 60), 2400), 10.0, 0.5))
                 for k in range(5)])
    return mix(gain(crush, 0.7), gain(bend, 0.5), gain(bits, 0.35))


def summon():
    """The Scarecrow King calling crows down: a rising call and wings
    gathering in."""
    call = swell(sweep(300.0, 620.0, 700, 1.2), 120.0, 200.0)
    rasp = swell(lowpass(noise(8940, 700), 1800), 120.0, 200.0)
    wings = mix(*[at(300 + 55 * k, decay(lowpass(noise(8941 + k, 50), 700), 10.0, 2.0))
                  for k in range(8)])
    return mix(gain(call, 0.45), gain(rasp, 0.35), gain(wings, 0.4))


def freeze():
    """The Winter Lord's aura taking the towers: a cold sweep falling and
    ice settling over it."""
    sweep_down = sweep_lowpass(noise(8950, 720), 6000.0, 900.0)
    tone_down = sweep(1600.0, 800.0, 720, 0.8)
    ice = mix(*[at(220 + 70 * k, decay(tone(3136.0 - 200 * k, 160), 50.0, 1.0))
                for k in range(5)])
    return swell(mix(gain(sweep_down, 0.45), gain(tone_down, 0.2), gain(ice, 0.2)),
                 60.0, 240.0)


# --------------------------------------------- the new bosses (task 0284)
#
# Each longer than every ordinary night sound, at `GIANT_PEAK`, and heard
# with no position on arrival, as the Giant is.

def engine():
    """**The Harvester**: an old engine possessed - a sputtering low drone
    with the teeth of the thresher ticking over it."""
    n = int(RATE * 1.5)
    out = []
    for i in range(n):
        t = i / RATE
        chug = 0.6 + 0.4 * math.sin(2.0 * math.pi * 7.0 * t) ** 2
        v = (math.sin(2.0 * math.pi * 55.0 * t) * 0.6
             + math.sin(2.0 * math.pi * 110.0 * t + 0.4) * 0.35
             + math.sin(2.0 * math.pi * 165.0 * t + 1.1) * 0.2)
        out.append(v * chug)
    teeth = mix(*[at(90 * k, decay(highpass(noise(8960 + k, 30), 1800), 4.0, 0.5))
                  for k in range(16)])
    return swell(mix(lowpass(out, 900.0), gain(teeth, 0.25)), 260.0, 420.0)


def king_call():
    """**The Scarecrow King**: a dry, rasping call, a crow's voice made huge,
    and the flock answering under it."""
    call = sweep(180.0, 260.0, 1500, 1.3)
    rasp = lowpass(noise(8980, 1500), 1400)
    flock = mix(*[at(500 + 140 * k, decay(sweep(900.0, 650.0, 200, 0.8), 70.0, 4.0))
                  for k in range(6)])
    return swell(mix(gain(call, 0.55), gain(rasp, 0.4), gain(flock, 0.18)),
                 280.0, 500.0)


def lord_ice():
    """**The Winter Lord**: a deep cold howl, and ice ringing over it."""
    howl = sweep(70.0, 52.0, 1600, 1.2)
    wind = sweep_lowpass(noise(8990, 1600), 500.0, 2200.0)
    chimes = mix(*[at(300 + 180 * k, decay(tone(2349.0 + 263 * (k % 3), 400), 160.0, 2.0))
                   for k in range(6)])
    return swell(mix(gain(howl, 0.6), gain(wind, 0.35), gain(chimes, 0.12)),
                 300.0, 520.0)


# --------------------------------------------------------- what happens next

def impact():
    """Something landing in something soft. Short, so fifty of them can."""
    thud = decay(lowpass(noise(8520, 120), 1100), 20.0, 1.0)
    meat = decay(sweep(260.0, 120.0, 110, 0.5), 26.0, 1.5)
    return mix(gain(thud, 0.7), gain(meat, 0.5))


def death():
    """A body going down: the voice gives out, then it lands."""
    give = decay(sweep(210.0, 84.0, 260, 0.7), 80.0, 4.0)
    rasp = decay(lowpass(noise(8521, 260), 1400), 60.0, 6.0)
    land = at(190, decay(lowpass(noise(8522, 140), 700), 28.0, 2.0))
    return mix(gain(give, 0.55), gain(rasp, 0.4), gain(land, 0.5))


def wall_break():
    """Wood letting go: a crack and then the pieces."""
    snap = decay(highpass(noise(8523, 120), 1200), 14.0, 1.0)
    timber = decay(sweep(320.0, 110.0, 200, 0.6), 50.0, 2.0)
    debris = mix(
        at(90, decay(lowpass(noise(8524, 90), 2600), 16.0)),
        at(170, decay(lowpass(noise(8525, 90), 2200), 14.0)),
        at(240, decay(lowpass(noise(8526, 110), 1800), 18.0)),
    )
    return mix(gain(snap, 0.7), gain(timber, 0.55), gain(debris, 0.45))


def house_hit():
    """**The most alarming sound in the game.**

    It is the only one that means you are losing, so it is the loudest, and it
    is built out of the three things ears refuse to ignore: a low boom you
    feel, a bright crack on top of it, and two notes a semitone apart, which
    is the interval every alarm ever made is built on. Nothing else in the
    game is dissonant on purpose.
    """
    boom = decay(sweep(170.0, 52.0, 520, 0.4), 130.0, 1.5)
    crack = decay(highpass(noise(8527, 180), 1600), 22.0, 1.0)
    alarm_a = at(60, decay(tone(740.0, 420), 150.0, 6.0))
    alarm_b = at(60, decay(tone(784.0, 420), 150.0, 6.0))
    return mix(gain(boom, 0.8), gain(crack, 0.55),
               gain(alarm_a, 0.3), gain(alarm_b, 0.3))


# ------------------------------------------------------------------ the menus

def ui_move():
    """A selection moving. One short, soft, high tick: a column walked from top
    to bottom is a patter, not a drum."""
    return lowpass(decay(tone(1175.0, 40), 9.0, 1.0), 5000.0)


def ui_confirm():
    """An entry taken. Two notes rising a fifth - "yes", rather than "click"."""
    a = decay(tone(784.0, 60), 22.0, 2.0)
    b = at(45, decay(tone(1175.0, 90), 32.0, 2.0))
    return lowpass(mix(gain(a, 0.55), gain(b, 0.55)), 5500.0)


def ui_back():
    """Backing out. The same two notes the other way round, lower - a door
    closed gently rather than slammed."""
    a = decay(tone(1047.0, 50), 20.0, 2.0)
    b = at(40, decay(tone(698.0, 80), 30.0, 2.0))
    return lowpass(mix(gain(a, 0.5), gain(b, 0.5)), 4500.0)


## Every day sound: the id the game asks for, the recipe, and what it may peak
## at. The id is what `Audio.play()` takes, minus the `sfx/` the folder adds.
DAY_SOUNDS = [
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
    # Task 0281: the verbs that borrowed, the cliff's metals, the machines
    # and the smith - each its own, all furniture.
    ("dig", dig, SOFT_PEAK),
    ("ship", ship, SOFT_PEAK),
    ("fertilise", fertilise, SOFT_PEAK),
    ("mine_copper", mine_copper, SOFT_PEAK),
    ("mine_coal", mine_coal, SOFT_PEAK),
    ("mine_gold", mine_gold, SOFT_PEAK),
    ("keg", keg, SOFT_PEAK),
    ("preserves_jar", preserves_jar, SOFT_PEAK),
    ("dairy", dairy, SOFT_PEAK),
    ("loom", loom, SOFT_PEAK),
    ("mill", mill, SOFT_PEAK),
    ("anvil", anvil, SOFT_PEAK),
    # Task 0282: the fishing bar, by ear.
    ("fish_tick", fish_tick, TICK_PEAK),
    ("fish_hit", fish_hit, SOFT_PEAK),
    ("fish_miss", fish_miss, SOFT_PEAK),
    ("fish_catch", fish_catch, SOFT_PEAK),
]

## **The day's moments** (task 0281): once or twice a day each, so not
## furniture - their own list and peak, joined into `SOUNDS`.
MOMENT_SOUNDS = [
    ("bed", bed, MOMENT_PEAK),
    ("wake", wake, MOMENT_PEAK),
    ("pass_out", pass_out, MOMENT_PEAK),
    ("payout", payout, MOMENT_PEAK),
    ("stall_bell", stall_bell, MOMENT_PEAK),
    ("tool_ready", tool_ready, MOMENT_PEAK),
]

## And the night's, which is the loud half.
NIGHT_SOUNDS = [
    ("shot_gun", shot_gun, NIGHT_PEAK),
    ("shot_bolt", shot_bolt, NIGHT_PEAK),
    ("flame", flame, NIGHT_PEAK),
    ("mortar", mortar, NIGHT_PEAK),
    ("mine_blast", mine_blast, NIGHT_PEAK),
    ("groan_walker", groan_walker, NIGHT_PEAK),
    ("groan_runner", groan_runner, NIGHT_PEAK),
    ("groan_tank", groan_tank, NIGHT_PEAK),
    ("groan_breaker", groan_breaker, NIGHT_PEAK),
    ("roar_giant", roar_giant, GIANT_PEAK),
    # Task 0284: the new enemies' voices and what they do...
    ("voice_spitter", voice_spitter, NIGHT_PEAK),
    ("spit", spit, NIGHT_PEAK),
    ("spit_splat", spit_splat, NIGHT_PEAK),
    ("squeak", squeak, NIGHT_PEAK),
    ("caw", caw, NIGHT_PEAK),
    ("rumble", rumble, NIGHT_PEAK),
    ("burst", burst, NIGHT_PEAK),
    ("voice_frost", voice_frost, NIGHT_PEAK),
    ("shatter", shatter, NIGHT_PEAK),
    ("crackle", crackle, NIGHT_PEAK),
    ("whisper", whisper, WHISPER_PEAK),
    ("charge", charge, NIGHT_PEAK),
    ("crunch", crunch, NIGHT_PEAK),
    ("summon", summon, NIGHT_PEAK),
    ("freeze", freeze, NIGHT_PEAK),
    # ...and the three new bosses, as big as the Giant.
    ("engine", engine, GIANT_PEAK),
    ("king_call", king_call, GIANT_PEAK),
    ("lord_ice", lord_ice, GIANT_PEAK),
    ("impact", impact, NIGHT_PEAK),
    ("death", death, NIGHT_PEAK),
    ("wall_break", wall_break, NIGHT_PEAK),
    ("house_hit", house_hit, ALARM_PEAK),
    # Task 0283: the cursor's hand, quiet as furniture...
    ("place", place, SOFT_PEAK),
    ("upgrade", upgrade, SOFT_PEAK),
    ("mend", mend, SOFT_PEAK),
    ("sell_back", sell_back, SOFT_PEAK),
    # ...and the guardian's night under the guns.
    ("horn", horn, GUARDIAN_PEAK),
    ("power_flare", power_flare, GUARDIAN_PEAK),
    ("farm_bell", farm_bell, GUARDIAN_PEAK),
    ("dog_bark", dog_bark, GUARDIAN_PEAK),
    ("dog_bite", dog_bite, GUARDIAN_PEAK),
    ("power_mend", power_mend, GUARDIAN_PEAK),
    ("straw", straw, GUARDIAN_PEAK),
    ("buzz", buzz, GUARDIAN_PEAK),
    ("catapult", catapult, GUARDIAN_PEAK),
    ("splat", splat, GUARDIAN_PEAK),
    ("hum", hum, GUARDIAN_PEAK),
    ("zap", zap, GUARDIAN_PEAK),
]

## And the menus' three (2026-10-07): moving the selection, taking an entry,
## backing out - the feedback WELCOME BACK, HERO's menus give, at the quietest
## level in the game. `MenuFocus` plays them.
UI_SOUNDS = [
    ("ui_move", ui_move, UI_PEAK),
    ("ui_confirm", ui_confirm, UI_PEAK),
    ("ui_back", ui_back, UI_PEAK),
]

SOUNDS = DAY_SOUNDS + MOMENT_SOUNDS + NIGHT_SOUNDS + UI_SOUNDS


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
    print("  %-14s %7s %6s %6s %7s" % ("sound", "seconds", "peak", "rms",
                                       "bright"))
    for name, recipe, peak in SOUNDS:
        seconds, hit, rms, bright = measure(render(recipe, peak))
        print("  %-14s %7.3f %6.2f %6.3f %7.2f"
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
    io.open(os.path.join(folder, "_a-night.wav"), "wb").write(
        wav_bytes(a_night()))
    print("  preview: %d day and %d night sounds, %d chops over %.0fs, "
          % (len(DAY_SOUNDS), len(NIGHT_SOUNDS), hits, seconds)
          + "and a %.0fs night, in %s"
          % (max(t for t, _, _ in A_NIGHT) + 3.0, folder))


## A night, as a timeline of (seconds, sound, how far away).
##
## **For the done-when that needs ears**: "with eyes closed, a night's audio
## says roughly what is happening". A wave arrives in the distance, the guns
## answer, something gets through, the Giant comes, a wall goes, and the house
## takes two hits. Nothing here is the game - it is the game's sounds in the
## order the game would play them, at the volumes the falloff would give them,
## so the question can be asked of a file rather than of a playthrough.
A_NIGHT = [
    (0.4, "groan_walker", 440.0),
    (1.1, "groan_walker", 400.0),
    (1.9, "shot_gun", 40.0),
    (2.3, "impact", 200.0),
    (2.7, "shot_bolt", 60.0),
    (3.0, "impact", 240.0),
    (3.4, "groan_runner", 300.0),
    (3.9, "shot_gun", 40.0),
    (4.2, "death", 220.0),
    (4.8, "shot_bolt", 60.0),
    (5.1, "impact", 180.0),
    (5.6, "mortar", 90.0),
    (6.2, "death", 260.0),
    (6.6, "groan_tank", 260.0),
    (7.1, "flame", 70.0),
    (7.9, "shot_gun", 40.0),
    (8.3, "death", 200.0),
    (9.0, "roar_giant", -1.0),
    (10.6, "groan_breaker", 180.0),
    (11.2, "mine_blast", 150.0),
    (11.8, "shot_gun", 40.0),
    (12.4, "wall_break", 120.0),
    (13.0, "groan_breaker", 90.0),
    (13.6, "impact", 80.0),
    (14.2, "house_hit", 60.0),
    (15.1, "shot_gun", 40.0),
    (15.6, "house_hit", 60.0),
    (16.4, "death", 100.0),
    (17.0, "shot_bolt", 60.0),
    (17.6, "death", 140.0),
]


def falloff(distance):
    """`Audio.loudness`, read out of the GDScript rather than copied.

    Same argument as `pitch_jitter`: two numbers that have to match and live
    in different files are two numbers that will not. A distance below zero
    means the sound has no position - the Giant's roar - and is full volume.
    """
    near = _audio_number("NEAR")
    earshot = _audio_number("EARSHOT")
    floor = _audio_number("FAR_FLOOR")
    if distance < 0.0 or distance <= near:
        return 1.0
    if distance >= earshot:
        return floor
    return 1.0 - (1.0 - floor) * (distance - near) / (earshot - near)


def a_night():
    """The timeline above, mixed down."""
    made = {name: render(recipe, peak) for name, recipe, peak in SOUNDS}
    length = int(RATE * (max(t for t, _, _ in A_NIGHT) + 3.0))
    track = [0.0] * length
    for when, name, distance in A_NIGHT:
        one = made[name]
        level = falloff(distance)
        start = int(when * RATE)
        for i, v in enumerate(one):
            if start + i >= length:
                break
            track[start + i] += v * level
    # The night is busy and these are meant to overlap; keep it off the rails
    # without squashing the dynamics that are the whole point.
    high = max(abs(v) for v in track)
    if high > 0.98:
        track = [v * 0.98 / high for v in track]
    return track


def _audio_number(name):
    path = os.path.join(ROOT, "src", "app", "audio.gd")
    for line in io.open(path, encoding="utf-8"):
        if line.startswith("const %s " % name):
            return float(line.split(":=")[1].split("#")[0].strip())
    raise SystemExit("gen_sfx: audio.gd has no %s any more" % name)


def gd_number(relative_path, name):
    """A `const` out of a GDScript file, by name.

    **Two numbers that have to match and live in different files are two
    numbers that will not.** Every generator that needs to know something the
    game already decided - the pitch jitter, the distance falloff, the
    transition's length, how long the bed waits between birds - reads it from
    where it lives rather than keeping a copy. One reader, so there is one
    place for that habit to break.
    """
    path = os.path.join(ROOT, *relative_path.split("/"))
    for line in io.open(path, encoding="utf-8"):
        if line.startswith("const %s " % name) or \
                line.startswith("const %s:" % name):
            return float(line.split(":=")[1].split("#")[0].strip())
    raise SystemExit("%s has no %s any more" % (relative_path, name))


def pitch_jitter():
    return gd_number("src/app/audio.gd", "PITCH_JITTER")


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
        print("OK    %d sounds match their recipes (%d day, %d moments, "
              "%d night, %d menu)"
              % (len(files), len(DAY_SOUNDS), len(MOMENT_SOUNDS),
                 len(NIGHT_SOUNDS), len(UI_SOUNDS)))
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
