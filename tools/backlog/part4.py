# -*- coding: utf-8 -*-
"""Backlog part 4: sound and juice, the shell around the game, and shipping.

None of this changes a rule. All of it is the difference between a prototype
that proves the loop and something a stranger will play to night 10.
"""

P6 = "6 - Sound and juice"
P7 = "7 - Shell and product"
P8 = "8 - Ship the MVP"

TASKS = [
    # ============================================== phase 6 - sound and juice
    dict(id=83, phase=P6, title="Audio buses and a sound manager",
         slug="audio-buses", deps=[9],
         files="src/core/audio.gd, default_bus_layout.tres",
         goal="Master, SFX and Music buses plus a small `Audio.play(id)`, so the "
              "sound tasks after this only have to drop in files.",
         req=["Three buses in `default_bus_layout.tres`",
              "`Audio` autoload mapping a string id to a stream and a bus",
              "Volumes read from Settings on boot and on `changed`",
              "An unknown id warns once and stays silent",
              "A polyphony cap and a same-frame dedupe, so twenty towers firing "
              "on one tick cannot clip"],
         dod=["`Audio.play('missing')` warns exactly once and does not crash",
              "Master at zero silences everything including music",
              "Twenty simultaneous shots produce one clean sound, not clipping"]),

    dict(id=84, phase=P6, title="The sounds of the day", slug="sfx-day",
         deps=[83],
         files="tools/gen_sfx.py, assets/sfx/",
         goal="Chop, mine, till, plant, water, the fishing splash and the bite, "
              "the craft, the sale - generated, not licensed.",
         req=["`tools/gen_sfx.py` synthesises every effect to WAV and is "
              "deterministic",
              "Every day verb has a sound and a small random pitch so repetition "
              "does not grate",
              "Cozy, soft, short: the day is the calm half",
              "The bite is the most attention-grabbing sound of the day, because "
              "it is the only one with a window"],
         dod=["Chopping a tree for a full minute does not become annoying - go "
              "and check",
              "Regenerating produces byte-identical files"]),

    dict(id=85, phase=P6, title="The sounds of the night", slug="sfx-night",
         deps=[83, 26],
         files="tools/gen_sfx.py, assets/sfx/",
         goal="The other half: shots, the flamethrower, the mortar, impacts, the "
              "groan, the death, the wall breaking, the house being hit.",
         req=["Every tower and every enemy has its own sound",
              "The house taking damage is the most alarming sound in the game",
              "A distance falloff, so the far side of the farm is quieter",
              "The Giant is audible before it is visible",
              "The same generator as 0084"],
         dod=["With eyes closed, a night's audio says roughly what is happening",
              "Fifty zombies do not turn into noise"]),

    dict(id=86, phase=P6, title="Two pieces of music", slug="music",
         deps=[83, 22],
         files="tools/gen_music.py, assets/music/",
         goal="One warm loop for the farm, one cold one for the night, and a "
              "crossfade on the reality switch.",
         req=["Generated, looping cleanly, a couple of minutes each",
              "The two share a motif, so the night is recognisably the same farm",
              "A crossfade tied to the transition length",
              "An intensity layer that comes in on the last wave of a night",
              "Music is off in menus by default, and that is a setting"],
         dod=["The loop point is inaudible",
              "The crossfade lands with the transition, not before or after it"]),

    dict(id=87, phase=P6, title="Ambience", slug="ambience", deps=[84, 85],
         files="src/core/ambience.gd",
         goal="The bed under everything: birds and water by day, wind and "
              "distant groaning by night.",
         req=["A day bed and a night bed, cross-fading with the transition",
              "Positional touches: the pond is louder near the pond",
              "It ducks under an important sound rather than fighting it",
              "It is on its own bus so it can be turned down alone"],
         dod=["Standing still on the farm for a minute is pleasant, not empty",
              "The ambience never masks the house-damage sound"]),

    dict(id=88, phase=P6, title="Juice: shake, hit stop, damage numbers",
         slug="juice", deps=[26, 77],
         files="src/ui/juice.gd",
         goal="Make a kill feel like a kill. Small, cheap, and entirely in the "
              "view layer.",
         req=["Screen shake scaled to the event, with a cap and a setting to "
              "disable it",
              "A few frames of hit stop on a big hit, implemented without "
              "touching the tick rate",
              "Floating damage numbers, colour-coded by damage type, batched when "
              "many land at once",
              "A flash on a hit entity and a squash on death",
              "None of it is in core and none of it touches the hash"],
         dod=["Hit stop does not desynchronise the simulation - prove it with the "
              "hash",
              "Everything here can be turned off and the game still reads",
              "A crowded wave does not spawn a thousand number labels"]),

    dict(id=89, phase=P6, title="Tooltips", slug="tooltips", deps=[81],
         files="src/ui/tooltip.gd",
         goal="Every cost, stat and icon explains itself, so the game does not "
              "need a manual.",
         req=["A hover tooltip on resources, structures, recipes, tech nodes and "
              "enemies",
              "It shows the numbers from game_data, never a copy of them",
              "A short delay before it appears and none before it moves to the "
              "next",
              "It never leaves the screen edge",
              "Keyboard focus shows the same tooltip as hover"],
         dod=["Every interactive element has one",
              "Changing a lever changes the tooltip with no other edit"]),

    dict(id=90, phase=P6, title="The log panel", slug="log-panel", deps=[81, 61],
         files="src/ui/log_panel.gd",
         goal="A short running account of what just happened, because at 4x speed "
              "the player will miss things.",
         req=["The last few events: a wave arriving, a structure lost, a crop "
              "ready, a craft finished",
              "Colour-coded by severity, with the alarming ones held longer",
              "It fades when nothing is happening and never covers the farm",
              "Events are emitted by core as data and formatted by the view",
              "A key expands it into a scrollable history for the night"],
         dod=["A night at 4x is followable from the log alone",
              "It holds a bounded number of entries and cannot grow without "
              "limit"]),

    # ============================================= phase 7 - shell and product
    dict(id=91, phase=P7, title="The title screen", slug="title-screen",
         deps=[81, 6],
         files="src/ui/title_screen.gd, scenes/Title.tscn",
         goal="The game currently boots into a farm. Make it boot into a game.",
         req=["The farm at dusk behind the title, with the night creeping in - "
              "the premise, in one image",
              "The logo, generated with the same tools as everything else",
              "Continue, New run, Statistics, Options, Quit",
              "Continue is absent, not greyed, when there is no save",
              "Any key or click moves past the ident into the menu"],
         dod=["Booting lands here and not in a run",
              "The screen says what kind of game this is before a word is read"]),

    dict(id=92, phase=P7, title="The main menu and the router",
         slug="main-menu", deps=[91, 10],
         files="src/core/app.gd, src/ui/main_menu.gd",
         goal="One router that owns which screen is up, so screens stop knowing "
              "about each other.",
         req=["An `App` autoload with `goto(state)` and a `state_changed` signal",
              "States: BOOT, TITLE, MENU, RUN, TECH, STATS, OPTIONS, SUMMARY",
              "A back stack, so Options returns to whoever opened it",
              "No `get_node('/root/...')` reaching across screens",
              "The run becomes one state rather than the root scene"],
         dod=["Options from the title and from the pause menu both return "
              "correctly",
              "`input_check` still drives a full night after the refactor"]),

    dict(id=93, phase=P7, title="Options: video", slug="options-video",
         deps=[9, 92],
         files="src/ui/options_video.gd",
         goal="Resolution, window mode and scaling, done properly for a pixel art "
              "game.",
         req=["A resolution list built from the monitor, marking the integer "
              "multiples of 480x270",
              "Windowed, borderless and exclusive fullscreen",
              "Integer scaling on by default, with a toggle and a warning about "
              "what turning it off does",
              "VSync and an FPS cap",
              "Applied immediately with a revert countdown, so a bad mode cannot "
              "strand the player"],
         dod=["Every listed mode applies and survives a restart",
              "Picking an impossible mode reverts on its own within ten seconds"]),

    dict(id=94, phase=P7, title="Options: audio", slug="options-audio",
         deps=[83, 92],
         files="src/ui/options_audio.gd",
         goal="Master, music, effects and ambience, with a test sound on each.",
         req=["Four sliders, each writing to its bus through Settings",
              "A test sound on release, on the bus being adjusted",
              "A mute toggle that is separate from a zero slider",
              "Values persist and apply on boot"],
         dod=["Each slider affects only its own bus",
              "Muting and unmuting restores the previous levels"]),

    dict(id=95, phase=P7, title="Options: controls", slug="options-controls",
         deps=[9, 92],
         files="src/ui/options_controls.gd, src/core/input_actions.gd",
         goal="Named actions instead of hardcoded keys, and a screen to rebind "
              "them.",
         req=["Every key the game reads is a named action: move, interact, build, "
              "cancel, inventory, ability, speed, night, pause",
              "A rebind screen that detects a conflict and refuses it with the "
              "clash named",
              "Reset to defaults, per binding and for all",
              "Bindings persist through Settings",
              "Mouse bindings are included, not a special case"],
         dod=["`grep` finds no raw keycode left in `src/ui/`",
              "A rebound key works immediately and after a restart"]),

    dict(id=96, phase=P7, title="The pause menu", slug="pause-menu",
         deps=[92, 6],
         files="src/ui/pause_menu.gd",
         goal="Escape stops the world, and pausing mid-night is safe.",
         req=["Pause stops the tick accumulator: no ticks run and none are "
              "banked to run later",
              "Resume, Options, Save and quit, Abandon run",
              "Pausing mid-night and resuming produces an identical night",
              "Abandon asks twice and says what will be lost"],
         dod=["A paused night resumed gives the same hash as an unpaused one",
              "Pausing for five minutes does not fast-forward on resume"]),

    dict(id=97, phase=P7, title="English and Portuguese", slug="i18n", deps=[81],
         files="src/core/i18n.gd, assets/locale/",
         goal="Every string through a translation table, with pt-BR alongside "
              "English - the reference sheet is in Portuguese and so is the "
              "audience.",
         req=["No literal player-facing string left in code: keys only",
              "English and pt-BR CSVs, English as the fallback",
              "A checker that finds missing keys, unused keys and strings that "
              "overflow their control",
              "Language is a setting and applies without a restart",
              "Plurals and number formatting handled, not concatenated"],
         dod=["The checker reports zero missing keys in both languages",
              "Switching language mid-game updates every visible screen",
              "No pt-BR string overflows its control - the checker proves it"]),

    dict(id=98, phase=P7, title="Accessibility", slug="accessibility",
         deps=[93, 97],
         files="src/core/a11y.gd, src/ui/options_a11y.gd",
         goal="The cheap things that decide whether a lot of people can play it "
              "at all.",
         req=["Screen shake, flashing and particle density each separately "
              "reducible",
              "A larger UI scale and a high-contrast HUD option",
              "Colour-blind safe damage types: shape and icon, never colour alone",
              "Hold-to-act as an alternative to repeated pressing",
              "A slower game speed option that scales the tick budget, not the "
              "rules"],
         dod=["Every damage type is identifiable in greyscale",
              "The slow speed option does not change the determinism hash",
              "The game is playable start to finish with shake and flashing off"]),

    dict(id=99, phase=P7, title="An icon and a boot ident", slug="icon-ident",
         deps=[14, 91],
         files="tools/gen_icon.py, assets/icon.png",
         goal="Something recognisable in a taskbar and on an itch page, and two "
              "seconds before the title that are not the Godot logo.",
         req=["An icon generated at every size a platform asks for, readable at "
              "16x16",
              "It says farm and night in one image",
              "The boot splash is replaced; no default Godot branding anywhere",
              "A short ident, skippable on any input"],
         dod=["The 16x16 icon is still recognisable",
              "No Godot logo appears anywhere in a release build"]),

    dict(id=100, phase=P7, title="Exports: Windows and Web",
         slug="exports", deps=[5, 92],
         files="export_presets.cfg, tools/release.py",
         goal="Two builds anyone can run, from one command, with the Web one "
              "small enough that a stranger will wait for it.",
         req=["`python tools/release.py` builds both and writes them into "
              "`build/`",
              "The Web build excludes `implementation/`, `tools/`, `docs/` and "
              "previous builds from the pack - check, because this is where that "
              "goes wrong",
              "A wire-size budget for the Web build, gzipped, and the build fails "
              "when it is exceeded",
              "The Web build takes focus and audio correctly on first click",
              "The version and the build date are baked in and shown on the title "
              "screen"],
         dod=["Both builds run a full night on a machine without Godot installed",
              "The Web build is inside its budget and the number is printed",
              "The two builds produce the same determinism hash"]),

    # ==================================================== phase 8 - ship the MVP
    dict(id=101, phase=P8, title="Onboarding in seven lines",
         slug="onboarding", deps=[41, 97],
         files="src/core/tutorial.gd",
         goal="A stranger reaches night 1 and understands the loop, with no more "
              "text than the design document allows.",
         req=["Seven lines, total, across the whole first day",
              "Each appears on the thing it describes",
              "The reality switch is explained by showing it, not by describing "
              "it",
              "Every line is translated",
              "Watch someone play it and write down where they stopped"],
         dod=["A first-time player reaches the end of night 1 without being told "
              "anything out loud",
              "The journal names where they hesitated, because that is the "
              "finding"]),

    dict(id=102, phase=P8, title="A performance budget", slug="perf-budget",
         deps=[5, 60],
         files="tools/perf.py, src/tools/perf_check.gd",
         goal="A number, checked automatically, instead of a feeling about "
              "whether it runs well.",
         req=["A budget in milliseconds per frame for the worst case: night 10, "
              "everything built, lights and particles on",
              "A headless benchmark that reports tick cost, path cost and entity "
              "count",
              "Wired into `verify.py`, failing when the budget is exceeded",
              "A baseline file, moved deliberately the way the hash is",
              "The report names the most expensive system, so a regression points "
              "at itself"],
         dod=["The worst case is inside the budget on this machine",
              "Adding a deliberately slow loop makes verify fail and name it"]),

    dict(id=103, phase=P8, title="Crash and error reporting", slug="error-report",
         deps=[10],
         files="src/core/crash.gd",
         goal="When it breaks on someone else's machine, get enough to fix it "
              "without them.",
         req=["A handler that writes state, seed, tick, phase and the last log "
              "lines to `user://crash/`",
              "A dialogue offering the file's location rather than vanishing",
              "The run save is preserved, not overwritten by the crash",
              "No personal data in the report - say what is in it",
              "It never sends anything anywhere by itself"],
         dod=["A deliberate crash produces a report with the seed and the tick",
              "The run is still loadable afterwards"]),

    dict(id=104, phase=P8, title="Saves survive an update", slug="save-compat",
         deps=[10, 62],
         files="src/core/save.gd",
         goal="Adding a lever or a tech node must not delete somebody's run.",
         req=["A save version and a migration per bump, applied in order",
              "A missing key takes the default; an unknown key is dropped with a "
              "warning",
              "Golden saves in the repository, one per version, loaded by "
              "`verify.py`",
              "A save that cannot be migrated says so, keeps the file, and "
              "offers a new run"],
         dod=["Every golden save loads and plays",
              "Adding a resource to game_data does not break a save that predates "
              "it"]),

    dict(id=105, phase=P8, title="A playtest build", slug="playtest-build",
         deps=[100, 103],
         files="tools/playtest.py",
         goal="A build to put in front of someone, with the instrumentation to "
              "learn something from it.",
         req=["A build flag that turns on local session logging: nights reached, "
              "time per day, what was built, where the run ended",
              "The log is a local file the player can read and send, never an "
              "upload",
              "A one-page note for the tester: what to try, what to ignore, what "
              "to report",
              "An in-game feedback key that timestamps a note into the log",
              "It is obvious it is a playtest build"],
         dod=["A session produces a readable log",
              "`tools/playtest.py` summarises a folder of logs into the "
              "questions that matter"]),

    dict(id=106, phase=P8, title="The release checklist", slug="release-checklist",
         deps=[105, 99],
         files="implementation/RELEASE.md",
         goal="The list you run before publishing, written once, so nothing is "
              "remembered at the wrong moment.",
         req=["Every check with its command: verify, exports, save compatibility, "
              "the i18n checker, the perf budget, both builds smoke-tested",
              "Version bump, changelog, and a tag",
              "A known-issues section that is honest",
              "A rollback plan in one paragraph",
              "Run it once, end to end, and fix what it finds"],
         dod=["Running the list top to bottom produces a publishable build",
              "The journal records what the first run of it found, because it "
              "will find something"]),

    dict(id=107, phase=P8, title="Store assets", slug="store-assets",
         deps=[82, 99],
         files="tools/gen_marketing.py, build/store/",
         goal="The page it goes on: capsule images, screenshots, the pitch, "
              "generated from the game rather than mocked up.",
         req=["Capsules at the usual sizes, from the real game and the real "
              "palette",
              "Five screenshots from `shot.gd`, picked to show the loop, not five "
              "of the farm",
              "The elevator pitch from section 20 of the design document, edited "
              "to fit a store page",
              "An animated GIF of the reality switch",
              "English and Portuguese copy"],
         dod=["One command regenerates the whole set",
              "The screenshots show a day, a night, the switch, a busy wave and "
              "the tech tree"]),

    dict(id=108, phase=P8, title="The devlog and a trailer clip",
         slug="devlog", deps=[82, 107],
         files="tools/devlog.py, docs/devlog/",
         goal="The thing that gets people to look: thirty seconds that show the "
              "farm, the switch and the horde.",
         req=["A scripted capture: a day of farming, the transition, a night "
              "holding, a wall falling",
              "It is captured from a seeded run, so it can be captured again",
              "A devlog page from the journal: what the loop was meant to be and "
              "what it turned out to be",
              "Honest about what is not in the MVP",
              "Both in English and Portuguese"],
         dod=["The clip is thirty seconds and needs no explanation",
              "The devlog is generated from `implementation/PROGRESS.md` rather "
              "than written twice"]),
]
