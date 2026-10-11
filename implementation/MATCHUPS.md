# Matchups

Every weapon's night (task 0259), written by `python tools/matchups.py` from `src/tools/matchups.gd`. Seed 2590259; a lane of the last 24 cells of the east road; the base line 2 gun towers at level one 4 cells from the house; one group of 1440 hit points of a kind - a boss with 360 of each of its season's two - sent one every 8 ticks; a fight to its clearing or 2400 ticks.

**The budget** is the dearest unit's price, 1910: money plus materials at `SELL_PRICE`, every defence at the top level its season allows. **The score** is house damage prevented against the base line alone, per thousand of the budget: what a defence adds to that line, a barrier or a support piece as much as a tower - and a defence its placement or its own limit keeps from spending it all is not made cheaper by that. Beside the lane: what shoots, lights or lures. On the road: what is walked over, and the traps. Round the house, 2 cells out from its walls, the lane's side first: the barriers. What lasts a while (the barricade, the bait) goes down when the group comes within 10 cells of the house end.

| defence | level | price | role |
|---|---|---|---|
| auto_crossbow | 3 | 985 | beside |
| barricade | 1 | 5 | ring |
| beehive | 2 | 215 | beside |
| catapult | 3 | 484 | beside |
| decoy | 1 | 20 | beside |
| electric_fence | 1 | 21 | ring |
| fence | 1 | 7 | ring |
| flame_tower | 3 | 1855 | beside |
| garlic_braid | 1 | 30 | road |
| gun_tower | 3 | 724 | beside |
| mine | 1 | 219 | road |
| mortar | 3 | 1910 | beside |
| sandbag_wall | 1 | 19 | ring |
| searchlight | 2 | 369 | beside |
| wall | 2 | 58 | ring |
| zombie_bait | 1 | 2 | road |

## The ordinary night (date 59)

| defence | breaker | crow | digger | frost_zombie | rat | runner | spitter | tank | walker | wraith | giant | harvester | scarecrow_king | winter_lord |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| *base line: house damage* | 95 | 516 | 240 | 390 | 350 | 417 | 368 | 180 | 660 | 576 | 319 | 226 | 271 | 274 |
| auto_crossbow | 49 | **270** | 125 | 204 | 145 | **218** | 192 | 54 | 345 | 0 | 146 | 90 | **119** | 110 |
| barricade | 0 | 0 | 0 | -5 | 1 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 6 | 0 |
| beehive | 44 | 270 | 3 | 5 | 101 | 18 | 0 | 0 | 345 | 0 | 105 | 41 | 87 | 5 |
| catapult | **49** | 0 | **125** | 204 | **183** | 218 | **192** | **94** | 345 | 0 | **167** | **94** | 43 | **117** |
| decoy | -31 | 0 | 0 | 0 | 0 | 4 | 0 | 94 | 10 | 0 | 27 | 0 | 0 | 41 |
| electric_fence | 49 | 0 | 0 | 0 | 2 | 4 | 0 | 0 | 0 | 0 | 8 | 1 | 1 | 0 |
| fence | 49 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 0 |
| flame_tower | 13 | 0 | 25 | 68 | 183 | 218 | 0 | 7 | 345 | 0 | 146 | 44 | 18 | 117 |
| garlic_braid | -31 | 0 | -3 | -5 | 0 | -3 | -4 | 0 | -5 | 0 | 0 | 0 | 15 | -5 |
| gun_tower | 31 | 270 | 43 | 89 | 13 | 218 | 67 | 39 | 345 | 0 | 136 | 20 | 119 | 41 |
| mine | 49 | 0 | 53 | 115 | 47 | 15 | 146 | 54 | 99 | **113** | 47 | 42 | 43 | 117 |
| mortar | 49 | 0 | 125 | **204** | 180 | 144 | 192 | 94 | **345** | 0 | 144 | 94 | 43 | 92 |
| sandbag_wall | 49 | 0 | 0 | 0 | 1 | 3 | 0 | 0 | 5 | 0 | 8 | 1 | 3 | 0 |
| searchlight | 34 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 | 18 | 6 | 0 | 1 | 2 |
| wall | 49 | 0 | 3 | 0 | 3 | 6 | 0 | 0 | 10 | 0 | 13 | 2 | 4 | 0 |
| zombie_bait | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 5 | 0 | 1 | 0 | 0 | 0 |

## The fog night (date 74)

| defence | breaker | crow | digger | frost_zombie | rat | runner | spitter | tank | walker | wraith | giant | harvester | scarecrow_king | winter_lord |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| *base line: house damage* | 95 | 519 | 240 | 400 | 352 | 420 | 376 | 180 | 670 | 576 | 316 | 227 | 274 | 284 |
| auto_crossbow | 49 | **271** | 125 | 209 | 140 | **219** | 196 | 47 | 350 | 0 | **144** | 82 | **120** | 116 |
| barricade | 0 | 0 | -3 | -5 | 1 | -3 | -4 | 0 | -15 | 0 | -3 | 0 | 1 | -5 |
| beehive | 41 | 0 | 0 | 0 | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 12 | 17 | 0 |
| catapult | 49 | 0 | **125** | 209 | **184** | 219 | **196** | **94** | 350 | 0 | 144 | **95** | 42 | **122** |
| decoy | -31 | 0 | 0 | 5 | 0 | 4 | 0 | 94 | 0 | 0 | 20 | 0 | 0 | 47 |
| electric_fence | 49 | 0 | -3 | 0 | 3 | 6 | 0 | 0 | 5 | 0 | 3 | 2 | 0 | 0 |
| fence | 49 | 0 | -3 | 0 | 1 | 1 | 0 | 0 | 5 | 0 | 1 | 1 | 0 | 0 |
| flame_tower | 10 | 0 | 9 | 26 | 142 | 219 | 0 | 0 | 350 | 0 | 144 | 37 | 12 | 94 |
| garlic_braid | -31 | 0 | -3 | 0 | 1 | -3 | -4 | 0 | -5 | 0 | -3 | 0 | 6 | 0 |
| gun_tower | 18 | 271 | 37 | 83 | 13 | 219 | 54 | 31 | 350 | 0 | 81 | 20 | 114 | 47 |
| mine | 49 | 0 | 53 | 125 | 49 | 17 | 150 | 54 | 99 | **113** | 45 | 42 | 42 | 122 |
| mortar | **49** | 0 | 125 | **209** | 180 | 138 | 196 | 94 | **350** | 0 | 139 | 95 | 42 | 97 |
| sandbag_wall | 49 | 0 | 0 | 0 | 2 | 3 | 0 | 0 | 5 | 0 | 3 | 1 | 3 | 0 |
| searchlight | 34 | 1 | 0 | 5 | 1 | 1 | 4 | 0 | 10 | 18 | 5 | 1 | 3 | 7 |
| wall | 49 | 0 | 3 | 5 | 4 | 7 | 0 | 0 | 10 | 0 | 8 | 2 | 3 | 0 |
| zombie_bait | 0 | 0 | 0 | 5 | 0 | 3 | 0 | 0 | 5 | 0 | 3 | 0 | 0 | 5 |

## The rain night (date 58)

| defence | breaker | crow | digger | frost_zombie | rat | runner | spitter | tank | walker | wraith | giant | harvester | scarecrow_king | winter_lord |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| *base line: house damage* | 90 | 516 | 240 | 390 | 347 | 414 | 368 | 180 | 640 | 576 | 310 | 223 | 250 | 274 |
| auto_crossbow | 47 | **270** | 125 | 204 | 150 | **216** | 192 | 78 | 335 | 0 | 141 | **93** | **109** | **117** |
| barricade | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | -1 | 0 |
| beehive | 47 | 270 | 6 | 10 | 106 | 216 | 0 | 7 | 335 | 0 | 135 | 43 | 87 | 15 |
| catapult | 47 | 0 | 125 | 204 | 181 | 216 | 192 | 94 | 335 | 0 | **162** | 93 | 37 | 110 |
| decoy | -34 | 0 | 0 | 10 | 0 | 4 | 0 | 94 | 10 | 0 | 24 | 0 | 0 | 41 |
| electric_fence | 47 | 0 | 0 | 0 | 1 | 4 | 0 | 0 | 0 | 0 | 4 | 2 | -3 | 0 |
| fence | 47 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | -3 | 0 |
| flame_tower | 5 | 0 | 6 | 10 | 181 | 97 | 0 | 7 | 335 | 0 | 141 | 42 | 3 | 67 |
| garlic_braid | -34 | 0 | 0 | -5 | 0 | -3 | -4 | 0 | -10 | 0 | -3 | 0 | 6 | -5 |
| gun_tower | 39 | 270 | 56 | 115 | 17 | 216 | 75 | 47 | 335 | 0 | 141 | 29 | 109 | 41 |
| mine | 47 | 0 | 56 | 120 | 46 | 15 | 150 | 62 | 125 | **113** | 35 | 41 | 39 | 117 |
| mortar | **47** | 0 | **125** | **204** | **181** | 182 | **192** | **94** | **335** | 0 | 141 | 93 | 37 | 110 |
| sandbag_wall | 47 | 0 | 3 | 5 | 1 | 3 | 0 | 7 | 0 | 0 | 3 | 1 | 0 | 0 |
| searchlight | 28 | 0 | 3 | 5 | 0 | 0 | 0 | 7 | 0 | 25 | 0 | 0 | 1 | 9 |
| wall | 47 | 0 | 6 | 5 | 3 | 7 | 0 | 7 | 10 | 0 | 4 | 2 | 3 | 0 |
| zombie_bait | 0 | 0 | 0 | 5 | 0 | 3 | 0 | 7 | 0 | 0 | 3 | 0 | 0 | 5 |

## The Blood Moon night (date 96)

| defence | breaker | crow | digger | frost_zombie | rat | runner | spitter | tank | walker | wraith | giant | harvester | scarecrow_king | winter_lord |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| *base line: house damage* | 95 | 516 | 246 | 400 | 350 | 426 | 376 | 180 | 690 | 576 | 322 | 226 | 271 | 284 |
| auto_crossbow | 34 | **270** | 65 | 104 | 107 | 223 | 125 | 31 | 361 | 0 | 147 | 54 | **119** | 91 |
| barricade | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 6 | 0 |
| beehive | 41 | 270 | 0 | 0 | 101 | 7 | 4 | 0 | 26 | 0 | 13 | 37 | 81 | 0 |
| catapult | **49** | 0 | **128** | **209** | **183** | **223** | 196 | **94** | 361 | 0 | **168** | **94** | 43 | **103** |
| decoy | -31 | 0 | 0 | 5 | 0 | 4 | 0 | 94 | 10 | 0 | 14 | 0 | 0 | 47 |
| electric_fence | 49 | 0 | 0 | 0 | 2 | 4 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 |
| fence | 49 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 0 |
| flame_tower | 7 | 0 | 12 | 20 | 183 | 31 | 0 | 0 | 319 | 0 | 146 | 44 | 6 | 83 |
| garlic_braid | -31 | 0 | 0 | -5 | 0 | -1 | -4 | 0 | -5 | 0 | -1 | 0 | 12 | -5 |
| gun_tower | 20 | 270 | 21 | 47 | 13 | 223 | 41 | 23 | 188 | 0 | 51 | 20 | 108 | 47 |
| mine | 23 | 0 | 28 | 62 | 47 | 18 | 104 | 39 | 89 | **56** | 47 | 42 | 28 | 69 |
| mortar | 49 | 0 | 128 | 209 | 180 | 108 | **196** | 94 | **361** | 0 | 142 | 94 | 43 | 78 |
| sandbag_wall | 49 | 0 | 0 | 0 | 1 | 3 | 0 | 0 | 5 | 0 | 1 | 1 | 0 | 0 |
| searchlight | 34 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 12 | 0 | 0 | 1 | -5 |
| wall | 49 | 0 | 3 | 0 | 3 | 6 | 0 | 0 | 5 | 0 | 6 | 2 | 1 | 0 |
| zombie_bait | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 5 | 0 | 1 | 0 | 0 | 0 |

## Each enemy's top three answers

- breaker, ordinary night: catapult 49, mortar 49, auto_crossbow 49
- crow, ordinary night: auto_crossbow 270, gun_tower 270, beehive 270
- digger, ordinary night: catapult 125, mortar 125, auto_crossbow 125
- frost_zombie, ordinary night: mortar 204, catapult 204, auto_crossbow 204
- rat, ordinary night: catapult 183, flame_tower 183, mortar 180
- runner, ordinary night: auto_crossbow 218, catapult 218, gun_tower 218
- spitter, ordinary night: catapult 192, mortar 192, auto_crossbow 192
- tank, ordinary night: catapult 94, mortar 94, decoy 94
- walker, ordinary night: mortar 345, catapult 345, auto_crossbow 345
- wraith, ordinary night: mine 113, searchlight 18
- giant, ordinary night: catapult 167, auto_crossbow 146, flame_tower 146
- harvester, ordinary night: catapult 94, mortar 94, auto_crossbow 90
- scarecrow_king, ordinary night: auto_crossbow 119, gun_tower 119, beehive 87
- winter_lord, ordinary night: catapult 117, flame_tower 117, mine 117
- breaker, fog night: mortar 49, catapult 49, auto_crossbow 49
- crow, fog night: auto_crossbow 271, gun_tower 271, searchlight 1
- digger, fog night: catapult 125, mortar 125, auto_crossbow 125
- frost_zombie, fog night: mortar 209, catapult 209, auto_crossbow 209
- rat, fog night: catapult 184, mortar 180, flame_tower 142
- runner, fog night: auto_crossbow 219, catapult 219, gun_tower 219
- spitter, fog night: catapult 196, mortar 196, auto_crossbow 196
- tank, fog night: catapult 94, mortar 94, decoy 94
- walker, fog night: mortar 350, catapult 350, auto_crossbow 350
- wraith, fog night: mine 113, searchlight 18
- giant, fog night: auto_crossbow 144, catapult 144, flame_tower 144
- harvester, fog night: catapult 95, mortar 95, auto_crossbow 82
- scarecrow_king, fog night: auto_crossbow 120, gun_tower 114, catapult 42
- winter_lord, fog night: catapult 122, mine 122, auto_crossbow 116
- breaker, rain night: mortar 47, catapult 47, auto_crossbow 47
- crow, rain night: auto_crossbow 270, gun_tower 270, beehive 270
- digger, rain night: mortar 125, catapult 125, auto_crossbow 125
- frost_zombie, rain night: mortar 204, catapult 204, auto_crossbow 204
- rat, rain night: mortar 181, catapult 181, flame_tower 181
- runner, rain night: auto_crossbow 216, catapult 216, gun_tower 216
- spitter, rain night: mortar 192, catapult 192, auto_crossbow 192
- tank, rain night: mortar 94, catapult 94, decoy 94
- walker, rain night: mortar 335, catapult 335, auto_crossbow 335
- wraith, rain night: mine 113, searchlight 25
- giant, rain night: catapult 162, auto_crossbow 141, flame_tower 141
- harvester, rain night: auto_crossbow 93, catapult 93, mortar 93
- scarecrow_king, rain night: auto_crossbow 109, gun_tower 109, beehive 87
- winter_lord, rain night: auto_crossbow 117, mine 117, catapult 110
- breaker, Blood Moon night: catapult 49, mortar 49, electric_fence 49
- crow, Blood Moon night: auto_crossbow 270, gun_tower 270, beehive 270
- digger, Blood Moon night: catapult 128, mortar 128, auto_crossbow 65
- frost_zombie, Blood Moon night: catapult 209, mortar 209, auto_crossbow 104
- rat, Blood Moon night: catapult 183, flame_tower 183, mortar 180
- runner, Blood Moon night: catapult 223, auto_crossbow 223, gun_tower 223
- spitter, Blood Moon night: mortar 196, catapult 196, auto_crossbow 125
- tank, Blood Moon night: catapult 94, mortar 94, decoy 94
- walker, Blood Moon night: mortar 361, catapult 361, auto_crossbow 361
- wraith, Blood Moon night: mine 56, searchlight 12
- giant, Blood Moon night: catapult 168, auto_crossbow 147, flame_tower 146
- harvester, Blood Moon night: catapult 94, mortar 94, auto_crossbow 54
- scarecrow_king, Blood Moon night: auto_crossbow 119, gun_tower 108, beehive 81
- winter_lord, Blood Moon night: catapult 103, auto_crossbow 91, flame_tower 83

## Each defence's best night

- auto_crossbow: crow, fog night (271)
- barricade: UNPROVEN: at best 6 against scarecrow_king on the ordinary night, where auto_crossbow scores 119
- beehive: UNPROVEN: at best 345 against walker on the ordinary night, where mortar scores 345
- catapult: runner, Blood Moon night (223)
- decoy: UNPROVEN: at best 94 against tank on the ordinary night, where catapult scores 94
- electric_fence: UNPROVEN: at best 49 against breaker on the ordinary night, where catapult scores 49
- fence: UNPROVEN: at best 49 against breaker on the ordinary night, where catapult scores 49
- flame_tower: UNPROVEN: at best 350 against walker on the fog night, where mortar scores 350
- garlic_braid: UNPROVEN: at best 15 against scarecrow_king on the ordinary night, where auto_crossbow scores 119
- gun_tower: UNPROVEN: at best 350 against walker on the fog night, where mortar scores 350
- mine: wraith, ordinary night (113)
- mortar: walker, Blood Moon night (361)
- sandbag_wall: UNPROVEN: at best 49 against breaker on the ordinary night, where catapult scores 49
- searchlight: UNPROVEN: at best 34 against breaker on the ordinary night, where catapult scores 49
- wall: UNPROVEN: at best 49 against breaker on the ordinary night, where catapult scores 49
- zombie_bait: UNPROVEN: at best 7 against tank on the rain night, where mortar scores 94

## For the night authors

- breaker: catapult, mortar
- crow: auto_crossbow, gun_tower
- digger: catapult, mortar
- frost_zombie: mortar, catapult
- rat: catapult, flame_tower (rain: mortar)
- runner: auto_crossbow, catapult
- spitter: catapult, mortar
- tank: catapult, mortar
- walker: mortar, catapult
- wraith: mine, searchlight
- giant: catapult, auto_crossbow
- harvester: catapult, mortar (rain: auto_crossbow)
- scarecrow_king: auto_crossbow, gun_tower
- winter_lord: catapult, flame_tower (rain: auto_crossbow)

## The claims

- every defence is the top buy somewhere: 4 of 16 - UNPROVEN: barricade, beehive, decoy, electric_fence, fence, flame_tower, garlic_braid, gun_tower, sandbag_wall, searchlight, wall, zombie_bait
- no defence is top against every enemy on the ordinary night: yes (4 different tops over 14 enemies)
- no defence is top against every enemy on the fog night: yes (4 different tops over 14 enemies)
- no defence is top against every enemy on the rain night: yes (4 different tops over 14 enemies)
- no defence is top against every enemy on the Blood Moon night: yes (4 different tops over 14 enemies)
- spitter's top answer differs from the walker's (mortar): yes - catapult
- rat's top answer differs from the walker's (mortar): yes - catapult
- crow's top answer differs from the walker's (mortar): yes - auto_crossbow
- digger's top answer differs from the walker's (mortar): yes - catapult
- frost_zombie's top answer differs from the walker's (mortar): NO - mortar
- wraith's top answer differs from the walker's (mortar): yes - mine

## Every fight

| night | enemy | defence | placed | spent | house | kills | ticks | lost | score |
|---|---|---|---|---|---|---|---|---|---|
| ordinary | breaker | *base* | - | - | 95 | 1 | 2400 | 32 | - |
| ordinary | breaker | auto_crossbow | 1 | 985 | 0 | 28 | 2400 | 20 | 49 |
| ordinary | breaker | barricade | 5 | 25 | 95 | 1 | 2400 | 32 | 0 |
| ordinary | breaker | beehive | 8 | 1720 | 10 | 2 | 2400 | 44 | 44 |
| ordinary | breaker | catapult | 3 | 1452 | 0 | 32 | 440 | 0 | 49 |
| ordinary | breaker | decoy | 22 | 440 | 155 | 1 | 1056 | 24 | -31 |
| ordinary | breaker | electric_fence | 30 | 630 | 0 | 1 | 2400 | 41 | 49 |
| ordinary | breaker | fence | 30 | 210 | 0 | 1 | 2400 | 41 | 49 |
| ordinary | breaker | flame_tower | 1 | 1855 | 70 | 5 | 2400 | 31 | 13 |
| ordinary | breaker | garlic_braid | 18 | 540 | 155 | 1 | 937 | 1 | -31 |
| ordinary | breaker | gun_tower | 2 | 1448 | 35 | 10 | 2400 | 34 | 31 |
| ordinary | breaker | mine | 6 | 1314 | 0 | 22 | 2400 | 26 | 49 |
| ordinary | breaker | mortar | 1 | 1910 | 0 | 32 | 445 | 0 | 49 |
| ordinary | breaker | sandbag_wall | 30 | 570 | 0 | 1 | 2400 | 41 | 49 |
| ordinary | breaker | searchlight | 5 | 1845 | 30 | 2 | 2400 | 44 | 34 |
| ordinary | breaker | wall | 30 | 1740 | 0 | 1 | 2400 | 41 | 49 |
| ordinary | breaker | zombie_bait | 3 | 6 | 95 | 1 | 2400 | 32 | 0 |
| ordinary | crow | *base* | - | - | 516 | 8 | 1762 | 0 | - |
| ordinary | crow | auto_crossbow | 1 | 985 | 0 | 180 | 1619 | 0 | 270 |
| ordinary | crow | barricade | 5 | 25 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | beehive | 8 | 1720 | 0 | 180 | 1683 | 0 | 270 |
| ordinary | crow | catapult | 3 | 1452 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | decoy | 22 | 440 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | electric_fence | 30 | 630 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | fence | 30 | 210 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | flame_tower | 1 | 1855 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | garlic_braid | 18 | 540 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | gun_tower | 2 | 1448 | 0 | 180 | 1644 | 0 | 270 |
| ordinary | crow | mine | 6 | 1314 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | mortar | 1 | 1910 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | sandbag_wall | 30 | 570 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | searchlight | 5 | 1845 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | wall | 30 | 1740 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | crow | zombie_bait | 3 | 6 | 516 | 8 | 1762 | 0 | 0 |
| ordinary | digger | *base* | - | - | 240 | 2 | 705 | 0 | - |
| ordinary | digger | auto_crossbow | 1 | 985 | 0 | 42 | 628 | 0 | 125 |
| ordinary | digger | barricade | 5 | 25 | 240 | 2 | 705 | 0 | 0 |
| ordinary | digger | beehive | 8 | 1720 | 234 | 3 | 705 | 0 | 3 |
| ordinary | digger | catapult | 3 | 1452 | 0 | 42 | 474 | 0 | 125 |
| ordinary | digger | decoy | 22 | 440 | 240 | 2 | 705 | 0 | 0 |
| ordinary | digger | electric_fence | 30 | 630 | 240 | 2 | 705 | 0 | 0 |
| ordinary | digger | fence | 30 | 210 | 240 | 2 | 705 | 0 | 0 |
| ordinary | digger | flame_tower | 1 | 1855 | 192 | 10 | 705 | 0 | 25 |
| ordinary | digger | garlic_braid | 18 | 540 | 246 | 1 | 804 | 0 | -3 |
| ordinary | digger | gun_tower | 2 | 1448 | 156 | 16 | 705 | 0 | 43 |
| ordinary | digger | mine | 6 | 1314 | 138 | 19 | 705 | 0 | 53 |
| ordinary | digger | mortar | 1 | 1910 | 0 | 42 | 529 | 0 | 125 |
| ordinary | digger | sandbag_wall | 30 | 570 | 240 | 2 | 705 | 1 | 0 |
| ordinary | digger | searchlight | 5 | 1845 | 240 | 2 | 705 | 0 | 0 |
| ordinary | digger | wall | 30 | 1740 | 234 | 3 | 705 | 1 | 3 |
| ordinary | digger | zombie_bait | 3 | 6 | 240 | 2 | 705 | 0 | 0 |
| ordinary | frost_zombie | *base* | - | - | 390 | 3 | 893 | 0 | - |
| ordinary | frost_zombie | auto_crossbow | 1 | 985 | 0 | 42 | 739 | 0 | 204 |
| ordinary | frost_zombie | barricade | 5 | 25 | 400 | 2 | 955 | 0 | -5 |
| ordinary | frost_zombie | beehive | 8 | 1720 | 380 | 4 | 893 | 0 | 5 |
| ordinary | frost_zombie | catapult | 3 | 1452 | 0 | 42 | 556 | 0 | 204 |
| ordinary | frost_zombie | decoy | 22 | 440 | 390 | 3 | 1177 | 21 | 0 |
| ordinary | frost_zombie | electric_fence | 30 | 630 | 390 | 3 | 893 | 1 | 0 |
| ordinary | frost_zombie | fence | 30 | 210 | 390 | 3 | 893 | 1 | 0 |
| ordinary | frost_zombie | flame_tower | 1 | 1855 | 260 | 16 | 886 | 0 | 68 |
| ordinary | frost_zombie | garlic_braid | 18 | 540 | 400 | 2 | 1042 | 0 | -5 |
| ordinary | frost_zombie | gun_tower | 2 | 1448 | 220 | 20 | 893 | 0 | 89 |
| ordinary | frost_zombie | mine | 6 | 1314 | 170 | 25 | 893 | 0 | 115 |
| ordinary | frost_zombie | mortar | 1 | 1910 | 0 | 42 | 468 | 0 | 204 |
| ordinary | frost_zombie | sandbag_wall | 30 | 570 | 390 | 3 | 893 | 1 | 0 |
| ordinary | frost_zombie | searchlight | 5 | 1845 | 390 | 3 | 893 | 0 | 0 |
| ordinary | frost_zombie | wall | 30 | 1740 | 390 | 3 | 893 | 1 | 0 |
| ordinary | frost_zombie | zombie_bait | 3 | 6 | 390 | 3 | 893 | 0 | 0 |
| ordinary | rat | *base* | - | - | 350 | 10 | 647 | 0 | - |
| ordinary | rat | auto_crossbow | 1 | 985 | 72 | 288 | 635 | 0 | 145 |
| ordinary | rat | barricade | 5 | 25 | 348 | 12 | 653 | 1 | 1 |
| ordinary | rat | beehive | 8 | 1720 | 157 | 203 | 641 | 0 | 101 |
| ordinary | rat | catapult | 3 | 1452 | 0 | 360 | 529 | 0 | 183 |
| ordinary | rat | decoy | 22 | 440 | 350 | 10 | 647 | 0 | 0 |
| ordinary | rat | electric_fence | 30 | 630 | 346 | 14 | 647 | 1 | 2 |
| ordinary | rat | fence | 30 | 210 | 348 | 12 | 647 | 1 | 1 |
| ordinary | rat | flame_tower | 1 | 1855 | 0 | 360 | 563 | 0 | 183 |
| ordinary | rat | garlic_braid | 18 | 540 | 349 | 11 | 751 | 0 | 0 |
| ordinary | rat | gun_tower | 2 | 1448 | 325 | 35 | 647 | 0 | 13 |
| ordinary | rat | mine | 6 | 1314 | 259 | 101 | 647 | 0 | 47 |
| ordinary | rat | mortar | 1 | 1910 | 5 | 355 | 635 | 0 | 180 |
| ordinary | rat | sandbag_wall | 30 | 570 | 347 | 13 | 647 | 1 | 1 |
| ordinary | rat | searchlight | 5 | 1845 | 350 | 10 | 647 | 0 | 0 |
| ordinary | rat | wall | 30 | 1740 | 344 | 16 | 647 | 1 | 3 |
| ordinary | rat | zombie_bait | 3 | 6 | 350 | 10 | 647 | 0 | 0 |
| ordinary | runner | *base* | - | - | 417 | 5 | 1356 | 0 | - |
| ordinary | runner | auto_crossbow | 1 | 985 | 0 | 144 | 1257 | 0 | 218 |
| ordinary | runner | barricade | 5 | 25 | 417 | 5 | 1380 | 0 | 0 |
| ordinary | runner | beehive | 8 | 1720 | 381 | 17 | 1356 | 0 | 18 |
| ordinary | runner | catapult | 3 | 1452 | 0 | 144 | 1257 | 0 | 218 |
| ordinary | runner | decoy | 22 | 440 | 408 | 8 | 1356 | 21 | 4 |
| ordinary | runner | electric_fence | 30 | 630 | 408 | 8 | 1356 | 1 | 4 |
| ordinary | runner | fence | 30 | 210 | 414 | 6 | 1356 | 1 | 1 |
| ordinary | runner | flame_tower | 1 | 1855 | 0 | 144 | 1309 | 0 | 218 |
| ordinary | runner | garlic_braid | 18 | 540 | 423 | 3 | 1413 | 0 | -3 |
| ordinary | runner | gun_tower | 2 | 1448 | 0 | 144 | 1287 | 0 | 218 |
| ordinary | runner | mine | 6 | 1314 | 387 | 15 | 1356 | 0 | 15 |
| ordinary | runner | mortar | 1 | 1910 | 141 | 97 | 1323 | 0 | 144 |
| ordinary | runner | sandbag_wall | 30 | 570 | 411 | 7 | 1356 | 1 | 3 |
| ordinary | runner | searchlight | 5 | 1845 | 417 | 5 | 1356 | 0 | 0 |
| ordinary | runner | wall | 30 | 1740 | 405 | 9 | 1356 | 1 | 6 |
| ordinary | runner | zombie_bait | 3 | 6 | 411 | 7 | 1356 | 0 | 3 |
| ordinary | spitter | *base* | - | - | 368 | 2 | 941 | 2 | - |
| ordinary | spitter | auto_crossbow | 1 | 985 | 0 | 48 | 721 | 0 | 192 |
| ordinary | spitter | barricade | 5 | 25 | 368 | 2 | 1003 | 2 | 0 |
| ordinary | spitter | beehive | 8 | 1720 | 368 | 2 | 1053 | 10 | 0 |
| ordinary | spitter | catapult | 3 | 1452 | 0 | 48 | 571 | 0 | 192 |
| ordinary | spitter | decoy | 22 | 440 | 368 | 2 | 941 | 2 | 0 |
| ordinary | spitter | electric_fence | 30 | 630 | 368 | 2 | 941 | 3 | 0 |
| ordinary | spitter | fence | 30 | 210 | 368 | 2 | 941 | 3 | 0 |
| ordinary | spitter | flame_tower | 1 | 1855 | 368 | 2 | 941 | 3 | 0 |
| ordinary | spitter | garlic_braid | 18 | 540 | 376 | 1 | 1090 | 2 | -4 |
| ordinary | spitter | gun_tower | 2 | 1448 | 240 | 18 | 941 | 4 | 67 |
| ordinary | spitter | mine | 6 | 1314 | 88 | 37 | 941 | 2 | 146 |
| ordinary | spitter | mortar | 1 | 1910 | 0 | 48 | 589 | 0 | 192 |
| ordinary | spitter | sandbag_wall | 30 | 570 | 368 | 2 | 941 | 3 | 0 |
| ordinary | spitter | searchlight | 5 | 1845 | 368 | 2 | 941 | 2 | 0 |
| ordinary | spitter | wall | 30 | 1740 | 368 | 2 | 941 | 3 | 0 |
| ordinary | spitter | zombie_bait | 3 | 6 | 368 | 2 | 941 | 2 | 0 |
| ordinary | tank | *base* | - | - | 180 | 0 | 982 | 0 | - |
| ordinary | tank | auto_crossbow | 1 | 985 | 75 | 7 | 982 | 0 | 54 |
| ordinary | tank | barricade | 5 | 25 | 180 | 0 | 1079 | 0 | 0 |
| ordinary | tank | beehive | 8 | 1720 | 180 | 0 | 982 | 0 | 0 |
| ordinary | tank | catapult | 3 | 1452 | 0 | 12 | 489 | 0 | 94 |
| ordinary | tank | decoy | 22 | 440 | 0 | 0 | 2400 | 19 | 94 |
| ordinary | tank | electric_fence | 30 | 630 | 180 | 0 | 982 | 1 | 0 |
| ordinary | tank | fence | 30 | 210 | 180 | 0 | 982 | 1 | 0 |
| ordinary | tank | flame_tower | 1 | 1855 | 165 | 1 | 982 | 0 | 7 |
| ordinary | tank | garlic_braid | 18 | 540 | 180 | 0 | 1218 | 0 | 0 |
| ordinary | tank | gun_tower | 2 | 1448 | 105 | 5 | 982 | 0 | 39 |
| ordinary | tank | mine | 6 | 1314 | 75 | 7 | 982 | 0 | 54 |
| ordinary | tank | mortar | 1 | 1910 | 0 | 12 | 573 | 0 | 94 |
| ordinary | tank | sandbag_wall | 30 | 570 | 180 | 0 | 982 | 1 | 0 |
| ordinary | tank | searchlight | 5 | 1845 | 180 | 0 | 982 | 0 | 0 |
| ordinary | tank | wall | 30 | 1740 | 180 | 0 | 982 | 1 | 0 |
| ordinary | tank | zombie_bait | 3 | 6 | 180 | 0 | 982 | 0 | 0 |
| ordinary | walker | *base* | - | - | 660 | 6 | 1039 | 0 | - |
| ordinary | walker | auto_crossbow | 1 | 985 | 0 | 72 | 836 | 0 | 345 |
| ordinary | walker | barricade | 5 | 25 | 660 | 6 | 1091 | 0 | 0 |
| ordinary | walker | beehive | 8 | 1720 | 0 | 72 | 1026 | 0 | 345 |
| ordinary | walker | catapult | 3 | 1452 | 0 | 72 | 706 | 0 | 345 |
| ordinary | walker | decoy | 22 | 440 | 640 | 8 | 1039 | 21 | 10 |
| ordinary | walker | electric_fence | 30 | 630 | 660 | 6 | 1039 | 1 | 0 |
| ordinary | walker | fence | 30 | 210 | 660 | 6 | 1039 | 1 | 0 |
| ordinary | walker | flame_tower | 1 | 1855 | 0 | 72 | 935 | 0 | 345 |
| ordinary | walker | garlic_braid | 18 | 540 | 670 | 5 | 1163 | 0 | -5 |
| ordinary | walker | gun_tower | 2 | 1448 | 0 | 72 | 886 | 0 | 345 |
| ordinary | walker | mine | 6 | 1314 | 470 | 25 | 1039 | 0 | 99 |
| ordinary | walker | mortar | 1 | 1910 | 0 | 72 | 680 | 0 | 345 |
| ordinary | walker | sandbag_wall | 30 | 570 | 650 | 7 | 1039 | 1 | 5 |
| ordinary | walker | searchlight | 5 | 1845 | 650 | 7 | 1039 | 0 | 5 |
| ordinary | walker | wall | 30 | 1740 | 640 | 8 | 1039 | 1 | 10 |
| ordinary | walker | zombie_bait | 3 | 6 | 650 | 7 | 1039 | 0 | 5 |
| ordinary | wraith | *base* | - | - | 576 | 0 | 800 | 0 | - |
| ordinary | wraith | auto_crossbow | 1 | 985 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | barricade | 5 | 25 | 576 | 0 | 846 | 0 | 0 |
| ordinary | wraith | beehive | 8 | 1720 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | catapult | 3 | 1452 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | decoy | 22 | 440 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | electric_fence | 30 | 630 | 576 | 0 | 800 | 1 | 0 |
| ordinary | wraith | fence | 30 | 210 | 576 | 0 | 800 | 1 | 0 |
| ordinary | wraith | flame_tower | 1 | 1855 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | garlic_braid | 18 | 540 | 576 | 0 | 913 | 0 | 0 |
| ordinary | wraith | gun_tower | 2 | 1448 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | mine | 6 | 1314 | 360 | 18 | 800 | 0 | 113 |
| ordinary | wraith | mortar | 1 | 1910 | 576 | 0 | 800 | 0 | 0 |
| ordinary | wraith | sandbag_wall | 30 | 570 | 576 | 0 | 800 | 1 | 0 |
| ordinary | wraith | searchlight | 5 | 1845 | 540 | 3 | 800 | 0 | 18 |
| ordinary | wraith | wall | 30 | 1740 | 576 | 0 | 800 | 1 | 0 |
| ordinary | wraith | zombie_bait | 3 | 6 | 576 | 0 | 800 | 0 | 0 |
| ordinary | giant | *base* | - | - | 319 | 3 | 1176 | 0 | - |
| ordinary | giant | auto_crossbow | 1 | 985 | 40 | 54 | 1176 | 0 | 146 |
| ordinary | giant | barricade | 5 | 25 | 313 | 5 | 1303 | 0 | 3 |
| ordinary | giant | beehive | 8 | 1720 | 118 | 28 | 1176 | 0 | 105 |
| ordinary | giant | catapult | 3 | 1452 | 0 | 55 | 1121 | 0 | 167 |
| ordinary | giant | decoy | 22 | 440 | 266 | 9 | 1176 | 21 | 27 |
| ordinary | giant | electric_fence | 30 | 630 | 303 | 6 | 1176 | 1 | 8 |
| ordinary | giant | fence | 30 | 210 | 316 | 4 | 1176 | 1 | 1 |
| ordinary | giant | flame_tower | 1 | 1855 | 40 | 54 | 1176 | 0 | 146 |
| ordinary | giant | garlic_braid | 18 | 540 | 319 | 3 | 1486 | 0 | 0 |
| ordinary | giant | gun_tower | 2 | 1448 | 58 | 48 | 1176 | 0 | 136 |
| ordinary | giant | mine | 6 | 1314 | 229 | 19 | 1176 | 0 | 47 |
| ordinary | giant | mortar | 1 | 1910 | 43 | 53 | 1176 | 0 | 144 |
| ordinary | giant | sandbag_wall | 30 | 570 | 303 | 6 | 1176 | 1 | 8 |
| ordinary | giant | searchlight | 5 | 1845 | 306 | 5 | 1176 | 0 | 6 |
| ordinary | giant | wall | 30 | 1740 | 293 | 7 | 1176 | 1 | 13 |
| ordinary | giant | zombie_bait | 3 | 6 | 316 | 4 | 1176 | 0 | 1 |
| ordinary | harvester | *base* | - | - | 226 | 11 | 681 | 2 | - |
| ordinary | harvester | auto_crossbow | 1 | 985 | 53 | 107 | 781 | 3 | 90 |
| ordinary | harvester | barricade | 5 | 25 | 225 | 12 | 726 | 3 | 0 |
| ordinary | harvester | beehive | 8 | 1720 | 147 | 76 | 1085 | 10 | 41 |
| ordinary | harvester | catapult | 3 | 1452 | 45 | 108 | 607 | 0 | 94 |
| ordinary | harvester | decoy | 22 | 440 | 226 | 11 | 681 | 2 | 0 |
| ordinary | harvester | electric_fence | 30 | 630 | 223 | 14 | 681 | 3 | 1 |
| ordinary | harvester | fence | 30 | 210 | 225 | 12 | 681 | 3 | 0 |
| ordinary | harvester | flame_tower | 1 | 1855 | 141 | 96 | 765 | 3 | 44 |
| ordinary | harvester | garlic_braid | 18 | 540 | 225 | 12 | 893 | 2 | 0 |
| ordinary | harvester | gun_tower | 2 | 1448 | 186 | 37 | 825 | 4 | 20 |
| ordinary | harvester | mine | 6 | 1314 | 145 | 92 | 681 | 2 | 42 |
| ordinary | harvester | mortar | 1 | 1910 | 45 | 108 | 607 | 0 | 94 |
| ordinary | harvester | sandbag_wall | 30 | 570 | 223 | 14 | 681 | 3 | 1 |
| ordinary | harvester | searchlight | 5 | 1845 | 225 | 12 | 681 | 2 | 0 |
| ordinary | harvester | wall | 30 | 1740 | 222 | 15 | 681 | 3 | 2 |
| ordinary | harvester | zombie_bait | 3 | 6 | 226 | 11 | 681 | 2 | 0 |
| ordinary | scarecrow_king | *base* | - | - | 271 | 8 | 1192 | 0 | - |
| ordinary | scarecrow_king | auto_crossbow | 1 | 985 | 43 | 73 | 1171 | 0 | 119 |
| ordinary | scarecrow_king | barricade | 5 | 25 | 259 | 12 | 1277 | 0 | 6 |
| ordinary | scarecrow_king | beehive | 8 | 1720 | 103 | 62 | 1171 | 0 | 87 |
| ordinary | scarecrow_king | catapult | 3 | 1452 | 187 | 25 | 1192 | 0 | 43 |
| ordinary | scarecrow_king | decoy | 22 | 440 | 271 | 8 | 1192 | 0 | 0 |
| ordinary | scarecrow_king | electric_fence | 30 | 630 | 268 | 9 | 1283 | 1 | 1 |
| ordinary | scarecrow_king | fence | 30 | 210 | 268 | 9 | 1268 | 1 | 1 |
| ordinary | scarecrow_king | flame_tower | 1 | 1855 | 235 | 14 | 1192 | 0 | 18 |
| ordinary | scarecrow_king | garlic_braid | 18 | 540 | 241 | 17 | 1432 | 0 | 15 |
| ordinary | scarecrow_king | gun_tower | 2 | 1448 | 43 | 73 | 1171 | 0 | 119 |
| ordinary | scarecrow_king | mine | 6 | 1314 | 187 | 25 | 1192 | 0 | 43 |
| ordinary | scarecrow_king | mortar | 1 | 1910 | 187 | 25 | 1192 | 0 | 43 |
| ordinary | scarecrow_king | sandbag_wall | 30 | 570 | 265 | 9 | 1192 | 1 | 3 |
| ordinary | scarecrow_king | searchlight | 5 | 1845 | 268 | 9 | 1192 | 0 | 1 |
| ordinary | scarecrow_king | wall | 30 | 1740 | 262 | 10 | 1192 | 1 | 4 |
| ordinary | scarecrow_king | zombie_bait | 3 | 6 | 271 | 8 | 1192 | 0 | 0 |
| ordinary | winter_lord | *base* | - | - | 274 | 3 | 1312 | 0 | - |
| ordinary | winter_lord | auto_crossbow | 1 | 985 | 62 | 22 | 1312 | 0 | 110 |
| ordinary | winter_lord | barricade | 5 | 25 | 274 | 3 | 1434 | 0 | 0 |
| ordinary | winter_lord | beehive | 8 | 1720 | 264 | 4 | 1312 | 0 | 5 |
| ordinary | winter_lord | catapult | 3 | 1452 | 50 | 23 | 1312 | 0 | 117 |
| ordinary | winter_lord | decoy | 22 | 440 | 194 | 2 | 2400 | 20 | 41 |
| ordinary | winter_lord | electric_fence | 30 | 630 | 274 | 3 | 1312 | 1 | 0 |
| ordinary | winter_lord | fence | 30 | 210 | 274 | 3 | 1312 | 1 | 0 |
| ordinary | winter_lord | flame_tower | 1 | 1855 | 50 | 23 | 1312 | 0 | 117 |
| ordinary | winter_lord | garlic_braid | 18 | 540 | 284 | 2 | 1610 | 0 | -5 |
| ordinary | winter_lord | gun_tower | 2 | 1448 | 194 | 11 | 1312 | 0 | 41 |
| ordinary | winter_lord | mine | 6 | 1314 | 50 | 23 | 1312 | 0 | 117 |
| ordinary | winter_lord | mortar | 1 | 1910 | 98 | 19 | 1312 | 0 | 92 |
| ordinary | winter_lord | sandbag_wall | 30 | 570 | 274 | 3 | 1312 | 1 | 0 |
| ordinary | winter_lord | searchlight | 5 | 1845 | 270 | 3 | 1312 | 0 | 2 |
| ordinary | winter_lord | wall | 30 | 1740 | 274 | 3 | 1312 | 1 | 0 |
| ordinary | winter_lord | zombie_bait | 3 | 6 | 274 | 3 | 1312 | 0 | 0 |
| fog | breaker | *base* | - | - | 95 | 1 | 2400 | 32 | - |
| fog | breaker | auto_crossbow | 1 | 985 | 0 | 24 | 2400 | 27 | 49 |
| fog | breaker | barricade | 5 | 25 | 95 | 1 | 2400 | 32 | 0 |
| fog | breaker | beehive | 8 | 1720 | 15 | 1 | 2400 | 45 | 41 |
| fog | breaker | catapult | 3 | 1452 | 0 | 32 | 484 | 0 | 49 |
| fog | breaker | decoy | 22 | 440 | 155 | 1 | 1054 | 24 | -31 |
| fog | breaker | electric_fence | 30 | 630 | 0 | 1 | 2400 | 41 | 49 |
| fog | breaker | fence | 30 | 210 | 0 | 1 | 2400 | 41 | 49 |
| fog | breaker | flame_tower | 1 | 1855 | 75 | 3 | 2400 | 35 | 10 |
| fog | breaker | garlic_braid | 18 | 540 | 155 | 1 | 937 | 1 | -31 |
| fog | breaker | gun_tower | 2 | 1448 | 60 | 5 | 2400 | 33 | 18 |
| fog | breaker | mine | 6 | 1314 | 0 | 22 | 2400 | 26 | 49 |
| fog | breaker | mortar | 1 | 1910 | 0 | 32 | 466 | 0 | 49 |
| fog | breaker | sandbag_wall | 30 | 570 | 0 | 1 | 2400 | 41 | 49 |
| fog | breaker | searchlight | 5 | 1845 | 30 | 2 | 2400 | 44 | 34 |
| fog | breaker | wall | 30 | 1740 | 0 | 1 | 2400 | 41 | 49 |
| fog | breaker | zombie_bait | 3 | 6 | 95 | 1 | 2400 | 32 | 0 |
| fog | crow | *base* | - | - | 519 | 7 | 1762 | 0 | - |
| fog | crow | auto_crossbow | 1 | 985 | 0 | 180 | 1633 | 0 | 271 |
| fog | crow | barricade | 5 | 25 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | beehive | 8 | 1720 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | catapult | 3 | 1452 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | decoy | 22 | 440 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | electric_fence | 30 | 630 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | fence | 30 | 210 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | flame_tower | 1 | 1855 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | garlic_braid | 18 | 540 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | gun_tower | 2 | 1448 | 0 | 180 | 1656 | 0 | 271 |
| fog | crow | mine | 6 | 1314 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | mortar | 1 | 1910 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | sandbag_wall | 30 | 570 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | searchlight | 5 | 1845 | 516 | 8 | 1762 | 0 | 1 |
| fog | crow | wall | 30 | 1740 | 519 | 7 | 1762 | 0 | 0 |
| fog | crow | zombie_bait | 3 | 6 | 519 | 7 | 1762 | 0 | 0 |
| fog | digger | *base* | - | - | 240 | 2 | 705 | 0 | - |
| fog | digger | auto_crossbow | 1 | 985 | 0 | 42 | 639 | 0 | 125 |
| fog | digger | barricade | 5 | 25 | 246 | 1 | 705 | 0 | -3 |
| fog | digger | beehive | 8 | 1720 | 240 | 2 | 705 | 0 | 0 |
| fog | digger | catapult | 3 | 1452 | 0 | 42 | 490 | 0 | 125 |
| fog | digger | decoy | 22 | 440 | 240 | 2 | 705 | 0 | 0 |
| fog | digger | electric_fence | 30 | 630 | 246 | 1 | 705 | 0 | -3 |
| fog | digger | fence | 30 | 210 | 246 | 1 | 705 | 0 | -3 |
| fog | digger | flame_tower | 1 | 1855 | 222 | 5 | 705 | 0 | 9 |
| fog | digger | garlic_braid | 18 | 540 | 246 | 1 | 804 | 0 | -3 |
| fog | digger | gun_tower | 2 | 1448 | 168 | 14 | 705 | 0 | 37 |
| fog | digger | mine | 6 | 1314 | 138 | 19 | 705 | 0 | 53 |
| fog | digger | mortar | 1 | 1910 | 0 | 42 | 545 | 0 | 125 |
| fog | digger | sandbag_wall | 30 | 570 | 240 | 2 | 705 | 1 | 0 |
| fog | digger | searchlight | 5 | 1845 | 240 | 2 | 705 | 0 | 0 |
| fog | digger | wall | 30 | 1740 | 234 | 3 | 705 | 1 | 3 |
| fog | digger | zombie_bait | 3 | 6 | 240 | 2 | 705 | 0 | 0 |
| fog | frost_zombie | *base* | - | - | 400 | 2 | 893 | 0 | - |
| fog | frost_zombie | auto_crossbow | 1 | 985 | 0 | 42 | 790 | 0 | 209 |
| fog | frost_zombie | barricade | 5 | 25 | 410 | 1 | 955 | 0 | -5 |
| fog | frost_zombie | beehive | 8 | 1720 | 400 | 2 | 893 | 0 | 0 |
| fog | frost_zombie | catapult | 3 | 1452 | 0 | 42 | 580 | 0 | 209 |
| fog | frost_zombie | decoy | 22 | 440 | 390 | 3 | 1177 | 21 | 5 |
| fog | frost_zombie | electric_fence | 30 | 630 | 400 | 2 | 893 | 1 | 0 |
| fog | frost_zombie | fence | 30 | 210 | 400 | 2 | 893 | 1 | 0 |
| fog | frost_zombie | flame_tower | 1 | 1855 | 350 | 7 | 893 | 0 | 26 |
| fog | frost_zombie | garlic_braid | 18 | 540 | 400 | 2 | 1042 | 0 | 0 |
| fog | frost_zombie | gun_tower | 2 | 1448 | 240 | 18 | 893 | 0 | 83 |
| fog | frost_zombie | mine | 6 | 1314 | 160 | 26 | 893 | 0 | 125 |
| fog | frost_zombie | mortar | 1 | 1910 | 0 | 42 | 492 | 0 | 209 |
| fog | frost_zombie | sandbag_wall | 30 | 570 | 400 | 2 | 893 | 1 | 0 |
| fog | frost_zombie | searchlight | 5 | 1845 | 390 | 3 | 893 | 0 | 5 |
| fog | frost_zombie | wall | 30 | 1740 | 390 | 3 | 893 | 1 | 5 |
| fog | frost_zombie | zombie_bait | 3 | 6 | 390 | 3 | 893 | 0 | 5 |
| fog | rat | *base* | - | - | 352 | 8 | 647 | 0 | - |
| fog | rat | auto_crossbow | 1 | 985 | 84 | 276 | 627 | 0 | 140 |
| fog | rat | barricade | 5 | 25 | 350 | 10 | 653 | 1 | 1 |
| fog | rat | beehive | 8 | 1720 | 294 | 66 | 647 | 0 | 30 |
| fog | rat | catapult | 3 | 1452 | 0 | 360 | 541 | 0 | 184 |
| fog | rat | decoy | 22 | 440 | 352 | 8 | 647 | 0 | 0 |
| fog | rat | electric_fence | 30 | 630 | 346 | 14 | 647 | 1 | 3 |
| fog | rat | fence | 30 | 210 | 350 | 10 | 647 | 1 | 1 |
| fog | rat | flame_tower | 1 | 1855 | 79 | 281 | 635 | 0 | 142 |
| fog | rat | garlic_braid | 18 | 540 | 349 | 11 | 751 | 0 | 1 |
| fog | rat | gun_tower | 2 | 1448 | 327 | 33 | 647 | 0 | 13 |
| fog | rat | mine | 6 | 1314 | 258 | 102 | 647 | 0 | 49 |
| fog | rat | mortar | 1 | 1910 | 7 | 353 | 635 | 0 | 180 |
| fog | rat | sandbag_wall | 30 | 570 | 348 | 12 | 647 | 1 | 2 |
| fog | rat | searchlight | 5 | 1845 | 350 | 10 | 647 | 0 | 1 |
| fog | rat | wall | 30 | 1740 | 344 | 16 | 647 | 1 | 4 |
| fog | rat | zombie_bait | 3 | 6 | 352 | 8 | 647 | 0 | 0 |
| fog | runner | *base* | - | - | 420 | 4 | 1356 | 0 | - |
| fog | runner | auto_crossbow | 1 | 985 | 0 | 144 | 1266 | 0 | 219 |
| fog | runner | barricade | 5 | 25 | 426 | 2 | 1380 | 0 | -3 |
| fog | runner | beehive | 8 | 1720 | 420 | 4 | 1356 | 0 | 0 |
| fog | runner | catapult | 3 | 1452 | 0 | 144 | 1266 | 0 | 219 |
| fog | runner | decoy | 22 | 440 | 411 | 7 | 1356 | 21 | 4 |
| fog | runner | electric_fence | 30 | 630 | 408 | 8 | 1356 | 1 | 6 |
| fog | runner | fence | 30 | 210 | 417 | 5 | 1356 | 1 | 1 |
| fog | runner | flame_tower | 1 | 1855 | 0 | 144 | 1318 | 0 | 219 |
| fog | runner | garlic_braid | 18 | 540 | 426 | 2 | 1413 | 0 | -3 |
| fog | runner | gun_tower | 2 | 1448 | 0 | 144 | 1294 | 0 | 219 |
| fog | runner | mine | 6 | 1314 | 387 | 15 | 1356 | 0 | 17 |
| fog | runner | mortar | 1 | 1910 | 156 | 92 | 1332 | 0 | 138 |
| fog | runner | sandbag_wall | 30 | 570 | 414 | 6 | 1356 | 1 | 3 |
| fog | runner | searchlight | 5 | 1845 | 417 | 5 | 1356 | 0 | 1 |
| fog | runner | wall | 30 | 1740 | 405 | 9 | 1356 | 1 | 7 |
| fog | runner | zombie_bait | 3 | 6 | 414 | 6 | 1356 | 0 | 3 |
| fog | spitter | *base* | - | - | 376 | 1 | 941 | 2 | - |
| fog | spitter | auto_crossbow | 1 | 985 | 0 | 48 | 728 | 2 | 196 |
| fog | spitter | barricade | 5 | 25 | 384 | 0 | 1003 | 2 | -4 |
| fog | spitter | beehive | 8 | 1720 | 376 | 1 | 1053 | 10 | 0 |
| fog | spitter | catapult | 3 | 1452 | 0 | 48 | 595 | 0 | 196 |
| fog | spitter | decoy | 22 | 440 | 376 | 1 | 941 | 2 | 0 |
| fog | spitter | electric_fence | 30 | 630 | 376 | 1 | 941 | 3 | 0 |
| fog | spitter | fence | 30 | 210 | 376 | 1 | 941 | 3 | 0 |
| fog | spitter | flame_tower | 1 | 1855 | 376 | 1 | 941 | 3 | 0 |
| fog | spitter | garlic_braid | 18 | 540 | 384 | 0 | 1090 | 2 | -4 |
| fog | spitter | gun_tower | 2 | 1448 | 272 | 14 | 941 | 4 | 54 |
| fog | spitter | mine | 6 | 1314 | 88 | 37 | 941 | 2 | 150 |
| fog | spitter | mortar | 1 | 1910 | 0 | 48 | 613 | 0 | 196 |
| fog | spitter | sandbag_wall | 30 | 570 | 376 | 1 | 941 | 3 | 0 |
| fog | spitter | searchlight | 5 | 1845 | 368 | 2 | 941 | 2 | 4 |
| fog | spitter | wall | 30 | 1740 | 376 | 1 | 941 | 3 | 0 |
| fog | spitter | zombie_bait | 3 | 6 | 376 | 1 | 941 | 2 | 0 |
| fog | tank | *base* | - | - | 180 | 0 | 982 | 0 | - |
| fog | tank | auto_crossbow | 1 | 985 | 90 | 6 | 982 | 0 | 47 |
| fog | tank | barricade | 5 | 25 | 180 | 0 | 1079 | 0 | 0 |
| fog | tank | beehive | 8 | 1720 | 180 | 0 | 982 | 0 | 0 |
| fog | tank | catapult | 3 | 1452 | 0 | 12 | 527 | 0 | 94 |
| fog | tank | decoy | 22 | 440 | 0 | 0 | 2400 | 19 | 94 |
| fog | tank | electric_fence | 30 | 630 | 180 | 0 | 982 | 1 | 0 |
| fog | tank | fence | 30 | 210 | 180 | 0 | 982 | 1 | 0 |
| fog | tank | flame_tower | 1 | 1855 | 180 | 0 | 982 | 0 | 0 |
| fog | tank | garlic_braid | 18 | 540 | 180 | 0 | 1218 | 0 | 0 |
| fog | tank | gun_tower | 2 | 1448 | 120 | 4 | 982 | 0 | 31 |
| fog | tank | mine | 6 | 1314 | 75 | 7 | 982 | 0 | 54 |
| fog | tank | mortar | 1 | 1910 | 0 | 12 | 611 | 0 | 94 |
| fog | tank | sandbag_wall | 30 | 570 | 180 | 0 | 982 | 1 | 0 |
| fog | tank | searchlight | 5 | 1845 | 180 | 0 | 982 | 0 | 0 |
| fog | tank | wall | 30 | 1740 | 180 | 0 | 982 | 1 | 0 |
| fog | tank | zombie_bait | 3 | 6 | 180 | 0 | 982 | 0 | 0 |
| fog | walker | *base* | - | - | 670 | 5 | 1039 | 0 | - |
| fog | walker | auto_crossbow | 1 | 985 | 0 | 72 | 856 | 0 | 350 |
| fog | walker | barricade | 5 | 25 | 700 | 2 | 1091 | 0 | -15 |
| fog | walker | beehive | 8 | 1720 | 670 | 5 | 1039 | 0 | 0 |
| fog | walker | catapult | 3 | 1452 | 0 | 72 | 726 | 0 | 350 |
| fog | walker | decoy | 22 | 440 | 670 | 5 | 1039 | 21 | 0 |
| fog | walker | electric_fence | 30 | 630 | 660 | 6 | 1039 | 1 | 5 |
| fog | walker | fence | 30 | 210 | 660 | 6 | 1039 | 1 | 5 |
| fog | walker | flame_tower | 1 | 1855 | 0 | 72 | 955 | 0 | 350 |
| fog | walker | garlic_braid | 18 | 540 | 680 | 4 | 1163 | 0 | -5 |
| fog | walker | gun_tower | 2 | 1448 | 0 | 72 | 903 | 0 | 350 |
| fog | walker | mine | 6 | 1314 | 480 | 24 | 1039 | 0 | 99 |
| fog | walker | mortar | 1 | 1910 | 0 | 72 | 700 | 0 | 350 |
| fog | walker | sandbag_wall | 30 | 570 | 660 | 6 | 1039 | 1 | 5 |
| fog | walker | searchlight | 5 | 1845 | 650 | 7 | 1039 | 0 | 10 |
| fog | walker | wall | 30 | 1740 | 650 | 7 | 1039 | 1 | 10 |
| fog | walker | zombie_bait | 3 | 6 | 660 | 6 | 1039 | 0 | 5 |
| fog | wraith | *base* | - | - | 576 | 0 | 800 | 0 | - |
| fog | wraith | auto_crossbow | 1 | 985 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | barricade | 5 | 25 | 576 | 0 | 846 | 0 | 0 |
| fog | wraith | beehive | 8 | 1720 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | catapult | 3 | 1452 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | decoy | 22 | 440 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | electric_fence | 30 | 630 | 576 | 0 | 800 | 1 | 0 |
| fog | wraith | fence | 30 | 210 | 576 | 0 | 800 | 1 | 0 |
| fog | wraith | flame_tower | 1 | 1855 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | garlic_braid | 18 | 540 | 576 | 0 | 913 | 0 | 0 |
| fog | wraith | gun_tower | 2 | 1448 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | mine | 6 | 1314 | 360 | 18 | 800 | 0 | 113 |
| fog | wraith | mortar | 1 | 1910 | 576 | 0 | 800 | 0 | 0 |
| fog | wraith | sandbag_wall | 30 | 570 | 576 | 0 | 800 | 1 | 0 |
| fog | wraith | searchlight | 5 | 1845 | 540 | 3 | 800 | 0 | 18 |
| fog | wraith | wall | 30 | 1740 | 576 | 0 | 800 | 1 | 0 |
| fog | wraith | zombie_bait | 3 | 6 | 576 | 0 | 800 | 0 | 0 |
| fog | giant | *base* | - | - | 316 | 4 | 1176 | 0 | - |
| fog | giant | auto_crossbow | 1 | 985 | 40 | 54 | 1176 | 0 | 144 |
| fog | giant | barricade | 5 | 25 | 322 | 2 | 1303 | 0 | -3 |
| fog | giant | beehive | 8 | 1720 | 316 | 4 | 1176 | 0 | 0 |
| fog | giant | catapult | 3 | 1452 | 40 | 54 | 1176 | 0 | 144 |
| fog | giant | decoy | 22 | 440 | 276 | 8 | 1176 | 21 | 20 |
| fog | giant | electric_fence | 30 | 630 | 310 | 6 | 1176 | 1 | 3 |
| fog | giant | fence | 30 | 210 | 313 | 5 | 1176 | 1 | 1 |
| fog | giant | flame_tower | 1 | 1855 | 40 | 54 | 1176 | 0 | 144 |
| fog | giant | garlic_braid | 18 | 540 | 322 | 2 | 1486 | 0 | -3 |
| fog | giant | gun_tower | 2 | 1448 | 161 | 30 | 1176 | 0 | 81 |
| fog | giant | mine | 6 | 1314 | 229 | 19 | 1176 | 0 | 45 |
| fog | giant | mortar | 1 | 1910 | 49 | 51 | 1176 | 0 | 139 |
| fog | giant | sandbag_wall | 30 | 570 | 310 | 6 | 1176 | 1 | 3 |
| fog | giant | searchlight | 5 | 1845 | 306 | 5 | 1176 | 0 | 5 |
| fog | giant | wall | 30 | 1740 | 300 | 7 | 1176 | 1 | 8 |
| fog | giant | zombie_bait | 3 | 6 | 309 | 4 | 1176 | 0 | 3 |
| fog | harvester | *base* | - | - | 227 | 10 | 681 | 2 | - |
| fog | harvester | auto_crossbow | 1 | 985 | 69 | 105 | 765 | 3 | 82 |
| fog | harvester | barricade | 5 | 25 | 227 | 10 | 726 | 3 | 0 |
| fog | harvester | beehive | 8 | 1720 | 204 | 26 | 1085 | 10 | 12 |
| fog | harvester | catapult | 3 | 1452 | 45 | 108 | 607 | 0 | 95 |
| fog | harvester | decoy | 22 | 440 | 227 | 10 | 681 | 2 | 0 |
| fog | harvester | electric_fence | 30 | 630 | 223 | 14 | 681 | 3 | 2 |
| fog | harvester | fence | 30 | 210 | 225 | 12 | 681 | 3 | 1 |
| fog | harvester | flame_tower | 1 | 1855 | 156 | 81 | 765 | 3 | 37 |
| fog | harvester | garlic_braid | 18 | 540 | 226 | 11 | 893 | 2 | 0 |
| fog | harvester | gun_tower | 2 | 1448 | 188 | 35 | 825 | 4 | 20 |
| fog | harvester | mine | 6 | 1314 | 146 | 91 | 681 | 2 | 42 |
| fog | harvester | mortar | 1 | 1910 | 45 | 108 | 607 | 0 | 95 |
| fog | harvester | sandbag_wall | 30 | 570 | 224 | 13 | 681 | 3 | 1 |
| fog | harvester | searchlight | 5 | 1845 | 225 | 12 | 681 | 2 | 1 |
| fog | harvester | wall | 30 | 1740 | 222 | 15 | 681 | 3 | 2 |
| fog | harvester | zombie_bait | 3 | 6 | 227 | 10 | 681 | 2 | 0 |
| fog | scarecrow_king | *base* | - | - | 274 | 7 | 1192 | 0 | - |
| fog | scarecrow_king | auto_crossbow | 1 | 985 | 43 | 73 | 1171 | 0 | 120 |
| fog | scarecrow_king | barricade | 5 | 25 | 271 | 8 | 1277 | 0 | 1 |
| fog | scarecrow_king | beehive | 8 | 1720 | 241 | 18 | 1171 | 0 | 17 |
| fog | scarecrow_king | catapult | 3 | 1452 | 193 | 23 | 1192 | 0 | 42 |
| fog | scarecrow_king | decoy | 22 | 440 | 274 | 7 | 1192 | 0 | 0 |
| fog | scarecrow_king | electric_fence | 30 | 630 | 274 | 7 | 1283 | 1 | 0 |
| fog | scarecrow_king | fence | 30 | 210 | 274 | 7 | 1268 | 1 | 0 |
| fog | scarecrow_king | flame_tower | 1 | 1855 | 250 | 11 | 1192 | 0 | 12 |
| fog | scarecrow_king | garlic_braid | 18 | 540 | 262 | 10 | 1432 | 0 | 6 |
| fog | scarecrow_king | gun_tower | 2 | 1448 | 55 | 69 | 1192 | 0 | 114 |
| fog | scarecrow_king | mine | 6 | 1314 | 193 | 23 | 1192 | 0 | 42 |
| fog | scarecrow_king | mortar | 1 | 1910 | 193 | 23 | 1192 | 0 | 42 |
| fog | scarecrow_king | sandbag_wall | 30 | 570 | 268 | 8 | 1192 | 1 | 3 |
| fog | scarecrow_king | searchlight | 5 | 1845 | 268 | 9 | 1192 | 0 | 3 |
| fog | scarecrow_king | wall | 30 | 1740 | 268 | 8 | 1192 | 1 | 3 |
| fog | scarecrow_king | zombie_bait | 3 | 6 | 274 | 7 | 1192 | 0 | 0 |
| fog | winter_lord | *base* | - | - | 284 | 2 | 1312 | 0 | - |
| fog | winter_lord | auto_crossbow | 1 | 985 | 62 | 22 | 1312 | 0 | 116 |
| fog | winter_lord | barricade | 5 | 25 | 294 | 1 | 1434 | 0 | -5 |
| fog | winter_lord | beehive | 8 | 1720 | 284 | 2 | 1312 | 0 | 0 |
| fog | winter_lord | catapult | 3 | 1452 | 50 | 23 | 1312 | 0 | 122 |
| fog | winter_lord | decoy | 22 | 440 | 194 | 1 | 2400 | 21 | 47 |
| fog | winter_lord | electric_fence | 30 | 630 | 284 | 2 | 1312 | 1 | 0 |
| fog | winter_lord | fence | 30 | 210 | 284 | 2 | 1312 | 1 | 0 |
| fog | winter_lord | flame_tower | 1 | 1855 | 104 | 18 | 1312 | 0 | 94 |
| fog | winter_lord | garlic_braid | 18 | 540 | 284 | 2 | 1610 | 0 | 0 |
| fog | winter_lord | gun_tower | 2 | 1448 | 194 | 11 | 1312 | 0 | 47 |
| fog | winter_lord | mine | 6 | 1314 | 50 | 23 | 1312 | 0 | 122 |
| fog | winter_lord | mortar | 1 | 1910 | 98 | 19 | 1312 | 0 | 97 |
| fog | winter_lord | sandbag_wall | 30 | 570 | 284 | 2 | 1312 | 1 | 0 |
| fog | winter_lord | searchlight | 5 | 1845 | 270 | 3 | 1312 | 0 | 7 |
| fog | winter_lord | wall | 30 | 1740 | 284 | 2 | 1312 | 1 | 0 |
| fog | winter_lord | zombie_bait | 3 | 6 | 274 | 3 | 1312 | 0 | 5 |
| rain | breaker | *base* | - | - | 90 | 1 | 2400 | 26 | - |
| rain | breaker | auto_crossbow | 1 | 985 | 0 | 32 | 795 | 1 | 47 |
| rain | breaker | barricade | 5 | 25 | 90 | 1 | 2400 | 26 | 0 |
| rain | breaker | beehive | 8 | 1720 | 0 | 3 | 2400 | 34 | 47 |
| rain | breaker | catapult | 3 | 1452 | 0 | 32 | 522 | 0 | 47 |
| rain | breaker | decoy | 22 | 440 | 155 | 1 | 1222 | 24 | -34 |
| rain | breaker | electric_fence | 30 | 630 | 0 | 1 | 2400 | 26 | 47 |
| rain | breaker | fence | 30 | 210 | 0 | 1 | 2400 | 26 | 47 |
| rain | breaker | flame_tower | 1 | 1855 | 80 | 2 | 2400 | 27 | 5 |
| rain | breaker | garlic_braid | 18 | 540 | 155 | 1 | 1079 | 1 | -34 |
| rain | breaker | gun_tower | 2 | 1448 | 15 | 13 | 2400 | 28 | 39 |
| rain | breaker | mine | 6 | 1314 | 0 | 26 | 2400 | 15 | 47 |
| rain | breaker | mortar | 1 | 1910 | 0 | 32 | 483 | 0 | 47 |
| rain | breaker | sandbag_wall | 30 | 570 | 0 | 1 | 2400 | 26 | 47 |
| rain | breaker | searchlight | 5 | 1845 | 35 | 3 | 2400 | 31 | 28 |
| rain | breaker | wall | 30 | 1740 | 0 | 1 | 2400 | 26 | 47 |
| rain | breaker | zombie_bait | 3 | 6 | 90 | 1 | 2400 | 26 | 0 |
| rain | crow | *base* | - | - | 516 | 8 | 1762 | 0 | - |
| rain | crow | auto_crossbow | 1 | 985 | 0 | 180 | 1619 | 0 | 270 |
| rain | crow | barricade | 5 | 25 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | beehive | 8 | 1720 | 0 | 180 | 1683 | 0 | 270 |
| rain | crow | catapult | 3 | 1452 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | decoy | 22 | 440 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | electric_fence | 30 | 630 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | fence | 30 | 210 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | flame_tower | 1 | 1855 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | garlic_braid | 18 | 540 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | gun_tower | 2 | 1448 | 0 | 180 | 1644 | 0 | 270 |
| rain | crow | mine | 6 | 1314 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | mortar | 1 | 1910 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | sandbag_wall | 30 | 570 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | searchlight | 5 | 1845 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | wall | 30 | 1740 | 516 | 8 | 1762 | 0 | 0 |
| rain | crow | zombie_bait | 3 | 6 | 516 | 8 | 1762 | 0 | 0 |
| rain | digger | *base* | - | - | 240 | 2 | 799 | 0 | - |
| rain | digger | auto_crossbow | 1 | 985 | 0 | 42 | 680 | 0 | 125 |
| rain | digger | barricade | 5 | 25 | 240 | 2 | 799 | 0 | 0 |
| rain | digger | beehive | 8 | 1720 | 228 | 4 | 799 | 0 | 6 |
| rain | digger | catapult | 3 | 1452 | 0 | 42 | 512 | 0 | 125 |
| rain | digger | decoy | 22 | 440 | 240 | 2 | 799 | 0 | 0 |
| rain | digger | electric_fence | 30 | 630 | 240 | 2 | 799 | 0 | 0 |
| rain | digger | fence | 30 | 210 | 240 | 2 | 799 | 0 | 0 |
| rain | digger | flame_tower | 1 | 1855 | 228 | 4 | 799 | 0 | 6 |
| rain | digger | garlic_braid | 18 | 540 | 240 | 2 | 906 | 0 | 0 |
| rain | digger | gun_tower | 2 | 1448 | 132 | 20 | 799 | 0 | 56 |
| rain | digger | mine | 6 | 1314 | 132 | 20 | 799 | 0 | 56 |
| rain | digger | mortar | 1 | 1910 | 0 | 42 | 438 | 0 | 125 |
| rain | digger | sandbag_wall | 30 | 570 | 234 | 3 | 799 | 1 | 3 |
| rain | digger | searchlight | 5 | 1845 | 234 | 3 | 799 | 0 | 3 |
| rain | digger | wall | 30 | 1740 | 228 | 4 | 799 | 1 | 6 |
| rain | digger | zombie_bait | 3 | 6 | 240 | 2 | 799 | 0 | 0 |
| rain | frost_zombie | *base* | - | - | 390 | 3 | 1034 | 0 | - |
| rain | frost_zombie | auto_crossbow | 1 | 985 | 0 | 42 | 813 | 0 | 204 |
| rain | frost_zombie | barricade | 5 | 25 | 390 | 3 | 1111 | 0 | 0 |
| rain | frost_zombie | beehive | 8 | 1720 | 370 | 5 | 1034 | 0 | 10 |
| rain | frost_zombie | catapult | 3 | 1452 | 0 | 42 | 607 | 0 | 204 |
| rain | frost_zombie | decoy | 22 | 440 | 370 | 5 | 1377 | 21 | 10 |
| rain | frost_zombie | electric_fence | 30 | 630 | 390 | 3 | 1034 | 1 | 0 |
| rain | frost_zombie | fence | 30 | 210 | 390 | 3 | 1034 | 1 | 0 |
| rain | frost_zombie | flame_tower | 1 | 1855 | 370 | 5 | 1034 | 0 | 10 |
| rain | frost_zombie | garlic_braid | 18 | 540 | 400 | 2 | 1196 | 0 | -5 |
| rain | frost_zombie | gun_tower | 2 | 1448 | 170 | 25 | 1034 | 0 | 115 |
| rain | frost_zombie | mine | 6 | 1314 | 160 | 26 | 1034 | 0 | 120 |
| rain | frost_zombie | mortar | 1 | 1910 | 0 | 42 | 543 | 0 | 204 |
| rain | frost_zombie | sandbag_wall | 30 | 570 | 380 | 4 | 1034 | 1 | 5 |
| rain | frost_zombie | searchlight | 5 | 1845 | 380 | 4 | 1034 | 0 | 5 |
| rain | frost_zombie | wall | 30 | 1740 | 380 | 4 | 1034 | 1 | 5 |
| rain | frost_zombie | zombie_bait | 3 | 6 | 380 | 4 | 1034 | 0 | 5 |
| rain | rat | *base* | - | - | 347 | 13 | 720 | 0 | - |
| rain | rat | auto_crossbow | 1 | 985 | 59 | 301 | 688 | 0 | 150 |
| rain | rat | barricade | 5 | 25 | 346 | 14 | 759 | 1 | 0 |
| rain | rat | beehive | 8 | 1720 | 143 | 217 | 710 | 0 | 106 |
| rain | rat | catapult | 3 | 1452 | 0 | 360 | 554 | 0 | 181 |
| rain | rat | decoy | 22 | 440 | 347 | 13 | 720 | 0 | 0 |
| rain | rat | electric_fence | 30 | 630 | 344 | 16 | 720 | 1 | 1 |
| rain | rat | fence | 30 | 210 | 346 | 14 | 720 | 1 | 0 |
| rain | rat | flame_tower | 1 | 1855 | 0 | 360 | 638 | 0 | 181 |
| rain | rat | garlic_braid | 18 | 540 | 346 | 14 | 842 | 0 | 0 |
| rain | rat | gun_tower | 2 | 1448 | 314 | 46 | 720 | 0 | 17 |
| rain | rat | mine | 6 | 1314 | 258 | 102 | 720 | 0 | 46 |
| rain | rat | mortar | 1 | 1910 | 0 | 360 | 514 | 0 | 181 |
| rain | rat | sandbag_wall | 30 | 570 | 344 | 16 | 720 | 1 | 1 |
| rain | rat | searchlight | 5 | 1845 | 346 | 14 | 720 | 0 | 0 |
| rain | rat | wall | 30 | 1740 | 340 | 20 | 720 | 1 | 3 |
| rain | rat | zombie_bait | 3 | 6 | 347 | 13 | 720 | 0 | 0 |
| rain | runner | *base* | - | - | 414 | 6 | 1403 | 0 | - |
| rain | runner | auto_crossbow | 1 | 985 | 0 | 144 | 1282 | 0 | 216 |
| rain | runner | barricade | 5 | 25 | 414 | 6 | 1432 | 0 | 0 |
| rain | runner | beehive | 8 | 1720 | 0 | 144 | 1392 | 0 | 216 |
| rain | runner | catapult | 3 | 1452 | 0 | 144 | 1295 | 0 | 216 |
| rain | runner | decoy | 22 | 440 | 405 | 9 | 1403 | 21 | 4 |
| rain | runner | electric_fence | 30 | 630 | 405 | 9 | 1403 | 1 | 4 |
| rain | runner | fence | 30 | 210 | 411 | 7 | 1403 | 1 | 1 |
| rain | runner | flame_tower | 1 | 1855 | 228 | 68 | 1403 | 0 | 97 |
| rain | runner | garlic_braid | 18 | 540 | 420 | 4 | 1464 | 0 | -3 |
| rain | runner | gun_tower | 2 | 1448 | 0 | 144 | 1314 | 0 | 216 |
| rain | runner | mine | 6 | 1314 | 384 | 16 | 1403 | 0 | 15 |
| rain | runner | mortar | 1 | 1910 | 66 | 122 | 1383 | 0 | 182 |
| rain | runner | sandbag_wall | 30 | 570 | 408 | 8 | 1403 | 1 | 3 |
| rain | runner | searchlight | 5 | 1845 | 414 | 6 | 1403 | 0 | 0 |
| rain | runner | wall | 30 | 1740 | 399 | 11 | 1403 | 1 | 7 |
| rain | runner | zombie_bait | 3 | 6 | 408 | 8 | 1403 | 0 | 3 |
| rain | spitter | *base* | - | - | 368 | 2 | 1082 | 2 | - |
| rain | spitter | auto_crossbow | 1 | 985 | 0 | 48 | 806 | 0 | 192 |
| rain | spitter | barricade | 5 | 25 | 368 | 2 | 1159 | 2 | 0 |
| rain | spitter | beehive | 8 | 1720 | 368 | 2 | 1188 | 10 | 0 |
| rain | spitter | catapult | 3 | 1452 | 0 | 48 | 572 | 0 | 192 |
| rain | spitter | decoy | 22 | 440 | 368 | 2 | 1082 | 2 | 0 |
| rain | spitter | electric_fence | 30 | 630 | 368 | 2 | 1082 | 3 | 0 |
| rain | spitter | fence | 30 | 210 | 368 | 2 | 1082 | 3 | 0 |
| rain | spitter | flame_tower | 1 | 1855 | 368 | 2 | 1082 | 3 | 0 |
| rain | spitter | garlic_braid | 18 | 540 | 376 | 1 | 1244 | 2 | -4 |
| rain | spitter | gun_tower | 2 | 1448 | 224 | 20 | 1082 | 4 | 75 |
| rain | spitter | mine | 6 | 1314 | 80 | 38 | 1082 | 2 | 150 |
| rain | spitter | mortar | 1 | 1910 | 0 | 48 | 543 | 0 | 192 |
| rain | spitter | sandbag_wall | 30 | 570 | 368 | 2 | 1082 | 3 | 0 |
| rain | spitter | searchlight | 5 | 1845 | 368 | 2 | 1082 | 2 | 0 |
| rain | spitter | wall | 30 | 1740 | 368 | 2 | 1082 | 3 | 0 |
| rain | spitter | zombie_bait | 3 | 6 | 368 | 2 | 1082 | 2 | 0 |
| rain | tank | *base* | - | - | 180 | 0 | 1194 | 0 | - |
| rain | tank | auto_crossbow | 1 | 985 | 30 | 10 | 1194 | 0 | 78 |
| rain | tank | barricade | 5 | 25 | 180 | 0 | 1314 | 0 | 0 |
| rain | tank | beehive | 8 | 1720 | 165 | 1 | 1194 | 0 | 7 |
| rain | tank | catapult | 3 | 1452 | 0 | 12 | 575 | 0 | 94 |
| rain | tank | decoy | 22 | 440 | 0 | 1 | 2400 | 17 | 94 |
| rain | tank | electric_fence | 30 | 630 | 180 | 0 | 1194 | 1 | 0 |
| rain | tank | fence | 30 | 210 | 180 | 0 | 1194 | 1 | 0 |
| rain | tank | flame_tower | 1 | 1855 | 165 | 1 | 1194 | 0 | 7 |
| rain | tank | garlic_braid | 18 | 540 | 180 | 0 | 1447 | 0 | 0 |
| rain | tank | gun_tower | 2 | 1448 | 90 | 6 | 1194 | 0 | 47 |
| rain | tank | mine | 6 | 1314 | 60 | 8 | 1194 | 0 | 62 |
| rain | tank | mortar | 1 | 1910 | 0 | 12 | 520 | 0 | 94 |
| rain | tank | sandbag_wall | 30 | 570 | 165 | 1 | 1194 | 1 | 7 |
| rain | tank | searchlight | 5 | 1845 | 165 | 1 | 1194 | 0 | 7 |
| rain | tank | wall | 30 | 1740 | 165 | 1 | 1194 | 1 | 7 |
| rain | tank | zombie_bait | 3 | 6 | 165 | 1 | 1194 | 0 | 7 |
| rain | walker | *base* | - | - | 640 | 8 | 1156 | 0 | - |
| rain | walker | auto_crossbow | 1 | 985 | 0 | 72 | 898 | 0 | 335 |
| rain | walker | barricade | 5 | 25 | 640 | 8 | 1220 | 0 | 0 |
| rain | walker | beehive | 8 | 1720 | 0 | 72 | 1096 | 0 | 335 |
| rain | walker | catapult | 3 | 1452 | 0 | 72 | 828 | 0 | 335 |
| rain | walker | decoy | 22 | 440 | 620 | 10 | 1163 | 21 | 10 |
| rain | walker | electric_fence | 30 | 630 | 640 | 8 | 1156 | 1 | 0 |
| rain | walker | fence | 30 | 210 | 640 | 8 | 1156 | 1 | 0 |
| rain | walker | flame_tower | 1 | 1855 | 0 | 72 | 1053 | 0 | 335 |
| rain | walker | garlic_braid | 18 | 540 | 660 | 6 | 1291 | 0 | -10 |
| rain | walker | gun_tower | 2 | 1448 | 0 | 72 | 954 | 0 | 335 |
| rain | walker | mine | 6 | 1314 | 400 | 32 | 1156 | 0 | 125 |
| rain | walker | mortar | 1 | 1910 | 0 | 72 | 745 | 0 | 335 |
| rain | walker | sandbag_wall | 30 | 570 | 640 | 8 | 1156 | 1 | 0 |
| rain | walker | searchlight | 5 | 1845 | 640 | 8 | 1156 | 0 | 0 |
| rain | walker | wall | 30 | 1740 | 620 | 10 | 1156 | 1 | 10 |
| rain | walker | zombie_bait | 3 | 6 | 640 | 8 | 1156 | 0 | 0 |
| rain | wraith | *base* | - | - | 576 | 0 | 894 | 0 | - |
| rain | wraith | auto_crossbow | 1 | 985 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | barricade | 5 | 25 | 576 | 0 | 951 | 0 | 0 |
| rain | wraith | beehive | 8 | 1720 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | catapult | 3 | 1452 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | decoy | 22 | 440 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | electric_fence | 30 | 630 | 576 | 0 | 894 | 1 | 0 |
| rain | wraith | fence | 30 | 210 | 576 | 0 | 894 | 1 | 0 |
| rain | wraith | flame_tower | 1 | 1855 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | garlic_braid | 18 | 540 | 576 | 0 | 1015 | 0 | 0 |
| rain | wraith | gun_tower | 2 | 1448 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | mine | 6 | 1314 | 360 | 18 | 894 | 0 | 113 |
| rain | wraith | mortar | 1 | 1910 | 576 | 0 | 894 | 0 | 0 |
| rain | wraith | sandbag_wall | 30 | 570 | 576 | 0 | 894 | 1 | 0 |
| rain | wraith | searchlight | 5 | 1845 | 528 | 4 | 894 | 0 | 25 |
| rain | wraith | wall | 30 | 1740 | 576 | 0 | 894 | 1 | 0 |
| rain | wraith | zombie_bait | 3 | 6 | 576 | 0 | 894 | 0 | 0 |
| rain | giant | *base* | - | - | 310 | 6 | 1458 | 0 | - |
| rain | giant | auto_crossbow | 1 | 985 | 40 | 54 | 1458 | 0 | 141 |
| rain | giant | barricade | 5 | 25 | 310 | 6 | 1615 | 0 | 0 |
| rain | giant | beehive | 8 | 1720 | 52 | 50 | 1458 | 0 | 135 |
| rain | giant | catapult | 3 | 1452 | 0 | 55 | 1246 | 0 | 162 |
| rain | giant | decoy | 22 | 440 | 263 | 10 | 1458 | 21 | 24 |
| rain | giant | electric_fence | 30 | 630 | 301 | 9 | 1458 | 1 | 4 |
| rain | giant | fence | 30 | 210 | 307 | 7 | 1458 | 1 | 1 |
| rain | giant | flame_tower | 1 | 1855 | 40 | 54 | 1458 | 0 | 141 |
| rain | giant | garlic_braid | 18 | 540 | 316 | 4 | 1792 | 0 | -3 |
| rain | giant | gun_tower | 2 | 1448 | 40 | 54 | 1458 | 0 | 141 |
| rain | giant | mine | 6 | 1314 | 243 | 19 | 1458 | 0 | 35 |
| rain | giant | mortar | 1 | 1910 | 40 | 54 | 1458 | 0 | 141 |
| rain | giant | sandbag_wall | 30 | 570 | 304 | 8 | 1458 | 1 | 3 |
| rain | giant | searchlight | 5 | 1845 | 310 | 6 | 1458 | 0 | 0 |
| rain | giant | wall | 30 | 1740 | 301 | 9 | 1458 | 1 | 4 |
| rain | giant | zombie_bait | 3 | 6 | 303 | 6 | 1458 | 0 | 3 |
| rain | harvester | *base* | - | - | 223 | 14 | 822 | 2 | - |
| rain | harvester | auto_crossbow | 1 | 985 | 45 | 108 | 718 | 2 | 93 |
| rain | harvester | barricade | 5 | 25 | 221 | 16 | 903 | 3 | 1 |
| rain | harvester | beehive | 8 | 1720 | 140 | 90 | 1214 | 10 | 43 |
| rain | harvester | catapult | 3 | 1452 | 45 | 108 | 718 | 0 | 93 |
| rain | harvester | decoy | 22 | 440 | 223 | 14 | 822 | 2 | 0 |
| rain | harvester | electric_fence | 30 | 630 | 219 | 18 | 822 | 3 | 2 |
| rain | harvester | fence | 30 | 210 | 222 | 15 | 822 | 3 | 0 |
| rain | harvester | flame_tower | 1 | 1855 | 141 | 96 | 906 | 3 | 42 |
| rain | harvester | garlic_braid | 18 | 540 | 222 | 15 | 964 | 2 | 0 |
| rain | harvester | gun_tower | 2 | 1448 | 167 | 49 | 966 | 4 | 29 |
| rain | harvester | mine | 6 | 1314 | 144 | 93 | 822 | 2 | 41 |
| rain | harvester | mortar | 1 | 1910 | 45 | 108 | 718 | 0 | 93 |
| rain | harvester | sandbag_wall | 30 | 570 | 221 | 16 | 822 | 3 | 1 |
| rain | harvester | searchlight | 5 | 1845 | 222 | 15 | 822 | 2 | 0 |
| rain | harvester | wall | 30 | 1740 | 218 | 19 | 822 | 3 | 2 |
| rain | harvester | zombie_bait | 3 | 6 | 223 | 14 | 822 | 2 | 0 |
| rain | scarecrow_king | *base* | - | - | 250 | 13 | 1406 | 0 | - |
| rain | scarecrow_king | auto_crossbow | 1 | 985 | 40 | 74 | 1406 | 0 | 109 |
| rain | scarecrow_king | barricade | 5 | 25 | 253 | 13 | 1538 | 0 | -1 |
| rain | scarecrow_king | beehive | 8 | 1720 | 82 | 67 | 1406 | 0 | 87 |
| rain | scarecrow_king | catapult | 3 | 1452 | 178 | 28 | 1406 | 0 | 37 |
| rain | scarecrow_king | decoy | 22 | 440 | 250 | 13 | 1406 | 0 | 0 |
| rain | scarecrow_king | electric_fence | 30 | 630 | 256 | 12 | 1483 | 1 | -3 |
| rain | scarecrow_king | fence | 30 | 210 | 256 | 12 | 1468 | 1 | -3 |
| rain | scarecrow_king | flame_tower | 1 | 1855 | 244 | 14 | 1406 | 0 | 3 |
| rain | scarecrow_king | garlic_braid | 18 | 540 | 238 | 18 | 1687 | 0 | 6 |
| rain | scarecrow_king | gun_tower | 2 | 1448 | 40 | 74 | 1406 | 0 | 109 |
| rain | scarecrow_king | mine | 6 | 1314 | 175 | 29 | 1406 | 0 | 39 |
| rain | scarecrow_king | mortar | 1 | 1910 | 178 | 28 | 1406 | 0 | 37 |
| rain | scarecrow_king | sandbag_wall | 30 | 570 | 250 | 13 | 1406 | 1 | 0 |
| rain | scarecrow_king | searchlight | 5 | 1845 | 247 | 15 | 1406 | 0 | 1 |
| rain | scarecrow_king | wall | 30 | 1740 | 244 | 15 | 1406 | 1 | 3 |
| rain | scarecrow_king | zombie_bait | 3 | 6 | 250 | 13 | 1406 | 0 | 0 |
| rain | winter_lord | *base* | - | - | 274 | 3 | 1594 | 0 | - |
| rain | winter_lord | auto_crossbow | 1 | 985 | 50 | 23 | 1594 | 0 | 117 |
| rain | winter_lord | barricade | 5 | 25 | 274 | 3 | 1807 | 0 | 0 |
| rain | winter_lord | beehive | 8 | 1720 | 244 | 6 | 1594 | 0 | 15 |
| rain | winter_lord | catapult | 3 | 1452 | 62 | 22 | 1594 | 0 | 110 |
| rain | winter_lord | decoy | 22 | 440 | 194 | 0 | 2400 | 20 | 41 |
| rain | winter_lord | electric_fence | 30 | 630 | 274 | 3 | 1594 | 1 | 0 |
| rain | winter_lord | fence | 30 | 210 | 274 | 3 | 1594 | 1 | 0 |
| rain | winter_lord | flame_tower | 1 | 1855 | 146 | 14 | 1594 | 0 | 67 |
| rain | winter_lord | garlic_braid | 18 | 540 | 284 | 2 | 1978 | 0 | -5 |
| rain | winter_lord | gun_tower | 2 | 1448 | 194 | 11 | 1594 | 0 | 41 |
| rain | winter_lord | mine | 6 | 1314 | 50 | 23 | 1594 | 0 | 117 |
| rain | winter_lord | mortar | 1 | 1910 | 62 | 22 | 1594 | 0 | 110 |
| rain | winter_lord | sandbag_wall | 30 | 570 | 274 | 3 | 1594 | 1 | 0 |
| rain | winter_lord | searchlight | 5 | 1845 | 256 | 4 | 1594 | 0 | 9 |
| rain | winter_lord | wall | 30 | 1740 | 274 | 3 | 1594 | 1 | 0 |
| rain | winter_lord | zombie_bait | 3 | 6 | 264 | 4 | 1594 | 0 | 5 |
| Blood Moon | breaker | *base* | - | - | 95 | 0 | 2400 | 32 | - |
| Blood Moon | breaker | auto_crossbow | 1 | 985 | 30 | 13 | 2400 | 30 | 34 |
| Blood Moon | breaker | barricade | 5 | 25 | 95 | 0 | 2400 | 32 | 0 |
| Blood Moon | breaker | beehive | 8 | 1720 | 15 | 1 | 2400 | 45 | 41 |
| Blood Moon | breaker | catapult | 3 | 1452 | 0 | 32 | 448 | 0 | 49 |
| Blood Moon | breaker | decoy | 22 | 440 | 155 | 1 | 1054 | 24 | -31 |
| Blood Moon | breaker | electric_fence | 30 | 630 | 0 | 0 | 2400 | 42 | 49 |
| Blood Moon | breaker | fence | 30 | 210 | 0 | 0 | 2400 | 42 | 49 |
| Blood Moon | breaker | flame_tower | 1 | 1855 | 80 | 2 | 2400 | 33 | 7 |
| Blood Moon | breaker | garlic_braid | 18 | 540 | 155 | 1 | 937 | 1 | -31 |
| Blood Moon | breaker | gun_tower | 2 | 1448 | 55 | 6 | 2400 | 33 | 20 |
| Blood Moon | breaker | mine | 6 | 1314 | 50 | 20 | 2400 | 14 | 23 |
| Blood Moon | breaker | mortar | 1 | 1910 | 0 | 32 | 566 | 0 | 49 |
| Blood Moon | breaker | sandbag_wall | 30 | 570 | 0 | 0 | 2400 | 42 | 49 |
| Blood Moon | breaker | searchlight | 5 | 1845 | 30 | 1 | 2400 | 45 | 34 |
| Blood Moon | breaker | wall | 30 | 1740 | 0 | 0 | 2400 | 42 | 49 |
| Blood Moon | breaker | zombie_bait | 3 | 6 | 95 | 0 | 2400 | 32 | 0 |
| Blood Moon | crow | *base* | - | - | 516 | 8 | 1762 | 0 | - |
| Blood Moon | crow | auto_crossbow | 1 | 985 | 0 | 180 | 1641 | 0 | 270 |
| Blood Moon | crow | barricade | 5 | 25 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | beehive | 8 | 1720 | 0 | 180 | 1724 | 0 | 270 |
| Blood Moon | crow | catapult | 3 | 1452 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | decoy | 22 | 440 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | electric_fence | 30 | 630 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | fence | 30 | 210 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | flame_tower | 1 | 1855 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | garlic_braid | 18 | 540 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | gun_tower | 2 | 1448 | 0 | 180 | 1644 | 0 | 270 |
| Blood Moon | crow | mine | 6 | 1314 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | mortar | 1 | 1910 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | sandbag_wall | 30 | 570 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | searchlight | 5 | 1845 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | wall | 30 | 1740 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | crow | zombie_bait | 3 | 6 | 516 | 8 | 1762 | 0 | 0 |
| Blood Moon | digger | *base* | - | - | 246 | 1 | 705 | 0 | - |
| Blood Moon | digger | auto_crossbow | 1 | 985 | 120 | 22 | 705 | 0 | 65 |
| Blood Moon | digger | barricade | 5 | 25 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | beehive | 8 | 1720 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | catapult | 3 | 1452 | 0 | 42 | 474 | 0 | 128 |
| Blood Moon | digger | decoy | 22 | 440 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | electric_fence | 30 | 630 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | fence | 30 | 210 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | flame_tower | 1 | 1855 | 222 | 5 | 705 | 0 | 12 |
| Blood Moon | digger | garlic_braid | 18 | 540 | 246 | 1 | 804 | 0 | 0 |
| Blood Moon | digger | gun_tower | 2 | 1448 | 204 | 8 | 705 | 0 | 21 |
| Blood Moon | digger | mine | 6 | 1314 | 192 | 10 | 705 | 0 | 28 |
| Blood Moon | digger | mortar | 1 | 1910 | 0 | 42 | 529 | 0 | 128 |
| Blood Moon | digger | sandbag_wall | 30 | 570 | 246 | 1 | 705 | 1 | 0 |
| Blood Moon | digger | searchlight | 5 | 1845 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | digger | wall | 30 | 1740 | 240 | 2 | 705 | 1 | 3 |
| Blood Moon | digger | zombie_bait | 3 | 6 | 246 | 1 | 705 | 0 | 0 |
| Blood Moon | frost_zombie | *base* | - | - | 400 | 2 | 893 | 0 | - |
| Blood Moon | frost_zombie | auto_crossbow | 1 | 985 | 200 | 22 | 893 | 0 | 104 |
| Blood Moon | frost_zombie | barricade | 5 | 25 | 400 | 2 | 955 | 0 | 0 |
| Blood Moon | frost_zombie | beehive | 8 | 1720 | 400 | 2 | 893 | 0 | 0 |
| Blood Moon | frost_zombie | catapult | 3 | 1452 | 0 | 42 | 587 | 0 | 209 |
| Blood Moon | frost_zombie | decoy | 22 | 440 | 390 | 3 | 1176 | 21 | 5 |
| Blood Moon | frost_zombie | electric_fence | 30 | 630 | 400 | 2 | 893 | 1 | 0 |
| Blood Moon | frost_zombie | fence | 30 | 210 | 400 | 2 | 893 | 1 | 0 |
| Blood Moon | frost_zombie | flame_tower | 1 | 1855 | 360 | 6 | 893 | 0 | 20 |
| Blood Moon | frost_zombie | garlic_braid | 18 | 540 | 410 | 1 | 1042 | 0 | -5 |
| Blood Moon | frost_zombie | gun_tower | 2 | 1448 | 310 | 11 | 893 | 0 | 47 |
| Blood Moon | frost_zombie | mine | 6 | 1314 | 280 | 14 | 893 | 0 | 62 |
| Blood Moon | frost_zombie | mortar | 1 | 1910 | 0 | 42 | 589 | 0 | 209 |
| Blood Moon | frost_zombie | sandbag_wall | 30 | 570 | 400 | 2 | 893 | 1 | 0 |
| Blood Moon | frost_zombie | searchlight | 5 | 1845 | 400 | 2 | 893 | 0 | 0 |
| Blood Moon | frost_zombie | wall | 30 | 1740 | 400 | 2 | 893 | 1 | 0 |
| Blood Moon | frost_zombie | zombie_bait | 3 | 6 | 400 | 2 | 893 | 0 | 0 |
| Blood Moon | rat | *base* | - | - | 350 | 10 | 647 | 0 | - |
| Blood Moon | rat | auto_crossbow | 1 | 985 | 145 | 215 | 628 | 0 | 107 |
| Blood Moon | rat | barricade | 5 | 25 | 348 | 12 | 653 | 1 | 1 |
| Blood Moon | rat | beehive | 8 | 1720 | 157 | 203 | 641 | 0 | 101 |
| Blood Moon | rat | catapult | 3 | 1452 | 0 | 360 | 529 | 0 | 183 |
| Blood Moon | rat | decoy | 22 | 440 | 350 | 10 | 647 | 0 | 0 |
| Blood Moon | rat | electric_fence | 30 | 630 | 346 | 14 | 647 | 1 | 2 |
| Blood Moon | rat | fence | 30 | 210 | 348 | 12 | 647 | 1 | 1 |
| Blood Moon | rat | flame_tower | 1 | 1855 | 0 | 360 | 563 | 0 | 183 |
| Blood Moon | rat | garlic_braid | 18 | 540 | 349 | 11 | 751 | 0 | 0 |
| Blood Moon | rat | gun_tower | 2 | 1448 | 325 | 35 | 647 | 0 | 13 |
| Blood Moon | rat | mine | 6 | 1314 | 259 | 101 | 647 | 0 | 47 |
| Blood Moon | rat | mortar | 1 | 1910 | 5 | 355 | 635 | 0 | 180 |
| Blood Moon | rat | sandbag_wall | 30 | 570 | 347 | 13 | 647 | 1 | 1 |
| Blood Moon | rat | searchlight | 5 | 1845 | 350 | 10 | 647 | 0 | 0 |
| Blood Moon | rat | wall | 30 | 1740 | 344 | 16 | 647 | 1 | 3 |
| Blood Moon | rat | zombie_bait | 3 | 6 | 350 | 10 | 647 | 0 | 0 |
| Blood Moon | runner | *base* | - | - | 426 | 2 | 1356 | 0 | - |
| Blood Moon | runner | auto_crossbow | 1 | 985 | 0 | 144 | 1280 | 0 | 223 |
| Blood Moon | runner | barricade | 5 | 25 | 423 | 3 | 1380 | 0 | 1 |
| Blood Moon | runner | beehive | 8 | 1720 | 411 | 7 | 1356 | 0 | 7 |
| Blood Moon | runner | catapult | 3 | 1452 | 0 | 144 | 1257 | 0 | 223 |
| Blood Moon | runner | decoy | 22 | 440 | 417 | 5 | 1356 | 21 | 4 |
| Blood Moon | runner | electric_fence | 30 | 630 | 417 | 5 | 1356 | 1 | 4 |
| Blood Moon | runner | fence | 30 | 210 | 423 | 3 | 1356 | 1 | 1 |
| Blood Moon | runner | flame_tower | 1 | 1855 | 366 | 22 | 1356 | 0 | 31 |
| Blood Moon | runner | garlic_braid | 18 | 540 | 429 | 1 | 1413 | 0 | -1 |
| Blood Moon | runner | gun_tower | 2 | 1448 | 0 | 144 | 1331 | 0 | 223 |
| Blood Moon | runner | mine | 6 | 1314 | 390 | 14 | 1356 | 0 | 18 |
| Blood Moon | runner | mortar | 1 | 1910 | 219 | 71 | 1323 | 0 | 108 |
| Blood Moon | runner | sandbag_wall | 30 | 570 | 420 | 4 | 1356 | 1 | 3 |
| Blood Moon | runner | searchlight | 5 | 1845 | 426 | 2 | 1356 | 0 | 0 |
| Blood Moon | runner | wall | 30 | 1740 | 414 | 6 | 1356 | 1 | 6 |
| Blood Moon | runner | zombie_bait | 3 | 6 | 420 | 4 | 1356 | 0 | 3 |
| Blood Moon | spitter | *base* | - | - | 376 | 1 | 941 | 2 | - |
| Blood Moon | spitter | auto_crossbow | 1 | 985 | 136 | 31 | 941 | 3 | 125 |
| Blood Moon | spitter | barricade | 5 | 25 | 376 | 1 | 1003 | 2 | 0 |
| Blood Moon | spitter | beehive | 8 | 1720 | 368 | 2 | 1053 | 10 | 4 |
| Blood Moon | spitter | catapult | 3 | 1452 | 0 | 48 | 619 | 0 | 196 |
| Blood Moon | spitter | decoy | 22 | 440 | 376 | 1 | 941 | 2 | 0 |
| Blood Moon | spitter | electric_fence | 30 | 630 | 376 | 1 | 941 | 3 | 0 |
| Blood Moon | spitter | fence | 30 | 210 | 376 | 1 | 941 | 3 | 0 |
| Blood Moon | spitter | flame_tower | 1 | 1855 | 376 | 1 | 941 | 3 | 0 |
| Blood Moon | spitter | garlic_braid | 18 | 540 | 384 | 0 | 1090 | 2 | -4 |
| Blood Moon | spitter | gun_tower | 2 | 1448 | 296 | 11 | 941 | 4 | 41 |
| Blood Moon | spitter | mine | 6 | 1314 | 176 | 26 | 941 | 2 | 104 |
| Blood Moon | spitter | mortar | 1 | 1910 | 0 | 48 | 589 | 0 | 196 |
| Blood Moon | spitter | sandbag_wall | 30 | 570 | 376 | 1 | 941 | 3 | 0 |
| Blood Moon | spitter | searchlight | 5 | 1845 | 376 | 1 | 941 | 2 | 0 |
| Blood Moon | spitter | wall | 30 | 1740 | 376 | 1 | 941 | 3 | 0 |
| Blood Moon | spitter | zombie_bait | 3 | 6 | 376 | 1 | 941 | 2 | 0 |
| Blood Moon | tank | *base* | - | - | 180 | 0 | 982 | 0 | - |
| Blood Moon | tank | auto_crossbow | 1 | 985 | 120 | 4 | 982 | 0 | 31 |
| Blood Moon | tank | barricade | 5 | 25 | 180 | 0 | 1079 | 0 | 0 |
| Blood Moon | tank | beehive | 8 | 1720 | 180 | 0 | 982 | 0 | 0 |
| Blood Moon | tank | catapult | 3 | 1452 | 0 | 12 | 565 | 0 | 94 |
| Blood Moon | tank | decoy | 22 | 440 | 0 | 0 | 2400 | 19 | 94 |
| Blood Moon | tank | electric_fence | 30 | 630 | 180 | 0 | 982 | 1 | 0 |
| Blood Moon | tank | fence | 30 | 210 | 180 | 0 | 982 | 1 | 0 |
| Blood Moon | tank | flame_tower | 1 | 1855 | 180 | 0 | 982 | 0 | 0 |
| Blood Moon | tank | garlic_braid | 18 | 540 | 180 | 0 | 1218 | 0 | 0 |
| Blood Moon | tank | gun_tower | 2 | 1448 | 135 | 3 | 982 | 0 | 23 |
| Blood Moon | tank | mine | 6 | 1314 | 105 | 5 | 982 | 0 | 39 |
| Blood Moon | tank | mortar | 1 | 1910 | 0 | 12 | 573 | 0 | 94 |
| Blood Moon | tank | sandbag_wall | 30 | 570 | 180 | 0 | 982 | 1 | 0 |
| Blood Moon | tank | searchlight | 5 | 1845 | 180 | 0 | 982 | 0 | 0 |
| Blood Moon | tank | wall | 30 | 1740 | 180 | 0 | 982 | 1 | 0 |
| Blood Moon | tank | zombie_bait | 3 | 6 | 180 | 0 | 982 | 0 | 0 |
| Blood Moon | walker | *base* | - | - | 690 | 3 | 1039 | 0 | - |
| Blood Moon | walker | auto_crossbow | 1 | 985 | 0 | 72 | 864 | 0 | 361 |
| Blood Moon | walker | barricade | 5 | 25 | 690 | 3 | 1091 | 0 | 0 |
| Blood Moon | walker | beehive | 8 | 1720 | 640 | 8 | 1039 | 0 | 26 |
| Blood Moon | walker | catapult | 3 | 1452 | 0 | 72 | 706 | 0 | 361 |
| Blood Moon | walker | decoy | 22 | 440 | 670 | 5 | 1039 | 21 | 10 |
| Blood Moon | walker | electric_fence | 30 | 630 | 690 | 3 | 1039 | 1 | 0 |
| Blood Moon | walker | fence | 30 | 210 | 690 | 3 | 1039 | 1 | 0 |
| Blood Moon | walker | flame_tower | 1 | 1855 | 80 | 64 | 1039 | 0 | 319 |
| Blood Moon | walker | garlic_braid | 18 | 540 | 700 | 2 | 1163 | 0 | -5 |
| Blood Moon | walker | gun_tower | 2 | 1448 | 330 | 39 | 1039 | 0 | 188 |
| Blood Moon | walker | mine | 6 | 1314 | 520 | 20 | 1039 | 0 | 89 |
| Blood Moon | walker | mortar | 1 | 1910 | 0 | 72 | 680 | 0 | 361 |
| Blood Moon | walker | sandbag_wall | 30 | 570 | 680 | 4 | 1039 | 1 | 5 |
| Blood Moon | walker | searchlight | 5 | 1845 | 690 | 3 | 1039 | 0 | 0 |
| Blood Moon | walker | wall | 30 | 1740 | 680 | 4 | 1039 | 1 | 5 |
| Blood Moon | walker | zombie_bait | 3 | 6 | 680 | 4 | 1039 | 0 | 5 |
| Blood Moon | wraith | *base* | - | - | 576 | 0 | 800 | 0 | - |
| Blood Moon | wraith | auto_crossbow | 1 | 985 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | barricade | 5 | 25 | 576 | 0 | 846 | 0 | 0 |
| Blood Moon | wraith | beehive | 8 | 1720 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | catapult | 3 | 1452 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | decoy | 22 | 440 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | electric_fence | 30 | 630 | 576 | 0 | 800 | 1 | 0 |
| Blood Moon | wraith | fence | 30 | 210 | 576 | 0 | 800 | 1 | 0 |
| Blood Moon | wraith | flame_tower | 1 | 1855 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | garlic_braid | 18 | 540 | 576 | 0 | 913 | 0 | 0 |
| Blood Moon | wraith | gun_tower | 2 | 1448 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | mine | 6 | 1314 | 468 | 9 | 800 | 0 | 56 |
| Blood Moon | wraith | mortar | 1 | 1910 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | wraith | sandbag_wall | 30 | 570 | 576 | 0 | 800 | 1 | 0 |
| Blood Moon | wraith | searchlight | 5 | 1845 | 552 | 2 | 800 | 0 | 12 |
| Blood Moon | wraith | wall | 30 | 1740 | 576 | 0 | 800 | 1 | 0 |
| Blood Moon | wraith | zombie_bait | 3 | 6 | 576 | 0 | 800 | 0 | 0 |
| Blood Moon | giant | *base* | - | - | 322 | 2 | 1176 | 0 | - |
| Blood Moon | giant | auto_crossbow | 1 | 985 | 40 | 54 | 1176 | 0 | 147 |
| Blood Moon | giant | barricade | 5 | 25 | 319 | 3 | 1303 | 0 | 1 |
| Blood Moon | giant | beehive | 8 | 1720 | 296 | 6 | 1176 | 0 | 13 |
| Blood Moon | giant | catapult | 3 | 1452 | 0 | 55 | 1121 | 0 | 168 |
| Blood Moon | giant | decoy | 22 | 440 | 295 | 4 | 1176 | 21 | 14 |
| Blood Moon | giant | electric_fence | 30 | 630 | 319 | 3 | 1176 | 1 | 1 |
| Blood Moon | giant | fence | 30 | 210 | 319 | 3 | 1176 | 1 | 1 |
| Blood Moon | giant | flame_tower | 1 | 1855 | 43 | 53 | 1176 | 0 | 146 |
| Blood Moon | giant | garlic_braid | 18 | 540 | 325 | 1 | 1486 | 0 | -1 |
| Blood Moon | giant | gun_tower | 2 | 1448 | 223 | 21 | 1176 | 0 | 51 |
| Blood Moon | giant | mine | 6 | 1314 | 232 | 18 | 1176 | 0 | 47 |
| Blood Moon | giant | mortar | 1 | 1910 | 49 | 51 | 1176 | 0 | 142 |
| Blood Moon | giant | sandbag_wall | 30 | 570 | 319 | 3 | 1176 | 1 | 1 |
| Blood Moon | giant | searchlight | 5 | 1845 | 322 | 2 | 1176 | 0 | 0 |
| Blood Moon | giant | wall | 30 | 1740 | 309 | 4 | 1176 | 1 | 6 |
| Blood Moon | giant | zombie_bait | 3 | 6 | 319 | 3 | 1176 | 0 | 1 |
| Blood Moon | harvester | *base* | - | - | 226 | 11 | 681 | 2 | - |
| Blood Moon | harvester | auto_crossbow | 1 | 985 | 121 | 95 | 721 | 3 | 54 |
| Blood Moon | harvester | barricade | 5 | 25 | 225 | 12 | 726 | 3 | 0 |
| Blood Moon | harvester | beehive | 8 | 1720 | 155 | 75 | 1085 | 10 | 37 |
| Blood Moon | harvester | catapult | 3 | 1452 | 45 | 108 | 607 | 0 | 94 |
| Blood Moon | harvester | decoy | 22 | 440 | 226 | 11 | 681 | 2 | 0 |
| Blood Moon | harvester | electric_fence | 30 | 630 | 223 | 14 | 681 | 3 | 1 |
| Blood Moon | harvester | fence | 30 | 210 | 225 | 12 | 681 | 3 | 0 |
| Blood Moon | harvester | flame_tower | 1 | 1855 | 141 | 96 | 765 | 3 | 44 |
| Blood Moon | harvester | garlic_braid | 18 | 540 | 225 | 12 | 893 | 2 | 0 |
| Blood Moon | harvester | gun_tower | 2 | 1448 | 186 | 37 | 825 | 4 | 20 |
| Blood Moon | harvester | mine | 6 | 1314 | 145 | 92 | 681 | 2 | 42 |
| Blood Moon | harvester | mortar | 1 | 1910 | 45 | 108 | 607 | 0 | 94 |
| Blood Moon | harvester | sandbag_wall | 30 | 570 | 223 | 14 | 681 | 3 | 1 |
| Blood Moon | harvester | searchlight | 5 | 1845 | 225 | 12 | 681 | 2 | 0 |
| Blood Moon | harvester | wall | 30 | 1740 | 222 | 15 | 681 | 3 | 2 |
| Blood Moon | harvester | zombie_bait | 3 | 6 | 226 | 11 | 681 | 2 | 0 |
| Blood Moon | scarecrow_king | *base* | - | - | 271 | 8 | 1192 | 0 | - |
| Blood Moon | scarecrow_king | auto_crossbow | 1 | 985 | 43 | 73 | 1171 | 0 | 119 |
| Blood Moon | scarecrow_king | barricade | 5 | 25 | 259 | 12 | 1277 | 0 | 6 |
| Blood Moon | scarecrow_king | beehive | 8 | 1720 | 115 | 59 | 1171 | 0 | 81 |
| Blood Moon | scarecrow_king | catapult | 3 | 1452 | 187 | 25 | 1192 | 0 | 43 |
| Blood Moon | scarecrow_king | decoy | 22 | 440 | 271 | 8 | 1192 | 0 | 0 |
| Blood Moon | scarecrow_king | electric_fence | 30 | 630 | 268 | 9 | 1283 | 1 | 1 |
| Blood Moon | scarecrow_king | fence | 30 | 210 | 268 | 9 | 1268 | 1 | 1 |
| Blood Moon | scarecrow_king | flame_tower | 1 | 1855 | 259 | 10 | 1192 | 0 | 6 |
| Blood Moon | scarecrow_king | garlic_braid | 18 | 540 | 247 | 16 | 1432 | 0 | 12 |
| Blood Moon | scarecrow_king | gun_tower | 2 | 1448 | 64 | 69 | 1171 | 0 | 108 |
| Blood Moon | scarecrow_king | mine | 6 | 1314 | 217 | 17 | 1192 | 0 | 28 |
| Blood Moon | scarecrow_king | mortar | 1 | 1910 | 187 | 25 | 1192 | 0 | 43 |
| Blood Moon | scarecrow_king | sandbag_wall | 30 | 570 | 271 | 8 | 1192 | 1 | 0 |
| Blood Moon | scarecrow_king | searchlight | 5 | 1845 | 268 | 9 | 1192 | 0 | 1 |
| Blood Moon | scarecrow_king | wall | 30 | 1740 | 268 | 9 | 1192 | 1 | 1 |
| Blood Moon | scarecrow_king | zombie_bait | 3 | 6 | 271 | 8 | 1192 | 0 | 0 |
| Blood Moon | winter_lord | *base* | - | - | 284 | 2 | 1312 | 0 | - |
| Blood Moon | winter_lord | auto_crossbow | 1 | 985 | 110 | 18 | 1312 | 0 | 91 |
| Blood Moon | winter_lord | barricade | 5 | 25 | 284 | 2 | 1434 | 0 | 0 |
| Blood Moon | winter_lord | beehive | 8 | 1720 | 284 | 2 | 1312 | 0 | 0 |
| Blood Moon | winter_lord | catapult | 3 | 1452 | 86 | 20 | 1312 | 0 | 103 |
| Blood Moon | winter_lord | decoy | 22 | 440 | 194 | 1 | 2400 | 21 | 47 |
| Blood Moon | winter_lord | electric_fence | 30 | 630 | 284 | 2 | 1312 | 1 | 0 |
| Blood Moon | winter_lord | fence | 30 | 210 | 284 | 2 | 1312 | 1 | 0 |
| Blood Moon | winter_lord | flame_tower | 1 | 1855 | 124 | 16 | 1312 | 0 | 83 |
| Blood Moon | winter_lord | garlic_braid | 18 | 540 | 294 | 1 | 1610 | 0 | -5 |
| Blood Moon | winter_lord | gun_tower | 2 | 1448 | 194 | 11 | 1312 | 0 | 47 |
| Blood Moon | winter_lord | mine | 6 | 1314 | 152 | 14 | 1312 | 0 | 69 |
| Blood Moon | winter_lord | mortar | 1 | 1910 | 134 | 16 | 1312 | 0 | 78 |
| Blood Moon | winter_lord | sandbag_wall | 30 | 570 | 284 | 2 | 1312 | 1 | 0 |
| Blood Moon | winter_lord | searchlight | 5 | 1845 | 294 | 1 | 1312 | 0 | -5 |
| Blood Moon | winter_lord | wall | 30 | 1740 | 284 | 2 | 1312 | 1 | 0 |
| Blood Moon | winter_lord | zombie_bait | 3 | 6 | 284 | 2 | 1312 | 0 | 0 |
