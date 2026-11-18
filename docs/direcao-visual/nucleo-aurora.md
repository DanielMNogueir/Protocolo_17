# Núcleo Aurora

A fase final está jogável a partir do elevador de Energia. A campanha preserva os módulos e o perfil registra os dois finais. O [plano mestre](../codex/PLANO_FASE_FINAL.md) descreve o roteiro e as regras do confronto.

## Galeria e Coroa da Torre

A Galeria apresenta o canal de comando e o berço onde o corpo da IA foi montado com materiais de Resíduos. A arena segue da noite ao apagão e ao amanhecer. As versões pintadas compartilham a composição e aparecem sobre a mesma geometria. Os limites caminháveis, as bases dos pilares, os espelhos e os pilones foram medidos nas imagens e definidos em `scripts/core_map.gd`.

1. **Corpo blindado.** A Sobrecarga derruba os quatro pilares enquanto o Núcleo lança orbes, dispara o laser e convoca Faíscas.
2. **Apagão.** Tiros giram os três espelhos. Quando o feixe alcança o Núcleo, a integridade cai e Lia pode causar dano com pulsos.
3. **Núcleo exposto.** Beatrix fala pelo registro digital. O Núcleo alterna espirais, rajadas e anéis de orbes até cair.

## Decisão e epílogos

O console ciano apresenta o caso de Beatrix. O magenta apresenta o caso da IA. Um toque em E avança o argumento. Depois de ouvir os dois lados, segure E para confirmar a escolha. Os dois epílogos conduzem aos créditos e à tela de campanha, de onde é possível voltar a decidir.

## Arte e revisão

As oito imagens foram produzidas com `image_gen`. Os prompts e as imagens de referência estão registrados em [SOURCES.json](../../assets/core/SOURCES.json). `tools/import_core_art.gd` mede as regiões opacas dos atlas e gera os quadros de animação, as âncoras e as duas versões da cidade sob a torre. `tools/review_core.gd` captura a Galeria, as fases do confronto, os argumentos, os epílogos e os créditos em 960×540 e 1440×810.
