# implementation/aseprite — a arte do jogo refeita no Aseprite

Esta pasta é tudo o que o chat do Aseprite precisa para redesenhar **toda a
arte do HARVEST THE NIGHT** com o toolkit procedural
(`C:\Users\Helel\Documents\aseprite`, skill `pixel-sprites`), em lotes, com a
sua revisão em cada um. O Claude do jogo (este chat) integra cada lote
aprovado.

## Como usar

1. Abra o chat do Aseprite. Se ele pedir acesso à pasta do repositório, deixe.
2. Cole o prompt abaixo. Ele está também em [`PROMPT.txt`](PROMPT.txt).
3. Ele trabalha **um lote por vez**:
   - desenha;
   - passa na checagem;
   - mostra a revisão (antes × depois, 1x e 4x, de dia e de noite, ao lado
     do fazendeiro);
   - espera o seu "aprovado".
4. Com a aprovação, ele grava a entrega em `deliveries/<lote>/` e segue para o
   próximo.
5. Quando quiser, traga o lote aprovado para cá com:

   ```
   Integra o lote Bxx do Aseprite: leia implementation/aseprite/INTEGRATION.md
   ```

   Pode ser lote a lote, ou vários de uma vez. **Lote a lote é melhor:** um
   problema aparece no jogo cedo, antes de virar padrão nos outros.

### O prompt para o chat do Aseprite

```
Vamos refazer toda a arte do jogo HARVEST THE NIGHT no Aseprite, com o toolkit
C:\Users\Helel\Documents\aseprite e a skill pixel-sprites.

Leia e execute C:\Users\Helel\Documents\repos\harvest_the_night\implementation\aseprite\RUNNER.md
(antes de desenhar, leia também o CONTRACT.md e o inventory/DERIVED.md da mesma pasta).

Faça os lotes em ordem, do B00 ao B19, um de cada vez: desenhe, rode a
checagem até dar PASS, me mostre a revisão e espere eu aprovar. Quando eu
aprovar, grave o APPROVAL.json e o HANDOFF.md na entrega e siga para o próximo
lote. O B00 vem primeiro: a paleta e um piloto do estilo, para eu aprovar o
visual antes de tudo.

A arte deste jogo fica em game_assets/harvest_the_night/ no toolkit, e as
entregas só em implementation/aseprite/deliveries/ no repositório. Não mude
nada do jogo, não faça commit nem push. Fale comigo em português.
```

## Os lotes

1332 quadros ao todo. O inventário diz, para cada arquivo:
- o canvas e o pivô;
- quantos quadros e o tempo de cada um;
- a direção;
- o tamanho da arte de hoje;
- as regras que a checagem cobra;
- o texto que explica o que ele é.

| Lote | O quê | Quadros |
|---|---|---|
| [B00](inventory/B00-palette-and-pilot.md) | A paleta e o piloto de estilo: fazendeiro, zumbi, árvore, grama, torre e ícone, para você aprovar o visual | — |
| [B01](inventory/B01-farmer-walk-idle.md) | O fazendeiro: andar e parado em 8 direções, e a sombra | 89 |
| [B02](inventory/B02-farmer-field-work.md) | O fazendeiro arando, plantando, regando, colhendo (A007) | 48 |
| [B03](inventory/B03-farmer-gather-work.md) | Cortando, minerando, recolhendo, carregando (A008) | 48 |
| [B04](inventory/B04-farmer-make-work.md) | Fabricando, negociando, consertando (A009) | 36 |
| [B05](inventory/B05-farmer-fishing-care.md) | Pescando e cuidando dos animais (A024, A025) | 65 |
| [B06](inventory/B06-farmer-night.md) | Deitando, dormindo, as reações e o Zzz (A001, A002) | 13 |
| [B07](inventory/B07-terrain.md) | Terreno e terra arada | 31 |
| [B08](inventory/B08-crops.md) | Plantações | 54 |
| [B09](inventory/B09-nature-resources.md) | Árvores, pedras, minérios, recursos e aspersores | 51 |
| [B10](inventory/B10-animals.md) | Animais e o cachorro | 65 |
| [B11](inventory/B11-farm-buildings.md) | A casa, as construções e as máquinas | 51 |
| [B12](inventory/B12-people-interior.md) | O mascate, o espantalho guardião e o interior da casa | 36 |
| [B13](inventory/B13-towers.md) | Torres | 76 |
| [B14](inventory/B14-barriers-traps.md) | Muros, cercas, armadilhas, chamariz e lonas | 66 |
| [B15](inventory/B15-enemies.md) | Inimigos e as cabeças da previsão | 141 |
| [B16](inventory/B16-bosses.md) | Chefes | 74 |
| [B17](inventory/B17-effects.md) | Efeitos | 60 |
| [B18](inventory/B18-item-icons.md) | Ícones dos itens e retratos dos peixes | 210 |
| [B19](inventory/B19-hud-menus.md) | Ícones da noite, cursor, barra de pesca, livro de coleção e relatório | 118 |

Onde cada lote está:

```
python implementation/aseprite/inventory.py status
```

**Fica fora**, porque o jogo deriva do que for desenhado ou é código
([`inventory/DERIVED.md`](inventory/DERIVED.md)):
- as 160 junções de muro;
- os aliases dos inimigos;
- as bordas giradas do terreno;
- os recortes antigos das construções;
- as peças intermediárias do importador;
- o kit de painéis e botões;
- a fonte, o logo, o ícone do app e a vinheta do estúdio.

## O que eu já decidi (mude se quiser)

- **Uma paleta só para o jogo, feita no B00.** Ela contém as 42 cores atuais
  sem mudança, porque o código, a fonte e a luz da noite dependem delas. Pode
  ganhar tons para as rampas do Aseprite, até umas 64 cores; passar disso
  precisa do seu ok.
- **Nada muda de tamanho, nome, pivô, número de quadros ou tempo.** O código
  e os testes dependem desses números. Se você quiser mudar algum, o chat
  registra como desvio com as suas palavras, e eu vejo na integração se o
  jogo aguenta.
- **Oficina, cozinha, prensa, gerador e a banca** eram desenhados com metade
  da densidade e dobrados pelo jogo. Agora são desenhados com densidade cheia,
  num canvas do dobro, como a casa já foi na tarefa 0217. Na tela ficam do
  mesmo tamanho, com o dobro de detalhe.
- **O fazendeiro é refeito inteiro** (B01 a B06), incluindo as animações que
  você tinha adiado (A001, A002, A007, A008, A009, A024, A025). Integradas,
  elas destravam as 10 tarefas que faltam no backlog.
  - Ficam de fora a corrida (cancelada) e o acordar e o desmaio do A001
    (aposentados em 2026-10-08).
- **A identidade do fazendeiro continua a mesma:** chapéu de palha com fita
  marrom, cabelo escuro, roupa azul de trabalho, botas marrons. Muda só se
  você pedir no B00.

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| [`RUNNER.md`](RUNNER.md) | O procedimento que o chat do Aseprite segue, lote a lote |
| [`CONTRACT.md`](CONTRACT.md) | As regras técnicas: escala, canvas, pivô, paleta, alfa, pontos, entrega |
| [`INTEGRATION.md`](INTEGRATION.md) | Como o Claude do jogo integra um lote aprovado |
| [`PROMPT.txt`](PROMPT.txt) | O prompt acima, para copiar |
| `inventory.py` | Gera o inventário, mostra o estado, checa uma entrega, monta a folha da arte de hoje |
| `inventory/` | O que desenhar, lote a lote (gerado, não editar) |
| `deliveries/` | As entregas do chat do Aseprite, uma pasta por lote |

```
python implementation/aseprite/inventory.py build          # refaz o inventário (só o Claude do jogo)
python implementation/aseprite/inventory.py status         # onde cada lote está
python implementation/aseprite/inventory.py check B07      # checa a entrega de um lote
python implementation/aseprite/inventory.py sheet B07 DIR  # folha 4x da arte de hoje do lote
```

A pasta tem um `.gdignore`, então o Godot não importa as entregas.
