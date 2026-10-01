# Lia — 24 direções em intervalos de 15°

Integração de 21/09/2026. A apresentação armada da Lia agora usa 24 orientações do corpo e da arma: 0°, 15°, 30°…345°, em repouso, caminhada e disparo. O corpo permanece em pé; não se trata de girar uma imagem plana. A mira real continua livre em 360°.

## Conjunto de sprites

Dez pranchas novas, todas 1536×1024, seis colunas por quatro linhas. Cada célula corresponde a uma direção, em ordem crescente no sentido horário: 0° direita, 90° frente/baixo, 180° esquerda, 270° costas/cima.

- `idle.png`: 24 poses armadas neutras.
- `blink.png`: 24 quadros correspondentes de piscada; nas vistas de costas, sem olhos visíveis, o desenho conserva a pose.
- `walk0.png` a `walk7.png`: oito fases de caminhada para cada uma das 24 direções, 192 quadros.
- Total: 240 quadros usados pela apresentação. Cada quadro contém corpo, mãos e rifle juntos.
- Os dez `source_*.png` preservam as fontes geradas. Os derivados convertem o fundo magenta para alfa real, sem pintar ou interpolar imagens.
- `frames.json`/`frames.gd` guardam os recortes e âncoras individuais do quadril, chão e emissor ciano.

Arte criada com a ferramenta integrada `image_gen`, partindo de `assets/lia_official/source_actions.png` e `assets/lia_expanded/source_idle.png`. A primeira volta foi revisada com o guia geométrico `aim_guide.svg` para diferenciar as orientações do rifle. Os prompts completos estão em `PROMPTS.md`. A origem exata das fontes está em `SOURCES.json`.

## Integração

`scripts/lia_directional.gd` escolhe o setor de 15° mais próximo da mira, com erro máximo de seleção de 7,5° e passagem circular entre 345° e 0°. `scripts/lia_official.gd` delega as poses armadas ao novo renderizador, conservando os efeitos de dano, esquiva, recuo e a pose original de manutenção.

A caminhada continua com oito quadros a 18 fps, sem reiniciar a passada ao mudar de direção ou disparar. O relógio visual anterior mantém as pausas. O repouso tem uma leve respiração ancorada nos pés e piscada de 0,16 segundo a cada quatro segundos. O corpo e o cano recebem a mesma transformação visual; a arma não é uma camada independente.

Todos os ângulos e fases compartilham uma única escala, calibrada em 48 unidades pela pose frontal. O centro horizontal do quadril vem da pose neutra de cada direção e é conservado nas fases da caminhada, para que o comprimento da arma ou a abertura das pernas não desloquem o pivô. A base dos pés permanece em y=18.

Para reproduzir a extração: Godot `--headless --path . --script tools/import_directional_lia.gd`, seguido de `--headless --path . --editor --import --quit`.

## Verificação

- Godot 4.7.1, renderer Compatibility/Intel Iris Xe: projeto carregado e cena real renderizada nas 24 direções.
- `test_weapon_visual.gd`: **3752 verificações aprovadas**, incluindo os 240 quadros, alfa/recortes, oito fases distintas por direção, escala, base dos pés, emissor, setores e limites, transição circular e preservação de 24 campos da simulação durante o desenho da cena.
- `test_lia_animation.gd`: **22 verificações aprovadas**.
- `test_lia_official.gd`: **97 verificações headless aprovadas**, recursos originais e manutenção preservados.
- `test_world.gd`: **2405 verificações aprovadas**.
- `test_simulation.gd`: **90/91 aprovadas**. Permanece a falha anterior na preparação do caso de parede (`tests/test_simulation.gd:63`), que coloca um personagem de raio 14 a apenas 5 unidades da borda do reservatório e exige terreno livre. Simulação e teste não foram alterados. O bot completou as quatro etapas, com 17 eliminações.
- Mensagem ambiental já conhecida: `Failed to read the root certificate store`; não impede importação ou renderização.

Hashes SHA-256 confirmam que `simulation.gd`, `world.gd`, `actors_art.gd`, `weapon_visual.gd`, `audio.gd`, `main.gd` e `project.godot` continuam idênticos aos do início desta ampliação direcional. Nenhuma regra, inimigo, cenário, HUD ou controle foi alterado.

## Revisão visual e limites

Abra `captures/lia_24_preview.html` para alternar entre caminhada animada, repouso/piscada e disparo, inclusive em câmera lenta. Ela usa as capturas reais do Godot, não uma segunda implementação da animação. As pranchas `captures/lia_24_idle.png`, `lia_24_fire.png` e as oito `lia_24_step_*.png` mostram os ângulos lado a lado.

Os setores do código são exatos; a perspectiva da ilustração é estilizada e pode apresentar pequenas diferenças de inclinação/proporção entre vistas. O conjunto continua sendo pixel art por quadros, não uma malha 3D com interpolação contínua. A manutenção com ferramenta conserva suas quatro poses oficiais anteriores; a expansão para 24 vistas cobre a personagem armada. Esquiva/dano usam os quadros de movimento e efeitos já existentes, sem novas regras.

## Arquivos desta ampliação

Alterados: `scripts/lia_official.gd`, `tests/test_weapon_visual.gd` e notas de histórico nas pastas anteriores.

Adicionados: `scripts/lia_directional.gd`, `tools/import_directional_lia.gd`, esta pasta de sprites/fontes/metadados/documentação, `captures/lia_24_*` e metadados Godot `.import`/`.uid`.

Backups em `backups/before_24_directions/`; logs e hashes em `.runtime/directions24_review/`.
