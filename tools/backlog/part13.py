# -*- coding: utf-8 -*-
"""Backlog part 13: shipping 1.0.

The last phase changes no rule the year depends on. It makes sure a 0.1 save
survives the jump, gives the new controls their options, teaches the first
week, reads every new word again in Portuguese, and then puts the year in
front of a tester, on a store page and into a release. It sits last because
each of these reads what everything before it built - and only the store page
and the release wait for the last art pack.
"""

P17 = "17 - Ship 1.0"

TASKS = [
    # ===================================================== phase 17 - ship 1.0
    dict(id=291, phase=P17, title="Saves into 1.0", slug="saves-v1",
         deps=[151, 156, 165, 279, 287],
         files="src/app/save.gd, src/tools/make_goldens.gd, "
               "src/tools/play_goldens.gd (new), tools/verify.py, "
               "tools/goldens/, src/ui/title_screen.gd, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/headless_check.gd, "
               "assets/locale/strings.csv",
         goal="Somebody who played the 0.1 prototype opens 1.0 and finds "
              "their farm in the calendar, or is told plainly where it went - "
              "never a crash and never an empty title. This is the last look "
              "at every save shape before a stranger's save depends on it.",
         req=["An inventory first, in the journal: every `State.VERSION` "
              "from 1 to now, the task that bumped it, its step in "
              "`Save.migrations()` and its golden in `tools/goldens/`. A "
              "version with no step is fixed here. Only the 0.1 shape "
              "(State 4) was ever in a player's hands, so the versions in "
              "between need their step, not a golden each",
              "The real 0.1 golden is 0151's `run-v4.sav` (made from the MVP "
              "commit `bea89a88`: State 4, BuildInfo 0.1.0). If it is "
              "missing, make it the same way: check that commit out in a "
              "`git worktree` outside the repository, `--import` it, run "
              "`make_goldens.gd` there with `GODOT` set, copy back only the "
              "v4 goldens and remove the worktree. A golden that exists is "
              "never regenerated",
              "Two declared shapes beside it, made by `make_goldens.gd` from "
              "`run-v4.sav`'s raw payload (no migration, no reconcile - read "
              "underneath `Save.read_run_at` the way `headless_check`'s "
              "`_payload_of` does), each consistent with itself the way the "
              "MVP moved its counters (`day`, `night`, `nights_won`, "
              "`nights_paid`, the bosses down), and declared as shapes in "
              "the script's header like `run-v1-newer.sav`: "
              "`run-v4-endless.sav`, a run carried on past night 10 "
              "(`endless` true, `nights_won` 11, in DAY), and "
              "`run-v4-finished.sav`, a won MVP run (`nights_won` 10, "
              "`endless` false, in RESULT with `last_result.run_over` true)",
              "A written rule, per shape, migrate or archive, decided by one "
              "pure function in `Save` (e.g. `Save.verdict(state)`, asked of "
              "the migrated state): a run inside nights 1-10 migrates to its "
              "calendar day through 0151's step; the endless and finished "
              "shapes migrate only if they land on a day whose night "
              "resolves and whose boss bookkeeping (0153's hold at day 14) "
              "is consistent, and are archived otherwise. The rule and why "
              "go in the journal and in `Save`'s doc comment",
              "Archiving never deletes, and only the player's run moves: "
              "`Save.read_run()` (`RUN_PATH`) moves an archived run to "
              "`user://archive/run-v<N>-<k>.sav` (never over a file already "
              "there) and reports a new `Save.ARCHIVED` trouble; "
              "`read_run_at` gives the same verdict and moves nothing, so a "
              "golden in `res://` is never touched. CONTINUE is absent and "
              "the title says so once, the `SAVE_ARCHIVED` line on its own "
              "rather than under `SAVE_UNREADABLE`/`SAVE_KEPT` (nothing was "
              "unreadable), a row with a real width - e.g. 'Your 0.1 run is "
              "kept in the archive folder. 1.0 starts a new year.' / 'Sua "
              "partida da 0.1 ficou guardada no arquivo. A 1.0 começa um "
              "ano novo.'",
              "The profile is kept: a 0.1 profile (`runs_started`, "
              "`runs_won`, `best_night`, `stats`) loads through "
              "`Save.read_profile` with its numbers, and every 1.0 key (the "
              "fish book of 0182, the collections and achievements of 0287) "
              "at its default. 0160 left `best_night` to this task: decide "
              "and record whether it still means 'most nights won in one "
              "run'. A key whose meaning moved gets a named step in a "
              "profile version of its own (e.g. `Save.PROFILE_VERSION` and a "
              "`profile_migrations()` table run through `Save.step_up` in "
              "`read_profile`; `FORMAT_VERSION` is the file header's, not "
              "the profile's), never a silent reread. A `profile-v1.sav` "
              "shape goes in `tools/goldens/` (add "
              "`Save.read_profile_at`/`write_profile_at` if the pair is "
              "missing). The 0.1 `settings.cfg` is 0293's, beside its "
              "`Settings.VERSION` bump",
              "Fix `_task_0104_saves` in `headless_check.gd`: `_goldens()` "
              "lists only `run-v*.sav` (the profile golden and any settings "
              "fixture are not runs); a shape the rule archives is asserted "
              "refused with `Save.ARCHIVED`, not 'loads'; and 'a farm "
              "somebody built on' compares against the occupant count of "
              "`State.create(seed)` in this build, not the MVP's 106 - since "
              "0156 a fresh farm can pass that number on its own",
              "A day and a night for every golden is a tool, not the suite "
              "(a dozen goldens times a night to dawn is minutes of ticks): "
              "`src/tools/play_goldens.gd` loads every run golden the rule "
              "migrates, plays 600 day ticks, goes to bed and through "
              "0118's road (START, the night runner to dawn, "
              "`confirm_result`), and checks it wakes on the next calendar "
              "date in DAY with no enemy left on the farm; `tools/verify.py` "
              "runs it as a `goldens` row through `check_script`. The suite "
              "keeps load + 600 ticks per golden",
              "Saves never touch the determinism scenario: SIM and DATA "
              "stay where they are"],
         dod=["`_task_0291_saves` in `src/tools/headless_v1.gd`: each 0.1 "
              "shape (`run-v4.sav`, `-endless`, `-finished`) gets the "
              "rule's verdict; a migrated one lands on the date the rule "
              "says and plays 600 ticks; an archived one, copied to "
              "`Save.RUN_PATH` and read through `Save.read_run()`, ends "
              "byte for byte under `user://archive/`, `Save.can_continue()` "
              "is false and the title's `trouble_says()` holds the "
              "`SAVE_ARCHIVED` line (the group removes the files it made)",
              "the same group: the 0.1 profile golden loads through "
              "`Save.read_profile_at` with its numbers (and `best_night` as "
              "the journal decided) and every 1.0 key at its default",
              "verify prints the `goldens` row passing: every migrated "
              "golden woke on its next date in DAY with no enemy on the "
              "farm - the dates and the row's time in the journal",
              "the title with the archive line captured at 1920x1080 in "
              "both languages (`python tools/shot.py 0291 --title --fhd` "
              "and `--title --fhd --pt_BR`, staging an archived run in "
              "`shot.gd` the way the crash dialogue is staged, and putting "
              "back any real `user://run.sav` afterwards) and opened: the "
              "line fits and sits clear of the menu"]),

    dict(id=292, phase=P17, title="Options for the new controls",
         slug="options-v1", deps=[131, 180, 158],
         files="src/app/settings.gd, src/app/input_actions.gd, "
               "src/ui/options_controls.gd, src/ui/options_game.gd, "
               "src/ui/guardian_cursor.gd, src/ui/main.gd, "
               "src/ui/world_view.gd, src/ui/forecast_panel.gd, "
               "src/ui/day_hud.gd, assets/locale/strings.csv, "
               "src/tools/input_v1.gd, src/tools/headless_v1.gd",
         goal="The guardian's cursor, the night camera and the fishing bar "
              "each get the knob a player reaches for: how fast the cursor "
              "moves, whether the screen edge pans, how far a stick must "
              "tilt, a kinder fishing bar, and a forecast that stays up all "
              "day.",
         req=["Five keys in `Settings.DEFAULTS` (`src/app/settings.gd`), "
              "each in its page's `resets` and with a row: "
              "`controls/cursor_speed` (percent of the repeat rate 0131 "
              "shipped, steps 50/75/100/150/200), `controls/edge_pan` (on), "
              "`controls/pad_deadzone` (0.10-0.50 in 0.05 steps, default "
              "what 0121 shipped - `project.godot` has 0.2 on the move "
              "actions today), `gameplay/fishing_assist` and "
              "`gameplay/forecast_all_day` (both off). A key 0130, 0131 or "
              "0180 already made is reused, never doubled",
              "Cursor speed, edge pan and deadzone are input preferences, "
              "not rules: 0131's hold-repeat in `guardian_cursor.gd` scales "
              "its rate by cursor speed, 0130's edge-band pan in `main.gd`/"
              "`world_view.gd` runs only with edge pan on, and "
              "`InputActions` applies the deadzone with "
              "`InputMap.action_set_deadzone` to the move, pan and cursor "
              "actions (0121, 0130, 0131). Their step lists sit with their "
              "rows on the options pages, the way `OptionsA11y.ROWS` and "
              "`Video.FPS_CAPS` keep theirs - preferences, not balance, so "
              "not in `game_data.gd`, and neither hash moves for them",
              "Fishing assist: 0180 shipped it as a rule - a run flag written "
              "through an intent from its Settings key, the zone wider and "
              "the marker slower, never read by core from `Settings` - and "
              "left only the row. Reuse 0180's key (rename nothing) and its "
              "levers. If 0180 left a gap (core reading `Settings`, a "
              "strength with no `# LEVER` in `GameData.FISHING`, a view-side "
              "widening that changes catches), fix it here and say so: a "
              "new lever moves DATA and a rule fix moves SIM, on purpose, "
              "both numbers in the journal; otherwise neither hash moves",
              "Forecast all day is view only: 0158's panel "
              "(`src/ui/forecast_panel.gd`, shown by `day_hud.gd`) shows "
              "from 06:00 instead of 18:00 and still hides once START is "
              "pressed. The forecast is a pure function of (seed, date), "
              "so seeing it at breakfast can never change the night",
              "Rows where a player looks for them: cursor speed, edge pan "
              "and deadzone under a heading on the controls page "
              "(`OptionsControls`), fishing assist and the forecast on the "
              "game page (`OptionsGame`). Both pages still work by keyboard, "
              "mouse and pad, and RESET puts the new keys back",
              "Applied live and kept: a change made with a night up behind "
              "the options moves the cursor and the camera at once, the way "
              "`SimDriver` hears `gameplay/night_speed` through "
              "`Settings.changed`, and every value survives a restart "
              "through `settings.cfg`. New keys alone need no "
              "`Settings.VERSION` bump",
              "Strings in `assets/locale/strings.csv` with real widths, under "
              "each page's prefix (`CTL_CURSOR_SPEED`, `CTL_EDGE_PAN`, "
              "`CTL_DEADZONE`, a `CTL_*` heading, `GAME_FISHING_ASSIST`, "
              "`GAME_FORECAST_ALL_DAY`), toggles reusing `OPT_ON`/`OPT_OFF`: "
              "e.g. CURSOR SPEED / VELOCIDADE DO CURSOR, EDGE PAN / ROLAR "
              "PELA BORDA, STICK DEADZONE / ZONA MORTA DO ANALÓGICO, FISHING "
              "ASSIST / PESCA ASSISTIDA, FORECAST ALL DAY / PREVISÃO O DIA "
              "TODO"],
         dod=["`_case_0292_options` in `src/tools/input_v1.gd` steps each new "
              "row by keyboard and by pad, finds the value in `Settings` "
              "and in a reloaded `settings.cfg`, and RESET puts it back",
              "the same case at night: with edge pan on, a pointer held in "
              "0130's edge band for a second moves the camera, and with it "
              "off it does not (a synthetic mouse motion into the band, or "
              "the edge-pan helper 0130's pan reads if the headless window "
              "cannot hold focus); a stick tilt under the deadzone moves no "
              "cursor and one over it does; a held d-pad at 200 crosses "
              "about twice the cells it crosses at 100",
              "the same case by day: with forecast all day on, the panel is "
              "up at 08:00, and with it off it is hidden at noon as "
              "`_case_0158_panel` expects; with fishing assist on, the next "
              "cast carries 0180's assist flag, and with it off it does not",
              "`_task_0292_options` in `src/tools/headless_v1.gd`: no file in "
              "`src/core/` names `Settings`; `Forecast.tonight` gives the "
              "same record at 08:00 as at 18:00",
              "the controls and game pages captured at 1920x1080 in both "
              "languages (`$GODOT --path . --position -4000,-4000 --script "
              "res://src/tools/capture_menus.gd -- "
              "--out=res://implementation/shots/0292/`, then again with "
              "`--pt_BR`) and opened: no label runs off its row and no two "
              "rows overlap"]),

    dict(id=293, phase=P17, title="The first week, taught",
         slug="onboarding-v1", deps=[195, 141, 158, 180],
         files="src/core/game_data.gd, src/core/tutorial.gd, "
               "src/ui/tutorial_prompt.gd, src/app/settings.gd, "
               "tools/goldens/, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="A stranger learns 1.0 the way they learned the MVP's first day "
              "- one short line, on the thing it is about, gone when it is "
              "done - but spread over Spring 1 to 7, so the first morning is "
              "not a lecture and the forecast, the bin and the rod arrive "
              "when they first matter.",
         req=["Start from what 0141 and 0195 left in `GameData.TUTORIAL` and "
              "write the week down as data: each step gains the Spring date "
              "it may first show (e.g. `from_day`, read against "
              "`Calendar.date`), in the order a week happens - day 1 chop, "
              "plant, water, the bed, the cursor, START and dawn; the bin "
              "and the stall once there is something to sell; the forecast "
              "at 18:00 of the first night with something new in it; the "
              "rod and the minigame mid-week; the season and the Full Moon "
              "by day 7. Where a 0195 tip already teaches a lesson (the "
              "bin, the first bite, a new season), the week takes it over "
              "or leaves it to the tip - one line per lesson, never both. "
              "The schedule is the task's to justify in the journal",
              "It still watches and never gates (the `Tutorial` header): "
              "`Tutorial.tick` keeps checking every step, a step done early "
              "by a player who found it alone is done, and `current()` and "
              "`points_at()` only offer steps whose day has come. Keep "
              "0141's assert that ignoring the prompts reaches the same "
              "night with the same state apart from `tutorial` - one day "
              "and night in the suite, never Spring 1-7",
              "Every step finishes on something the state shows: the "
              "forecast step is done when the night it forecast begins, not "
              "when a panel was looked at - the rules cannot see the screen",
              "Short, per day: `check_tutorial` counts the week's lines per "
              "day against a new `# LEVER` `MAX_TUTORIAL_LINES_PER_DAY` "
              "(3-7, start at 5) and the week against `MAX_TUTORIAL_LINES`, "
              "whose comment and range are raised only as far as the week "
              "needs, with the reason in the journal (0195's tips keep their "
              "own check and do not count per day). "
              "`MAX_TUTORIAL_LINE_LENGTH` is unchanged, and no line "
              "describes the switch of reality - the bed and the fade show "
              "it",
              "Never twice, but the new lessons still reach a returning "
              "player: `gameplay/tutorial_seen` is one bool, so whoever "
              "finished the 0.1 day one would never see the bed or the "
              "cursor. Unless 0141 or 0195 already changed it, make it the "
              "list of step ids seen, with a `Settings.VERSION` bump whose "
              "`Settings._migrate` turns `true` into the 0.1 steps. The bump "
              "gets its golden: a 0.1 `settings.cfg` fixture in "
              "`tools/goldens/` (e.g. `settings-v1.cfg`, in the format "
              "`git show bea89a88:src/app/settings.gd` saves, with a "
              "non-default language, volumes, a rebind and `tutorial_seen` "
              "true) - the fixture goes in even if 0141 or 0195 already "
              "changed the key",
              "Each line sits on its thing through `tutorial_prompt.gd`: the "
              "bed, the cursor's cell, the START button, the forecast panel, "
              "the bin, the pond. At night the line follows the camera, not "
              "the sleeping farmer",
              "Rewrite in place what assumed every step shows on day one: "
              "`_task_0041_tutorial` in `headless_check.gd`, 0141's "
              "`_task_0141_tutorial`/`_case_0141_tutorial` and 0195's tip "
              "groups in `headless_v1.gd`/`input_v1.gd`",
              "Every line is a `TUT_*` row in both languages with a real "
              "width. `TUTORIAL` is in `GameData.digest()`, so DATA moves on "
              "purpose; SIM moves only if the done list in the determinism "
              "scenario changes - say which, both numbers in the journal",
              "What the loop cannot know - whether a stranger reads them - "
              "becomes a question in 0295's tester note, not a guess here"],
         dod=["`check_tutorial` passes, and the journal has the week as a "
              "table: day, steps, lines",
              "`_task_0293_first_week` in `src/tools/headless_v1.gd`: a "
              "scripted player that only does what `Tutorial.current()` and "
              "`points_at()` ask gets from Spring 1 at 06:00 to Spring 2's "
              "morning with the house standing and every day-1 step done "
              "(going to bed early, so the group stays a few seconds); no "
              "step is offered before its day",
              "the same group: the 0.1 `settings.cfg` fixture loads with its "
              "language, volumes and rebind kept, every key it lacks at its "
              "`Settings.DEFAULTS` value, and its `tutorial_seen` of `true` "
              "migrated to the 0.1 step ids, so only the new steps are "
              "offered",
              "1920x1080 captures of the bed line, the cursor line at night "
              "and the forecast line at dusk, in both languages (new "
              "scenarios such as `tut_bed`, `tut_cursor`, `tut_forecast`: "
              "`python tools/shot.py 0293 tut_bed tut_cursor tut_forecast "
              "--fhd` and again with `--pt_BR`), opened: each line is on its "
              "thing and nothing on screen covers it"]),

    dict(id=294, phase=P17, title="Every new word in Portuguese",
         slug="translation-v1", deps=[287, 293, 291, 292],
         files="assets/locale/strings.csv, tools/i18n_check.py, "
               "src/ui/names.gd, src/tools/headless_v1.gd",
         goal="Portuguese is the owner's language and most of the audience's. "
              "Every line 1.0 added gets read again as a whole: one name for "
              "each thing, sentences that agree in gender and number, and "
              "nothing running off its button.",
         req=["Read every row added since 0112 (`git log -p -- "
              "assets/locale/strings.csv` from 0112's commit on) in both "
              "languages, then on screen. The journal lists every pt_BR "
              "change with the before and the after",
              "One name per thing, and the plan's: its names become a "
              "glossary in `tools/i18n_check.py` (key to expected pt_BR, "
              "compared without case) that fails a row which drifts - the "
              "seasons, Lua Cheia, Lua de Sangue, neblina, chuva, essência, "
              "caixa de envio, mascate, banca, guardião, COMEÇAR, the crops "
              "of §3.1, the fish of §3.2, the machines of §3.5, the defences "
              "of §5, the enemies and bosses of §6, ossos, farinha de osso, "
              "pedras da lua",
              "Three MVP names disagree with the plan today: "
              "`DEF_FLAME_TOWER` 'torre de fogo' (plan: lança-chamas), "
              "`ENEMY_BREAKER` 'quebrador' (destruidor) and `ENEMY_TANK` "
              "'brutamontes' (tanque). The plan wins unless the journal "
              "records the owner choosing otherwise; the plurals and every "
              "sentence that uses them move with them",
              "Counted names have plurals: every enemy, fish, crop and item "
              "a line counts (the forecast's '34 andarilhos', the morning "
              "report, the fish book) has its `.other` row in both "
              "languages - the bare key is the singular, and a `.one` row "
              "exists only where the counted singular differs from the "
              "name, as `I18n.plural` documents",
              "Agreement: a pt_BR line that puts a name into a sentence "
              "agrees with it ('a Colheitadeira caiu', 'o Gigante caiu'). "
              "Where one template cannot agree with every name, rewrite it "
              "so the name stands alone ('Caiu: %s') rather than adding "
              "gender data to the rules",
              "Widths: every row added since 0112 that is drawn in a fixed "
              "control (HUD label, button, hotbar tooltip, option row) and "
              "still has `width` 0 - which means unchecked - is measured and "
              "given its real width. `python tools/i18n_check.py --report` "
              "names the widest lines, and the widest pt_BR ones are looked "
              "at on screen. `i18n_check` already refuses a glyph the font "
              "lacks; look at the accented ones in use (ã, õ, ç, ê, á, and "
              "capitals on buttons such as COMEÇAR) at 1920x1080 too",
              "`Names.KEYS` covers every id 1.0 added and `Names.NOTES` every "
              "tech node (already asserted); `ITEM_TECH` reads essence / "
              "essência (0219's rename, the id stays `tech`) and the "
              "glossary holds it there. Text only: neither hash moves"],
         dod=["`python tools/i18n_check.py` passes with the glossary "
              "enforced, and fails when one glossary row is changed by hand "
              "(tried once, reverted, said in the journal)",
              "`_task_0294_names` in `src/tools/headless_v1.gd`: every id in "
              "`CROPS`, `RESOURCES`, `DEFENCES`, `ENEMIES`, `BUILDINGS`, "
              "`RECIPES`, `TECH_TREE` and the fish species of 0179 has a "
              "`Names.KEYS` key whose row is non-empty in `en` and in "
              "`pt_BR` read straight from the table (no English fallback, "
              "no key printed as itself), and its pt_BR text differs from "
              "its English one unless the glossary marks the word as the "
              "same in both",
              "pt_BR captures at 1920x1080 of both HUDs, the forecast, the "
              "hotbar, the morning report, the fish book, the collections "
              "and every options page (`python tools/shot.py 0294 --fhd "
              "--pt_BR` and `capture_menus.gd -- "
              "--out=res://implementation/shots/0294/ --pt_BR`), opened one "
              "by one: no clipped, overlapping or English word"]),

    dict(id=295, phase=P17, title="A playtest build of the year",
         slug="playtest-v1", deps=[280, 291, 292, 293, 294],
         files="src/app/playtest.gd, src/ui/main.gd, tools/playtest.py, "
               "docs/PLAYTEST.md, src/tools/headless_v1.gd, "
               "src/tools/headless_check.gd",
         goal="Put the year in front of somebody and learn from it: a build "
              "that says it is a playtest, a log of what 1.0 is about - "
              "bedtimes, the build step, dawn, seasons, lost nights - and a "
              "reader that answers 1.0's questions instead of the MVP's. It "
              "goes out with the art that has arrived, placeholders and all.",
         req=["The log learns the calendar: `Playtest.watch` writes the "
              "season and day when a day begins ('Spring 3 began'), the hour "
              "he went to bed or that he passed out at 02:00, how long the "
              "build step ran before START, how the night ended (dawn, all "
              "killed, the house fell) and when a boss night repeats - all "
              "in the `  m:ss  what` shape the reader parses",
              "A lost night no longer ends the session: today `watch` calls "
              "`run_ended` on `night_lost` ('the house fell on night N'), "
              "which in 1.0 is a setback inside a run. A session ends at the "
              "end of the year (0160's ending), at Abandon (`main.gd`) or "
              "when the window closes. `run_ended`'s 'reached night' reads "
              "the calendar date - 0151 named `playtest.gd` among the "
              "`nights_won + 1` readers; finish it here if it did not",
              "`tools/playtest.py` asks 1.0's questions: did they reach the "
              "first night; how long was Spring 1 in real minutes (the plan "
              "wants 8-10 for the day and 3-5 for the night); bed or "
              "pass-out, night by night; how long the build step ran; how "
              "far into the year they got and how many nights they lost per "
              "season (the plan's target is 2-4 lost before winter); where "
              "the notes cluster. `--self-check` gets a 1.0 sample log and "
              "fails when any answer comes back empty",
              "`docs/PLAYTEST.md` rewritten for 1.0 (it still says ten "
              "nights and a night you send for; 0117 only corrected what "
              "happens after night ten): what the game is now; the most "
              "useful stretch to play (Spring 1 to the Giant on day 14); "
              "what to try (bed early and late, the cursor by mouse and by "
              "pad, START, the bin, the rod); what to ignore, including the "
              "placeholders still on screen as `python tools/placeholders.py` "
              "(0120) lists them; the same F1 and local-log promises",
              "`_task_0105_playtest` in `headless_check.gd` stays true: if a "
              "line it reads has moved, rewrite it in the same change",
              "The build: `python tools/release.py --playtest` writes "
              "`build/playtest/` with `READ ME FIRST.md` beside it, and the "
              "badge says playtest. It builds only the Windows playtest "
              "preset, so no web budget is weighed here - `PACK_BUDGET` and "
              "`WIRE_BUDGET` are 0297's",
              "Nothing is sent: the build is made and checked and the "
              "journal says where it is. Handing it to a tester is the "
              "owner's call. Playtest code is `src/app/` and only reads the "
              "state: neither hash moves",
              "Questions the loop cannot answer - whether a stranger reads "
              "the week's lines (0293), whether a night is long enough, and "
              "0196's: after the morning's field, are the pond, the cliff "
              "and the animals worth doing for themselves or only for the "
              "night - go into PLAYTEST.md's 'what to report', not into a "
              "guess in the journal"],
         dod=["`_task_0295_playtest_log` in `src/tools/headless_v1.gd`: a "
              "short scripted run through bed, START, dawn, a lost night and "
              "the next morning writes, in order, the lines the reader "
              "parses, and the session is still open after the lost night - "
              "the lost night parked through 0118's road with the house set "
              "to fall, so the group takes seconds, not two whole nights",
              "`python tools/playtest.py --self-check` passes with the 1.0 "
              "sample, and `python tools/playtest.py <folder>` on the log "
              "that group wrote answers every question",
              "`python tools/release.py --playtest` succeeds, including its "
              "400-frame boot of the playtest build; "
              "`python tools/shot.py 0295 --title --playtest --fhd` shows "
              "the badge on the first screen - opened",
              "no 'ten nights' or 'night ten' is left in `docs/PLAYTEST.md`, "
              "in any case"]),

    dict(id=296, phase=P17, title="The store page and trailer for 1.0",
         slug="store-v1", deps=[290, 294],
         files="docs/STORE.md, tools/gen_marketing.py, src/tools/shot.gd, "
               "tools/devlog.py, docs/devlog/the-trailer.gif, "
               "implementation/shots/trailer/, src/tools/headless_v1.gd, "
               "src/tools/headless_check.gd",
         goal="The store page still sells the prototype: ten nights, about an "
              "hour, sixteen crops and a night you send for. Make it describe "
              "the year - seasons, going to bed, the guardian on the porch, "
              "dawn - in pictures from the real game and words the data can "
              "check.",
         req=["`docs/STORE.md` rewritten in both languages: a year of four "
              "fourteen-day seasons, the night that starts when he goes to "
              "bed (or passes out at 02:00), the guardian's cursor, dawn at "
              "06:00, four bosses, what the days pay for; 'What is in it' "
              "with real counts; 'What is not' honest (nothing online, one "
              "farm, no stamina, no greenhouse, one difficulty); a length "
              "worked out from the day and night levers times 56, not hoped "
              "for. The pitch stays `design.md` §20 verbatim, which "
              "`gen_marketing.py --check` and `_task_0107_store` enforce",
              "Words the data can check: each count is a digit before a "
              "fixed noun in both sections ('12 crops' / '12 culturas'), "
              "and `_task_0296_store_copy` in `src/tools/headless_v1.gd` "
              "reads `docs/STORE.md` (the way `_task_0106_release` reads "
              "`CHANGELOG.md`) and fails when a count it states - crops, "
              "defences, enemies, bosses (`is_boss`), days in a season - "
              "disagrees with `GameData`",
              "Screenshots at 1920x1080 through `gen_marketing.py`'s "
              "`SCREENSHOTS`, its `capture()` passing `--fhd`: a spring day, "
              "the same farm in winter, going to bed, the guardian's build "
              "step with cursor and route, a wave holding, dawn with the "
              "survivors walking off, and the tech tree or the collections. "
              "Reuse the scenarios earlier tasks added (`python "
              "tools/shot.py --list`), add only the missing ones. Capsules "
              "keep `capsule()`'s rule - a whole-number `NEAREST` scale or a "
              "crop, never a smoothed resample - with `HUD_ROWS` scaled to "
              "the capture; if the header capsule comes out a close-up, "
              "pick a wider source shot and say so",
              "Rewrite `_task_0107_store` in `headless_check.gd` in place: "
              "the five picture names it looks for in `gen_marketing.py` "
              "become the new list; its pitch, `NEAREST`, `SWITCH_FRAMES` "
              "and no-`HTTPRequest` asserts stay",
              "The switch GIF and its stills come from `shot.gd --switch`, "
              "which 0129 opened with the bed beat: check it is 1.0's switch "
              "- he lies down and the farm goes dark - and fix the strip if "
              "it still sends for the night",
              "The trailer's four beats in `shot.gd` (`BEAT_DAY`, "
              "`BEAT_SWITCH`, `BEAT_NIGHT`, `BEAT_FALL` - names kept, "
              "`_task_0108_devlog` reads them) tell the 1.0 story: a day's "
              "work, going to bed, the guardian placing a defence and "
              "pressing START, a wave held until dawn. They still sum to "
              "`TRAILER_SECONDS * TRAILER_FPS`, and `devlog.py`'s "
              "`clip_caption` (EN and PT) says the new story",
              "The trailer goes through the devlog tool, and never bare (the "
              "bare command deletes the tracked frames before capturing): "
              "capture with `python tools/shot.py trailer --trailer`, look at "
              "the frames, assemble with `python tools/devlog.py --keep`. If "
              "a capture fails, `git checkout HEAD -- "
              "implementation/shots/trailer` puts the frames back. `python "
              "tools/devlog.py --check` (verify's devlog row) passes at the "
              "end. The devlog's 'what is not in it' list is 0297's, beside "
              "the Known issues it sits with",
              "`python tools/gen_marketing.py` makes the set in "
              "`build/store/`; nothing is uploaded. Captures and copy only: "
              "neither hash moves"],
         dod=["`python tools/gen_marketing.py` builds the set and `--check` "
              "passes; every screenshot and capsule is opened at full size "
              "and named in the journal",
              "`_task_0296_store_copy` passes, and fails when one count in "
              "the copy is changed (tried once, reverted, said in the "
              "journal); the rewritten `_task_0107_store` passes",
              "`docs/devlog/the-trailer.gif` is remade (its size in the "
              "journal) and watched start to finish: the bed, the cursor, "
              "START and dawn are all in it",
              "`python tools/devlog.py --check` passes and `git status` shows "
              "the trailer frames replaced, not missing"]),

    dict(id=297, phase=P17, title="Releasing 1.0", slug="release-v1",
         deps=[290, 291, 292, 293, 294, 295, 296],
         files="src/core/build_info.gd, CHANGELOG.md, "
               "implementation/RELEASE.md, export_presets.cfg, "
               "tools/release.py, tools/devlog.py, docs/devlog/, "
               "tools/goldens/, src/tools/headless_v1.gd",
         goal="Run the checklist 0106 wrote, for 1.0: one version everywhere, "
              "a changelog a player would recognise, both builds made and "
              "proven, the known issues told honestly - and then stop, "
              "because publishing is the owner's.",
         req=["Every task below 0297 is done (`python tools/task.py stats`). "
              "One that is not - an optional art leaf such as 0289 the owner "
              "declined, or a blocked task - is closed by the owner's word "
              "or listed under Known issues with why. No release over a "
              "todo nobody explained",
              "One version: `BuildInfo.VERSION` becomes `1.0.0` and `STAGE` "
              "stops saying prototype; `CHANGELOG.md` gets a 1.0.0 section "
              "on top (`_task_0106_release` requires one); both Windows "
              "presets in `export_presets.cfg` (Windows Desktop and Windows "
              "Playtest) get `application/file_version` and "
              "`application/product_version` (four numbers, `1.0.0.0`). "
              "`_task_0297_release` in `src/tools/headless_v1.gd` fails when "
              "any of them disagrees with `BuildInfo.VERSION`",
              "The changelog in sentences a player would recognise: a year "
              "of seasons, going to bed, the guardian, dawn, the new crops, "
              "fishing, animals, machines, defences, enemies and bosses, "
              "collections, the new options - and what happens to a 0.1 "
              "save (0291's rule)",
              "The save the next version must read: if "
              "`tools/goldens/run-v<State.VERSION>.sav` is missing, "
              "`make_goldens.gd` writes it from this build, and nobody "
              "regenerates it after",
              "`implementation/RELEASE.md` brought to 1.0 and run top to "
              "bottom: the tag says `v1.0.0`; step 3 names 0291's 0.1 "
              "goldens; Known issues rewritten from the journal (0280's "
              "answer, 0295's playtest, anything still on a placeholder, "
              "0290's follow-ups, the perf and wire numbers); Rollback says "
              "a 0.1 run is migrated or archived, never eaten. Keep the "
              "commands and headings `_task_0106_release` looks for",
              "The devlog describes 1.0 (moved here from 0296): "
              "`devlog.py`'s 'What is not in it' stops reading `design.md` "
              "§15 and lists what is not in 1.0 from the plan (the "
              "greenhouse of §3.1, stamina in §3.9, the Nightmare mode of "
              "§11, the one-farm pillar of §3.3 and §12) on both pages, "
              "keeping the heading `_task_0108_devlog` reads; its 'still "
              "wrong' list is the Known issues above. "
              "`docs/devlog/preamble.md` is the owner's opinion and is left "
              "alone - the journal asks for a 1.0 paragraph",
              "`python tools/release.py` - verify, stamp, both exports, the "
              "pack check, the budgets, the 400-frame boot - passes. If "
              "`PACK_BUDGET` or `WIRE_BUDGET` fails, find what grew from the "
              "pack listing and move it once, deliberately, with the old "
              "and new number and the biggest files in the journal - the "
              "way a hash moves. Version, words and builds only: neither "
              "hash moves",
              "Step 6's smoke test by hand is the owner's wherever the loop "
              "cannot do it (the Web build in a browser, a pad in the hand): "
              "the journal says what the tools checked and what is left for "
              "a person, and never claims a hand test that did not happen",
              "Nothing leaves the machine: no `git push`, no `git push "
              "--tags`, no upload. Commit the release (the runner loop's "
              "step 6) and only then, `release.py` having passed, make the "
              "annotated tag `v1.0.0` on that commit, so it holds the "
              "stamped `BuildInfo.BUILT`; the journal ends with the push "
              "and upload commands for the owner"],
         dod=["`python tools/release.py` passes and prints both builds "
              "against their budgets; the numbers are in the journal",
              "the title screen shows the 1.0.0 `BuildInfo.short()` - "
              "captured with `python tools/shot.py 0297 --title --fhd` and "
              "opened",
              "`_task_0297_release` fails on a preset whose version "
              "disagrees (tried once, reverted) and passes on the real ones; "
              "`python tools/devlog.py --check` passes with the 1.0 list",
              "`git tag -l v1.0.0` lists the local annotated tag on the "
              "commit holding this task's changes, `git status` shows "
              "nothing of this task uncommitted, and nothing was pushed"]),
]
