# HARVEST THE NIGHT — Plano do jogo: dia, noite e o caminho até a v1.0

> **Status:** proposta para revisão, escrita em 2026-10-07.
> O MVP do `design.md` está pronto: 10 noites, o Gigante e o modo infinito.
> Este documento é o plano do jogo completo. Onde ele muda o `design.md`, a
> seção 12 diz o quê. Os números são pontos de partida; todos viram alavancas
> (`# LEVER` no `game_data.gd`) e se acertam no playtest.

## Resumo em 30 segundos

- **De dia, o fazendeiro ganha dinheiro.** Ele planta, pesca, minera, corta
  madeira, cria animais, produz e vende.
- **À noite, ele vai dormir.** Ao deitar, a fazenda atravessa para a outra
  realidade. Você não anda mais com ele: vira o **guardião da fazenda**, com
  um cursor e a câmera livre, e posiciona as armas, armadilhas e muros com o
  dinheiro e os materiais que o dia rendeu.
- **A noite acaba às 06:00.** Se a casa estiver de pé, a noite está vencida.
  Os zumbis que sobraram fogem (já implementado), você vê o resultado e ele
  acorda para mais um dia.
- **A campanha é um ano: 4 estações de 14 dias, ou seja 56 dias e 56
  noites.** São 8 noites de Lua Cheia e 4 chefes, cerca de 10 a 13 horas de
  jogo. Depois vem o Ano 2, que não acaba.

---

## 1. O ciclo de um dia

| Momento | Hora no jogo | Quem você controla | O que acontece |
|---|---|---|---|
| **Manhã** | 06:00 | o fazendeiro | Ele acorda na cama. Aparece o relatório da noite, e os restos que ela deixou ficam pela fazenda para coletar. |
| **Dia** | 06:00–18:00 | o fazendeiro | Plantar, regar, colher, pescar, minerar, cortar, cuidar dos animais, produzir e vender. A banca abre das 08:00 às 17:00. |
| **Entardecer** | 18:00–00:00 | o fazendeiro | Chega a **previsão da noite**: de onde vem a horda, quantos são e quais tipos. É a hora de terminar o serviço e voltar para casa. |
| **Dormir** | quando você quiser | — | Deitar na cama é a troca de realidade. Se ele ainda estiver acordado às 02:00, desmaia (veja abaixo). |
| **Noite: preparação** | relógio parado | o cursor do guardião | Colocar, melhorar, vender e consertar defesas, e ver a rota que os zumbis vão fazer. Quando estiver pronto, aperte **COMEÇAR**. |
| **Noite: ondas** | até as 06:00 (3 a 5 min reais) | o cursor | As ondas chegam na hora que a previsão disse. As torres atiram sozinhas. Você conserta, coloca defesas de emergência, usa poderes, acelera (1x/2x/4x) ou pula o resto. |
| **Amanhecer** | 06:00 | — | O sol nasce. Os sobreviventes viram as costas e saem da fazenda, e com a casa de pé a noite está vencida. Vem a tela de resultado, e o fazendeiro acorda. |

**Regras do ciclo:**

- **Duração do dia.** Proposta: de 8 a 10 minutos reais (hoje são 4; o
  Stardew tem cerca de 14). A fazenda ficou do tamanho da do Stardew, 80x65, e
  o dia de 4 minutos não acompanhou. Atravessar a fazenda andando já leva uns
  28 segundos.
- **Dormir cedo é permitido.** O resto do dia é pulado.
- **Desmaiar às 02:00.** Ele acorda na cama do mesmo jeito, mas a horda já
  está no portão: a preparação dura só 30 segundos em vez de ser livre.
- **A preparação não tem pressa.** O relógio fica parado até você apertar
  COMEÇAR. Hoje ela dura 20 s fixos e não dá para encerrar antes.
- **O dinheiro do dia vira defesa à noite.** A noite devolve **essência**
  (para a árvore de tecnologia) e **restos** que ajudam o dia (seção 4.6).
- **Ninguém anda à noite.** O fazendeiro dorme. Tudo o que você faz à noite é
  pelo cursor, e isso resolve um incômodo de hoje: andar com ele no escuro
  para construir e consertar.

---

## 2. Quantos dias e quantas noites

### Ano 1: a campanha

**56 dias e 56 noites**, em 4 estações de 14 dias (duas semanas cada). O
Stardew usa 28 dias por estação; aqui seriam 112 noites de cerco, demais para
um tower defense. Com 14, cada estação apresenta coisas novas no ritmo certo.

Toda estação segue o mesmo ritmo:

```text
dias 1–6        as noites crescem aos poucos
dia 7           LUA CHEIA: horda grande, recompensa dobrada
dias 8–13       as noites crescem de novo, com a novidade da estação
dia 14          LUA CHEIA com o CHEFE da estação
dia 1 seguinte  noite calma: a horda se reagrupa e a fazenda respira
```

| Estação | Dias | Por onde atacam | Inimigos novos | Chefe (dia 14) | Armas novas |
|---|---|---|---|---|---|
| **Primavera** | 1–14 | leste | andarilho, corredor, tanque, destruidor (todos já existem) | **O Gigante** (já existe) | torre de tiro, besta automática, cerca, barricada, muro e mina (todas já existem) |
| **Verão** | 15–28 | leste e sudeste | cuspidor, enxame de ratos | **A Colheitadeira**, uma máquina possuída | lança-chamas (já existe), espantalho, colmeia |
| **Outono** | 29–42 | mais o norte | corvo (voa e ignora muros), escavador (passa por baixo de cercas) | **O Rei Espantalho**, que chama corvos | morteiro (já existe), catapulta de abóbora, réstia de alho |
| **Inverno** | 43–56 | por todos os lados | zumbi de gelo (deixa as torres lentas), assombração (invisível sem luz) | **O Senhor do Inverno**, o chefe final | holofote, cerca elétrica |

A escalada acontece também no mapa: a cada estação abre mais um lado da
fazenda, até ela ficar cercada no inverno. Hoje a horda só vem do leste e do
sudeste.

### Eventos que mudam a noite

A previsão do entardecer avisa quando um evento vai acontecer:

- **Lua Cheia** (dias 7 e 14): mais zumbis e recompensa dobrada.
- **Neblina**: o alcance das torres cai 1. O holofote anula o efeito.
- **Chuva**: o fogo enfraquece e a lama deixa os zumbis lentos.
- **Lua de Sangue** (rara, só do outono em diante): zumbis de elite, que dão
  essência extra.

### Depois do Ano 1

- **O fim do Ano 1** é o Senhor do Inverno caído e os créditos: "você
  sobreviveu um ano".
- **O Ano 2 não acaba.** As estações se repetem com noites geradas, mais
  pesadas a cada estação. É o modo infinito de hoje, agora com calendário.
- **Duração estimada do Ano 1:** 56 ciclos de 11 a 14 minutos, ou seja de 10
  a 13 horas.

### Perder uma noite

- **Hoje**, perder custa um dia e a mesma noite volta. Isso funcionava no MVP,
  que não tinha calendário.
- **Com calendário**, a proposta é:
  - O calendário **sempre anda**, porque as plantações e as estações dependem
    dele.
  - A dificuldade da noite segue o calendário, e não o número de noites
    vencidas.
  - Perder custa caro, sem fim de jogo: a horda leva 25% do estoque (como
    hoje), pisoteia as plantações que estiverem no caminho (novo), e as
    defesas destruídas continuam destruídas (como hoje).
  - **Noite de chefe perdida se repete.** O chefe volta toda noite até cair, e
    a estação seguinte só começa depois disso. "O inverno não acaba enquanto
    o Senhor do Inverno estiver de pé."

---

## 3. O dia: ganhar dinheiro

### 3.1 Plantar

- **As plantas crescem por dias, não por segundos**, como no Stardew. Cada
  manhã conta um dia de crescimento para as que foram regadas na véspera.
  Hoje cenoura, trigo e milho ficam prontos em 1 a 3 minutos, o que fazia
  sentido no ciclo de 3 minutos do MVP.
- **Qualquer grama pode ser arada** com a enxada, como no Stardew. Os 60
  canteiros de hoje viram a horta inicial.
- **Rega:** continua diária e seca quando a noite começa (como hoje). Mais
  tarde vêm os **aspersores**, para automatizar.
- **Toda cultura tem um papel,** e isso cumpre o pilar "recursos têm dois
  usos":
  - 💰 é para vender;
  - 🍲 vira comida, que conserta a casa e as estruturas;
  - 🛡 é ingrediente de defesa.

| Estação | Cultura | Fica pronta em | Rebrota | Papel |
|---|---|---|---|---|
| Primavera | **Cenoura** (existe) | 3 dias | — | 🍲 refeições, que consertam a casa |
| Primavera | Batata | 5 dias | — | 💰🍲 |
| Primavera | Alho | 4 dias | — | 🛡 vira a réstia de alho: os zumbis evitam a área ou andam devagar perto dela |
| Primavera | Morango | 8 dias | a cada 4 | 💰 rende bem |
| Verão | **Milho** (existe) | 8 dias | a cada 4 | 🛡 vira óleo, que vira pólvora e munição incendiária (como hoje) |
| Verão | Pimenta | 5 dias | a cada 3 | 🛡 munição incendiária mais forte |
| Verão | Girassol | 7 dias | — | 🛡 as flores alimentam a colmeia; as sementes viram óleo |
| Verão | Melancia | 10 dias | — | 💰 a mais valiosa do verão |
| Outono | **Trigo** (existe) | 4 dias | — | 🍲 vira pão; 🛡 a palha vira espantalho e feno para os animais |
| Outono | Abóbora | 10 dias | — | 💰 ou 🛡 munição da catapulta |
| Outono | Uva | 8 dias | a cada 3 | 💰 vira vinho no barril |
| Outono | Beterraba | 6 dias | — | 💰 vira açúcar para geleias |
| Inverno | — | — | — | Nada cresce ao ar livre. É hora de pescar, minerar, produzir e viver do estoque do outono. |

Isso dá **12 culturas** (3 já existem). Uma estufa para plantar no inverno
fica para depois da v1.0.

### 3.2 Pescar

Hoje a pesca é assim: joga a linha, espera de 2 a 10 s, aperta na hora certa.
Só existe um peixe, e em 1 de cada 6 vezes ele vem triplo. A proposta:

- **Espécies por lugar, estação e hora.** São 3 lagos (o grande do noroeste,
  a lagoa do sudoeste e o lago do sudeste) e cerca de 12 peixes, mais **4
  lendários**, um por estação. Exemplos:
  - comuns: carpa, perca, bagre, tilápia;
  - médios: truta, lúcio, enguia;
  - raros: dourado, salmão, esturjão;
  - lendários: o Velho Bagre, a Rainha Dourada, o Lúcio Fantasma e o Esturjão
    de Gelo.
- **Um minijogo simples**, que funciona bem no controle: quando o peixe
  morde, um marcador corre numa barra e você aperta quando ele passa pela
  faixa verde, de 1 a 3 vezes conforme o peixe. É mais simples que a barra do
  Stardew.
- **Varas:**
  - **bambu**, a inicial;
  - **fibra**: a mordida vem mais rápido e o peixe raro aparece mais;
  - **ferro**: ganha espaço para isca e é a única que pega lendário.
- **Isca:** minhoca, que aparece ao arar, ou isca feita de restos de peixe.
- **Usos:** vender 💰, cozinhar 🍲, prensar em óleo 🛡 (como hoje), e a
  **isca de zumbi**, um peixe podre que atrai a horda para uma armadilha.
- **Coleção:** um livro de peixes com uma página para cada espécie.

### 3.3 Minerar e cortar

- **Pedreira do noroeste** (já existe):
  - pedra e ferro, como hoje;
  - **cobre** e **carvão** (novos), para aspersores, ferramentas e o gerador;
  - **ouro** a partir do outono.
- **Pedras da lua:** na manhã depois de uma Lua Cheia, aparecem fragmentos no
  caminho por onde a horda veio. Elas valem essência ou dinheiro. É a noite
  alimentando o dia.
- **Madeira** como hoje, mais a **madeira de lei**, que sai de tocos grandes
  com o machado melhorado e serve para muros fortes.
- **Sem mina ou caverna.** O pilar "uma fazenda só" continua valendo.

### 3.4 Animais

- **Hoje** são 1 vaca e 2 galinhas fixas que só dão carne.
- **Galinheiro:** galinhas dão ovos.
- **Celeiro:**
  - vacas dão leite;
  - ovelhas dão lã;
  - porcos acham trufas.
- **Alimentação:** feno, feito com a palha do trigo. É mais um uso para o
  trigo.
- **À noite** os animais dormem nas construções.
  - Os destruidores atacam construções, então proteger o celeiro passa a
    importar.
  - Por ser um jogo aconchegante, **nenhum animal morre**. Um celeiro
    destruído apenas para de produzir até ser consertado.
- **O cachorro:** é bicho de estimação de dia e, à noite, vira um poder
  ("chamar o cão", seção 4.4).

### 3.5 Produzir

**Como é hoje:**

- **Oficina:** kits de barricada, cerca, muro e mina, além de pólvora e
  munição incendiária.
- **Prensa:** transforma milho e peixe em óleo.
- **Cozinha:** faz refeições.
- **Gerador:** dá energia.

**O que entra:**

| Máquina | Produto | Valor |
|---|---|---|
| **Barril** | vinho e suco | 💰 caro |
| **Conserva** | geleia e picles | 💰 |
| **Laticínios** | queijo e manteiga | 💰 |
| **Tear** | tecido, feito com lã | 💰, e também 🛡 sacos de areia |
| **Moinho** | farinha, depois pão | 🍲 |

Produzir multiplica o valor: um vinho rende muito mais que as uvas vendidas
cruas. É o caminho do jogador que quer "farmar grana".

### 3.6 Vender

- **A banca** (já existe) agora tem um mascate que vem todo dia, das 08:00 às
  17:00. O estoque de sementes muda com a estação. Hoje a banca vende apenas
  madeira, pedra, ferro e as três culturas de hoje.
- **Caixa de envio** (nova, como a do Stardew): você deixa os itens nela a
  qualquer hora e recebe o pagamento na manhã seguinte.
- **Abrir a banca continua parando o relógio**, como hoje.

### 3.7 Ferramentas

- **São cinco:** enxada, regador, machado, picareta e vara de pesca.
- **Cada uma tem três níveis**, básico, ferro e ouro, comprados com dinheiro
  e minério na oficina.
- **O que melhora:** a área (o regador molha 3, depois 5 canteiros de uma
  vez), a velocidade (menos golpes) e, na vara, a qualidade da pesca.
- **Hoje não existem ferramentas.** O efeito "ferramentas afiadas" é um nó da
  árvore de tecnologia.

### 3.8 A casa

- **A cama** (hoje só decoração) passa a ser o botão da noite.
- **Melhorias pagas com dinheiro** (Casa I, II e III): cada nível dá mais
  vida para a casa e mais espaço para guardar coisas.
- **A vida da casa é o que protege o fazendeiro dormindo:** se a casa cai, a
  noite está perdida. Hoje ela tem 100 de vida, ou 140 com "madeira reforçada".

### 3.9 Sem estamina na v1.0

O relógio já é o limite do dia. O Stardew usa energia para mandar o jogador
dormir, e aqui a noite já faz esse papel. Se o playtest mostrar que falta um
freio, a estamina pode entrar depois.

---

## 4. A noite: defender a fazenda dormindo

### 4.1 O guardião (o cursor)

- **A câmera fica livre** e percorre a fazenda inteira com as setas, o WASD,
  a borda da tela ou o analógico. Não tem zoom, como hoje.
- **Na barra de armas**, cada defesa mostra o preço. Você clica para
  posicionar, e o fantasma da construção e a área de alcance já existem.
- **Clicando numa defesa**, você melhora, vende ou conserta.
- **No controle**, o cursor gruda nas casas do mapa.
- **A rota prevista dos zumbis** aparece na preparação; isso também já existe.
- **A cara do guardião** é decisão de arte: uma lanterna, uma coruja ou o
  espantalho da varanda que ganha vida à noite.

### 4.2 Preparação

- **O relógio fica parado e não há pressa.** A preparação só termina quando
  você aperta **COMEÇAR**.
- **O painel da previsão** mostra os lados de ataque, as ondas, os tipos de
  zumbi e o evento da noite. As regras já sabem calcular tudo isso.
- **A exceção é o desmaio:** se o fazendeiro desmaiou às 02:00, a preparação
  dura só 30 s.

### 4.3 Durante as ondas

- **As torres atacam sozinhas**: é o pilar "defesa semi-idle".
- **Você ainda pode** posicionar, melhorar, vender e consertar. Hoje só a
  barricada pode ser colocada à noite.
- **Velocidade:** 1x, 2x ou 4x, e pular o resto quando a casa estiver com
  50% de vida ou mais (como hoje). A velocidade vale **só à noite**; isso foi
  corrigido em 2026-10-07 (seção 13).
- **O que não dá para fazer à noite:** andar, plantar, colher ou abrir a
  banca. O fazendeiro está dormindo.

### 4.4 Poderes (com recarga e mirados com o cursor)

| Poder | Efeito | Status |
|---|---|---|
| **Sinalizador** | dano em área e deixa os zumbis lentos | existe, mas hoje explode onde o fazendeiro está; passa a ser mirado |
| **Sino da fazenda** | todos os zumbis param por 2 s | novo |
| **Chamar o cão** | o cachorro morde um alvo e volta | novo |
| **Conserto de emergência** | uma estrutura recupera 30% da vida na hora | novo |

Os poderes novos são desbloqueados na árvore de tecnologia, um por estação a
partir do verão.

### 4.5 Vencer e perder

**A noite tem hora para acabar: 06:00.** É o tempo que o fazendeiro dorme.
Hoje ela só termina quando o último zumbi morre ou a casa cai.

- **Vencer:** a casa ainda está de pé quando o sol nasce. Matar todos antes
  disso também vence, só que mais cedo.
- **Amanhecer:** quem sobrou vai embora andando e some na luz. Hoje isso só
  acontece depois de uma derrota; corrigido em 2026-10-07, porque antes eles
  ficavam parados na fazenda o dia inteiro e já estavam na porta quando a
  noite seguinte começava. Com a nova regra, passa a ser o fim de toda noite.
- **Perder:** a casa caiu antes do sol nascer. As consequências estão no fim
  da seção 2.
- **Noite de chefe:** o chefe precisa cair antes do amanhecer. Se ainda
  estiver de pé, ele foge com os outros e volta na noite seguinte, sem a
  multa da derrota.
- **Por que assim:**
  - a noite fica com uma duração que você conhece de antemão;
  - "aguentar até o sol nascer" vale tanto quanto "matar tudo";
  - o muro, que atrasa a horda, ganha força, como o `design.md` pede.

### 4.6 Recompensas da noite

- **Essência:** é a moeda da árvore de tecnologia (hoje se chama "pontos de
  tecnologia"). Você ganha pela noite vencida e por bônus como casa intacta,
  nada destruído e nenhum zumbi passando.
- **Recompensa em dinheiro:** é **menor** que hoje, porque quem dá dinheiro é
  o dia.
- **Restos:** de manhã você recolhe **ossos**, que viram farinha de osso
  (adubo, para as plantas crescerem mais rápido), e as **pedras da lua**
  depois da Lua Cheia.

---

## 5. As armas (defesas)

| Defesa | O que faz | Custo principal | Desbloqueia | Status |
|---|---|---|---|---|
| Torre de tiro | um alvo por vez, barata | madeira, ferro | Primavera | existe (3 níveis) |
| Besta automática | atravessa a fila inteira | madeira, ferro | Primavera | existe (3 níveis) |
| Mina | muito dano, uma vez só | ferro, pólvora | Primavera | existe |
| Cerca, barricada e muro | bloqueiam e desviam o caminho | madeira, pedra | Primavera | existem |
| Lança-chamas | dano em área com queimadura | ferro, óleo, e gasta munição incendiária | Verão | existe (3 níveis) |
| **Espantalho** | chamariz: atrai os zumbis e aguenta pancada | palha, madeira | Verão | novo |
| **Colmeia** | abelhas dão dano contínuo; precisa de girassóis por perto | madeira, girassol | Verão | novo |
| Morteiro | área de longe; gasta pólvora | pedra, ferro, pólvora | Outono | existe (3 níveis) |
| **Catapulta de abóbora** | área; gasta abóboras | madeira, abóbora | Outono | novo |
| **Réstia de alho** | os zumbis evitam a área ou andam devagar perto | alho | Outono | novo |
| **Holofote** | ilumina: mais alcance para as torres vizinhas, revela assombrações e anula a neblina | ferro, cobre, energia | Inverno | novo |
| **Cerca elétrica** | atordoa quem encosta | cobre, energia | Inverno | novo |

São **14 defesas**: 8 já existem e 6 são novas. Mais algumas regras:

- **De dia, as defesas "dormem".** Elas continuam no lugar, cobertas por uma
  lona, e acordam no entardecer; esse acordar já existe hoje.
- **Elas ocupam espaço da fazenda.** Torre em cima do canteiro é canteiro a
  menos. **O espaço também tem dois usos.**
- **Regra de bolso para o preço:** no começo de cada estação, o que um dia
  bem trabalhado rende deve comprar mais ou menos uma defesa nova. Vencer o
  chefe deve exigir de 5 a 7 dias de economia focada.

---

## 6. Inimigos e chefes

| Inimigo | Estação | Comportamento | Status |
|---|---|---|---|
| Andarilho | Primavera | lento, vai direto para a casa | existe |
| Corredor | Primavera | rápido, contorna as construções | existe |
| Tanque | Primavera | lento, com armadura | existe |
| Destruidor | Primavera (fim) | caça torres e construções | existe |
| **Cuspidor** | Verão | ataca as torres de longe | novo |
| **Enxame de ratos** | Verão | muitos, pequenos e rápidos; as minas e o fogo resolvem | novo |
| **Corvo** | Outono | voa por cima dos muros e come as plantações | novo |
| **Escavador** | Outono | passa por baixo de cercas e barricadas | novo |
| **Zumbi de gelo** | Inverno | ao morrer, deixa as torres próximas mais lentas | novo |
| **Assombração** | Inverno | invisível fora da luz (holofote, lampiões) | novo |

| Chefe | Noite | O que testa |
|---|---|---|
| **O Gigante** | Primavera 14 | dano concentrado; ele destrói barricadas (já existe) |
| **A Colheitadeira** | Verão 28 | uma máquina possuída que esmaga muros em linha reta; testa defesa em profundidade |
| **O Rei Espantalho** | Outono 42 | chama revoadas de corvos; testa defesa contra ataque aéreo e proteção das plantações |
| **O Senhor do Inverno** | Inverno 56 | o final: congela as torres em volta; testa a construção inteira do ano |

Isso dá **10 inimigos e 4 chefes**. Hoje são 4 inimigos e 1 chefe.

---

## 7. Progressão

- **Dinheiro (do dia)** compra:
  - sementes;
  - ferramentas;
  - construções de produção e animais;
  - melhorias da casa;
  - parte do custo das defesas.
- **Materiais (do dia)** pagam o resto: madeira, pedra, ferro, cobre, óleo,
  pólvora, abóboras e outros.
- **Essência (da noite)** vai para a árvore de tecnologia.
  - Os 3 ramos de hoje continuam: produção, defesa e sobrevivência.
  - Cada estação libera um andar novo em cada ramo.
  - O ramo de produção é a noite pagando para o dia ficar melhor; ele já
    funciona assim hoje.
- **O desbloqueio vem pelo calendário:** armas e inimigos novos aparecem
  quando a estação chega, e não por compra.
- **Coleções:** peixes, culturas, chefes derrotados e "um ano sem perder a
  casa". Elas dão a vontade de voltar para o Ano 2.

---

## 8. Itens (resumo por categoria)

| Categoria | Exemplos | Hoje | v1.0 |
|---|---|---|---|
| Culturas | cenoura, milho, abóbora, alho | 3 | 12 |
| Peixes | carpa, truta, dourado e os lendários | 1 | cerca de 16 |
| Minerais | pedra, ferro, cobre, carvão, ouro, pedra da lua | 2 | 6 |
| Madeira | madeira, madeira de lei | 1 | 2 |
| Produtos animais | ovo, leite, lã, trufa, carne | 1 (carne) | 5 |
| Produtos feitos | óleo, refeições, vinho, geleia, queijo, pão, tecido | 4 | cerca de 12 |
| Munições | pólvora, incendiária, abóbora | 2 | 3 |
| Kits de defesa | barricada, cerca, muro, mina e os novos | 4 | 8 |
| Restos da noite | ossos, farinha de osso, pedra da lua, essência | — | 4 |
| Ferramentas | 5 ferramentas, 3 níveis cada | — | 15 |

---

## 9. Interface

- **De dia:** relógio (06:00–02:00), calendário ("Primavera 3 · Lua Cheia em
  4 dias"), dinheiro e os recursos principais, como hoje.
- **No entardecer:** o painel da previsão da noite e o lembrete "hora de
  dormir".
- **À noite:**
  - estação, noite e onda;
  - a vida da casa;
  - essência;
  - poderes;
  - velocidade;
  - a barra de armas com os preços;
  - o botão COMEÇAR.
- **De manhã:** o relatório da noite, com o que entrou, o que se perdeu e os
  restos para coletar.

---

## 10. Como o jogo vai se desenvolver (fases)

Cada fase vira tarefas no backlog (`tools/backlog/`), que o loop executa uma
por vez, com testes e capturas de tela, como foi no MVP. **A Fase 1 é o
teste:** se a noite com ele dormindo e você no cursor ficar gostosa, o
resto vem; se não ficar, ajustamos antes de produzir conteúdo.

| Fase | O que entra | Pronta quando |
|---|---|---|
| **0. Consertos** | O bug do amanhecer e a velocidade da noite vazando para o dia (feitos). Confirmar e corrigir as suspeitas da seção 13. A arte que falta do fazendeiro (parado, correndo, trabalhando e **dormindo**). | A suíte passa e as suspeitas foram confirmadas ou descartadas. |
| **1. Dormir = noite** ⭐ | Deitar na cama inicia a noite. Relógio de 06:00 a 02:00, com desmaio. O fazendeiro dorme e a câmera fica livre. Construir, melhorar, vender e consertar pelo cursor. Sinalizador mirado. Preparação até apertar COMEÇAR. A noite termina às 06:00 e os sobreviventes fogem. De manhã ele acorda com o relatório. | Uma noite inteira jogada só com o cursor, no mouse e no controle. **Pergunta de checagem:** "a noite ficou melhor com ele dormindo?" |
| **2. Calendário e estações** | Quatro estações de 14 dias. Previsão da noite. Lua Cheia e chefe por estação. A dificuldade segue o calendário. Novas regras de derrota. Um lado de ataque novo por estação. A paleta e o terreno mudam com a estação. | As 56 noites existem; podem ainda ser rascunhos gerados. |
| **3. O dia que dá dinheiro** | Crescimento por dias. Arar qualquer grama. 12 culturas. Caixa de envio. Mascate com estoque da estação. Ferramentas. Pesca 2.0 (espécies, minijogo, varas). Cobre, carvão e ouro. Galinheiro, celeiro e os animais novos. Barril, conserva, laticínios, tear e moinho. | Um dia de primavera e um de verão rendem dinheiro de jeitos diferentes. **Checagem:** "o dia é gostoso mesmo sem pensar na noite?" |
| **4. As armas da noite** | As 6 defesas novas. Os 3 poderes novos. A árvore de tecnologia por estação. Restos (ossos e pedras da lua). | Toda arma tem um momento em que é a melhor escolha. |
| **5. Inimigos e chefes** | Os 6 inimigos novos, os 3 chefes novos e os eventos (neblina, chuva, Lua de Sangue). | Cada inimigo pede uma resposta diferente, e o autojogador prova isso. |
| **6. As 56 noites e o balanceamento** | Noites-chave escritas à mão (estreias, Luas Cheias e chefes), as noites comuns geradas por estação, o autojogador do ciclo novo e a varredura de balanceamento. | Um jogador médio chega ao inverno perdendo de 2 a 4 noites. **Checagem:** "as 56 noites cansam?" |
| **7. Arte, som e acabamento** | Terreno por estação, todos os sprites novos, música por estação, coleções e conquistas. | Cada peça de arte foi aprovada por você, como foi com o andar do fazendeiro. |
| **8. Lançamento da v1.0** | Playtest, página da loja, trailer, exportações. | Um desconhecido joga do dia 1 da primavera ao fim do inverno. |

**Ordem de grandeza:** algo como 120 a 150 tarefas de código mais uma fila de
arte. A arte é o gargalo, porque cada sprite passa pela sua aprovação.

---

## 11. Decisões para você

A recomendação vem primeiro. Se você não mudar nada, o plano segue com ela.

| # | Pergunta | Recomendo | Alternativas |
|---|---|---|---|
| 1 | Quantos dias por estação? | **14**, ou seja 56 noites | 28, como o Stardew (112 noites); 10 (40 noites) |
| 2 | Quanto dura o dia? | **8 a 10 min** | 4 min, como hoje; 14 min, como o Stardew |
| 3 | O que acontece ao perder uma noite? | **O calendário anda, a horda leva o estoque e o chefe repete** | repetir a mesma noite, como hoje |
| 4 | Quando dá para colocar defesas? | **Só à noite**, pelo cursor | de dia também, andando |
| 5 | O fazendeiro pode acordar no meio da noite? | **Não**, ele dorme | um botão "acordar" para emergências |
| 6 | Câmera à noite? | **Livre, sem zoom** | um mapa tático que afasta só à noite |
| 7 | Estamina? | **Não** na v1.0 | energia como a do Stardew |
| 8 | Onde dá para plantar? | **Em qualquer grama, arando** | só nos 60 canteiros |
| 9 | Preparação da noite | **Sem limite, com botão COMEÇAR** | tempo fixo (hoje 20 s) |
| 10 | Modos de dificuldade | **Normal na v1.0**; um "Pesadelo" (casa caiu = fim do ano) depois | — |
| 11 | Quem é o guardião da noite? | **O espantalho da varanda** | lanterna, coruja, ou cursor sem personagem |
| 12 | Quando a noite acaba? | **Às 06:00: casa de pé é vitória e quem sobrou foge** | só quando o último zumbi morre, como hoje |

---

## 12. O que muda em relação ao `design.md`

- **"Quando quiser, o jogador troca de realidade"** vira **"ao dormir, a
  fazenda troca de realidade"**, com desmaio às 02:00. O dia passa a ter fim.
- **"O jogador pode reparar e intervir durante a onda"** continua valendo,
  mas pelo cursor do guardião, e não andando.
- **"Vitória ou derrota"** ganha um relógio. A noite acaba às 06:00, e
  segurar a horda até o sol nascer também é vitória.
- **Estações, calendário e mais culturas e peixes** estavam fora do MVP (§15)
  e entram na v1.0. O próprio `design.md` diz: "Tudo isso pode existir
  depois."
- **"10 noites"** vira **56 noites**. As 10 de hoje viram a base da
  primavera.
- **A recompensa em dinheiro da noite diminui.** O dinheiro vem do dia, e a
  noite paga em essência e restos.
- **Continuam iguais** o pilar "uma fazenda só" (sem cidade, sem caverna) e a
  "defesa semi-idle".

---

## 13. Problemas conhecidos

A auditoria do código feita hoje mostrou estes pontos.

**Confirmado e corrigido (2026-10-07):**

- Os zumbis que venciam uma noite (a casa caía) ficavam parados na fazenda o
  dia inteiro e começavam a noite seguinte já na porta. Agora eles vão embora
  ao amanhecer. Tiros no ar, fogo e o brilho do sinalizador também acabam com
  a noite, e um save antigo com zumbis em plena luz do dia é consertado ao
  abrir.
- A velocidade da noite também valia de dia: quem punha 4x à noite ganhava um
  dia em 4x, com o relógio, as plantas e o fazendeiro 4 vezes mais rápidos.
  Agora 2x e 4x só valem à noite.

**Confirmado lendo o código, corrigir na Fase 0:**

- **A preparação não pode ser encerrada antes**, apesar de o código dizer que
  pode. A Fase 1 já troca isso pelo botão COMEÇAR.
- **O conserto mede tudo pela tabela base.** Uma torre melhorada só é
  consertada até a vida do nível 1. A casa só volta a 100, e não a 140 com
  "madeira reforçada" (`repair.gd`).
- **Os bônus de "casa intacta"** (o dinheiro e a tecnologia) comparam a vida
  da casa com 100. Com "madeira reforçada", a casa pode levar 40 de dano e
  ainda contar como intacta (`rewards.gd`, `tech.gd`).

**Suspeitas encontradas lendo o código, ainda sem rodar o jogo (confirmar na
Fase 0):**

- Se todas as casas de um ponto de nascimento estiverem ocupadas, os zumbis
  dali somem em silêncio. Umas 17 cercas poderiam ganhar uma noite.
- Um morteiro sem pólvora causa 0 de dano.
- O lança-chamas ignora os bônus de dano e de alcance e gasta 2 munições
  incendiárias por segundo.
- O regador no HUD sempre mostra "/8", mesmo com a melhoria.
- Barricadas colocadas de dia vencem antes da noite e mesmo assim contam na
  cota dela.
- Documentos desatualizados:
  - o `CHANGELOG.md` fala em 16 culturas, e são 3;
  - o `docs/PLAYTEST.md` diz que o jogo para na noite 10, e ele continua;
  - a dica do tutorial diz que a banca vende sementes, e ela não vende.
- **Balanceamento:** o autojogador nunca venceu a noite 10, e a noite 1 tem
  margem de uns 10 de vida. Isso vai ser refeito na Fase 6.

---

## Apêndice: um dia de primavera, do começo ao fim

> **06:00 — Primavera 9.** O fazendeiro acorda. Relatório: "Noite 8 vencida:
> +2 essência, $40, 6 ossos. A cerca do leste caiu."
>
> **06:30.** Ele recolhe os ossos perto da estrada do leste, rega a horta de
> cenoura e alho e colhe 12 morangos.
>
> **09:00.** Pesca no lago do noroeste: duas carpas e uma truta. A truta vai
> para a caixa de envio.
>
> **12:00.** Na pedreira, consegue 9 de ferro e 4 de cobre. Deixa o
> regador na oficina para virar regador de ferro.
>
> **16:30.** Vende os morangos e as carpas na banca antes de fechar e compra
> sementes de batata.
>
> **18:00.** Chega a previsão: "Esta noite: 34 andarilhos e 6 destruidores,
> pelo leste. Neblina." Ele pensa que vai precisar de um holofote, mas o
> holofote só chega no inverno, então a resposta é mais torres perto da casa.
>
> **21:00.** Vai para a cama. A fazenda escurece e o espantalho da varanda
> abre os olhos.
>
> **Noite — preparação.** Com o cursor, você coloca duas torres de tiro na
> curva da estrada, refaz a cerca do leste com o kit feito de dia e arma duas
> minas na frente da horta. Aperta COMEÇAR.
>
> **Ondas.** Você assiste em 2x. Na terceira onda, os destruidores vão para
> a torre da curva, e o sinalizador, mirado bem no meio deles, segura a
> linha.
>
> **06:00 — amanhecer.** A casa está de pé. Três andarilhos que ainda vinham
> pela estrada viram as costas e somem na luz. "Noite 9 vencida." O
> fazendeiro acorda: Primavera 10.
