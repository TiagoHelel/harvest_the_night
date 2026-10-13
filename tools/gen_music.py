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

## **The year's other pieces are shorter loops** (task 0285): twelve bars,
## thirty-eight seconds. A 96 s piece is four megabytes of WAV in the
## repository and most of a megabyte in the Web pack; nobody can hear where a
## seamless loop of thirty-eight seconds begins either, and five of them in
## ninety-six would have doubled the music's weight. Twelve divides by the
## four-bar chord cycle and by the motif's phrase lengths below.
SEASON_BARS = 12

## The urgent layer that arrives on the last wave. Six bars, which divides
## thirty exactly, so it can loop five times inside the night without ever
## drifting off the beat.
INTENSITY_BARS = 6

## Music sits under everything and never competes with a gunshot.
MUSIC_PEAK = 0.34

## The one the intensity layer may reach. Louder, because its whole job is to
## say that this is the last wave.
INTENSITY_PEAK = 0.44

## The sting the options screen auditions the music level with. Louder than
## the music, because it is heard on its own rather than under a game, and a
## test sound that is hard to hear is a test sound that answers nothing.
STING_PEAK = 0.50

## **The motif, as scale degrees.** One list, played by both pieces; see the
## module docstring. Zero is the root, seven is the octave.
MOTIF = [0, 2, 4, 2, 7, 4, 2, 0]

## Semitones above the root, for the modes the pieces are in. Spring and
## summer are major, the nights minor; since task 0285 each season has its
## own: autumn mixolydian (a major with its seventh flattened - warm, a little
## wistful), winter lydian (a major with its fourth raised - bright and cold),
## the winter night phrygian (a minor with its second flattened - the
## darkest), and the boss harmonic minor (the night with a leading note that
## will not settle).
MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]
MIXOLYDIAN = [0, 2, 4, 5, 7, 9, 10]
LYDIAN = [0, 2, 4, 6, 7, 9, 11]
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10]
HARMONIC_MINOR = [0, 2, 3, 5, 7, 8, 11]

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


def _season_bed(scale, length, degrees, level, octave, wobble_hz, wobble):
    """A held chord of `degrees`, snapped to the loop - the pad every season
    breathes on."""
    track = [0.0] * length
    for degree, share in degrees:
        layer = sustained(length, hz_of(scale, degree, octave), level * share,
                          wobble_hz=wobble_hz, wobble=wobble)
        for i in range(length):
            track[i] += layer[i]
    return track


def summer():
    """**Summer's day.** The farm's tune in full sun: the same major, an
    octave up and twice as often, a shaker on the off-beats and the bass
    walking every half bar. The busiest day piece, because summer's days are
    the busiest."""
    bar = bar_samples()
    beat = beat_samples()
    length = bar * SEASON_BARS
    track = _season_bed(MAJOR, length, [(0, 0.5), (4, 0.35), (2, 0.25)],
                        0.8, -1, 0.12, 0.35)
    for b in range(SEASON_BARS):
        degree = DAY_CHORDS[b % len(DAY_CHORDS)]
        wrapped(track, b * bar, thump(hz_of(MAJOR, degree, -2), 700, 220.0), 0.5)
        wrapped(track, b * bar + beat * 2,
                thump(hz_of(MAJOR, degree + 4, -2), 600, 180.0), 0.3)
        for k in range(BEATS_PER_BAR):
            tick = sfx.decay(sfx.highpass(sfx.noise(9100 + b * 4 + k, 60), 5000),
                             10.0, 1.0)
            wrapped(track, b * bar + k * beat + beat // 2, tick, 0.12)
    # **The motif every second bar**, up an octave, a note a half-beat.
    for b in range(0, SEASON_BARS, 2):
        for i, degree in enumerate(MOTIF):
            wrapped(track, b * bar + i * (beat // 2),
                    pluck(hz_of(MAJOR, degree, 1), 600, 180.0, 3600.0), 0.42)
    return track


def autumn():
    """**Autumn's day.** The motif in mixolydian, mid-register and slower -
    a note a beat, every fourth bar - with a falling counter-line answering
    it two bars later: the year turning."""
    bar = bar_samples()
    beat = beat_samples()
    length = bar * SEASON_BARS
    track = _season_bed(MIXOLYDIAN, length, [(0, 0.5), (4, 0.3), (6, 0.22)],
                        0.85, -1, 0.05, 0.5)
    for b in range(SEASON_BARS):
        degree = DAY_CHORDS[b % len(DAY_CHORDS)]
        wrapped(track, b * bar, thump(hz_of(MIXOLYDIAN, degree, -2), 1000, 340.0), 0.5)
    for b in range(0, SEASON_BARS, 4):
        for i, degree in enumerate(MOTIF):
            wrapped(track, b * bar + i * beat,
                    pluck(hz_of(MIXOLYDIAN, degree), 900, 300.0, 2200.0), 0.45)
        # The answer: the motif's notes falling, in the bar after it ends.
        for i, degree in enumerate(reversed(MOTIF[:4])):
            wrapped(track, (b + 2) * bar + i * beat + beat // 2,
                    pluck(hz_of(MIXOLYDIAN, degree + 2), 900, 280.0, 1800.0), 0.28)
    return track


def winter():
    """**Winter's day.** Lydian, high and spare: a thin bed, the motif once
    in the loop on bells two octaves up, and long silences - snow, and a
    farm that has less to do."""
    bar = bar_samples()
    beat = beat_samples()
    length = bar * SEASON_BARS
    track = _season_bed(LYDIAN, length, [(0, 0.45), (4, 0.3), (3, 0.18)],
                        0.6, 0, 0.03, 0.6)
    for b in range(0, SEASON_BARS, 2):
        degree = DAY_CHORDS[(b // 2) % len(DAY_CHORDS)]
        wrapped(track, b * bar, thump(hz_of(LYDIAN, degree, -1), 1400, 520.0), 0.32)
    for i, degree in enumerate(MOTIF):
        wrapped(track, bar + i * beat, bell(hz_of(LYDIAN, degree, 1), 1600, 700.0), 0.36)
    for b in (6, 9):
        wrapped(track, b * bar + beat, bell(hz_of(LYDIAN, 4, 2), 1800, 800.0), 0.2)
    return track


def winter_night():
    """**Winter's night.** Phrygian and lower than the night: a drone a
    flattened second rubs against, the pulse once a bar, and the motif on a
    bell once in the loop, a beat a note - the same farm, as cold as it gets."""
    bar = bar_samples()
    beat = beat_samples()
    length = bar * SEASON_BARS
    track = _season_bed(PHRYGIAN, length, [(0, 0.6), (1, 0.14), (4, 0.25)],
                        0.85, -2, 0.03, 0.6)
    for b in range(SEASON_BARS):
        degree = NIGHT_CHORDS[b % len(NIGHT_CHORDS)]
        wrapped(track, b * bar, thump(hz_of(PHRYGIAN, degree, -2), 1400, 520.0), 0.45)
    for i, degree in enumerate(MOTIF):
        wrapped(track, 3 * bar + i * beat, bell(hz_of(PHRYGIAN, degree, -1), 1600, 600.0), 0.32)
    return track


def boss():
    """**A boss night.** Harmonic minor, a pulse on every beat like the last
    wave's, and the motif every bar on the night's bell, low - from the build
    step to dawn, the night that holds the season."""
    bar = bar_samples()
    beat = beat_samples()
    length = bar * SEASON_BARS
    track = _season_bed(HARMONIC_MINOR, length, [(0, 0.55), (4, 0.3), (6, 0.18)],
                        0.8, -2, 0.25, 0.4)
    for b in range(SEASON_BARS):
        degree = NIGHT_CHORDS[b % len(NIGHT_CHORDS)]
        for k in range(BEATS_PER_BAR):
            wrapped(track, b * bar + k * beat,
                    thump(hz_of(HARMONIC_MINOR, degree, -2), 520, 160.0),
                    0.55 if k == 0 else 0.32)
        for i, degree in enumerate(MOTIF):
            wrapped(track, b * bar + i * (beat // 2),
                    bell(hz_of(HARMONIC_MINOR, degree, -1), 700, 220.0), 0.22)
    return track


def credits():
    """**The credits** (task 0285): the year's tune, once and slowly, in the
    day's major and voice - the motif a beat a note over the tonic, then held
    as the roll ends. As long as 0160's roll and it does not loop."""
    beat = beat_samples()
    length = int(RATE * credits_seconds())
    track = [0.0] * length
    bed = _season_bed(MAJOR, length, [(0, 0.5), (4, 0.3), (2, 0.2)], 0.7, -1, 0.0, 0.0)
    for i in range(length):
        track[i] += bed[i] * min(1.0, i / (RATE * 1.5))
    for i, degree in enumerate(MOTIF):
        note = pluck(hz_of(MAJOR, degree), 1400, 520.0)
        at = beat // 2 + i * beat
        for k, v in enumerate(note):
            if at + k < length:
                track[at + k] += v * 0.6
    return sfx.fade_out(track, 1500.0)


def credits_seconds():
    """**How long 0160's roll runs**, read from `credits_roll.gd`: it starts
    `ROLL_START` below the window and scrolls its lines, `LINE_HEIGHT` each,
    up and out at `SCROLL_SPEED` pixels a second."""
    path = os.path.join(ROOT, "src", "ui", "credits_roll.gd")
    text = io.open(path, encoding="utf-8").read()
    lines = text.split("const LINES", 1)[1].split("= [", 1)[1].split("]", 1)[0].count("&\"")
    start = sfx.gd_number("src/ui/credits_roll.gd", "ROLL_START")
    height = sfx.gd_number("src/ui/credits_roll.gd", "LINE_HEIGHT")
    speed = sfx.gd_number("src/ui/credits_roll.gd", "SCROLL_SPEED")
    return (start + lines * height) / speed


def sting():
    """**The sound the music slider makes**, added by task 0094.

    Three notes off the motif in the day's voice, rising, over a second - long
    enough to hear a level on and short enough to press four times in a row
    without waiting for it.

    It is a piece rather than an effect because a test sound has to play on
    the bus it is testing, and the bus a sound plays on is the folder it lives
    in. Nothing else in `assets/music/` is under nineteen seconds.

    It does not loop, and nothing asks it to: the loop-seam check names the
    three pieces that do.
    """
    gap = int(RATE * 0.15)
    length = gap * 2 + int(RATE * 0.85)
    track = [0.0] * length
    for i, degree in enumerate(MOTIF[:3]):
        note = pluck(hz_of(MAJOR, degree, 0), 700, 300.0)
        at = i * gap
        for k, v in enumerate(note):
            if at + k < length:
                track[at + k] += v * 0.85
    return track


def fanfare():
    """**A legendary out of the water** (task 0282): the year's tune answering
    the catch.

    The whole `MOTIF` in the day's voice, an octave up and four times the
    farm's pace, then the tonic held under its last note in the night's bell
    - the two pieces' voices meeting on the one catch a run gets of each.
    Three seconds; it does not loop, and is music rather than furniture
    because it is a tune: it plays on the Music bus beside `sting`.
    """
    step = beat_samples() // 4
    hold = int(RATE * 1.4)
    length = step * len(MOTIF) + hold
    track = [0.0] * length
    for i, degree in enumerate(MOTIF):
        note = pluck(hz_of(MAJOR, degree, 1), 600, 220.0, 3200.0)
        at = i * step
        for k, v in enumerate(note):
            if at + k < length:
                track[at + k] += v * 0.8
    end = step * (len(MOTIF) - 1)
    for degree in (0, 2, 4):
        chord = bell(hz_of(MAJOR, degree, 0), 1400, 600.0)
        for k, v in enumerate(chord):
            if end + k < length:
                track[end + k] += v * 0.35
    return sfx.fade_out(track, 60.0)


def _stinger(scale, degrees, voice, octave, gap_beats, tail_ms):
    """**An event night's stinger** (task 0286): a few of the motif's notes
    in a voice and a scale, heard once as the build step opens."""
    beat = beat_samples()
    step = int(beat * gap_beats)
    length = step * len(degrees) + int(RATE * tail_ms / 1000.0)
    track = [0.0] * length
    for i, degree in enumerate(degrees):
        note = voice(hz_of(scale, degree, octave))
        at = i * step
        for k, v in enumerate(note):
            if at + k < length:
                track[at + k] += v
    return sfx.fade_out(track, 300.0)


def sting_fog():
    """Fog: the motif's opening, low and slow in the night's bell, blurred."""
    return _stinger(MINOR, MOTIF[:3], lambda hz: bell(hz, 1600, 700.0), -1, 0.75, 1400)


def sting_rain():
    """Rain: the motif's opening falling in quick, light plucks."""
    return _stinger(MINOR, list(reversed(MOTIF[:4])),
                    lambda hz: pluck(hz, 500, 140.0, 3000.0), 0, 0.25, 700)


def sting_blood_moon():
    """The Blood Moon: the motif's leap in harmonic minor, held and wrong."""
    return _stinger(HARMONIC_MINOR, [0, 4, 7, 6], lambda hz: bell(hz, 1400, 600.0),
                    -1, 0.5, 1300)


def sting_full_moon():
    """The Full Moon: the motif rising to the octave in the night's bell, bright."""
    return _stinger(MINOR, [0, 2, 4, 7], lambda hz: bell(hz, 1200, 500.0), 0, 0.5, 1100)


## The files, and what each may peak at. **`farm` is spring's day** (task
## 0285), its id kept so every reader of it is.
PIECES = [
    ("farm", farm, MUSIC_PEAK),
    ("summer", summer, MUSIC_PEAK),
    ("autumn", autumn, MUSIC_PEAK),
    ("winter", winter, MUSIC_PEAK),
    ("night", night, MUSIC_PEAK),
    ("winter_night", winter_night, MUSIC_PEAK),
    ("boss", boss, INTENSITY_PEAK),
    ("night_intensity", intensity, INTENSITY_PEAK),
    ("credits", credits, MUSIC_PEAK),
    ("sting", sting, STING_PEAK),
    # Task 0282: the legendary catch's cue, short like the sting.
    ("fanfare", fanfare, STING_PEAK),
    # Task 0286: an event night's stinger as its build step opens.
    ("sting_fog", sting_fog, STING_PEAK),
    ("sting_rain", sting_rain, STING_PEAK),
    ("sting_blood_moon", sting_blood_moon, STING_PEAK),
    ("sting_full_moon", sting_full_moon, STING_PEAK),
]

## **What does not loop**, named rather than excused in bulk (task 0285): the
## credits play once, and the cues - the sting, the fanfare and, from 0286,
## the event stingers - are heard and done. Everything else loops and is held
## to the seam.
NOT_LOOPS = ["credits", "sting", "fanfare", "sting_fog", "sting_rain",
             "sting_blood_moon", "sting_full_moon"]


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
        print("  %-16s %7.2f %6.2f %6.3f %7s"
              % (name, seconds, hit, rms,
                 "once" if name in NOT_LOOPS else "%.2f" % seam(track)))
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
    print("  preview: %d pieces, 6 passes over the loop seam, and a "
          "%.1fs crossfade, in %s" % (len(made), seconds, folder))


def _transition_seconds():
    return sfx.gd_number("src/core/game_data.gd", "TRANSITION_SECONDS")


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
