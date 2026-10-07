# Distrito das Águas — solo e natureza integrados

Aplicado em 07/10/2026 ao projeto correto:
`C:/Users/macha/Downloads/protocolo/Protocolo_17`.
Abra o `project.godot` dessa pasta no Godot e pressione F5.

A [referência enviada pelo usuário](referencia-solo-usuario.png) orienta os materiais:
placas de concreto cinza azulado, desgaste visível, juntas ocupadas por musgo,
poças rasas e vegetação que se apoia nas margens úmidas. A implementação aproxima
esse acabamento da referência dentro do mapa jogável existente.

## Acabamento aplicado

- Placas maiores, com juntas escuras, fraturas e textura de concreto mais
  variada. O desenho das placas é compartilhado pelo piso e pelo musgo.
- Umidade calculada pela distância às margens, canais e reservatórios reais.
  A influência das raízes acrescenta contato entre plantas e chão.
- Musgo irregular que se acumula nas juntas e áreas úmidas. A variação de ruído
  altera a forma dos grupos sobre essas influências; não escolhe posições
  independentes da água e das plantas.
- Samambaias terrestres novas, sem bases de concreto, formando grupos sobre
  essas áreas de musgo. A vegetação aquática conserva seus recursos existentes.
- Dezoito poças rasas em depressões escolhidas nos quatro setores, filtradas
  pelos equipamentos, canais e acessos. Contornos irregulares, bordas escuras
  e reflexos substituem as antigas manchas geométricas espalhadas pelo piso.
- Bordas dos canais com topo de pedra, juntas, faces úmidas escuras e limo.

As plantas adicionais continuam ordenadas pelo contato com o chão. Musgo,
poças, fraturas e vegetação não alteram a colisão. Rotas, encontros, canais,
travessias, portões e objetivos conservam a geometria da etapa anterior.

## Comparação no jogo

Capturas reais no Godot; cada par conserva câmera, posição de Lia, relógio e
estado da simulação. Os recortes sem inimigos são vistas de revisão em estado
de reparo. A imagem de referência é conceitual; estas imagens mostram o jogo.

| Vista | Etapa anterior | Solo integrado |
|---|---|---|
| Terminal de captação | [Antes](../../captures/solo-integrado/antes/01_cais_terminal.png) | [Depois](../../captures/solo-integrado/01_cais_terminal.png) |
| Canal e clarificador | [Antes](../../captures/solo-integrado/antes/02_cais_canal.png) | [Depois](../../captures/solo-integrado/02_cais_canal.png) |
| Combate no cais | [Antes](../../captures/solo-integrado/antes/03_cais_combate.png) | [Depois](../../captures/solo-integrado/03_cais_combate.png) |
| Energia | [Antes](../../captures/solo-integrado/antes/04_energia.png) | [Depois](../../captures/solo-integrado/04_energia.png) |
| Filtragem | [Antes](../../captures/solo-integrado/antes/05_filtros.png) | [Depois](../../captures/solo-integrado/05_filtros.png) |
| Distribuição | [Antes](../../captures/solo-integrado/antes/06_distribuicao.png) | [Depois](../../captures/solo-integrado/06_distribuicao.png) |

Há onze capturas em cada pasta, incluindo jardim de filtragem, drenagem de
energia, comportas e cais restaurado.

## Recursos e proveniência

Os dois PNGs abaixo foram produzidos pela ferramenta integrada `image_gen`,
usando a imagem enviada como referência de estilo. Ambos medem 1254 × 1254 px.
Os recursos anteriores permanecem no projeto.

| Recurso salvo | Prompt completo | Uso |
|---|---|---|
| [wet_concrete_v2.png](../../assets/station/wet_concrete_v2.png) | [Prompt](../../assets/station/wet_concrete_v2-PROMPT.txt) | Textura dentro das placas; fissuras, juntas e musgo adicionais são desenhados pelo mapa. |
| [wetland_ferns.png](../../assets/station/wetland_ferns.png) | [Prompt](../../assets/station/wetland_ferns-PROMPT.txt) | Atlas de quatro grupos de samambaias com transparência real; recortes proporcionais, sem pedras/pedestais. |

Os arquivos estão em `C:/Users/macha/Downloads/protocolo/Protocolo_17/assets/station/`.
Não há fundos conceituais embutidos nas capturas do jogo.

## Validação e custo

Seis suítes pertinentes passaram, com 14.622 verificações no total:

| Verificação | Resultado |
|---|---|
| Solo integrado | 452: umidade das margens, contato das raízes, placas cobrindo o piso, transparência das poças/ferns, travessias sem musgo e reutilização das texturas |
| Água e travessias | 3.753: 827 plantas adicionais, passagem, esquiva, pulsos e atlas |
| Arte do ambiente | 54: recursos, bases, escala e profundidade |
| Integração do ambiente | 8.002: movimento nas bordas e contato com equipamentos |
| Simulação | 92: quatro sistemas restaurados, 17 inimigos derrotados, 208 disparos |
| Mundo | 2.269: rotas, objetivos, pontos de surgimento e portões |

O bot da campanha usa invulnerabilidade para isolar acesso e progressão;
o teste não mede a dificuldade humana. A revisão produziu onze capturas
gráficas no projeto real, sem erros de carregamento ou execução.

Os campos são preparados uma vez e reutilizados. As texturas de acabamento
ocupam cerca de 10,79 MiB, além dos campos de influência mantidos em memória
e dos novos recursos. A preparação local levou aproximadamente 1,54 s
na primeira utilização; ela não ocorre a cada quadro.

Uma amostra local de 120 quadros no cais mediu aproximadamente 6,59 ms por
quadro e 650 chamadas de desenho (etapa anterior: 8,99 ms e 976). A câmera
e os inimigos estavam parados, a água avançava e VSync estava desativado.
Isso mede essa vista de revisão, não combate intenso nem outras máquinas.
Godot 4.7.2, Compatibility, AMD Radeon RX 6600. Os `review.json` acompanham
as capturas atuais e anteriores.

## Manutenção

`scripts/ground_ecology.gd` prepara as texturas de contato, musgo e poças.
`station_art.gd` compartilha o arranjo das placas e os recortes das samambaias.
`wetlands.gd` mantém a composição das margens e os pontos das depressões.
O teste `tests/test_ground_ecology.gd` verifica esses contatos e o cache.

As versões substituídas estão preservadas em
`C:/Users/macha/Downloads/protocolo-17/.runtime/terrain3/backup`.
