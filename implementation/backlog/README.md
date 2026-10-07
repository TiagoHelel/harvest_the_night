# implementation/backlog — a fila de arte para o Codex

Esta pasta guarda **tudo o que precisa ser desenhado** para a versão 1.0 do
HARVEST THE NIGHT: pesca, animais, culturas, armas, inimigos, chefes, ícones, o
fazendeiro dormindo, o guardião da noite, o terreno de inverno e o resto.
Cada pedido é um **pacote** (A001 a A057), um arquivo em [`packs/`](packs/)
escrito para o Codex ler e gerar com o ImageGen.

O Claude **não desenha nada**. O loop do jogo (`implementation/prompts/`)
programa as regras com um desenho provisório no lugar. Quando você aprova um
pacote aqui, a tarefa de integração dele entra sozinha na fila do Claude, que
coloca a arte no jogo.

## Como rodar no Codex

Abra o Codex na raiz do repositório e mande:

```
Read and execute implementation/backlog/CODEX-RUNNER.md
```

Cada execução faz **um pacote**:

1. pega o próximo com `python implementation/backlog/assets.py next`;
2. gera as imagens seguindo o pacote e o [`ART-CONTRACT.md`](ART-CONTRACT.md);
3. monta uma página de revisão (1x e 4x, noite, ao lado do fazendeiro);
4. pergunta para você em português e ajusta;
5. só com o seu "aprovado" grava o `APPROVAL.json`, o recado para o Claude
   (`CLAUDE-Axxx-PROMPT.txt`) e marca o pacote como `approved`.

As entregas ficam em `deliveries/<Axxx-slug>/`.

## Estados de um pacote

| Estado | Quem muda | Significa |
|---|---|---|
| `todo` | — | ainda não começou |
| `generating` | Codex | gerando |
| `review` | Codex | esperando a sua opinião |
| `approved` | Codex, com a sua aprovação por escrito | pronto para o Claude |
| `integrated` | Claude | já está no jogo |
| `blocked` | quem travou, com o motivo | parado |

```
python implementation/backlog/assets.py stats     # quantos em cada estado
python implementation/backlog/assets.py list      # todos, com o que espera
python implementation/backlog/assets.py next      # o próximo para o Codex
```

O [`INDEX.md`](INDEX.md) mostra a lista inteira e é gerado sozinho. Nunca
edite o Status na mão: use `assets.py set`.

## A ordem

A ordem dos números é a ordem em que o jogo precisa da arte. Os primeiros são
os da noite com ele dormindo (A001–A005), que é o teste da Fase 1.

Alguns pacotes dependem de uma regra que ainda vai ser programada. Exemplos:
o tamanho do celeiro, quantos níveis tem a colmeia, que lonas cobrem as armas
de dia. Eles têm a linha **"Spec after game task"**, e o `assets.py next` só
oferece esses pacotes depois que a tarefa do jogo indicada terminar e
preencher as medidas finais. Até lá, o Codex pula para o próximo.

**Já dá para começar agora** (não dependem de código novo):

| Pacote | O quê |
|---|---|
| A001 | dormir, acordar e desmaiar |
| A002 | reações e o "Zzz" |
| A005 | ícones da barra de armas da noite |
| A006 | a corrida |
| A007–A009 | o fazendeiro trabalhando, no corpo novo |
| A010–A011 | calendário e rostos da previsão |
| A012 | o chão de inverno |
| A013 | as árvores nas estações |
| A019–A020 | ícones de ferramentas e de materiais |
| A029 | produtos dos animais |

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| [`CODEX-RUNNER.md`](CODEX-RUNNER.md) | o procedimento que o Codex executa, um pacote por vez |
| [`ART-CONTRACT.md`](ART-CONTRACT.md) | as regras técnicas: escala, tamanhos, pivô, paleta, transparência, entrega |
| [`INDEX.md`](INDEX.md) | a lista de pacotes com estado (gerado) |
| [`packs/`](packs/) | um pedido por pacote |
| `deliveries/` | o que o Codex entrega, uma pasta por pacote |
| `assets.py` | a ferramenta da fila (`next`, `list`, `set`, `stats`, `index`, `check`, `unblock`) |

Som e música continuam gerados por código (`tools/gen_sfx.py`,
`gen_music.py`, `gen_ambience.py`), por isso não estão nesta fila.
