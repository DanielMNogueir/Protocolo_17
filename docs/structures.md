# Estruturas modulares

`WorldStructure` contém somente o ciclo visual compartilhado `OFFLINE → STARTING → ONLINE`, o texto de interação e os sinais de mudança de estado. Combate, movimento, salvamento e progressão continuam sob responsabilidade da simulação existente.

`EnergyStation.tscn` é a primeira implementação. A cena possui arte dividida em sala técnica e gerador, três colisões de base (sala técnica, gerador e terminal), área de interação independente, obstáculo de navegação, luz, partículas, áudio, animação e indicador. O PNG original permanece intacto: `AtlasTexture` na sala e `Polygon2D` no gerador reutilizam a arte do atlas aprovado. O contorno do gerador separa sua silhueta inteira da tubulação vizinha; a geometria e as UVs têm a mesma escala uniforme, sem deformar a imagem.

O alpha atual desenha o mundo em um único `Node2D`. Para evitar reescrever um sistema estável, a cena é instanciada em `main.gd`, mas a apresentação usa as chamadas em camadas `draw_foundation`, `draw_body` e `draw_effects`. A sala técnica, o gerador e o terminal entram individualmente na mesma lista ordenada por Y de Lia e dos inimigos. Assim, Lia fica ocultada ao passar atrás da estação e aparece sobre a base ao passar pela frente. As colisões da simulação usam exatamente as três pegadas declaradas por `EnergyStation.COLLISION_RECTS`, também consideradas pelos inimigos.

## Criar outra estrutura

1. Duplique `scenes/structures/energy_station.tscn` e troque as texturas e recortes pelo novo equipamento. Se dois conceitos tiverem caixas sobrepostas no atlas, use um contorno que preserve cada silhueta inteira, como o gerador.
2. Crie um script que herde `P17WorldStructure` e defina origem, ponto de interação, linha de ordenação e poucas colisões simples.
3. Implemente as três etapas de desenho para o renderizador atual: piso/fundação, corpo ordenável e efeitos superiores.
4. Adicione as pegadas a `P17World._build_solids()` e o ponto de terminal a `P17World.GOALS`.
5. Instancie a cena em `main.gd`, sincronize o estado com `sim.restored` e inclua o corpo na lista `entities`.
6. Acrescente um teste estrutural e uma captura offline/online.

Quando o mapa migrar no futuro para `TileMapLayer`/`Camera2D`, a mesma cena poderá exibir seus nós visuais diretamente; colisão, área, navegação, luz e partículas já estão organizadas para isso.

