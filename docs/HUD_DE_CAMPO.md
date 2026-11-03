# HUD Industrial Aurora

Implementação da proposta visual **1 — Industrial Aurora**, escolhida pelo usuário. Molduras metálicas com oito cantos, camadas de aço e esmalte, rebites, guarnições em âmbar, visores rebaixados e teclas físicas substituem os painéis planos. A construção é nativa no Godot e não usa uma imagem estática da HUD.

A interface acompanha o papel de Lia como agente de recuperação: instrumentos escuros, ciano para integridade e mobilidade, âmbar para objetivos e rajada, coral para integridade crítica. Os painéis compartilham bordas, sombra, margens e tipografia em Águas e Resíduos.

Referências consultadas: [Hades, apresentação oficial e gameplay](https://www.supergiantgames.com/games/hades/) e [Outer Wilds, apresentação e imagens oficiais](https://www.mobiusdigitalgames.com/outer-wilds.html). A direção combina leitura periférica de combate com instrumentos de exploração. Os elementos são desenhados no Godot; nenhum recurso desses jogos foi incorporado.

- Integridade: retrato da cabeça e ombros recortado da folha original de Lia, número, segmentos adaptados à vida máxima e aviso textual de estado crítico, acompanhado por borda pulsante.
- Navegação: distrito, mapa, pausa e dificuldade em Águas. Os botões de Águas conservam clique e atalhos.
- Objetivo: setor, ação atual, drones, levas, tarefas e progresso da rede, sem o antigo bloco sobreposto no centro superior.
- Equipamento: duas cápsulas com ícones próprios de rajada e esquiva, teclas, dez segmentos de recarga, tempo restante e sinalizadores de prontidão nos dois distritos. Os ícones SVG são rasterizados e armazenados em cache uma única vez.
- Contexto: interação e sincronização no espaço central inferior; chefe com fundo próprio; mensagens temporárias abaixo da faixa superior.
- Resíduos: minimapa escurecido e marcador de Lia com contorno para melhorar a leitura sobre a imagem do distrito.

## Revisão

Godot 4.7.2, renderer Compatibility/ANGLE. Testes existentes: `tests/test_beta_rules.gd`, `tests/test_beta_input.gd` e `tests/test_residues.gd`.

`godot --path . --audio-driver Dummy --script tools/review_hud.gd` captura combate, integridade crítica, quatro tarefas, análise, terminal, chefe, etapas de Resíduos e interação. Inclui 960×540 e 1440×810. O diretório padrão é `user://hud-review`; a variável `P17_HUD_OUTPUT` permite escolher outro destino. As capturas são uma revisão de apresentação; não substituem playtest humano.

A revisão inclui vida máxima ampliada (14 unidades), estados críticos e parciais de recarga e cliques reais de mouse nos botões de mapa e pausa em ambas as resoluções. O radar usa a geometria e os objetivos reais de cada distrito. Nenhum executável antigo é atualizado automaticamente: execute o project.godot atual para ver a nova HUD.

## Seleção de perks

A oficina de módulos utiliza as mesmas molduras metálicas, rebites, esmalte escuro, detalhes em âmbar e teclas físicas da HUD de combate. Cada uma das nove melhorias tem categoria, bônus numérico, ícone correspondente ao efeito, título e descrição originais. O destaque do mouse aparece na moldura e no comando de instalação; toda a área do cartão continua clicável e os atalhos 1, 2 e 3 são preservados.

Revisão reproduzível: `godot --path . --audio-driver Dummy --script tools/review_perks.gd`. O roteiro não grava configurações ou checkpoints do jogador. Produz oito capturas das três etapas e do estado de destaque, em 960×540 e 1440×810; verifica 36 instalações por mouse/teclado, a escolha do módulo correto, a transição de setor e os limites dos cartões. Saída padrão: `user://perk-review`; sobrescreva com `P17_PERK_OUTPUT`.
## Prólogo

A identidade de Beatrix, integridade de três células, rotina de sete etapas, contenção, instruções, reparo e direção do objetivo usam o mesmo acabamento Industrial Aurora da campanha. Abertura, transição para Lia, registro preservado e retomada recebem molduras compartilhadas. A caixa de diálogo reutiliza `FieldHUD.panel` e seus controles reutilizam `FieldHUD.control`, com teclas físicas e alvos de clique correspondentes. Retratos originais, textos, regras de revelação, avanço e falas instantâneas são preservados.

Validação: `tests/test_prologue_shell.gd` verifica fluxo e controles; `tests/test_dialogue_panel.gd` cobre texto longo, retratos, ancoragem e cliques. `tools/review_prologue.gd` captura 13 estados em duas resoluções (26 imagens), inclui reparo, vida crítica e retomada, verifica os limites dos botões e o clique real para retomar. O roteiro utiliza configurações e checkpoints em memória; a variável `P17_PROLOGUE_OUTPUT` define o destino das capturas.
## Menus — Lia / Último sinal

O menu inicial implementa a primeira proposta aprovada: arte original de Lia e Aurora, marca Protocolo 17 com Aurora como subtítulo, ação principal à esquerda e navegação vertical. Sem save, mostra Iniciar operação; com save, mostra Continuar e Nova operação. Configurações, Rever prólogo e Sair estão disponíveis nos dois estados. O título usa fontes do sistema com fallback, sem distribuir arquivos de fonte do Windows.

Pausa, configurações e dificuldade reutilizam molduras e teclas Industrial Aurora. Setas e Tab percorrem as ações; Enter ou Espaço ativam o item com foco. O foco é visível, reinicia ao trocar de menu e cede ao mouse quando ele se move. Os atalhos existentes, incluindo 1–3 para dificuldade e Escape para voltar, permanecem disponíveis.

Revisão: `godot --path . --audio-driver Dummy --script tools/review_menus.gd`. Destino por `P17_MENU_OUTPUT` (padrão `user://menu-review`). O roteiro gera 24 capturas em 960×540, 1440×810 e 1280×720, incluindo um viewport lógico maior; verifica limites, separação dos alvos, navegação por teclado, continuar com checkpoint válido, áudio, comando de tela, pausa e replay. A persistência, o fullscreen e a saída são isolados no roteiro para não alterar o ambiente do jogador. As regressões de controles usam `tests/test_beta_input.gd` e `tests/test_prologue_shell.gd`.