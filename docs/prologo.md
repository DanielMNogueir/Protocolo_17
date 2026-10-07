# Prólogo jogável — Antes da queda

Nova operação começa com uma tela breve sobre Aurora em funcionamento. Em seguida,
o jogador controla Doutora Beatrix Window no laboratório: diagnóstico, consulta à
análise ambiental, desativação de um atuador com E, isolamento da rede, fuga
com esquiva e preservação de um registro. Depois dessa conquista, os drones atacam
a cientista; a imagem corta antes do impacto. A perda do sinal humano confirma o
acontecimento, e o jogo passa ao início normal da campanha de Lia.

A transmissão para Lia aguarda Enter ou o botão de assumir controle, permitindo
ler a mensagem com calma. P também continua disponível nessa passagem.

A máquina responde na barra de diálogo inferior, sem nome, identificação ou
referência visível a Protocolo 17. A cientista humana tenta impedir a contenção.
A verdadeira identidade da máquina e da futura guia digital permanece reservada
à narrativa posterior; essa versão não acrescenta ainda a guia à campanha.

## Controles e repetição

- WASD/setas: movimento.
- Um toque em E: inicia a calibração, consulta, desativação do atuador, isolamento ou preservação do registro; a ação termina automaticamente enquanto Beatrix permanece perto da estação. Afastar-se cancela a ação. Adaptação provisória para testes pelo AnyDesk, restrita ao prólogo.
- Shift: esquiva durante a fuga; avisos dos drones antecedem os disparos.
- Enter: primeiro completa a frase em exibição, depois avança.
- Cada fala espera uma nova confirmação; movimento, interação e ameaças ficam suspensos durante a leitura.
- Enter pressionado: acelera apenas a escrita da fala atual, sem avançar a conversa.
- Tab ou botão inferior: falas instantâneas, ainda com confirmação manual; preferência salva nas configurações.
- P ou **Pular introdução**: pula contexto, laboratório e encerramento juntos.
- Esc: pausa. A pausa oferece Retomar, Configurações, Voltar e Pular introdução.
- R: retoma a fuga após falhar, com vida restaurada e conexão já isolada.
- **Rever prólogo**, no menu: reproduz a introdução sem substituir o checkpoint
  da campanha. Terminar ou pular essa reprodução retorna ao menu.

Pular durante uma nova operação inicia Lia com saúde, posição, equipamentos e
progresso iniciais. Cliques usados nos botões não vazam como disparos no cenário.
Continuar operação carrega o checkpoint existente e não repete a introdução.

## Organização

- `scripts/prologue.gd`: sequência narrativa, texto, tarefas, movimento, interação,
  esquiva, ameaças, tentativa de contenção e passagem para Lia.
- `scripts/laboratory_world.gd`: geometria, colisão, arte, profundidade e animação.
- `scripts/laboratory_set.gd`: contornos, bases de colisão e bordas frontais medidos
  na imagem original. Todos passam pela mesma transformação para o mundo.
- `scripts/laboratory_effects.gd`: uma superfície de renderização de 960×640,
  compartilhada pelo fundo e pelos recortes em primeiro plano.
- `scripts/laboratory_set.gdshader`: reflexos em movimento nos vidros, atividade dos
  monitores e luz vermelha de contenção. O relógio acompanha o prólogo e congela
  na pausa; a superfície desliga fora do laboratório.
- `scripts/beatrix_art.gd`: poses em oito direções, caminhada e retrato.
- `scripts/prologue_presentation.gd`: apresentação de Aurora, balões e interface.
- `scripts/main.gd`: entrada, repetição, pausa, preferências e transição à campanha.
- `assets/prologue/laboratory_set_v1.png`: ambiente completo de 1536×1024, com o PNG
  original preservado. [Prompt e origem](../assets/prologue/LABORATORY_SET_SOURCE.md).
- Os atlas, shaders e scripts de arquitetura das versões anteriores permanecem
  preservados; não compõem a sala atual.

## Laboratório isométrico integrado

Uma sala desenhada como ambiente contínuo substitui a distribuição de objetos
avulsos. Bancadas conectadas organizam calibração, análise, microscopia e arquivo;
as plantas ficam em câmaras e recipientes de cultivo. Servidores, disjuntores,
ventilação e tubulações seguem as paredes. O núcleo de pesquisa tem uma base
com sinalização; corredores conectam as estações sem atravessar equipamentos.

Piso, paredes e móveis têm a mesma perspectiva diagonal. A arte já inclui sombras
de contato, luzes locais e reflexos. O shader anima vidros e emissões e muda a
luz dos instrumentos e seus reflexos durante o alarme, sem modificar a interface.

A imagem ocupa 840×560 unidades no enquadramento de 960×640. A câmera fixa do
prólogo mantém a circulação visível na resolução lógica de 960×540 da campanha.
As colisões seguem polígonos do piso e das bases, inclusive bancos e gabinetes.
O corpo alto do equipamento não gera uma parede invisível. A personagem e os
drones usam âncoras nos pés; os recortes do cenário ocultam corretamente Beatrix
atrás dos equipamentos. A profundidade segue a borda diagonal da base na posição
horizontal da cientista, em vez de ordenar todas as peças por uma altura fixa.

O indicador aponta o instrumento da estação e o local livre para se aproximar.
Um anel destaca o ponto de interação, e uma seta perto de Beatrix aponta para
o objetivo enquanto ele estiver distante; quando o destino estiver fora da área
de jogo, a seta aparece na borda visível. O atuador agora usa E no ponto livre
ao lado do gabinete. Os drones permanecem nas suas posições livres
durante o encerramento, com disparos visuais antes do corte, sem atravessar móveis.

Calibrar, consultar, desativar o atuador e isolar levam 0,6 segundo; preservar leva 0,9 segundo.
E continua funcionando com um toque. P pula tudo; Enter acelera a escrita e Tab alterna texto instantâneo.
A identidade da máquina continua oculta e a campanha de Lia mantém seu checkpoint.

## Validação

```text
godot --headless --path . --script tests/test_prologue.gd
godot --headless --path . --script tests/test_prologue_shell.gd
godot --path . --script tests/test_prologue_rendering.gd --audio-driver Dummy
godot --path . --script tools/review_prologue.gd --audio-driver Dummy
```

O bot percorre todas as tarefas com movimento e projéteis reais; usa invulnerabilidade
apenas para separar a verificação de acesso/progressão da dificuldade dos drones.
A falha por dano e a retomada são verificadas separadamente. O teste da interface
usa o controlador real com um destino de salvamento em memória, sem alterar saves
do usuário. O teste gráfico verifica movimento, alinhamento da câmera, mudança de
iluminação e oclusão. As capturas ficam em `captures/prologo`; a variável
`P17_PROLOGUE_OUTPUT` permite escolher outra pasta.

Validação da versão inicial: nove suítes passaram, com 9.160 verificações. Incluem
786 verificações do percurso do prólogo, 26 de integração/pular/reprodução e 872
gráficas; também passaram simulação da campanha, mundo, objetivos, origem dos
disparos, equipamentos hidráulicos e água dos canais. As três suítes do prólogo
e a simulação da campanha foram confirmadas novamente no projeto principal.

Revisão de ritmo e cenário: percurso do prólogo (678 verificações), integração de entrada/pular/reprodução (29), renderização (874, incluindo animação individual dos dois shaders) e simulação da campanha (92) passaram. Dez capturas revisadas visualmente incluem uma vista geral do laboratório. Foram verificados percurso com movimento real, toque único em E, avanço automático das falas, movimento durante falas de rotina, colisões, câmera, iluminação de alarme e oclusão.

Revisão do laboratório compacto: percurso com movimento e disparos reais (520 verificações), integração do controlador (29) e renderização (876) passaram na versão anterior, quando o atuador ainda usava pulsos. A verificação gráfica inclui sombras fora da base do núcleo e ausência de sombra no corredor livre. Dez capturas da sala em rotina, alarme, fuga e registro estão em `captures/prologo-compacto`. As posições do tutorial, dos drones e da retomada acompanham a nova sala. E com um toque, P para pular e o checkpoint da campanha continuam preservados.

Revisão do cenário isométrico integrado: percurso com movimento e disparos reais na versão anterior
(385 verificações), controlador/pular/reprodução (29), renderização com GPU (893)
e simulação da campanha (92) passaram. O teste gráfico usa posições acessíveis
atrás e à frente do núcleo e verifica a oclusão real da cientista, animação de
vidros e instrumentos, estabilidade dos recortes ao mover a câmera e alarme.

Capturas atuais: `captures/prologo-isometrico`. A ferramenta
`tools/review_laboratory_depth.gd` acrescenta vistas atrás do núcleo, à frente dele,
na calibração e na análise. As dez capturas gerais continuam sendo produzidas por
`tools/review_prologue.gd`.

Backups desta revisão estão em
`C:/Users/macha/Downloads/protocolo-17/.runtime/prologue10-set/backup`;
as revisões anteriores permanecem em `prologue9-lab/backup`,
`prologue8-rich/backup` e `prologue6/backup`.

## Escopo desta versão

Prólogo completo até a campanha atual, com falas em texto e áudio ambiente existente.
Não há dublagem. A duração depende da leitura e da exploração; não há esperas
obrigatórias para completar artificialmente uma duração. A revelação futura sobre
a guia digital não aparece nesta introdução.
