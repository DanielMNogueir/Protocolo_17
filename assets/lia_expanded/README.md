# Lia — expansão de poses, 16/09/2026

48 novos quadros completos derivados das referências oficiais: 32 de caminhada armada (8 por direção) e 16 de repouso armado (4 por direção). A apresentação anterior combinava 4 poses de pernas com um tronco armado estático. Agora cada quadro inclui cabeça, cabelo, tronco, braços, mãos, arma e pernas na mesma imagem.

## Arte e extração

- `source_walk.png`: prancha nova de caminhada, 1774×887, oito colunas e quatro linhas.
- `source_idle.png`: prancha nova de repouso, 1254×1254, quatro colunas e quatro linhas.
- Ordem das linhas em ambas: frente, esquerda, direita, costas.
- `walk.png` e `idle.png`: derivados RGBA para o jogo, com o fundo magenta convertido em transparência. Fontes preservadas integralmente.
- `frames.json` e `frames.gd`: recortes, pivôs de quadril/chão e pontos de saída do cano por quadro, em coordenadas das imagens fonte.
- `PROMPTS.md`: prompts completos e proveniência. Foi usada a ferramenta integrada `image_gen`, com as fontes oficiais de `assets/lia_official` como referência. As versões foram revisadas para corrigir o fundo, poses de passagem das pernas, orientação frontal da arma e postura dos braços de costas.

`tools/import_expanded_lia.gd` extrai as figuras por projeção de pixels e localiza o centro das calças e o emissor ciano. O pivô ignora o comprimento lateral da arma. Há uma escala comum por prancha, calculada a partir da altura frontal mediana de 48 unidades; nenhum quadro recebe normalização de tamanho individual. Os pés mantêm a base em y=18 relativa à posição da personagem. As coordenadas do cano foram conferidas nas capturas de disparo.

Para reproduzir a extração: Godot `--headless --path . --script tools/import_expanded_lia.gd`, depois `--headless --path . --editor --import --quit`.

## Comportamento visual

- Caminhada com oito quadros a 18 fps, preservando a duração anterior da passada de 4/9 segundos. Há poses de contato, compressão e passagem, variações de cabelo e ombros.
- Repouso com três quadros de respiração e um de piscada. A respiração usa 0→1→2→1, 0,55 segundo por fase; a piscada dura 0,16 segundo a cada quatro segundos. Na vista traseira o quarto quadro é uma variação de repouso.
- `lia_animation.gd` mantém um relógio exclusivamente visual: começa a caminhada/repouso na fase zero, preserva a fase nas mudanças de direção e congela junto com a simulação em pausa, mapa, diálogos e demais telas.
- Mãos e arma nunca são desenhadas como objetos independentes. O recuo usa uma leve inclinação do sprite inteiro em torno da linha do chão, conservando os pés e transformando o ponto do clarão junto com o corpo.
- Disparos não reiniciam a passada. Esquiva e dano conservam os rastros/modulação existentes. A manutenção continua usando a pose oficial anterior com ferramenta.

## Escopo e limites

A mudança é de apresentação. Os arquivos de simulação, mundo, áudio, efeitos da arma, inimigos/retrato (`actors_art.gd`) e configuração do projeto foram comparados por SHA-256 e permanecem idênticos aos do início da tarefa. Apenas a chamada visual e o avanço do relógio da Lia mudaram em `main.gd`.

As poses continuam em quatro direções; a mira e os tiros reais continuam em 360 graus. Não foram criadas poses diagonais, sequências próprias de esquiva/dano nem novas mecânicas. Os sprites novos foram gerados a partir das referências, não são quadros inéditos encontrados no pacote oficial. Pequenas variações de desenho/perspectiva entre caminhada e repouso permanecem; não se trata de um rig esquelético.

## Verificação

- Godot 4.7.1: importação e carregamento sem erros de script.
- Projeto executado com renderer Compatibility/Intel Iris Xe por 120 frames, saída 0.
- `test_lia_animation.gd`: 22 verificações aprovadas, incluindo pausa, diálogo, troca de direção e início de nova partida no loop real.
- `test_lia_official.gd`: 98 verificações aprovadas, incluindo os recursos originais preservados e renderização da cena real sem mutação da simulação.
- `test_world.gd`: 2405 verificações aprovadas.
- `test_simulation.gd`: 90/91 aprovadas; permanece a falha anterior na preparação do teste de parede, linha 63. Ele posiciona Lia em (475,1270), a 5 unidades da borda de um obstáculo, apesar do raio 14, e exige a posição livre. O teste e a simulação não foram alterados. O bot completou as quatro etapas com 17 eliminações.
- Mensagem ambiental já existente: `Failed to read the root certificate store`; não impediu importação, testes visuais ou renderização.

Logs desta entrega: `.runtime/pose_review/`. Backups dos scripts alterados: `backups/before_pose_expansion/`.

## Arquivos

Alterados: `scripts/lia_official.gd` (atlas, poses, cano e recuo); `scripts/main.gd` (cinco alterações de integração visual); `tests/test_weapon_visual.gd` (validação das poses completas); READMEs de `assets/lia_official` e `assets/weapon_official`; capturas visuais.

Adicionados: `scripts/lia_animation.gd`, `tests/test_lia_animation.gd`, `tools/import_expanded_lia.gd`, esta pasta de arte/fontes/metadados/documentação e metadados `.uid`/`.import` gerados pelo Godot.
