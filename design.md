# MVP — Farm Defense / Reality Shift

## 1. High Concept

Um jogo indie em pixel art com estética cozy inspirada em fazendas clássicas.

O jogador possui **uma única fazenda**, que é praticamente todo o mundo do jogo.

Durante o dia, o jogador:

- planta e colhe;
- pesca;
- corta madeira;
- minera;
- produz itens;
- vende recursos;
- compra materiais;
- constrói estruturas.

Quando quiser, o jogador pode **trocar de realidade**.

A mesma fazenda passa para a realidade noturna, onde funciona como um **mapa de defesa contra ondas de zumbis**.

Os recursos produzidos durante o dia são utilizados para:

- construir torres;
- criar barricadas;
- melhorar estruturas;
- produzir munição;
- reparar a base;
- desbloquear novas tecnologias.

O objetivo do MVP é provar que o loop:

**Produzir → Preparar → Defender → Recompensa → Melhorar → Produzir novamente**

é divertido.

---

# 2. Pilares do jogo

## Pilar 1 — Uma única fazenda

Não existe cidade grande para explorar no MVP.

A fazenda é o mundo inteiro.

Isso reduz o escopo e faz com que o jogador desenvolva apego ao próprio espaço.

## Pilar 2 — Duas realidades

### Dia

Cozy, colorido e produtivo.

### Noite

Sombrio, perigoso e defensivo.

O mapa é essencialmente o mesmo, mas a função do espaço muda.

## Pilar 3 — Recursos têm dois usos

Os recursos não existem apenas para vender.

Eles alimentam a defesa.

Exemplo:

| Recurso | Uso durante o dia | Uso na defesa |
|---|---|---|
| Madeira | Construção/venda | Barricadas |
| Pedra | Construção/venda | Muros |
| Ferro | Produção | Torres |
| Comida | Venda/produção | Cura/reparo |
| Óleo | Produção | Fogo |
| Dinheiro | Compra | Upgrades |

## Pilar 4 — Defesa semi-idle

O jogador monta a defesa e inicia a noite.

As torres atacam automaticamente.

Durante a onda, o jogador pode eventualmente:

- usar uma habilidade;
- reparar uma estrutura;
- priorizar um inimigo;
- construir uma defesa emergencial.

Mas o objetivo principal é **ver a estratégia montada funcionar**.

---

# 3. Loop principal

```text
              ┌──────────────┐
              │    FAZENDA   │
              │     DIA      │
              └──────┬───────┘
                     │
                     ▼
              Produzir recursos
                     │
                     ▼
              Vender / Craftar
                     │
                     ▼
              Preparar defesa
                     │
                     ▼
            TROCAR DE REALIDADE
                     │
                     ▼
              ┌──────────────┐
              │    FAZENDA   │
              │    NOITE     │
              └──────┬───────┘
                     │
                     ▼
              Onda de zumbis
                     │
                ┌────┴────┐
                │         │
             Vitória    Derrota
                │         │
                ▼         ▼
          Recompensas   Perde parte
                │        dos recursos
                └────┬────┘
                     ▼
                Melhorar base
                     │
                     └──────→ DIA
```

---

# 4. Escopo do MVP

O MVP deve ser **pequeno de propósito**.

## Mapa

Apenas **1 fazenda**.

Tamanho aproximado:

- 1,2–1,5 telas de largura;
- 1 tela de altura;
- câmera fixa ou quase fixa;
- visão top-down/3/4 em pixel art.

A fazenda deve conter:

- casa;
- pequena área de plantação;
- rio/lago;
- área de árvores;
- área de mineração;
- espaço para construções;
- loja/NPC.

---

# 5. Sistema de Dia

O jogador começa com uma pequena quantidade de recursos.

## Ações do MVP

### Plantar

3 tipos de plantação:

- Trigo
- Milho
- Cenoura

Cada uma possui:

- tempo de crescimento;
- valor de venda;
- valor de uso defensivo.

### Pescar

Uma pequena área de água.

O jogador interage e recebe:

- peixe comum;
- peixe raro.

### Madeira

Interagir com árvores para obter madeira.

### Mineração

Interagir com algumas pedras/minério para obter:

- pedra;
- ferro.

### Produção

Uma estação simples:

**Oficina**

Permite transformar recursos.

Exemplo:

```text
Madeira + Pedra → Barricada
Ferro + Madeira → Torre
Óleo + Madeira → Munição incendiária
```

---

# 6. Economia

A economia deve ser extremamente simples no MVP.

Recursos:

- Madeira
- Pedra
- Ferro
- Comida
- Óleo
- Dinheiro

O jogador pode vender recursos em uma pequena loja/NPC.

Exemplo:

```text
MADEIRA       $2
PEDRA         $3
FERRO         $7
TRIGO         $4
PEIXE         $8
ÓLEO          $10
```

O dinheiro serve principalmente para comprar:

- sementes;
- recursos;
- upgrades.

---

# 7. Construções da Fazenda

Poucas construções no MVP.

## Produção

### Plantação

Produz comida.

### Oficina

Transforma recursos.

### Gerador

Produz energia para estruturas avançadas.

---

# 8. Sistema de Defesa

A mesma fazenda vira o mapa do tower defense.

## Estruturas

### Torre de Tiro

- barata;
- dano baixo;
- alcance médio;
- alvo único.

### Torre de Fogo

- mais cara;
- dano em área;
- causa dano contínuo.

### Muro

- não causa dano;
- bloqueia/atraso zumbis.

### Barricada

- barata;
- vida baixa;
- serve como defesa emergencial.

### Armadilha

- ativação automática;
- dano alto;
- uso limitado.

---

# 9. Inimigos do MVP

Apenas 4 tipos.

## Zumbi básico

Lento e fraco.

## Corredor

Rápido e com pouca vida.

## Tanque

Lento e resistente.

## Zumbi destruidor

Prioriza estruturas.

---

# 10. Noites do MVP

O MVP deve ter **10 noites**.

### Noite 1

Tutorial.

Poucos zumbis básicos.

### Noite 2

Mais zumbis.

### Noite 3

Primeiro corredor.

### Noite 4

Onda maior.

### Noite 5

Primeiro tanque.

### Noite 6

Mistura de inimigos.

### Noite 7

Zumbis destruidores.

### Noite 8

Onda grande.

### Noite 9

Elite/mistura pesada.

### Noite 10

Boss.

O objetivo não é ter 100 horas de conteúdo.

O objetivo é descobrir se **10 ciclos já são divertidos**.

---

# 11. Boss do MVP

Um único boss:

## Gigante

Características:

- muita vida;
- destrói barricadas;
- força o jogador a ter dano concentrado;
- aparece acompanhado de zumbis comuns.

O boss deve servir como teste final da build criada nas 9 noites anteriores.

---

# 12. Progressão

Após cada noite o jogador recebe:

- dinheiro;
- recursos;
- pontos de tecnologia.

Exemplo:

```text
NOITE 3 COMPLETA

+ $50
+ 20 Ferro
+ 15 Madeira
+ 1 Tecnologia
```

Tecnologia desbloqueia melhorias.

Exemplo:

```text
Torre I
   ↓
Torre II
   ↓
Torre Automática
```

---

# 13. Sistema semi-idle

O jogo deve funcionar mesmo se o jogador não estiver clicando constantemente.

Durante o dia:

- planta;
- deixa plantações crescerem;
- máquinas produzem;
- volta depois para coletar.

Durante a noite:

- torres atacam automaticamente;
- inimigos seguem rotas;
- jogador pode intervir quando quiser.

O objetivo é criar a sensação:

> "Eu montei uma máquina e agora quero descobrir se ela funciona."

---

# 14. Interface mínima

HUD durante o dia:

```text
┌────────────────────────────────────────────┐
│ ☀ DIA 3       $ 245     🌾 32   🪵 41     │
│                          🪨 18   ⚙ 12      │
│                                            │
│              FAZENDA                       │
│                                            │
│                              [LOJA]        │
│                                            │
│                          [🌙 NOITE]        │
└────────────────────────────────────────────┘
```

Durante a noite:

```text
┌────────────────────────────────────────────┐
│ 🌙 NOITE 4          ONDA 7/10              │
│                                            │
│              🧟 → → →                      │
│                    🔫                      │
│              🧟 →    🏠                    │
│                    🔥                      │
│                                            │
│ HP DA CASA ████████░░                      │
│                                            │
│ [REPARAR] [HABILIDADE] [VELOCIDADE x2]    │
└────────────────────────────────────────────┘
```

---

# 15. O que NÃO entra no MVP

Para proteger o escopo:

- ❌ cidade;
- ❌ múltiplos mapas;
- ❌ casamento;
- ❌ relacionamento complexo com NPC;
- ❌ dezenas de NPCs;
- ❌ animais complexos;
- ❌ clima complexo;
- ❌ estações do ano;
- ❌ multiplayer;
- ❌ procedural generation;
- ❌ árvore tecnológica gigante;
- ❌ dezenas de crops;
- ❌ dezenas de inimigos;
- ❌ crafting complexo;
- ❌ história longa.

Tudo isso pode existir depois.

---

# 16. MVP Técnico

Uma implementação possível:

## Engine

Godot ou Unity.

## Mundo

Mapa 2D único.

## Gameplay

Estados:

```text
DAY
 ↓
PREPARATION
 ↓
NIGHT
 ↓
RESULT
 ↓
DAY
```

## Sistemas

```text
GameManager
 ├── DaySystem
 ├── FarmingSystem
 ├── FishingSystem
 ├── ResourceSystem
 ├── CraftingSystem
 ├── ShopSystem
 ├── BuildingSystem
 ├── DefenseSystem
 ├── ZombieSystem
 ├── WaveSystem
 └── SaveSystem
```

---

# 17. Critério de sucesso do MVP

O MVP não deve ser avaliado pela quantidade de conteúdo.

A pergunta é:

> **Depois de sobreviver à primeira noite, eu quero voltar para a fazenda e melhorar minha defesa para ver o que acontece na próxima?**

Se a resposta for sim, o conceito funciona.

O jogo precisa criar este ciclo psicológico:

```text
"Preciso de mais ferro."
        ↓
"Vou minerar."
        ↓
"Agora consigo construir a torre."
        ↓
"Será que ela segura a próxima noite?"
        ↓
"VAMOS DESCOBRIR."
        ↓
🧟 🧟 🧟
        ↓
"CARALHO, QUASE MORRI."
        ↓
"Preciso melhorar minha produção."
        ↓
Volta para o dia.
```

---

# 18. Direção visual

Pixel art detalhada e acolhedora.

## Dia

- cores quentes;
- iluminação natural;
- vegetação;
- água;
- pequenos detalhes animados;
- sensação cozy.

## Noite

O mesmo cenário, mas:

- iluminação azul/roxa;
- lua;
- sombras;
- fogueiras;
- zumbis;
- estruturas defensivas;
- partículas;
- incêndios;
- sangue apenas se a direção visual exigir.

O objetivo é fazer o jogador reconhecer imediatamente:

**"Essa é a minha fazenda."**

Mas sentir:

**"Essa não é mais a mesma realidade."**

---

# 19. Primeira versão jogável

A primeira build deveria ter somente:

### Dia

- 1 plantação;
- 1 recurso de madeira;
- 1 recurso de pedra;
- 1 mineração;
- 1 oficina;
- 1 loja;
- 1 botão para trocar de realidade.

### Noite

- 1 torre;
- 1 muro;
- 1 tipo de zumbi;
- 3 ondas.

Se isso já for divertido, adicionar:

- pesca;
- novos recursos;
- novas torres;
- novos zumbis;
- progressão;
- boss.

**Não começar pelas 10 noites.**

Primeiro provar o ciclo de 3 minutos:

**produzir → construir → defender → receber recompensa.**

---

# 20. Elevator Pitch

> **Um cozy farming game onde sua fazenda é também sua fortaleza.**
>
> Durante o dia, plante, pesque, minere e produza recursos.
>
> À noite, troque de realidade e transforme a mesma fazenda em uma fortaleza contra hordas de zumbis.
>
> Tudo que você produz durante o dia determina o que consegue construir à noite.
>
> **Construa sua fazenda. Monte sua defesa. Descubra se ela sobrevive.**
