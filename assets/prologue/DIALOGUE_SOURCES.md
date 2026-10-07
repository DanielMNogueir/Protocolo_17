# Diálogos da introdução — retrato e moldura

Atualizado em 07/10/2026.

## Resultado integrado

A introdução usa uma barra fixa na parte inferior, com retrato ou ícone do interlocutor à esquerda, nome em uma aba ligada à moldura e texto à direita. O mundo continua visível acima. As dicas do tutorial e os indicadores de navegação respeitam o espaço reservado à fala.

A moldura foi desenhada diretamente em Godot: metal escuro, bordas chanfradas, filetes de bronze, parafusos e pequenos detalhes luminosos. Ela acompanha a largura da janela, sem esticar uma imagem de borda. A IA usa um retrato holográfico anônimo, sem nome na aba; os detalhes luminosos da moldura mudam quando a contenção começa. O contexto de Aurora e a transmissão de Major 0 na transição usam a mesma barra.

Enter completa/avança; segurar Enter acelera apenas a revelação do texto; Tab alterna falas instantâneas; P pula a introdução. Os botões continuam disponíveis. Clicar no texto também completa/avança e não interfere com os botões do rodapé. A conversa aguarda uma confirmação nova a cada fala e suspende ações do tutorial enquanto o jogador lê. O conteúdo das falas da história foi preservado.

## Arquivos

- `scripts/dialogue_panel.gd`: composição, moldura, ícones, posição e controles.
- `scripts/prologue_presentation.gd`: integração nas falas, contexto e transição.
- `scripts/beatrix_art.gd`: retrato proporcional no diálogo e no HUD; sprites de movimento preservados.
- `assets/prologue/beatrix_portrait_v1.png`: retrato original RGBA, preservado sem edição dos pixels; criado com a ferramenta integrada `image_gen`, sem modo CLI. Referência: `assets/prologue/beatrix.png`.
- `tests/test_dialogue_panel.gd`: renderização, troca do interlocutor, ancoragem ao mover a câmera, leitura do contexto em três resoluções e controles de mouse.

## Prompt final do retrato

```text
Create ONE production dialogue portrait of Dr. Beatrix based on the woman in the supplied game sprite sheet. Use case: stylized-concept. Square transparent RGBA canvas. Preserve her identity: adult Brazilian-looking scientist with medium warm brown skin, brown expressive eyes, abundant shoulder-length chestnut brown curls, white laboratory coat over a muted teal blouse. A beautiful classic RPG dialogue bust, cropped at upper chest, centered, facing very slightly to the viewer's right, thoughtful attentive determined expression, mouth relaxed closed. Hair fits completely within the image with small transparent margins on top and sides; bust reaches the lower edge cleanly. Painted pixel art, clean deliberate medium-sized pixel clusters as if made for a 128x128 portrait, sharp contours and careful rich facial shading, not smooth vector art and not photo realism. Sophisticated grounded sci-fi botanical laboratory aesthetic; subtle cool cyan reflected light on coat edges and subtle warm bronze key light upper-left, while the skin stays natural. Clearly readable eyes and face at 80px display size. No tablet in front of face, no prop covering head, no UI, no frame, no text, no letters, no logos, no background scene, no additional faces, no sprite sheet. This is a new close-up portrait derived from her existing sprite identity, not a replacement of the supplied sheet.
```

## Validação

Os testes de regras da introdução, controles e renderização do diálogo passam. As capturas podem ser reproduzidas com `tools/review_prologue.gd`; `P17_PROLOGUE_OUTPUT` escolhe a pasta. A versão final foi conferida em `captures/dialogos-rpg`.

## Retrato da IA e avanço manual — 07/10/2026

`assets/prologue/ai_portrait_v1.png` foi criado com a ferramenta integrada `image_gen`, sem modo CLI, e preservado em RGBA sem editar os pixels. Representa um avatar holográfico anônimo; não expõe o nome da IA nem identifica um corpo físico. Major 0 conserva o ícone de rádio.

Todas as falas aguardam uma nova confirmação do jogador. Segurar Enter acelera apenas a revelação da fala atual e Tab exibe o texto instantaneamente; nenhum dos dois consome a fila. Movimento, combate e interação ficam suspensos durante a conversa, evitando que uma nova ação substitua o texto ou que o jogador seja atacado enquanto lê. Os materiais do laboratório continuam animados. A sequência final começa somente após a última fala ser confirmada.

A indicação anterior de avanço automático foi substituída por `AGUARDANDO VOCÊ` quando o texto está completo. Os testes cobrem espera prolongada, Enter segurado, texto instantâneo, preservação da fila, confirmação da última fala e a renderização do retrato.

### Prompt final — IA

```text
Use case: stylized-concept. Create ONE original game dialogue bust portrait representing an ANONYMOUS artificial intelligence as an abstract holographic face. Square transparent RGBA canvas. Elegant faceted digital humanoid visage and neck with no real human identity, no gender, calm unreadable expression, simple luminous cyan eyes, translucent turquoise planes, dark deep teal shadow facets, a sparse precise circuit/node pattern subtly embedded across the cheek and temple, tiny warm bronze connectors around a minimal dark graphite collar. It is a projected interface avatar, not an actual physical robot or drone. Slight three-quarter orientation towards the viewer's LEFT so it faces the dialogue text. Complete head with comfortable transparent top and side gutters, shoulder silhouette ends cleanly at the bottom edge, face occupies most of the image and remains very readable at 100px. Beautiful deliberate hand-painted PIXEL ART with rich pixel cluster shading as if designed at 128x128, crisp stepped contours, cinematic upper-left key light, matching a sophisticated sci-fi botanical laboratory RPG portrait. Restrained science-fiction design, thoughtful unsettling intelligence without cartoon evil or anger. No hair, no human skin, no red evil eyes, no skull, no brain jar, no screen monitor frame, no rectangular background, no logo, no letters, no numbers, no readable writing, no visible name, no protocol name, no scene, no UI or decorative border, no additional faces, no comparison panels. Do not resemble a blue-haired female player character or any maintenance drone. Preserve a genuinely transparent background.
```

