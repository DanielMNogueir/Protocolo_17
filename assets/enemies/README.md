# Inimigos — arte e resposta audiovisual

Integração de 27/09/2026. Quatro spritesheets novos seguem a Lia e os conceitos oficiais de máquinas de manutenção corrompidas: metal gasto, painéis verde-petróleo, cobre, sinalização amarela e energia magenta.

| Unidade | Silhueta | Som |
| --- | --- | --- |
| Explorador (`scout`) | Dois rotores, braços articulados e emissor inferior | Chirps agudos e modulação de rotor |
| Sentinela (`sentry`) | Esteiras, blindagem ocre e canhões duplos | Trava mecânica e pulso metálico |
| Investida (`rammer`) | Patas hidráulicas e lâmina frontal | Motor grave, aceleração e impacto |
| Contenção (`boss`) | Quatro patas, grandes canhões e reator exposto | Ressonância grave e descarga pesada |

## Recursos

- `scout.png`, `sentry.png`, `rammer.png`, `boss.png`: fontes geradas de 1254×1254 com alfa real, preservadas integralmente.
- Cada prancha contém oito direções e dois quadros mecânicos por direção: **64 quadros** no total. Ordem: direita, baixo-direita, baixo, baixo-esquerda, esquerda, cima-esquerda, cima, cima-direita; repetida na segunda fase.
- A animação combina esses quadros com flutuação, recuo, preparação luminosa, rastro da investida, reação a dano e destruição em fragmentos giratórios.
- Os recortes usam a maior silhueta conectada de cada célula, evitando que pequenas partículas de alfa alterem o pivô. Escala única por espécie e apoio calibrado na base de cada quadro.
- **20 sons originais**: detecção, preparação, ataque, dano e destruição para cada unidade. `scripts/enemy_audio.gd` sintetiza WAV mono a 22050 Hz; o sistema de áudio os prepara uma vez, respeita o volume/mudo existente e limita vozes simultâneas. Não exige downloads ou serviços durante a partida.

`scripts/enemy_presentation.gd` observa cópias dos estados de combate e mantém apenas animações, avisos sonoros e destroços temporários. Pausa e diálogos congelam a apresentação. Retentar/carregar/trocar de etapa reinicia esse estado sem inventar destruições. A simulação de combate continua sendo a versão aprovada com o disparo da Lia alinhado ao cano.

`scripts/enemy_art.gd` desenha as unidades e os efeitos; `actors_art.gd`, `main.gd` e `audio.gd` fazem a integração. `PROMPTS.md` contém os prompts completos; `SOURCES.json` registra os arquivos da ferramenta integrada `image_gen` e seus hashes.

## Verificação

- `test_enemy_presentation.gd`: 251 verificações, incluindo 64 quadros, alfa, recortes, sons distintos sem clipping, transições de animação, pausa, descarte dos destroços e ausência de mutação da simulação.
- Regressões aprovadas: campanha 91/91 (quatro etapas, 17 eliminações), origem dos disparos 962, animação da Lia 22, sprites oficiais 97, mundo 2405 e apresentação da arma 3724 em headless.
- Godot 4.7.1 / Compatibility: 32 capturas das animações e captura da cena real, sem erros de script. Permanece o aviso ambiental de certificado do Windows, que não impede os testes.

## Reproduzir a revisão

1. `Godot --headless --path . --script tools/import_enemy_art.gd` recalcula recortes; use `--log-file .runtime/import.log` se o diretório de logs do usuário estiver restrito.
2. `Godot --headless --path . --editor --import --quit` importa os PNGs.
3. `Godot --headless --path . --script tests/test_enemy_presentation.gd` verifica e exporta os sons de revisão.
4. `Godot --path . --script tools/review_enemies.gd` captura a renderização e cria `.runtime/enemy_review/preview.html`, com controle de quadros e botões para ouvir cada som.

As direções são discretas de 45°; a locomoção usa dois quadros por orientação com efeitos contínuos. A prancha de revisão amplia cada espécie para examinar detalhes; a captura da cena mostra o tamanho real usado na partida.
