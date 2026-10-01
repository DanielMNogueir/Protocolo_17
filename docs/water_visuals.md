# Água — revisão visual 03

A água dos canais usa uma camada 2D atrás do renderizador existente. Terreno,
pontes, máquinas, Lia e HUD permanecem no desenho e na ordem anteriores.
`main.gd` cria `P17WaterSurface` e passa a mesma translação arredondada da câmera,
o relógio do jogo e a quantidade de sistemas restaurados a `present()`.

## Aparência e movimento

- Centro mais profundo e escuro, prateleira rasa junto ao concreto e sombra fina de contato.
- Variação de cor contínua, sem os antigos blocos retangulares de 72×48.
- Reflexos e ondulações interrompidas, alongadas conforme a direção da corrente.
- Fluxo vertical no tronco central e nos canais laterais; horizontal no canal transversal.
  O vetor muda gradualmente nas junções.
- Movimento lento da superfície e pequenos destaques; o ruído da textura fica estático,
  a amostragem se desloca no shader. Nenhuma textura é reconstruída a cada quadro.
- Sombra sob as três pontes e o píer; pequenas perturbações no lado de saída dos apoios.
- Anéis discretos sob juncos e folhas existentes. As folhas flutuantes se deslocam até
  1,5 unidade; não foram acrescentados grupos de vegetação.
- Juntas úmidas no concreto. A alimentação existente do reservatório de distribuição
  agora chega ao encaixe da borda e produz uma pequena perturbação na água.

O setor oeste mantém um tom de contaminação discreto antes de três sistemas restaurados.
Os reservatórios do setor leste não recebem esse tom regional.

## Shader e dados

`water_surface.gdshader` faz uma passagem de cor, sem textura de tela, refração de
personagens, reflexão de tela ou luz volumétrica. São três leituras de uma pequena
textura de ruído e uma leitura do campo estático. A amostragem é quantizada em
células de dois pixels do mundo para conservar a leitura de pixel art.

O campo de profundidade, direção de fluxo e sombra é calculado uma vez usando os
retângulos reais das margens e pontes: RGB8 de 640×450, 864.000 bytes. A textura de
ruído é gerada pelo Godot (`NoiseTexture2D` / `FastNoiseLite`), 256×256, contínua nas
bordas. O custo de construção inicial é registrado separadamente do custo por quadro.

Os dois reservatórios abertos reutilizam o mesmo shader em uma única textura de
renderização pequena de 288×384, atualizada quando visível. Isso permite desenhar
água acima do fundo e abaixo da moldura/plantas sem reorganizar o renderer.
Cada região é copiada na escala de um pixel para um pixel, sem esticar a textura.
O campo desse atlas tem 72×96 pixels. O tamanho do atlas deve acompanhar os retângulos
se os reservatórios forem ampliados em uma próxima edição do mapa.

A geometria de terreno é desenhada conforme o viewport com uma margem de 90 unidades,
em vez do retângulo fixo anterior muito maior. Os sprites elevados mantêm a ordenação
e a seleção anteriores. Os anéis da água usam linhas agrupadas para reduzir chamadas.

## Manutenção

- Paleta, intensidade, espaçamento e velocidade: shader.
- Resolução dos dados, sombra das pontes e contatos: `water_surface.gd`.
- Umidade do concreto e encaixe do reservatório: `world.gd`.
- Pontos de contato da vegetação existente: `station_art.gd`.
- O tempo vem de `main.clock`, não de `TIME`, para capturas e revisão determinísticas.

## Verificação

```text
godot --headless --path . --script tests/test_water_surface.gd
godot --path . --script tests/test_water_rendering.gd --audio-driver Dummy
godot --path . --script tools/review_water.gd --audio-driver Dummy
godot --path . --script tools/review_environment_integration.gd --audio-driver Dummy
```

O teste de renderer verifica que os mesmos pontos da água mantêm suas cores quando
a câmera muda no mesmo instante, que há movimento ao avançar o tempo e que os
objetos da frente continuam acima da água. A ferramenta de revisão registra seis
vistas do jogo e 720 quadros de desempenho com câmera fixa, sem inimigos e sem limite
de VSync. Os resultados são específicos da máquina e dessas condições, não uma
medição de combate intenso. Defina `P17_WATER_ANIMATION=1` para salvar 60 quadros de
uma sequência de seis segundos; `P17_WATER_OUTPUT` escolhe a pasta de saída.

## Limites

É uma animação visual; não há simulação hidrodinâmica. Reflexos são abstratos,
coerentes com pixel art, e não espelham os sprites. O clarificador circular conserva
a água incorporada em sua ilustração original; animar essa área exigiria separar sua
arte em camadas. Canais e os dois reservatórios abertos já recebem a superfície nova.
