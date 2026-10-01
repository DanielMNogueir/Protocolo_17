# Integração do ambiente — rodada 02

O renderizador 2D original permanece. Não há migração para 3D, TileMapLayer,
novo sistema de física, alteração de combate ou substituição dos atlas.

## Dados de colocação

`P17EnvironmentProps.PROFILES` declara recorte, largura e contato por categoria.
`create()` resolve uma colocação em `visual_bounds`, `collision_rect`,
`depth_anchor`, `source`, `foot` e `station`. O corpo mantém escala uniforme;
o retângulo da colisão é uma fração medida do recorte, independente da parte alta.
`rect` permanece um alias da colisão para os consumidores antigos.

As colocações dos seis equipamentos técnicos estão em `World.building_objects()`.
Cada equipamento tem uma profundidade independente. `World.clarifier()` resolve
o tanque principal pelo mesmo perfil. As duas bacias abertas continuam obstáculos
integrais: são água sem passagem, e não máquinas elevadas.

`World.terminal()` mantém os pontos de missão originais e posiciona o equipamento
70 unidades à esquerda, com os pés 23 unidades acima do ponto. O terminal possui
uma base compacta; a interação continua com raio 84 e sob controle da simulação.
Os estados dos totens preservam a largura nominal e a proporção de cada recorte.

## Pontes

`P17BridgeLayout` separa tabuleiro, corrimãos, pilares e colisões. A faixa livre tem
92 unidades: Lia, cujo raio de colisão é 14, tem espaço para cruzar pelo centro e
pelas laterais. As faixas externas bloqueiam acesso à água.

As pontes foram reconstruídas com geometria pixel art própria no `P17BridgeLayout`.
O atlas antigo não é usado pelas pontes nem pelo píer. O piso é uma grade de células
quadradas, dividida por travessas de aço. Vigas, condutos laterais, guarda-corpos,
pilares completos, sapatas de concreto e parafusos são módulos separados.
As duas orientações são desenhadas nas dimensões do canal, sem esticar sprites,
retificar perspectiva ou amostrar partes de uma ponte inclinada.

As soleiras sobrepõem cada margem em 12 unidades. Os pilares ficam inteiramente
sobre os ombros sólidos da ponte e cada módulo entra na ordenação pela base.
O píer usa o mesmo vocabulário construtivo, com sua faixa livre original de 108.
A abertura das cancelas continua vinculada à etapa da simulação.

## Silhuetas e recortes

Os seis equipamentos, oito totens (incluindo estados restaurados) e oito props
foram medidos na imagem original. Cada recorte inclui a silhueta completa e uma
margem de dois pixels. Isso recupera as curvas da bomba/gerador, a saída do coletor,
a base do clarificador, pés dos totens e bordas de armazenamento.

Coletor e gerador têm retângulos de atlas sobrepostos. `STRUCTURE_CONTOURS` delimita
somente a respectiva máquina; o teste segue a silhueta opaca no atlas inteiro e
confirma que nenhum pixel dela fica de fora e nenhum pixel de outra máquina entra.
A geometria e as UVs seguem exatamente a mesma escala uniforme e translação.
Os contornos não alteram perspectiva, proporção ou posição dos pixels.
O gerador da cena usa o mesmo contorno em um `Polygon2D`; a sala usa `AtlasTexture`.
Os PNGs originais permanecem intactos.

A máscara retangular do núcleo desligado foi removida. Estado offline usa o tom
da máquina e o indicador do terminal; o núcleo e sua tubulação ficam visíveis.
As bases de cabinet, pallet e spool foram recalibradas após remover margens vazias;
a base do gerador coincide na cena e na simulação em `Rect2(841,381,151,40)`.

## Camadas

1. Terreno, água, tabuleiros, tubulações baixas, sombras e apoios.
2. Lia, inimigos, destroços, máquinas individuais, props, totens, pilares,
   corrimãos e cancelas, ordenados pela base.
3. Efeitos da estação, projéteis, partículas e interface existentes.

A estação de energia conserva sua máquina de estados. Sala técnica, gerador e
terminal entram individualmente na ordenação. Seu terminal agora tem uma colisão
compacta, também declarada na cena, afastada do ponto de reparo.

## Contexto e contato

Tanques de captação alimentam a bomba e o clarificador; os filtros e reservatórios
se ligam ao conjunto de bombeamento. Os painéis solares alimentam a estação de
energia. A distribuição possui ligações entre purificador, manifold e reservatório.
Cabos e tubos baixos são passáveis. Caixas, pallets e barris conservam os núcleos
de armazenamento existentes. Não foram distribuídos novos objetos decorativos.

Foram removidas as molduras do clarificador e as placas de 100×70 sob os totens.
As bases agora são pequenos apoios nos pés, parafusos, sombras de contato e marcas
úmidas. A vegetação é pontual; os corredores e as bocas das pontes ficam livres.

## Verificação

Executar com Godot 4.7.x:

```text
godot --headless --path . --script tests/test_asset_silhouettes.gd
godot --headless --path . --script tests/test_world.gd
godot --headless --path . --script tests/test_simulation.gd
godot --headless --path . --script tests/test_environment_art.gd
godot --headless --path . --script tests/test_environment_integration.gd
godot --headless --path . --script tests/test_energy_station.gd
godot --path . --script tools/review_environment_integration.gd --audio-driver Dummy
godot --path . --script tools/review_asset_silhouettes.gd --audio-driver Dummy
```

A revisão gráfica salva 20 capturas em `.runtime/integration_review/` e executa
caminhadas reais com `sim.tick()` pelas três pontes, nas duas direções, e ao redor
de bases, incluindo sala técnica, gerador e terminal. Nenhum teleporte é usado durante cada caminhada; o início de cada trecho
é definido para isolar aquele acesso. Os inimigos são removidos apenas nessa revisão
visual. O teste da campanha usa IA e combate reais, com invulnerabilidade do bot.

## Melhorias futuras de acabamento

- Uniformizar a densidade de texturas entre módulos da ponte, painéis solares,
  cancelas e máquinas detalhadas. O encaixe e a circulação já estão resolvidos.
- Os totens têm desenhos próprios para cada estado. Sua base permanece no lugar,
  mas a silhueta muda quando o sistema é restaurado.
- As colisões representam bases simples, sem contornar parafusos ou folhagens.
- Os métodos da estação usam coordenadas do mundo, como o renderizador existente;
  mover a cena no editor também exige atualizar os dados de colocação.
