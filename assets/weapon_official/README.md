# Arma e pulsos — integração visual

**Atualização de 21/09/2026:** arma e corpo agora têm 24 orientações integradas em intervalos de 15°, inclusive durante os oito quadros da caminhada. Consulte `assets/lia_directional/README.md`. Efeitos e regras de disparo permanecem intactos.

## Apresentação atual — expansão de poses

Desde 16/09/2026, a personagem usa 32 quadros completos de caminhada armada e 16 de repouso em `assets/lia_expanded`. Arma, mãos e corpo pertencem à mesma figura em cada quadro. O ponto do clarão é próprio de cada pose, e o recuo visual inclina o corpo a partir dos pés. Os efeitos de disparo e as regras de combate permanecem intactos. Consulte o README da nova pasta para detalhes e testes.

## Histórico da correção de empunhadura

A sobreposição da arma independente sobre a caminhada desarmada foi removida: mesmo com o ponto de apoio próximo, os braços da imagem continuavam soltos e a ferramenta parecia flutuar. A apresentação atual reutiliza a pose oficial em que Lia segura o rifle com as duas mãos. Tronco, braços, mãos e arma permanecem na mesma imagem e recebem a mesma transformação visual. O código antigo de arma independente (`geometry`, `draw_tool`, `baked_muzzle`) foi removido do renderizador de produção.

Parada, Lia usa a pose armada completa. Caminhando ou esquivando, mantém o tronco armado e combina as pernas dos quatro quadros de caminhada, com pivô no quadril, sobreposição na cintura e base dos pés preservada. O cano frontal que atravessa a linha da cintura é conservado por um recorte da mesma imagem. Não há arma nem luva avulsa sobrepostas aos braços desarmados. Dano e recuo afetam a apresentação sem alterar a simulação; a manutenção conserva sua pose com ferramenta.

As referências só possuem quatro direções de empunhadura. A arma acompanha essas poses cardeais, inclusive quando o mouse mira na diagonal, para preservar a conexão com as mãos. A direção efetiva dos tiros continua em 360 graus. A caminhada armada é uma composição de partes existentes, não uma sequência de braços inédita. O antigo sprite isolado fica preservado como referência, sem uso sobre a personagem.

Verificação desta correção: `test_weapon_visual.gd` passou em 644 verificações (32 ângulos, quatro fases de passos, continuidade dos recortes dos braços/arma e simulação intacta durante o desenho). Capturas parada/caminhando/disparando e `captures/weapon_steps.png` conferidas visualmente; projeto instanciado e renderizado em Godot 4.7.1 Compatibility. `test_lia_official.gd`: 97 verificações headless aprovadas; `test_world.gd`: 2405 aprovadas. `test_simulation.gd`: os mesmos 90/91 e a mesma falha preexistente de posição no teste de parede descrita abaixo.

Arquivos desta correção: `scripts/actors_art.gd`, `scripts/lia_official.gd`, `scripts/weapon_visual.gd`, `tests/test_weapon_visual.gd`, documentação e capturas. Hashes confirmam `main.gd`, `simulation.gd`, `world.gd`, `audio.gd`, `project.godot` e testes anteriores de Lia/mundo/simulação inalterados. Retrato e inimigos também permanecem byte a byte iguais. Backups em `backups/before_attached_grip/`, logs e hashes em `.runtime/grip_review/`.

## Histórico da integração inicial (substituída na empunhadura)

Os detalhes de arma independente e rotação abaixo descrevem a tentativa anterior. A correção acima é o comportamento atual; pulsos e efeitos continuam válidos.

Prancha oficial reutilizada: `exec-e3dd1488-5c80-401d-a8e5-172399fee108.png`, fornecida em `protocolo17_imagens_geradas.zip`. `source.png` preserva o original. O importador extrai somente a primeira linha: arma de pulso ciano, quatro vistas (frente, esquerda, direita, costas). As outras três armas não são novas mecânicas.

## Apresentação

- `pulse_tool.png`: sprites existentes com fundo magenta convertido para transparência, sem redesenho. `frames.gd` guarda os recortes detectados automaticamente.
- Arma de 25 unidades no eixo principal, proporcional à Lia de 48 unidades. Âncoras individuais de empunhadura; arma atrás da personagem quando mira para cima e na frente nas demais vistas. Pequena luva sobre o cabo conecta a peça às mãos.
- Na caminhada/repouso, substitui a antiga arma de retângulos. No disparo cardinal parado, preserva a arma integrada à pose oficial, sem desenhar duas armas. Nas diagonais usa o sprite independente rotacionado, mantendo a mira livre.
- Clarão de saída de até 75 ms e recuo exclusivamente visual de até 1,6 unidade por 100 ms. O instante vem do cooldown do tiro já existente; nenhum temporizador de combate é alterado.
- Projétil de Lia em pixel art: núcleo claro, borda ciano/teal e cauda curta. Padrões de 18×8 e 12×10 pixels criados em memória uma única vez pelo renderizador, sem dependências externas. Nearest-neighbor. O núcleo acompanha a posição real do projétil; não deslocamos a colisão para a ponta do sprite da arma.
- Projéteis inimigos, arte de inimigos, HUD/retrato, cenário e áudio preservados.

## Limites das referências

As poses oficiais não possuem braços separados nem caminhada armada. A apresentação sobrepõe a ferramenta à caminhada e reutiliza o repouso nas diagonais de tiro. Não é uma nova animação de braços desenhada quadro a quadro. A arma embutida na pose de disparo tem pequenas diferenças de detalhe em relação à arma isolada; ambas vêm das referências oficiais. O corpo continua tendo quatro direções, e a mira continua livre em 360 graus.

## Arquivos

Alterados: `scripts/actors_art.gd` (apresentação da arma), `scripts/main.gd` (passagem da idade visual do tiro e desenho dos pulsos de Lia).

Novos: `scripts/weapon_visual.gd`, `tools/import_official_weapon.gd`, `tests/test_weapon_visual.gd`, esta pasta de assets e metadados Godot, capturas `captures/weapon_idle.png`, `weapon_walk.png`, `weapon_fire.png`, `weapon_game.png`. Backups dos três arquivos consultados em `backups/before_official_weapon/`; `backups/.gdignore` impede Godot de registrar classes dos backups como scripts de produção.

## Verificação em Godot 4.7.1

- Teste gráfico `tests/test_weapon_visual.gd`: 100 verificações, exit 0; 32 ângulos de mira, escala/âncoras/recuo, quatro capturas e nenhuma mutação dos dados de combate durante renderização. Capturas conferidas após os ajustes de diagonais e transparência.
- `test_lia_official.gd` headless: 97 verificações, exit 0. A 98ª do modo gráfico anterior é a verificação de renderização, que depende de viewport gráfico.
- `test_world.gd`: 2405 verificações, exit 0.
- `test_simulation.gd`: 90/91, exit 1, mesma falha preexistente no preparo da posição do teste de parede (linha 63). O bot completou as quatro etapas com 17 eliminações. Ele usa invulnerabilidade para testar a progressão; não é teste de dificuldade.
- Projeto executado em Compatibility/Intel Iris Xe, 120 frames, sem erros de script. Godot continua emitindo a mensagem ambiental de certificados Windows já documentada.
- Hashes comparados: `simulation.gd`, `world.gd`, `audio.gd`, `lia_official.gd`, `project.godot` e todos os testes anteriores inalterados. Dano, cadência, velocidade dos projéteis, mira, movimento, esquiva e colisões são os mesmos.

Logs e hashes de referência: `.runtime/weapon_review/`. Para regenerar os recortes: Godot `--headless --path . --script tools/import_official_weapon.gd`, seguido da importação do editor. Para repetir a revisão: Godot `--path . --script tests/test_weapon_visual.gd`.
