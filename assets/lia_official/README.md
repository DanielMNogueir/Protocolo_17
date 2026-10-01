# Experimento visual — Lia oficial

**Atualização de 21/09/2026:** a Lia armada passou a usar 24 direções, em setores de 15°, conforme `assets/lia_directional/README.md`. Esta pasta continua preservando as referências oficiais e a manutenção original.

**Apresentação atual (16/09/2026):** a caminhada e o repouso armados foram ampliados para 48 quadros completos em `assets/lia_expanded`. Consulte o README dessa pasta para animação, geração, validação e limitações. As fontes oficiais desta pasta permanecem intactas; manutenção continua usando a prancha original. O texto abaixo registra as integrações anteriores.

Atualização de empunhadura: a personagem no campo agora conserva os braços e a arma da pose oficial armada, inclusive durante a caminhada, que combina o tronco armado com as pernas dos quadros existentes. A sobreposição de arma independente descrita no histórico abaixo foi removida. Consulte `assets/weapon_official/README.md` para a correção, testes e limite visual de quatro direções. Mecânicas permanecem inalteradas.

Integração de 10/09/2026, restrita à apresentação da Lia no mundo. As regras em `scripts/simulation.gd` não foram alteradas. O desenho anterior do retrato de rádio permanece para preservar o HUD. Cenário, inimigos, áudio, projeto e testes anteriores permanecem com hashes idênticos aos do início desta tarefa.

## Referências inspecionadas

Foram inspecionadas as 16 imagens de `protocolo17_imagens_geradas.zip`. O pacote contém referências de ambientes/HUD, retratos, drones, armas e três pranchas da Lia. Apenas duas pranchas da personagem foram integradas:

- `source_walk.png`: cópia intacta de `exec-1078931f-1c5f-40ba-8f21-0fc7b8c8e871.png`. 1254×1254, RGB, quatro linhas de caminhada: frente, esquerda, direita, costas; quatro quadros por linha.
- `source_actions.png`: cópia intacta de `exec-c2b5c592-7177-476b-aec5-9d1eefa7c236.png`. 1254×1254, RGB. Linhas: repouso, arma, recipiente e ferramenta de manutenção. Cada linha contém quatro direções, mas a ordem lateral muda: repouso/manutenção = frente/direita/esquerda/costas; arma = frente/esquerda/direita/costas.
- A variante `exec-9f394afb-8bf5-4f60-a646-0e3910e68728.png` foi examinada e não integrada: a arma na pose frontal/traseira não aponta consistentemente para frente/costas. A variante selecionada corrige isso.

## Extração e reprodução

`tools/import_official_lia.gd` detecta as faixas ocupadas e as caixas de cada figura por projeção de pixels. Não presume células de 313,5 px. As direções e ações foram identificadas por inspeção visual das pranchas. O fundo magenta e sua borda contaminada são convertidos em alfa zero; não há desenho novo, alteração das fontes, espelhamento nem geração de imagens.

Os derivados `walk.png` e `actions.png` preservam a resolução original. `frames.json` registra os 32 recortes; `frames.gd` oferece os mesmos dados como recurso exportável. Escala única calculada pela pose frontal de repouso: altura 48 unidades; base dos pés em posição da simulação +18. Nearest-neighbor usa a configuração existente do projeto. Importação é ferramenta de desenvolvimento, não executada pelo jogo.

## Adaptação às ações existentes

- Caminhada: quatro quadros por direção, 9 quadros/s, controlada pelo booleano de movimento já existente.
- Repouso: pose estática oficial, sem inventar uma sequência de respiração ausente.
- Disparo parado: pose armada oficial na direção mais próxima; apresentação acionada pelo cooldown do tiro existente, apenas leitura.
- Disparo em movimento: caminhada oficial com a ferramenta direcional independente já existente. A prancha não contém uma animação de caminhada armada.
- Manutenção: pose oficial com ferramenta enquanto há progresso de reparo.
- Esquiva: caminhada e rastros da imagem; dano/invulnerabilidade: modulação visual conforme os booleanos anteriores. Não existem quadros específicos de esquiva/dano no pacote.
- Mira e projéteis continuam em 360 graus; o corpo e as poses oficiais têm quatro direções.
- Transporte de recipiente não foi integrado, pois não existe essa mecânica no jogo atual.

## Arquivos da entrega

Alterados: `scripts/actors_art.gd` e somente as chamadas de apresentação da Lia em `scripts/main.gd`.

Adicionados: `scripts/lia_official.gd`, `tools/import_official_lia.gd`, `tests/test_lia_official.gd`, esta pasta de assets/documentação, `captures/lia_official_poses.png`, `captures/lia_official_game.png`. Godot gerou os respectivos metadados `.import`/`.uid`. Backup do arquivo original em `backups/before_official_lia/actors_art.gd.txt`. Referências de inspeção e logs em `.runtime/lia_reference/`.

## Verificação — Godot 4.7.1

- Importação/editor: concluídos sem erros de script.
- Execução gráfica do projeto: 120 frames, exit 0, Compatibility/Intel Iris Xe.
- `tests/test_lia_official.gd`: 98 verificações aprovadas, exit 0. Recursos, recortes, âncoras, direções e avanço de quadros; cena real renderizada sem mutação de posição, vida, velocidade, mira, etapa, invulnerabilidade, tiros ou cooldown da esquiva. Capturas conferidas visualmente.
- `tests/test_world.gd`: 2405 verificações aprovadas, incluindo 1165 amostras de rota e 16 verificações de acesso.
- `tests/test_simulation.gd`: 90 de 91 verificações aprovadas, exit 1. Falha preexistente no preparo do teste de parede, linha 63: coloca Lia em (475,1270), a apenas 5 unidades da borda do reservatório que termina em x=470, embora o raio de colisão seja 14. O próprio teste exige essa posição livre. Simulação, mundo e teste estão byte a byte inalterados nesta tarefa; nenhuma correção fora do escopo foi feita.
- O bot desse teste completou as quatro etapas com tiros e deslocamento reais, 17 eliminações. Usa invulnerabilidade para isolar progressão; isso não é validação de dificuldade.
- Godot emitiu `Failed to read the root certificate store`, aviso do ambiente Windows já observado anteriormente; não impediu renderização nem os testes aprovados.

Para repetir: na raiz do projeto, execute Godot `--headless --path . --script tests/test_world.gd` e `--headless --path . --script tests/test_simulation.gd`. Execute `--path . --script tests/test_lia_official.gd` com renderer gráfico para gerar as duas capturas e executar as 98 verificações. Em ambiente restrito, use APPDATA apontando para `.runtime`, como nesta execução, para isolar arquivos de usuário.
