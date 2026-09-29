# The devlog's opinion

The only part of `docs/devlog/index.md` that is not generated from the
journal. Two or three paragraphs, per language, and `tools/devlog.py` drops
them in under the clip.

A devlog with no opinion in it is a changelog, and nobody reads a changelog
for fun.

## English

The idea was one sentence long: **a farm that is also a fortress**, with no
second map and no loading screen between the two. You work a field all day
and then something walks over that same field at night. Everything that
matters about this game comes out of refusing to let those be two places.

What that turned out to mean, over a hundred and ten tasks, is that almost
every hard problem was the *same* problem wearing different clothes. The
rules had to be one flat dictionary of plain data so that the same state
could be saved, hashed, replayed, diffed and screenshotted - and the moment
anything reached for a node or a clock or an unsorted dictionary, something
downstream broke quietly. Half the entries below are that lesson being
learned again somewhere new.

The other half is checks. Not tests written afterwards to feel safe: checks
written to fail, planted with the bug they were supposed to catch, and
rewritten when they passed anyway. Three of the entries below are a check
that had been passing for twenty-odd tasks without being able to fail. That
is the sort of thing this list exists to say out loud.

## Portugues

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
