# HARVEST THE NIGHT - um devlog

![trinta segundos do jogo](the-trailer.gif)

*Trinta segundos, uma semente: um dia de fazenda, a luz passando, uma noite aguentando, e a cerca caindo.*

A ideia cabia numa frase: **uma fazenda que tambem e uma fortaleza**, sem um
segundo mapa e sem tela de carregamento entre os dois. Voce trabalha o campo
o dia inteiro e a noite alguma coisa atravessa esse mesmo campo. Tudo que
importa neste jogo vem de se recusar a deixar que sejam dois lugares.

O que isso acabou significando, ao longo de cento e dez tarefas, e que quase
todo problema dificil era o *mesmo* problema com outra roupa. As regras
tinham que ser um unico dicionario de dados simples para que o mesmo estado
pudesse ser salvo, hasheado, repetido, comparado e fotografado - e no
momento em que qualquer coisa pegava um node, um relogio ou um dicionario
sem ordenar, alguma coisa quebrava em silencio mais adiante. Metade das
entradas abaixo e essa licao sendo aprendida de novo em outro lugar.

A outra metade sao as verificacoes. Nao testes escritos depois para dar
seguranca: verificacoes escritas para falhar, plantadas com o bug que
deveriam pegar, e reescritas quando passavam mesmo assim. Tres das entradas
abaixo sao uma verificacao que vinha passando havia vinte e tantas tarefas
sem conseguir falhar. E o tipo de coisa que esta lista existe para dizer em
voz alta.

## O que era para ser

> **Um cozy farming game onde sua fazenda é também sua fortaleza.**
>
> Durante o dia, plante, pesque, minere e produza recursos.
>
> À noite, troque de realidade e transforme a mesma fazenda em uma fortaleza contra hordas de zumbis.
>
> Tudo que você produz durante o dia determina o que consegue construir à noite.
>
> **Construa sua fazenda. Monte sua defesa. Descubra se ela sobrevive.**
>

## O que acabou sendo

146 tarefas em 6 dias, de  a 2026-10-08. Uma de cada vez, cada uma terminada e verificada antes de comecar a proxima.

| # | O que foi feito | Terminado |
|---|---|---|
| 0042 | The shooting tower | 2026-09-27 |
| 0000 | The backlog itself | 2026-09-27 |
| 0001 | Godot project scaffold | 2026-09-27 |
| 0002 | Fixed-timestep deterministic simulation | 2026-09-27 |
| 0003 | game_data.gd, the one file of levers | 2026-09-27 |
| 0004 | Harden the headless check harness | 2026-09-27 |
| 0005 | verify.py and the determinism guard | 2026-09-27 |
| 0006 | The phase machine: day, preparation, night, result | 2026-09-27 |
| 0007 | The resource ledger | 2026-09-27 |
| 0008 | The farm grid | 2026-09-27 |
| 0009 | Settings singleton | 2026-09-27 |
| 0010 | Save the profile and the run | 2026-09-27 |
| 0011 | input_check harness | 2026-09-27 |
| 0012 | Debug overlay | 2026-09-27 |
| 0013 | The world renders | 2026-09-27 |
| 0014 | Sprites generated from ASCII maps | 2026-09-27 |
| 0015 | The player walks and interacts | 2026-09-27 |
| 0016 | Trees and wood | 2026-09-27 |
| 0017 | Rocks and stone | 2026-09-27 |
| 0018 | Wheat: till, plant, grow, harvest | 2026-09-27 |
| 0019 | The workshop and its first recipe | 2026-09-27 |
| 0020 | The shop: sell and buy | 2026-09-27 |
| 0021 | The day HUD | 2026-09-27 |
| 0022 | Switching reality | 2026-09-27 |
| 0023 | Build mode | 2026-09-27 |
| 0024 | The shooting tower | 2026-09-27 |
| 0025 | Zombies walk to the house | 2026-09-27 |
| 0026 | The tower kills the zombie | 2026-09-27 |
| 0027 | Three waves, a result screen, and back to the farm | 2026-09-27 |
| 0028 | Corn and carrot |  |
| 0029 | Growth stages and watering | 2026-09-27 |
| 0030 | Fishing | 2026-09-27 |
| 0031 | Iron from the rock face | 2026-09-27 |
| 0032 | Oil | 2026-09-27 |
| 0033 | The generator and energy | 2026-09-27 |
| 0034 | Cooking: food and meat | 2026-09-27 |
| 0035 | Gunpowder and ammunition | 2026-09-27 |
| 0036 | The inventory | 2026-09-27 |
| 0037 | The workshop queue | 2026-09-27 |
| 0038 | Production runs while you are elsewhere | 2026-09-27 |
| 0039 | The day clock and dusk | 2026-09-27 |
| 0040 | The shop grows | 2026-09-27 |
| 0041 | The first day teaches itself | 2026-09-27 |
| 0042 | Data-driven defences | 2026-09-27 |
| 0043 | The flamethrower tower | 2026-09-27 |
| 0044 | The mortar | 2026-09-27 |
| 0045 | The auto-crossbow | 2026-09-27 |
| 0046 | Fences and walls | 2026-09-27 |
| 0047 | Barricades | 2026-09-27 |
| 0048 | Mines and traps |  |
| 0049 | Zombies path around walls |  |
| 0050 | The runner |  |
| 0051 | The tank |  |
| 0052 | The breaker |  |
| 0053 | Repair during the night |  |
| 0054 | The player's ability |  |
| 0055 | Double speed and skipping the night |  |
| 0056 | The night HUD |  |
| 0057 | Structures take damage and die |  |
| 0058 | The Giant |  |
| 0059 | Waves as data |  |
| 0060 | The ten nights, authored |  |
| 0061 | Night rewards |  |
| 0062 | Technology points |  |
| 0063 | The tech tree |  |
| 0064 | Tower I, II, automatic |  |
| 0065 | Losing a night costs you |  |
| 0066 | Night 10 and the end of the run |  |
| 0067 | The autoplayer |  |
| 0068 | A balance sweep over the ten nights |  |
| 0069 | Run statistics | 2026-09-27 |
| 0070 | Endless nights past ten | 2026-09-27 |
| 0071 | The two palettes | 2026-09-27 |
| 0072 | The farm tileset | 2026-09-28 |
| 0073 | The player sprite | 2026-09-28 |
| 0074 | Zombie sprites | 2026-09-28 |
| 0075 | Buildings and towers | 2026-09-28 |
| 0076 | Night lighting | 2026-09-28 |
| 0077 | Particles | 2026-09-28 |
| 0078 | The reality transition | 2026-09-28 |
| 0079 | Resource icons and the UI kit | 2026-09-28 |
| 0080 | A pixel font | 2026-09-28 |
| 0081 | The UI theme | 2026-09-28 |
| 0082 | Screenshots, and actually looking at them | 2026-09-28 |
| 0083 | Audio buses and a sound manager | 2026-09-28 |
| 0084 | The sounds of the day | 2026-09-28 |
| 0085 | The sounds of the night | 2026-09-28 |
| 0086 | Two pieces of music | 2026-09-28 |
| 0087 | Ambience | 2026-09-28 |
| 0088 | Juice: shake, hit stop, damage numbers | 2026-09-28 |
| 0089 | Tooltips | 2026-09-28 |
| 0090 | The log panel | 2026-09-28 |
| 0091 | The title screen | 2026-09-28 |
| 0092 | The main menu and the router | 2026-09-28 |
| 0093 | Options: video | 2026-09-28 |
| 0094 | Options: audio | 2026-09-28 |
| 0095 | Options: controls | 2026-09-28 |
| 0096 | The pause menu | 2026-09-28 |
| 0097 | English and Portuguese | 2026-09-28 |
| 0098 | Accessibility | 2026-09-28 |
| 0099 | An icon and a boot ident | 2026-09-28 |
| 0100 | Exports: Windows and Web | 2026-09-28 |
| 0101 | Onboarding in seven lines | 2026-09-28 |
| 0102 | A performance budget | 2026-09-28 |
| 0103 | Crash and error reporting | 2026-09-28 |
| 0104 | Saves survive an update | 2026-09-28 |
| 0105 | A playtest build | 2026-09-28 |
| 0106 | The release checklist | 2026-09-28 |
| 0107 | Store assets | 2026-09-28 |
| 0108 | The devlog and a trailer clip | 2026-09-29 |
| 0109 | The character reacts | 2026-09-29 |
| 0110 | Refusals in two languages | 2026-09-29 |
| 0112 | Room in the test suites | 2026-10-07 |
| 0113 | Repairs mend to the real maximum | 2026-10-07 |
| 0114 | Untouched means the house the night started with | 2026-10-07 |
| 0115 | Spawn ground that cannot be built shut | 2026-10-07 |
| 0116 | The mortar and the flamethrower, empty and upgraded | 2026-10-07 |
| 0117 | Three stale documents | 2026-10-07 |
| 0118 | One road into the waves | 2026-10-07 |
| 0119 | Tests and tools build in the build step | 2026-10-08 |
| 0120 | One road for art that has not arrived | 2026-10-08 |
| 0121 | A controller for every action | 2026-10-08 |
| 0126 | The clock: 06:00 to 02:00 | 2026-10-08 |
| 0127 | Going to bed starts the night | 2026-10-08 |
| 0128 | Passing out at 02:00 | 2026-10-08 |
| 0129 | He stays in bed all night | 2026-10-08 |
| 0130 | The night camera | 2026-10-08 |
| 0131 | The guardian's cursor | 2026-10-08 |
| 0132 | Defences go down only at night | 2026-10-08 |
| 0133 | The hotbar of defences | 2026-10-08 |
| 0134 | Repairing by cursor | 2026-10-08 |
| 0135 | The flare goes where you aim it | 2026-10-08 |
| 0136 | The build step waits for START | 2026-10-08 |
| 0137 | The night ends at 06:00 | 2026-10-08 |
| 0138 | Waking up: the morning report | 2026-10-08 |
| 0122 | Art: the farmer's run - done 2026-10-08 (cancelled by the owner) |  |
| 0139 | The night HUD for the guardian | 2026-10-08 |
| 0140 | The day HUD: the hour and bedtime | 2026-10-08 |
| 0141 | Teaching the new night | 2026-10-08 |
| 0142 | The autoplayer sleeps too | 2026-10-08 |
| 0148 | Checkpoint: is the night better with him asleep? | 2026-10-08 |
| 0149 | The calendar: four seasons of fourteen days | 2026-10-08 |
| 0150 | Nights looked up by the calendar | 2026-10-08 |
| 0151 | The night is the calendar day | 2026-10-08 |
| 0152 | Full Moon nights | 2026-10-08 |
| 0153 | Boss nights repeat until the boss falls | 2026-10-08 |

## Toda vez que o jogo mudou por baixo

Dois hashes protegem este projeto: um sobre as regras e outro sobre as tabelas de balanceamento. Entre os dois eles se mexeram 40 vezes, e cada uma teve que ser escrita antes de ser aceita.

- **verify.py and the determinism guard** (0005) - `data` 3714036227 -> 1895612796
- **The resource ledger** (0007) - `sim` 2127612543 -> 673656594
- **The resource ledger** (0007) - `data` 3714036227 -> 1015548053
- **The farm grid** (0008) - `sim` 673656594 -> 3413240837
- **The farm grid** (0008) - `data` 1015548053 -> 2522481920
- **The player walks and interacts** (0015) - `sim` 3413240837 -> 4066923035
- **The player walks and interacts** (0015) - `data` 2522481920 -> 3593855788
- **Trees and wood** (0016) - `sim` 4066923035 -> 2123598417
- **Trees and wood** (0016) - `data` 3593855788 -> 3968728927
- **Rocks and stone** (0017) - `sim` 2123598417 -> 3337239467
- **Wheat: till, plant, grow, harvest** (0018) - `sim` 3337239467 -> 2213922541
- **The workshop and its first recipe** (0019) - `sim` 2213922541 -> 865751178
- **The shop: sell and buy** (0020) - `sim` 865751178 -> 684454707
- **The day HUD** (0021) - `sim` 684454707 -> 1543735352
- **Build mode** (0023) - `data` 1084797554 -> 2501830300
- **The shooting tower** (0024) - `sim` 3694981960 -> 4008937129
- **Zombies walk to the house** (0025) - `sim` 4008937129 -> 1177574569
- **The tower kills the zombie** (0026) - `sim` 1177574569 -> 3224086426
- **Three waves, a result screen, and back to the farm** (0027) - `data` 4216175348 -> 1636540132
- **The log panel** (0090) - `sim` 2555959448 -> 215410677
- **English and Portuguese** (0097) - `data` 2601044827 -> 2842078959
- **Onboarding in seven lines** (0101) - `sim` 215410677 -> 4262811284
- **Onboarding in seven lines** (0101) - `data` 2842078959 -> 407837701
- **Onboarding in seven lines** (0101) - `data` 2842078959 -> 407837701
- **Onboarding in seven lines** (0101) - `sim` 215410677 -> 4262811284
- **Saves survive an update** (0104) - `sim` 4262811284 -> 1961000123
- **Refusals in two languages** (0110) - `sim` 1961000123 -> 3960053733
- **Room in the test suites** (0112) - `data` 2015186086 -> 1968527100
- **The clock: 06:00 to 02:00** (0126) - `data` 1968527100 -> 1739027987
- **Passing out at 02:00** (0128) - `sim` 10253699 -> 734279793
- **Passing out at 02:00** (0128) - `data` 1739027987 -> 954093946
- **He stays in bed all night** (0129) - `sim` 734279793 -> 1212869859
- **Defences go down only at night** (0132) - `sim` 1212869859 -> 2823820161
- **Defences go down only at night** (0132) - `data` 954093946 -> 2599455698
- **The flare goes where you aim it** (0135) - `sim` 2823820161 -> 204996281
- **The build step waits for START** (0136) - `sim` 204996281 -> 2903453887
- **The night ends at 06:00** (0137) - `sim` 2903453887 -> 40581503
- **Waking up: the morning report** (0138) - `sim` 40581503 -> 1222657941
- **Teaching the new night** (0141) - `sim` 1222657941 -> 3911863006
- **Teaching the new night** (0141) - `data` 898358060 -> 3047858822

## O que deu errado

50 coisas, tiradas do diario pelas palavras que ele usa quando algo nao funcionou. E para isso que serve um devlog.

- **0039** - The clock was counting the wrong thing *(The day clock and dusk)*
- **0040** - A long, expensive bug hunt, and what it was *(The shop grows)*
- **0041** - Which is how the first real bug turned up *(The first day teaches itself)*
- **0042** - And it broke a test, correctly *(Data-driven defences)*
- **0045** - Right against a rush, wrong against a tank - by arithmetic *(The auto-crossbow)*
- **0050** - Three fixtures that were wrong before the code was *(The runner)*
- **0053** - Two tests that were wrong about the game *(Repair during the night)*
- **0067** - What it found, in order of how much it matters *(The autoplayer)*
- **0069** - Two asserts I wrote wrong *(Run statistics)*
- **0070** - An assert I wrote wrong *(Endless nights past ten)*
- **0073** - The shadow, and a test that lied to me *(The player sprite)*
- **0073** - An assert that was wrong about the rules *(The player sprite)*
- **0074** - Two things that were quietly wrong *(Zombie sprites)*
- **0074** - A bug in my own screenshot tooling, twice *(Zombie sprites)*
- **0076** - An assert that was right about the wrong version *(Night lighting)*
- **0077** - Three performance bugs, and the first measurement was wrong too *(Particles)*
- **0078** - What the first version got wrong *(The reality transition)*
- **0078** - Two bugs of my own *(The reality transition)*
- **0080** - A line of configuration that silently did nothing *(A pixel font)*
- **0082** - Three bugs between "a seed and a script" and the same picture twice *(Screenshots, and actually looking at them)*
- **0082** - Looking at the pictures is the point, and it found things *(Screenshots, and actually looking at them)*
- **0085** - Two asserts that were wrong before they were right *(The sounds of the night)*
- **0086** - Two asserts that the new setting broke, and only one of them was right *(Two pieces of music)*
- **0088** - A bug in task 0085 that this task's watching exposed *(Juice: shake, hit stop, damage numbers)*
- **0088** - Batching, and a test that proved nothing twice *(Juice: shake, hit stop, damage numbers)*
- **0090** - Two bugs found by writing it down *(The log panel)*
- **0092** - Two sorts of state, and the bug that taught me the difference *(The main menu and the router)*
- **0093** - Three things this got wrong, all found by the checks *(Options: video)*
- **0093** - The bugs planted to check the checks *(Options: video)*
- **0094** - The first slider in the game, and what it showed *(Options: audio)*
- **0095** - Three things the checks found *(Options: controls)*
- **0096** - Abandon asks twice, and the second question is the interesting one *(The pause menu)*
- **0100** - The pack is where this goes wrong, and it went wrong *(Exports: Windows and Web)*
- **0101** - Two nearly-right versions of "they found the stall" *(Onboarding in seven lines)*
- **0101** - The shot found the water line pointing off the screen *(Onboarding in seven lines)*
- **0102** - Four measurement bugs, all found by reading the numbers *(A performance budget)*
- **0103** - Three things found by looking rather than by running *(Crash and error reporting)*
- **0103** - And one the pictures found that was nothing to do with this task *(Crash and error reporting)*
- **0103** - The input case failed against code that was right *(Crash and error reporting)*
- **0104** - A missing key takes the default, which is a new game's value and not nought *(Saves survive an update)*
- **0104** - One fragility a planted bug found *(Saves survive an update)*
- **0105** - The finding this task was supposed to make is still owed *(A playtest build)*
- **0105** - Looking at the pictures moved the badge twice *(A playtest build)*
- **0105** - An old determinism check had been passing on luck *(A playtest build)*
- **0105** - Two things found by reading the tool's own output *(A playtest build)*
- **0106** - What the first run found: two tech nodes that did nothing *(The release checklist)*
- **0106** - Step 8 is the one step not run *(The release checklist)*
- **0106** - The known-issues section names five things and one of them is owed *(The release checklist)*
- **0107** - The capsules took two looks to stop being wrong *(Store assets)*
- **0107** - And the store screenshot found a bug in the game *(Store assets)*

## O que nao tem

A lista do proprio documento de design, escrita antes de qualquer coisa existir, para proteger o escopo:

- cidade
- múltiplos mapas
- casamento
- relacionamento complexo com NPC
- dezenas de NPCs
- animais complexos
- clima complexo
- estações do ano
- multiplayer
- procedural generation
- árvore tecnológica gigante
- dezenas de crops
- dezenas de inimigos
- crafting complexo
- história longa.

E o que ainda esta errado, da lista de release:

- Nobody has watched a first-time player through day one. Task 0101 built the seven tutorial lines and measured which four a player clears without reading them; the three that have to be read - the stall, putting a defence down, and sending for the night - have never been watched. Task 0105 built the build and the log reader to do it with. It is an hour of somebody's time and it has not been spent.
- Twenty-seven English sentences are still hard-coded in `src/core/` (`building.gd`, `sim.gd`, `farm.gd`, `tech.gd`). They are refusals - "there is something there already" - and a Portuguese player gets them in English. Task 0110.
- The web build's size budget is met gzipped. On a connection that does not negotiate compression it is roughly three times that. Nothing is done about this and nothing is planned.
- The tech tree's effects are checked, not balanced. As of 0.1.0 every node does what its sentence says, which was not true before this list was first run - but no pass has been made over whether the numbers are worth their costs.
- Endless mode past night ten exists in the rules and has not been played for any length of time by anybody.

---

*Gerado de implementation/PROGRESS.md por tools/devlog.py. Editar este arquivo a mao e editar algo que vai ser sobrescrito - o diario e a fonte.*
