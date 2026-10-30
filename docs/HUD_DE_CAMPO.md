# HUD de campo de Aurora

A interface acompanha o papel de Lia como agente de recuperação: instrumentos escuros, ciano para integridade e mobilidade, âmbar para objetivos e rajada, coral para integridade crítica. Os painéis compartilham bordas, sombra, margens e tipografia em Águas e Resíduos.

Referências consultadas: [Hades, apresentação oficial e gameplay](https://www.supergiantgames.com/games/hades/) e [Outer Wilds, apresentação e imagens oficiais](https://www.mobiusdigitalgames.com/outer-wilds.html). A direção combina leitura periférica de combate com instrumentos de exploração. Os elementos são desenhados no Godot; nenhum recurso desses jogos foi incorporado.

- Integridade: número, segmentos adaptados à vida máxima e aviso textual de estado crítico, acompanhado por borda pulsante.
- Navegação: distrito, mapa, pausa e dificuldade em Águas. Os botões de Águas conservam clique e atalhos.
- Objetivo: setor, ação atual, drones, levas, tarefas e progresso da rede, sem o antigo bloco sobreposto no centro superior.
- Equipamento: atalhos de disparo, rajada e esquiva; estados prontos e tempo restante com barras independentes nos dois distritos.
- Contexto: interação e sincronização no espaço central inferior; chefe com fundo próprio; mensagens temporárias abaixo da faixa superior.
- Resíduos: minimapa escurecido e marcador de Lia com contorno para melhorar a leitura sobre a imagem do distrito.

## Revisão

Godot 4.7.2, renderer Compatibility/ANGLE. Testes existentes: `tests/test_beta_rules.gd`, `tests/test_beta_input.gd` e `tests/test_residues.gd`.

`godot --path . --audio-driver Dummy --script tools/review_hud.gd` captura combate, integridade crítica, quatro tarefas, análise, terminal, chefe, etapas de Resíduos e interação. Inclui 960×540 e 1440×810. O diretório padrão é `user://hud-review`; a variável `P17_HUD_OUTPUT` permite escolher outro destino. As capturas são uma revisão de apresentação; não substituem playtest humano.