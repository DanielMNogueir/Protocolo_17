# Protocolo 17 — Aurora

Versão alpha do projeto Godot, enviada a partir da pasta `Protocolo_17 - GPT 6` em 20/09/2026.

Esta branch contém essa versão do jogo. As versões existentes em `main`, `daniel-dev` e `gabriel-dev` permanecem independentes.

## Abrir o jogo

1. Importe `project.godot` no Godot 4.7 (o projeto registra uso do 4.7.1).
2. Aguarde a importação dos recursos.
3. Pressione F5 para executar a cena principal.

## Controles

- WASD ou setas: mover.
- Mouse: mirar; botão esquerdo: disparar.
- Espaço: disparar mantendo a direção da mira.
- Shift: esquiva.
- E: manter pressionado para restaurar um terminal liberado.
- M: mapa; Esc: pausa.
- F10: áudio; F11: tela cheia.

## Conteúdo

Missão Operação Filtro, com quatro setores, combate contra drones e chefe, melhorias, checkpoints e encerramento. A pasta `assets/` inclui os recursos atuais de Lia e da arma, além da arte de abertura. `tests/` contém testes do projeto e `captures/` contém registros visuais, que podem refletir revisões anteriores.

Os checkpoints preservam a etapa e as melhorias, reiniciando o encontro da etapa ao continuar. Saves e configurações pessoais ficam em `user://`.

## Organização

- `scenes/`: cena principal.
- `scripts/`: simulação, mundo, apresentação, personagem, arma e áudio.
- `assets/`: imagens, sprites e dados de frames.
- `tests/`: testes existentes.
- `tools/`: ferramentas de importação e captura.
- `captures/`: imagens de referência.
- `export_presets.cfg`: configuração de exportação Windows.

Caches do Godot, logs, builds e backups locais foram excluídos do envio. As mecânicas e os arquivos-fonte do jogo foram copiados sem implementação de mudanças nesta publicação. Os testes não foram executados como parte do upload.
