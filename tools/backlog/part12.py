# -*- coding: utf-8 -*-
"""Backlog part 12: phase 16 - sound, collections and polish.

Phases 9 to 15 put a whole year on the farm and left most of it silent, on
stand-in art, or both. This phase gives the day, the fishing, the guardian,
the new enemies, the seasons and the weather their own sounds, gives Year 2 a
reason (collections and achievements kept in the profile), and ends on the
gate that proves every family is on its real art. Each task waits only on the
content it describes; none changes a rule except 0287's two tallies (harvests
and lost nights). A sound task never adds a state key to hear something:
`State.hash_of` hashes every key, so one would move SIM.
"""

P16 = "16 - Sound, collections and polish"

TASKS = [
    # ==================================== phase 16 - sound, collections, polish
    dict(id=281, phase=P16, title="The new day's sounds", slug="sfx-day-v2",
         deps=[196],
         files="tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Going to bed, waking up, the shipping bin, the peddler, the "
              "machines and the new ores each make their own noise, so the "
              "longer day of 1.0 sounds as varied as it plays. View only: "
              "neither hash moves. (The animal calls are 0286's and the "
              "dog's bark 0283's - moved there so this fits one invocation.)",
         req=["New recipes in `tools/gen_sfx.py`, built from the same `Noise` "
              "and primitives (no `random`): bed (under the blanket), wake (a "
              "stretch at 06:00), pass-out (a thud at 02:00), the morning "
              "payout coins, the peddler's stall bell, and the tool upgrade "
              "(an anvil ring when it is ordered, a bright ting when it is "
              "delivered next morning)",
              "And the farm's: one working sound per artisan machine (0187's "
              "keg and jar, 0188's dairy, loom and mill) and copper, coal and "
              "gold variants of `mine` for 0176's nodes. No animal voices "
              "here: 0286 writes the calls heard near the coop and the barn "
              "and 0283 the dog's bark for its power",
              "Furniture and moments: everything played per action keeps the "
              "rule `_task_0084_day_sounds` enforces (a peak of at most 0.6 - "
              "rendered at `SOFT_PEAK` - under 0.6 s, and quieter and shorter "
              "than the bite, so the bite stays the loudest and longest day "
              "sound). Bed, wake, pass-out, the morning coins, the stall bell "
              "and a delivered tool happen once or twice a day: give them "
              "their own list and peak in `gen_sfx.py` (e.g. "
              "`MOMENT_SOUNDS`, below `ALARM_PEAK`, joined into `SOUNDS`) and "
              "teach that group the named exception rather than loosening "
              "its rule",
              "`Sfx` hears them from the state and `src/core/` never calls "
              "`Audio` nor gains a key for a sound: bed and pass-out on the "
              "phase leaving DAY with 0127's `House.asleep` and 0128's "
              "`house_visit.passed_out`, wake on 0138's morning, the payout "
              "as ONE coins sound when 0189's bin is paid at `begin_day` "
              "(never one per coin, never the night's reward; `_watch_money` "
              "resets outside DAY and swallows that rise, so read the bin "
              "emptying), the stall bell when 0190's `STALL_OPENS` and "
              "`STALL_CLOSES` pass, at the stall's cell, the anvil when "
              "0173's pending upgrade appears and the ting when it is "
              "handed over",
              "A per-target table in `src/ui/sfx.gd` (e.g. `TARGET_SOUNDS`, "
              "occupant id -> sound) consulted before `VERB_SOUNDS` with the "
              "cell the action already carries: copper, coal and gold nodes "
              "sound like their ore and each machine like itself when a job "
              "goes in; a target absent from it falls back to the verb's sound",
              "Walk `Interact.DAY_ONLY` against `Sfx.VERB_SOUNDS`: every verb "
              "0165-0195 added (0189's `ship` - the bin's lid and drop -, "
              "0185's truffle dig, whatever else the list holds now) was "
              "mapped to a borrowed file to keep `_task_0084_day_sounds` "
              "green; each gets its own recipe, and two verbs share a file "
              "only where the journal says why",
              "Every new file is reached by the checks: the per-target table "
              "goes into the `wanted` list of `_task_0084_day_sounds` (so the "
              "furniture rule measures it), the moment list into the `heard` "
              "set its 'nothing in the folder is unreached' assert builds but "
              "not into the furniture loop - that assert fails on a WAV "
              "nothing asks for",
              "The numbers live in `gen_sfx.py` and `sfx.gd`, not in "
              "`game_data.gd` - the `Sfx.GROAN_EVERY_SECONDS` reasoning: a "
              "noise changes no rule and must not move the data hash"],
         dod=["`_task_0281_day_sounds` in `src/tools/headless_v1.gd`: every "
              "new id is a file, per-action sounds keep the furniture rule, "
              "the moment list is named and stays under the alarm, and ore and "
              "machine targets resolve to their own sound while an unknown "
              "target falls back to the verb's",
              "`_case_0281_day_moments` in `src/tools/input_v1.gd`, reading "
              "`Audio.last_played()` and `Audio.plays_of()`: going to bed "
              "plays the bed sound once, mining a copper node plays the copper "
              "variant and not `sfx/mine`, and a morning with items in the bin "
              "plays the coins exactly once",
              "`_task_0084_day_sounds` and `_task_0085_night_sounds` pass; "
              "`python tools/gen_sfx.py --report` lengths and peaks of every "
              "new sound are in the journal"]),

    dict(id=282, phase=P16, title="The sounds of the fishing minigame",
         slug="sfx-fishing", deps=[180, 182, 196],
         files="tools/gen_sfx.py, tools/gen_music.py, assets/sfx/, "
               "assets/music/, src/ui/sfx.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The minigame of 0180 can be played by ear as well as by eye: "
              "a tick from the bar, a hit, a miss, the catch, and a fanfare "
              "when one of 0182's legendaries comes out of the water. View "
              "only: neither hash moves, and no state key is added to be "
              "heard.",
         req=["Recipes in `tools/gen_sfx.py` for tick, hit, miss and catch. "
              "All four are furniture (at most `SOFT_PEAK`, shorter than the "
              "bite), so `_task_0084_day_sounds` still finds the bite the "
              "loudest and longest day sound: the bite opens the window, these "
              "only follow it",
              "The tick marks the marker turning at an end of the bar or "
              "entering the zone (pick one and say why), never every frame",
              "`Sfx` reads hit, miss and catch off 0180's minigame state the "
              "way `_watch_fishing` reads `Fishing.is_biting`: a hit or a miss "
              "is the edge the press intent left in the state, the catch is "
              "the cast ending with a species landed. An assisted hit (0180's "
              "option) sounds like any other hit",
              "The legendary fanfare is music, not furniture: a short cue in "
              "`tools/gen_music.py` beside `sting` (Music bus, at most "
              "`STING_PEAK`, a `PIECES` entry so `--check` knows it) built on "
              "`MOTIF`, so the year's tune answers the catch. `Sfx` asks "
              "`Audio.play` for it when the species landed is one of 0182's "
              "legendaries, and the ordinary catch is skipped then",
              "Decide what becomes of `sfx/reel` (the MVP's one-press reel): "
              "kept as the line coming in under the minigame, or retired with "
              "its recipe and its `VERB_SOUNDS` entry - never left as a file "
              "nothing plays. `reel` is in `Interact.DAY_ONLY` today and "
              "`_task_0084_day_sounds` wants a sound for every verb there, so "
              "retire it only if 0180 took the verb out of that list",
              "Extend what `_task_0084_day_sounds` collects so every new file "
              "in `assets/sfx/` is reached; `python tools/gen_sfx.py --check` "
              "and `python tools/gen_music.py --check` are clean"],
         dod=["`_task_0282_fishing_sounds` in `src/tools/headless_v1.gd`: the "
              "four files exist and keep the furniture rule against the bite; "
              "the fanfare is in `assets/music/`, under five seconds and at "
              "most `STING_PEAK`, and its recipe reads `MOTIF`",
              "`_case_0282_fishing_sounds` in `src/tools/input_v1.gd`: a "
              "minigame driven through intents plays the hit for a press in "
              "the zone, the miss for one outside it and the catch on landing; "
              "a crafted legendary bite landed plays the fanfare and not the "
              "catch (`Audio.last_played()`)",
              "`gen_sfx.py --report` and `gen_music.py --report` numbers for "
              "the new sounds are in the journal"]),

    dict(id=283, phase=P16, title="The guardian's sounds", slug="sfx-night-v2",
         deps=[233, 234],
         files="tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/ui/main.gd, "
               "src/app/audio.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The night is played through the cursor now, so the cursor's "
              "work, the START horn, the four powers and the new defences get "
              "sounds - heard from where the guardian is looking, not from "
              "the farmer asleep in bed. View only: neither hash moves, and "
              "no state key is added to be heard.",
         req=["The ears: at night `Sfx` calls `listen_at` with the centre of "
              "0130's night camera (`main.gd` owns the `WorldView`; hand it "
              "over the way `Music.show_state` gets it), not "
              "`_where_the_player_is()` (the sleeping farmer), and "
              "`nearest_by_kind` measures from the same point. `Audio` has no "
              "getter for its ears today: add one if the checks need it. If "
              "0130 already did this, say so and move on",
              "The cursor's hand, quieter than the weapons (at most "
              "`SOFT_PEAK`) and played at its cell: place (a defence that "
              "appears), upgrade (its `level` rising), repair (hp or "
              "`house_hp` rising in PREPARATION/NIGHT, not the fill "
              "`begin_night` does) and sell. A defence that vanishes leaving "
              "rubble (`Farm.rubble_at`) broke and one that leaves none was "
              "sold - `_watch_structures` sounds every vanished non-mine as "
              "`wall_break` today, and a sale must not; put the decision in a "
              "static helper the checks can ask",
              "The START horn on 0136's PREPARATION -> NIGHT edge: once a "
              "night, with no position (`AudioScript.NOWHERE`), on the `DUCKS` "
              "list, below `NIGHT_PEAK`",
              "The powers of 0232/0233 - flare, farm bell, the dog and "
              "emergency repair - each heard when its cooldown rises (the "
              "reading `_watch_towers` uses for `reload`), at the aimed cell; "
              "the bell, which stops every zombie, with no position. The "
              "dog's bark and bite are written here (moved from 0281; 0286 "
              "leaves the dog out of its animal calls)",
              "The defences of 0224-0231: a straw rustle when the decoy is "
              "hit, the beehive's buzz, the catapult's thunk (and a splat "
              "where the pumpkin lands, if the shell is already in the state), "
              "the searchlight's hum and the electric fence's zap when it "
              "stuns. Buzz and hum are per kind and not per structure - from "
              "the nearest stinging hive or lit searchlight, the way groans "
              "are - so ten hives are not ten loops",
              "Replace every borrowed entry 0224-0231 put in "
              "`Sfx.TOWER_SOUNDS` to keep `_task_0085_night_sounds` green. "
              "That group's rule still holds: `TOWER_SOUNDS` lists exactly the "
              "defences with `damage` (their shot), so the rustle, the hum and "
              "the zap of defences without it - and the buzz, if it is not the "
              "hive's shot - go in a table of their own (e.g. "
              "`DEFENCE_SOUNDS`). The house being hit stays the loudest file "
              "in `assets/sfx/`, and every new night file stays shorter than "
              "the Giant's roar, which that group still asserts is the "
              "longest night sound until 0284 rewrites it",
              "Extend `_night_sound_ids()` in `headless_check.gd` with every "
              "new list, because `_task_0084_day_sounds` builds its 'nothing "
              "in the folder is unreached' set from it"],
         dod=["`_task_0283_guardian_sounds` in `src/tools/headless_v1.gd`: "
              "every new id is a file under `NIGHT_PEAK`, no two damaging "
              "defences share a file, every defence without `damage` is out "
              "of `TOWER_SOUNDS`, and the sold/broken/spent helper answers "
              "right for a crafted sale, a wreck with rubble and a spent mine",
              "`_case_0283_guardian_sounds` in `src/tools/input_v1.gd`: in the "
              "build step the cursor places, upgrades and sells a defence and "
              "`Audio.last_played()` is place, upgrade, sell (never "
              "`sfx/wall_break`); START plays the horn; an aimed flare plays "
              "the flare; panning the camera away from a firing tower makes "
              "it quieter (`Audio.loudness`)",
              "`_task_0084_day_sounds` and `_task_0085_night_sounds` pass; "
              "`python tools/gen_sfx.py --report` for the new sounds is in the "
              "journal"]),

    dict(id=284, phase=P16, title="The new enemies and bosses, heard",
         slug="sfx-enemies-v2",
         deps=[247, 248, 250, 252, 253, 254, 255, 257],
         files="tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Six new enemies and three new bosses each get a voice of their "
              "own, so a night heard with your eyes shut still says what is "
              "coming. View only: neither hash moves, and no state key is "
              "added to be heard. (The night events' stingers moved to 0286, "
              "beside the event beds, so this fits one invocation.)",
         req=["Recipes for the spitter (the spit, and a splat on the tower "
              "0247's projectile hits), the rat swarm (a squeak), the crow (a "
              "caw over wingbeats), the digger (a burrowing rumble and a burst "
              "when it surfaces), the frost zombie (a shatter as it dies and a "
              "crackle on the towers it chills) and the wraith (a whisper)",
              "Voices stay per kind and not per body: `nearest_by_kind` keeps "
              "a swarm of fifty rats to one voice (0085's promise). Deaths "
              "that differ by kind go through a small per-kind table that "
              "falls back to `DEATH_SOUND` and keeps `DEATH_GAP`",
              "The wraith cannot be shot outside light (0252): decide whether "
              "its whisper plays with no position (you know they are out, not "
              "where) or only from wraiths in light, and write why in the "
              "journal",
              "Three boss voices - the Harvester's engine, the Scarecrow "
              "King's call, the Winter Lord's ice - and their specials: the "
              "Harvester's charge telegraph and the crunch of the walls it "
              "crushes, the King summoning crows, the Winter Lord's freezing "
              "aura; each special heard on the edge its telegraph or effect "
              "already sets in the state (`is_winding`, 0253's "
              "`charge_line`, 0251's `Towers.chill_left`, 0255's `frozen` "
              "countdown), read like `reload`",
              "Every boss is announced like the Giant: on arrival, with no "
              "position, ducking the ambience. Wherever `sfx.gd` still tests "
              "`kind == &\"giant\"` (`_watch_bodies`, `nearest_by_kind`, "
              "`_ducks`), read `is_boss` instead, unless 0246 already did",
              "Rewrite `_task_0085_night_sounds`: 'the Giant's roar is the "
              "longest sound at night' becomes 'every boss voice is longer "
              "than every ordinary night sound'; the house being hit stays "
              "the loudest file (bosses at `GIANT_PEAK` or below); replace "
              "each borrowed `ENEMY_SOUNDS` entry 0247-0255 left",
              "Extend `_night_sound_ids()` so every new file in `assets/sfx/` "
              "is reached. The event stingers (fog, rain, the Blood Moon, the "
              "Full Moon) are not this task's: 0286 writes and plays them"],
         dod=["`_task_0284_enemy_sounds` in `src/tools/headless_v1.gd`: every "
              "enemy in `GameData.ENEMIES` has a voice file of its own, every "
              "boss voice is longer than any ordinary night sound and quieter "
              "than the alarm, and fifty rats are one entry in "
              "`nearest_by_kind`",
              "`_case_0284_boss_voices` in `src/tools/input_v1.gd`: a boss "
              "spawned in a real scene plays its voice once with no position "
              "and ducks the bed (`Audio.duck_gain()`)",
              "`_task_0085_night_sounds` (rewritten) passes; "
              "`python tools/gen_sfx.py --report` for every new sound is in "
              "the journal"]),

    dict(id=285, phase=P16, title="Music for four seasons",
         slug="music-seasons", deps=[160, 282],
         files="tools/gen_music.py, assets/music/, src/ui/music.gd, "
               "src/app/audio.gd, src/ui/main.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The two MVP pieces become a year: a day piece per season on "
              "the shared motif, a winter night, a boss track and the credits, "
              "each crossfading on the moment it belongs to. View only: "
              "neither hash moves.",
         req=["`tools/gen_music.py` adds day pieces for summer, autumn and "
              "winter beside today's `farm`, which becomes spring (keep its id "
              "or rename it and every reader in the same pass), a winter night "
              "beside `night`, a boss track and the credits. All read `MOTIF` "
              "at the one `BPM = 75` - a crossfade between two tempos is a "
              "stumble, as the module says - and each season gets its own "
              "scale, register and density",
              "Every looping piece gets the seam the module already builds "
              "(`snap()`, `wrapped()` tails) and runs longer than 15 s. The "
              "credits play once, as long as 0160's roll; they and the cues "
              "(`sting` and 0282's fanfare; 0286 adds its event stingers to "
              "the same list later) are named as not-loops rather than "
              "excused from the seam check in bulk. `Audio.play_music` loops "
              "whatever it plays (`_looping` sets the shared stream's loop "
              "mode), so the credits need a play-once road in "
              "`src/app/audio.gd`",
              "`Music.piece_for` stays static and askable and gains what it "
              "now needs: the season (0149's calendar) and whether tonight is "
              "a boss night (0153). Day plays that season's piece; the build "
              "step, the night and the morning report play the night piece "
              "(the winter one in winter); a boss night plays the boss track; "
              "a menu keeps the spring piece behind `audio/music_in_menus`",
              "Crossfades use the one length there is (`fade_seconds()`, the "
              "transition's): the season turns on the first morning of the "
              "new season, the boss track arrives with a boss night's build "
              "step and leaves at dawn, the credits take over on 0160's ending "
              "screen. Decide whether `layer_for`'s urgent layer plays over "
              "the boss track, and say why",
              "Size: a 96 s piece is about 4.2 MB of WAV in the repository and "
              "about 0.85 MB of QOA in the pack, and `tools/release.py` holds "
              "the Web pack to `PACK_BUDGET` (3.5 MB gzipped, 2.31 MB at task "
              "0100). Measure before and after, prefer shorter loops for the "
              "new pieces, and if the budget must move, move it on purpose "
              "with both numbers in the journal. Time matters too: "
              "`tools/verify.py` runs `gen_music.py --check`, which renders "
              "every piece (about 13 s for today's four) - put its time "
              "before and after in the journal",
              "Rewrite `_task_0086_music` in `headless_check.gd` for the new "
              "`piece_for` and the new list: its seam, motif and one-tempo "
              "checks cover every looping piece"],
         dod=["`_task_0285_season_music` in `src/tools/headless_v1.gd`: "
              "`piece_for` answers right for each season and phase, a boss "
              "night, and a menu with the setting off and on; every looping "
              "piece's `_loop_seam` ratio is at most 1.0 and its length over "
              "15 s; every arrangement reads `MOTIF`",
              "`_case_0285_season_music` in `src/tools/input_v1.gd`: a real "
              "run moved to a summer morning is playing the summer piece once "
              "the fade is over (`Audio.music_playing()`), and a boss night's "
              "build step the boss track",
              "The Web pack size before and after (`python tools/release.py`, "
              "or why it could not be measured) and "
              "`python tools/gen_music.py --report` lengths and seams are in "
              "the journal"]),

    dict(id=286, phase=P16, title="Fog, rain and winter wind",
         slug="ambience-v2", deps=[186, 256, 257, 285],
         files="tools/gen_ambience.py, assets/ambience/, tools/gen_music.py, "
               "assets/music/, src/ui/ambience.gd, src/ui/music.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The bed under everything follows the weather and the season: "
              "fog and rain on the nights that have them, wind through the "
              "winter, the animals heard near their coop and barn, and a "
              "short stinger when an event night reaches its build step. "
              "View only: neither hash moves. (The animal calls came from "
              "0281 and the stingers from 0284, so those fit one invocation.)",
         req=["`tools/gen_ambience.py` writes a fog bed and a rain bed for the "
              "night, and a winter bed (wind, no birds, no crickets) for "
              "winter's day and night, looped with its `seamless()` and under "
              "`BED_PEAK` - the bed stays the quietest thing in the game",
              "`Ambience.bed_for` stays static and gains the season and "
              "tonight's event: an event night's bed beats the season's, and "
              "winter's beats the ordinary day and night beds. The event is "
              "0256's `Weather` answer for `(seed, day)` (0257 added the "
              "Blood Moon to it) - the function the forecast panel calls, "
              "never a second draw and never the view's own "
              "`RandomNumberGenerator`",
              "Touches by season: winter gets its own short lists (no "
              "crickets, no songbirds), and no touch is in both a day list and "
              "a night list",
              "Animals near barns, written here (moved from 0281): cluck, moo, "
              "baa and oink in `gen_ambience.py` from `gen_sfx`'s primitives "
              "(it already imports `gen_sfx`), at most `TOUCH_PEAK`, played "
              "at the coop's and the barn's cells through the existing "
              "falloff - by day while the building stands with animals of "
              "that kind in it (0183's residents), and as a sleepy murmur at "
              "night, when they sleep inside (0186). The dog is not here: its "
              "bark is 0283's power sound. Decide whether a "
              "wrecked-but-standing barn still murmurs",
              "The beds change on the cue they use today (`Audio.play_bed` "
              "with the transition's length); nothing changes the bed in the "
              "middle of a night",
              "Event stingers (moved from 0284): fog, rain, the Blood Moon "
              "(0257) and the Full Moon (0152) as short cues in "
              "`tools/gen_music.py` beside `sting` - `PIECES` entries, at "
              "most `STING_PEAK`, named in 0285's not-loop list - played once "
              "through `Audio.play` (the Music bus, because the file is in "
              "`assets/music/`) when a night with that event reaches its "
              "build step. The event is the same `Weather` answer the bed "
              "reads (the Full Moon is 0152's `Calendar.is_full_moon`), never "
              "decided in the view",
              "Rewrite `_task_0087_ambience` in `headless_check.gd` for the "
              "new `bed_for`: every file is still asked for, every bed loops "
              "(`_loop_seam` at most 1.0) and peaks under 0.3, and the house "
              "being hit still stands far above the ducked bed"],
         dod=["`_task_0286_weather_ambience` in `src/tools/headless_v1.gd`: "
              "`bed_for` answers for every season, phase and event; each new "
              "bed loops and stays under the old peak; no touch is in both a "
              "day and a night list, and winter's hold no cricket and no "
              "songbird; animal calls are offered only where a coop or barn "
              "with animals stands; each stinger is in `assets/music/`, at "
              "most `STING_PEAK` and on 0285's not-loop list",
              "`_case_0286_weather_ambience` in `src/tools/input_v1.gd`: a "
              "foggy night's build step plays the fog bed "
              "(`Audio.bed_playing()`) and the fog stinger once "
              "(`Audio.plays_of()`), and a winter morning the winter bed",
              "`python tools/gen_ambience.py --report` for the new beds "
              "(length, peak, seam) and `gen_music.py --report` for the "
              "stingers are in the journal"]),

    dict(id=287, phase=P16, title="Collections and achievements",
         slug="collections", deps=[152, 155, 160, 170, 182, 253, 254, 255],
         dresses=["A056"],
         files="src/core/collections.gd, src/core/stats.gd, "
               "src/core/farming.gd, src/core/phases.gd, src/core/run.gd, "
               "src/core/game_data.gd, src/app/save.gd, src/app/app.gd, "
               "src/app/input_actions.gd, project.godot, "
               "src/ui/collections_screen.gd, src/ui/title_screen.gd, "
               "src/ui/main.gd, scenes/Title.tscn, scenes/Main.tscn, "
               "assets/locale/strings.csv, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd, "
               "src/tools/shot.gd, implementation/backlog/packs/"
               "A056-collections.md",
         goal="The plan's reason to start Year 2: four collections - fish, "
              "crops, the bosses' trophies and a year without losing the "
              "house - and a short list of achievements, kept in the profile "
              "across runs and shown on one screen.",
         req=["A node-free `src/core/collections.gd` in the shape of `Stats`: "
              "it reads facts other modules already count and keeps no second "
              "ledger - fish from 0182's book, trophies from 0246's "
              "`Combat.bosses_down_of` (`killed_by_kind_all_run`) for every "
              "`is_boss` kind, crops from a harvest tally - and folds them "
              "into the profile with the banking of `Stats.fold` "
              "(`stats.banked`), so folding twice adds nothing. Call it from "
              "inside `Stats.fold`, so every fold site (`main.gd`'s "
              "autosaves, `Run.record`) gets it without a second call",
              "Crops count harvests, not `gained`: everything "
              "`Resources.add` brings in (a purchase through `Shop.buy`, a "
              "gift, loot) lands in `gained` too. Add "
              "`stats.harvested_by_crop` to `Stats.initial()` (inside the "
              "`stats` TABLE, so reconcile fills old saves and no version bump "
              "is needed), counted in `Farming._harvest` the way `Stats.built` "
              "is counted in `Building.place`. SIM moves on purpose (the "
              "state gains keys): both numbers in the journal",
              "'A year without losing the house' is a run that saw Winter 14's "
              "boss fall (0160's `Run.is_over`) with no night on which the "
              "house fell; a boss that walks off at dawn (0153's escaped "
              "outcome) is not a lost house. Nothing counts lost nights "
              "today: add `stats.nights_lost` beside the crop tally, counted "
              "in `Phases.enter_result` when the house fell (read how 0153 "
              "marks an escape in `last_result` and leave that out)",
              "About a dozen achievements, decided here, repeating none of the "
              "collections - e.g. first night survived, a Full Moon held "
              "(0152's `Calendar.is_full_moon`), a legendary landed, every "
              "defence in `DEFENCES` built once, a night with nothing "
              "destroyed, Year 2 reached - each a pure test of the lifetime "
              "stats, the collections and this run's record. A table in "
              "`game_data.gd` (thresholds `# LEVER`, a `check_achievements` "
              "in `GameData.validate()` that every id it names exists, listed "
              "in `GameData.digest()` so DATA moves on purpose) whose entries "
              "carry literal `&\"ACH_*\"` keys for a name and a one-line "
              "description: a key built at runtime is invisible to "
              "`tools/i18n_check.py`",
              "The profile: `Save.default_profile()` gains `collections` and "
              "`achievements`; `read_profile` already merges the defaults, so "
              "an older profile loads with no format bump. No toast for a "
              "newly earned badge in this task: the skeleton asks for the "
              "screen, and the task has to fit one invocation",
              "`src/ui/collections_screen.gd`, a sibling of `StatsScreen` "
              "(a node in `scenes/Title.tscn` and `scenes/Main.tscn`, as it "
              "is): tabs for fish (0182's book view embedded - reuse its "
              "pages, do not rebuild them; 0182's own way in keeps working), "
              "crops, bosses, the year and achievements, each with a count. "
              "Locked trophies and badges are the earned art dimmed by code, "
              "so A056 needs no locked state",
              "Ways in: the title menu (`ENTRIES` gains `collections`, "
              "`TITLE_COLLECTIONS`), a `COLLECTIONS` router state in "
              "`App.STATES` and `App.NAMES` (update the state count "
              "`_task_0092_router` asserts in `headless_check.gd`) and, in a "
              "run, a new `collections` action in `InputActions.ACTIONS` "
              "(`ACT_COLLECTIONS`, `ACT_GROUP_SCREENS`) with key and pad "
              "bindings in `project.godot` (0121's sync and clash checks), "
              "opened and closed the way the `stats` key opens "
              "`StatsScreen`. Strings in both languages, e.g. "
              "`TITLE_COLLECTIONS` (COLLECTIONS / COLEÇÕES), the tabs, every "
              "`ACH_*`",
              "Placeholders until 0288 integrates A056, through 0120's road: "
              "the existing crop and fish icons on the tabs, each boss's first "
              "frame as its trophy, code-drawn shapes for the badges, the "
              "cover and the ornament - never a hand-drawn PNG"],
         dod=["`_task_0287_collections` in `src/tools/headless_v1.gd`, on "
              "crafted states rather than a 56-night run (the 120 s limit): a "
              "harvested crop ticks its page and the same crop added through "
              "`Resources.add` does not; a boss killed adds its trophy; a run "
              "that lost a night never earns the year, one whose boss only "
              "escaped still can, and one that lost none and beat Winter 14 "
              "does; folding twice adds nothing; a profile without the new "
              "keys reads with defaults; `GameData.validate()` refuses an "
              "achievement naming an unknown id",
              "`_case_0287_collections` in `src/tools/input_v1.gd`: the title "
              "menu opens the screen, the tabs move by keyboard and by pad, "
              "cancel goes back to the title; in a run the `collections` key "
              "opens and closes it",
              "FHD captures of every tab with an empty and a full profile in "
              "English, and with the full profile in Portuguese "
              "(`src/tools/capture_menus.gd` or a new `shot.gd` scenario), "
              "opened and looked at, in `implementation/shots/0287/`",
              "The Deliverables table of "
              "`implementation/backlog/packs/A056-collections.md` states the "
              "final geometry this task settled: canvases, pivots and runtime "
              "names for the cover, the tab icons, a trophy per boss, one "
              "badge per achievement id and the ornament"]),

    dict(id=288, phase=P16,
         title="Art: the collection book, trophies and badges",
         slug="art-collections", deps=[287], art=["A056"],
         files="assets/art_source/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_ui_art.py, "
               "src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, "
               "src/ui/collections_screen.gd",
         goal="The book cover, the four boss trophies and the achievement "
              "badges Codex drew replace 0287's stand-ins, so the screen a "
              "player opens before Year 2 looks like the rest of the game.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A056` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task never "
              "draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A056-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 "
              "before promoting; never resample, regenerate, or cut from "
              "previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/<family>/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_<family>_art.py`, "
              "`ArtPlacement` if needed).",
              "Family `ui`, no text in any of it: names, canvases and pivots "
              "exactly as A056's Deliverables table (settled by 0287) - the "
              "cover, the tab icons, a trophy per `is_boss` enemy, a badge per "
              "achievement id, the ornament. `tools/check_ui_art.py` "
              "hard-codes the 0018 resource icons (`len(plans)==15`): give the "
              "A056 set its own section and counts rather than loosening that "
              "one, and show it in `ui_art_showcase.gd`",
              "Delete A056's entries from 0120's placeholder registry "
              "(`src/ui/placeholder_art.gd`) once the raster outputs land at "
              "the same paths, so `collections_screen.gd` draws the real art "
              "through the lookup it already uses and "
              "`python tools/placeholders.py` no longer lists A056; locked "
              "trophies and badges stay the same art dimmed by code",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A056 integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass with the A056 set "
              "counted",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures of the collections screen, every tab "
              "with a full profile, opened in a run by day and by night, "
              "opened and looked at, in `implementation/shots/0288/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=289, phase=P16, title="Art: the morning report",
         slug="art-morning", deps=[138], art=["A057"],
         files="assets/art_source/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_ui_art.py, "
               "src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, "
               "src/ui/result_screen.gd",
         goal="A small sunrise over the farmhouse heads 0138's morning "
              "report. Optional: if the owner declines the pack, the header "
              "0138 drew becomes the shipped look and this task closes with a "
              "note.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A057` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task never "
              "draws, generates or substitutes art.",
              "The one exception, because A057 is optional: if its status is "
              "`blocked` with the owner's decline in the note, do not wait. "
              "Delete A057's entries from 0120's placeholder registry "
              "(`src/ui/placeholder_art.gd`) and draw 0138's code-drawn band "
              "directly in `result_screen.gd`, so it is the final look and no "
              "longer a stand-in (or drop the header if it only made sense as "
              "art), quote the decline in the journal and close with "
              "`python tools/task.py done 0289`. `task.py next` never offers a "
              "task whose pack is not approved, so this path is run by hand "
              "or by 0290",
              "Use only the folder named in the pack's "
              "`CLAUDE-A057-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 "
              "before promoting; never resample, regenerate, or cut from "
              "previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/<family>/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_<family>_art.py`, "
              "`ArtPlacement` if needed).",
              "Family `ui`: one header at the canvas and pivot 0138 settled in "
              "A057's Deliverables table, drawn by `result_screen.gd` above "
              "the report through the lookup it already uses, replacing 0138's "
              "stand-in (delete A057's registry entries in "
              "`src/ui/placeholder_art.gd` once the raster lands at the same "
              "path); no text in it (the report's words stay strings), "
              "checked in its own section of `tools/check_ui_art.py` and shown "
              "in `ui_art_showcase.gd`",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A057 integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass with the header "
              "counted",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures of the morning report after a won and "
              "after a lost night, and of the farm around it by day and by "
              "night, opened and looked at, in `implementation/shots/0289/`",
              "The sim and data hashes are unchanged (art never moves them)",
              "On the decline path instead: `python tools/placeholders.py` no "
              "longer lists A057, a capture of the morning report shows the "
              "band drawn directly, and the journal quotes the owner's words"]),

    dict(id=290, phase=P16, title="The 1.0 visual gate", slug="visual-gate-v1",
         deps=[122, 123, 124, 125, 143, 144, 145, 146, 147, 161, 162, 163,
               164, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
               208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 235, 236,
               237, 238, 239, 240, 241, 242, 243, 244, 245, 258, 260, 261,
               262, 263, 264, 265, 266, 267, 268, 269, 288],
         files="src/tools/shot.gd, src/tools/capture_menus.gd, "
               "implementation/shots/0290/, "
               "implementation/backlog/CATALOGUE.md, "
               "implementation/backlog/packs/, tools/backlog/, "
               "implementation/prompts/, implementation/PROGRESS.md",
         goal="Before 1.0 ships, look at the whole game in its real frame - "
              "every screen, season, family and state at 1920x1080, by day "
              "and by night - and prove nothing is still drawn on a stand-in. "
              "Like sprite task 0020: no claim of done from one nice farm "
              "shot.",
         req=["Capture at 1920x1080 by day and by night with "
              "`python tools/shot.py 0290 <scenarios> --fhd`, the showcases "
              "behind `python tools/show_art.py` and "
              "`src/tools/capture_menus.gd`; add the `shot.gd` scenarios that "
              "are missing (a night scenario uses 0130's camera hook)",
              "The world, at least: the four seasons' ground and trees, snow "
              "included; the farmer walking, running, every work verb and "
              "facing, in bed, passed out, fishing and reacting; the guardian "
              "and the cursor; every crop stage, tilled and trampled ground; "
              "the animals and their buildings, wrecked-but-standing included; "
              "machines, the bin, the peddler, the house tiers; every defence "
              "at every level with hurt, fire, wreck and its tarp; every enemy "
              "walking, attacking and dying; the four bosses and their "
              "telegraphs; effects; fog, rain, the Full and the Blood Moon",
              "Every screen: title, pause, options, the day HUD with clock "
              "and calendar, the forecast, the night HUD with hotbar and "
              "powers, the morning report, inventory, stall, workshop and "
              "machines, the tech tree by season, the fishing minigame, the "
              "fish book and collections, statistics, the year's end and the "
              "credits - in English and Portuguese where there are words",
              "Open every file. Judge scale against Stardew Valley at 1080p "
              "and the look against `docs/reference-sheet.png`: one art pixel "
              "is 4x4 physical pixels, the farmer about 128 px tall, and no "
              "new family drawn at the six legacy fixtures' 2x unless the "
              "journal says why",
              "0120's placeholder check (`python tools/placeholders.py` and "
              "`_task_0120_placeholders` in `headless_v1.gd`) reports nothing "
              "on a stand-in, and `python implementation/backlog/assets.py "
              "list` shows every pack `integrated`, A057 excepted only if "
              "declined. 0289 is not a dependency because A057 is optional: "
              "if it is still todo, read the pack's status - declined "
              "(`blocked` with the owner's words) means run 0289's decline "
              "path here and close it; approved means block this gate until "
              "0289 is done; anything else (todo, generating, review) means "
              "block it `waiting for asset A057 (Codex)` - a later decline "
              "then needs `python tools/task.py todo 0290` by hand",
              "Fix here what needs no new art and is small (placement, "
              "pivots, scale, sorting, the wrong state shown); a view fix "
              "bigger than that, and anything that needs new art (a "
              "correction pack in `implementation/backlog/packs/`), becomes a "
              "follow-up task in `tools/backlog/` with the next free id. Add "
              "each follow-up id to 0297's deps (in `tools/backlog/part13.py` "
              "and on the `Depends on:` line of its prompt, which "
              "`gen_backlog.py` does not overwrite) so 1.0 cannot ship ahead "
              "of it. This task never draws or generates art, and its fixes "
              "are view only: neither hash moves",
              "A 1.0 delivery catalogue, "
              "`implementation/backlog/CATALOGUE.md`, modelled on "
              "`implementation/sprites/DELIVERY.md`: per family "
              "the pack id, canvases, pivots, animation and state coverage, "
              "the capture that shows it, and its known limits"],
         dod=["Every capture in `implementation/shots/0290/` was opened; the "
              "journal lists what was looked at per family and per screen, "
              "what was wrong and what was done about it",
              "0120's placeholder check prints zero packs pending (A057 "
              "excepted only when declined and 0289 closed), quoted in the "
              "journal",
              "The catalogue names a capture for every family and state in the "
              "lists above",
              "Every follow-up is filed as a task (and a pack when it needs "
              "art) with ids, each one in 0297's deps, none left as prose"]),
]
