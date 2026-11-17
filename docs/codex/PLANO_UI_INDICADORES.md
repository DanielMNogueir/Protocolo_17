# Plano para o Codex: indicadores de objetivo e polimento da UI

> **Para quem é:** o Codex. Este plano complementa [`PLANO_FASE_FINAL.md`](PLANO_FASE_FINAL.md).
> **Pedido do Luiz:** "quero que os indicadores como seta mostrando onde é o próximo objetivo fiquem mais evidentes em todos os cenários, do jogo como um todo. Não são apenas gamers que vão jogar. Aplicar boas práticas na UI do jogo e dar uma polida nela."
> **Qual documento vence:** em UI, HUD, setas, prompts e tamanhos de texto, vale este. Nas decisões de jogo, vale o `PLANO_FASE_FINAL.md`.
> **Exceção em Energia:** aqui pode mudar só a **apresentação** (seta, farol, prompts, fontes, painéis). Mecânicas, números, tempos, colisão e a rota de `guidance_point()` continuam iguais.

### Decisões em aberto (confirmar com o Luiz; até lá, use o valor indicado)

| Decisão | Valor provisório |
|---|---|
| Intensidade padrão do guia | `FORTE` (seção 5) |
| Dica "SIGA A SETA DOURADA" na primeira entrada de cada distrito | sim, uma vez por save de configurações |
| Caminho pontilhado no chão | nível 2: faça depois do nível 1 e ligue só na intensidade `FORTE` |
| Opção de texto maior (125%) | nível 2 |

**Nível 1 é obrigatório antes da apresentação:** seções 1 a 4, 6 e 7. **Nível 2 vem depois:** caminho pontilhado, texto 125% e as opções da seção 5 além da intensidade.

---

## 0. Princípios: quem nunca jogou precisa entender em 1 segundo

Em qualquer tela de jogo, o jogador responde três perguntas sem ler nada longo:

1. **Para onde vou?** A seta grande junto da Lia e o farol no destino. Se o destino estiver fora da tela, um marcador na borda com o nome do lugar e a distância.
2. **O que aperto?** Sempre uma tecla desenhada (`FieldHUD.keycap`) seguida de um verbo: `[E] ABRIR A COMPORTA`. Nunca só "E" solto.
3. **Quanto falta?** O painel de objetivo mostra o progresso (pips ou "2/3").

Regras que valem para toda a UI:

- **Forma, cor e texto juntos.** Nunca use só cor para dizer algo, pois parte do público é daltônica. O código visual do jogo:

  | Significado | Cor | Forma |
  |---|---|---|
  | Objetivo, para onde ir | dourado `GOLD` | divisa dupla (seta) e losango |
  | Interagir aqui | ciano `CYAN` | anel no chão e tecla |
  | Perigo, aviso de ataque | vermelho `RED` | triângulo com "!" |
  | IA, inimigo, Major 0 | magenta | hexágono, ou o brilho do núcleo |
  | Concluído | ciano | ✓ |

- **Texto do objetivo:** verbo no imperativo mais o lugar, com no máximo 6 palavras. Por exemplo, "VÁ ATÉ A ESTAÇÃO NORTE" e não "→ NORTE".
- **Posições fixas** em todas as fases:
  - objetivo no topo à direita;
  - prompt de ação embaixo, no centro;
  - mapa embaixo, à direita;
  - vida no topo, à esquerda.
- **O guia nunca some em combate.** Ele pode ficar 30% mais transparente enquanto houver inimigo a menos de 200 px, mas continua visível.
- **Movimento calmo:** pulsos de 1 a 1,5 Hz. Nada pisca acima de 3 Hz, por segurança fotossensível.
- **Texto legível** em 960×540 (tabela da seção 3).

---

## 1. Um módulo de guia único: `scripts/objective_guide.gd`

Hoje há quatro setas diferentes. Substitua todas por este módulo:

| Onde | Como é hoje |
|---|---|
| `main.gd::_draw_guidance` (Águas) | divisa com braços de 9 px, linha de 2 px, alfa de 0,65 a 0,8, a 62 px da Lia, some a menos de 95 px |
| `residue_scenario.gd` (perto da linha 759) | igual |
| `power_scenario.gd` (perto da linha 1203) | igual |
| `prologue_presentation.gd::_draw_navigation` | marcador num painel de 40×40 com "OBJETIVO" a 8 px; já prende o marcador numa área segura |

**Faça o módulo no começo da etapa 1 do `PLANO_FASE_FINAL.md`.** Assim a fase final já nasce com ele. Trocar as setas das fases antigas é a etapa 2 (seção 7).

### 1.1 Interface

```gdscript
class_name P17ObjectiveGuide
extends RefCounted
## Pure guidance state shared by every scene. The scene feeds world positions
## and a world->screen transform; draw() paints arrow, beacon and edge marker.

const NEAR := 70.0            # world px: closer than this = arrived, arrow hides
const ARROW_OFFSET := 56.0    # world px from Lia's feet
const PX_PER_METER := 36.0    # Lia (~64 px) is ~1.75 m
const IDLE_TIME := 8.0        # s without getting 40 px closer -> re-highlight
const PROGRESS_STEP := 40.0

var mode := "hidden"          # hidden | arrow | edge | arrived
var place := ""               # short place name, e.g. "ESTAÇÃO NORTE"
var idle := 0.0
var highlight := 0.0          # 0..1, decays after a re-highlight

func update(delta: float, lia: Vector2, next_point: Vector2, target: Vector2,
		world_to_screen: Transform2D, safe: Rect2, active: bool, place_name: String) -> void
func arrow_direction() -> Vector2      # from Lia to next_point (follows the route)
func edge_position() -> Vector2        # screen position clamped inside `safe`
func distance_meters() -> int
func draw_world(c: CanvasItem, time: float, intensity: int) -> void   # arrow + beacon, world space
func draw_screen(c: CanvasItem, time: float, intensity: int) -> void  # edge marker + labels, HUD space
```

- `next_point` é o próximo ponto da rota A*, que já existe em cada cena, e define a direção da seta. Assim ela vira nas pontes e portões em vez de apontar para a parede.
- `target` é o destino final e é onde fica o farol.
- `world_to_screen`:
  - nas cenas com camada transformada (Resíduos, Energia, Núcleo), use `get_canvas_transform()` da camada de efeitos;
  - no prólogo, monte `Transform2D(0, offset)` com `offset = (size * 0.5 - prologue_camera).round()`, que é a mesma conta de hoje.
- `active = false` em diálogos, pausa, mapa e cutscenes, e o módulo não desenha nada.

### 1.2 Seta junto da Lia (modo `arrow`)

- **Forma:** divisa dupla, ou seja, duas setas "›" encaixadas, 10 px uma atrás da outra.
  - Braços de 16 px, traço de 4 px em `GOLD`, contorno de 2 px em `INK` por baixo.
  - Alfa de 0,95, ou 0,65 com inimigo a menos de 200 px.
- **Posição:** `lia + direction * ARROW_OFFSET + Vector2(0, 18)`, que é a altura dos pés.
- **Animação:** desliza 5 px na direção do alvo e volta, a 1,2 Hz.
- **Some** em diálogo ou quando `distance(lia, target) < NEAR`. Nesse caso o modo vira `arrived`, e o anel de interação da cena assume.

### 1.3 Farol no destino (sempre que `mode != hidden`)

É o que faz o jogador "bater o olho e saber onde ir", mesmo de longe:

- **Coluna de luz:** 16 px de largura e 140 px de altura, subindo do ponto do alvo, com gradiente `GOLD` de alfa 0,35 embaixo até 0 no topo.
- **Losango:** 14×18 px, flutuando 80 px acima do alvo e subindo e descendo 4 px a 1 Hz, com contorno `INK`.
- **Anel no chão:** elipse de 34×17 px que pulsa de 0,6 a 1,0 de alfa.
- **Rótulo:** `place` dentro de um `FieldHUD.panel` pequeno acima do losango, a 11 px, visível quando o alvo está na tela e a mais de `NEAR`.
- **Camada:** desenhe **por cima** da sobreposição de luz e escuridão. Em Energia e Resíduos isso é a camada `_fx`, que é adicionada depois de `_light` em `_setup_layers`, então a escuridão não apaga o guia. Em Águas, desenhe depois dos objetos altos do cenário.

### 1.4 Marcador de borda (modo `edge`, quando o alvo está fora da tela)

- Círculo de 22 px de raio, com painel `INK` a 0,94 e borda `GOLD` de 2 px. Dentro dele, um triângulo de 12 px apontando para o alvo.
- Ao lado, do lado de dentro da tela, um painel com duas linhas: `place` a 11 px e `"%d m" % distance_meters()` a 10 px.
- A posição é a interseção da reta Lia → alvo (em tela) com a área segura, recuada 26 px para dentro.
- A seta junto da Lia continua aparecendo no modo `edge`.

### 1.5 Área segura (o marcador nunca fica embaixo de um painel)

Crie `FieldHUD.guide_safe_rect(size: Vector2, dialogue_top: float = -1.0) -> Rect2`:

- Margem lateral de 24 px.
- O topo fica abaixo dos painéis de cima: o maior `end.y` entre `CAMPAIGN_RECT` (depois da seção 3) e o painel de objetivo, mais 12 px.
- A base fica acima da caixa de prompt (`size.y - 118`, seção 4) e do mapa pequeno (`size.y - 160`, que ocupa só a faixa direita). Use o menor dos dois, menos 12 px.
- Com diálogo aberto, a base é `dialogue_top - 24`, como o prólogo já faz.
- Os retângulos dos painéis viram constantes em `field_hud.gd`. Hoje `power_hud.gd` e `residue_hud.gd` repetem `Rect2(333, 28, 78, 23)` e `Rect2(419, 28, 107, 23)`; leia de `FieldHUD.MAP_BUTTON` e `FieldHUD.PAUSE_BUTTON`.

### 1.6 Realce por inatividade

Se em `IDLE_TIME` segundos a distância até o alvo não cair pelo menos `PROGRESS_STEP`, sem combate a menos de 200 px:

- `highlight = 1.0`, decaindo em 1,5 s;
- uma onda dourada sai da Lia na direção do alvo (arco de 40° crescendo até 140 px);
- o painel de objetivo pisca a borda em `GOLD` duas vezes;
- som curto `guide_ping` (seção 6).

O realce zera ao se aproximar 40 px. Não repita antes de 12 s.

### 1.7 Nome do lugar

Cada cena entrega um nome curto (`place`), sempre igual ao que aparece no mapa (M):

- **Prólogo:** crie `P17Prologue.PLACE_NAMES`, alinhado com `TARGETS`, com nomes como "BANCADA", "TERMINAL" e "PORTA DO LABORATÓRIO". Use os mesmos objetos que o texto do passo já cita.
- **Águas:** nome do setor ou da tarefa (`sector_operation.label()`).
- **Resíduos e Energia:** derivado de `objective_label()`, sem o verbo.
- **Núcleo:** tabela da seção 9 do plano final.

---

## 2. Painel de objetivo (`FieldHUD.mission`)

- **Linha de detalhe:** hoje começa com um glifo de texto (`_direction()`, "→ ↘ ↓…") a 11 px. Troque por uma **seta desenhada** de 14 px, girada na direção do alvo, na mesma cor e forma da seta do mundo. Depois vem o texto do objetivo a 12 px. No modo `arrived`, a seta vira um anel ciano com a tecla.
- **Painel:** passa de 330×120 para 330×132.
- **Status:** 9 → 10 px.
- **Pips:** o atual pisca devagar (1 Hz). Os concluídos levam ✓.

---

## 3. Tamanhos de texto e painéis (960×540)

**Piso:**

- 10 px para qualquer texto que o jogador precise ler para jogar;
- 9 px para rótulos decorativos;
- nada abaixo de 9.

Hoje há textos de 7 e 8 px.

| Onde | Hoje | Novo | Ajuste de layout |
|---|---|---|---|
| `vital`: "P17 / AGENTE DE RECUPERAÇÃO" | 8 | 10 | — |
| `abilities`: linha "PULSO: MOUSE / ESPAÇO…" | 8 | 10 | se não couber, quebre em duas linhas: "PULSO: MOUSE / ESPAÇO" e "RAJADA: BOTÃO DIREITO" |
| `navigation`: título e subtítulo | 9 e 8 | 10 e 10 | painel de 220×66 → 220×72 |
| `campaign`: cabeçalho | 8 | 10 | `CAMPAIGN_RECT` (320, 88, 220, 56) → (320, 96, 220, 62) |
| `campaign`: nomes dos distritos | 7 | 9 | nós a 52 px: use `fit`; se "RESÍDUOS" cortar, alargue o painel para 236 e mova x para 312 |
| Checklist de tarefas (`field_hud.gd`, perto da linha 188) | 7 | 9 | — |
| Contagem de recarga (perto da linha 202) | 8 | 10 | — |
| Prompts (`_prompt`) | 11 | 13 | seção 4 |
| Diálogo | — | não mexer | o painel de diálogo já está aprovado |

**Contraste:** `MUTED`, `WHITE`, `GOLD` e `CYAN` sobre `INK` já passam de 4,5:1. O problema de hoje é o tamanho, não a cor. Não escreva texto sobre o cenário sem painel.

Confira cada ajuste nas capturas da seção 6. Nenhum texto pode ser cortado por `fit` no meio de uma palavra importante.

---

## 4. Prompts de ação e interação

Crie `FieldHUD.prompt(c, size, key: String, verb: String, color: Color, progress: float = -1.0)` e use-o no lugar de `_prompt` em `residue_hud.gd`, `power_hud.gd`, no prólogo e no Núcleo:

- caixa de 480×52 centrada, com o topo em `size.y - 118`;
- `keycap` de 30×22 à esquerda e verbo a 13 px;
- "SEGURE" como texto antes da tecla quando for segurar: `SEGURE [E]  SUBIR AO NÚCLEO AURORA`;
- barra de progresso de segurar dentro da caixa, embaixo, com 4 px de altura;
- mesma posição em todas as fases.

**No mundo**, sobre o objeto interagível (Energia hoje desenha um anel de raio 46 e um "E" a 17 px):

- anel ciano no chão, elipse de 46×23, alfa de 0,64 a 0,9 pulsando a 1,2 Hz;
- uma tecla desenhada com `FieldHUD.keycap(c, "E", Rect2(...))`, de 22×18, 52 px acima do objeto, no lugar da letra solta.

---

## 5. Opções (`user://settings.cfg`, tela CONFIGURAÇÕES em `main.gd`)

| Chave | Valores | Padrão | Nível |
|---|---|---|---|
| `interface/guide` | `FORTE` (tudo da seção 1), `NORMAL` (sem coluna de luz e sem realce por inatividade), `MÍNIMA` (só a seta junto da Lia) | `FORTE` | 1 |
| `interface/text_scale` | 100%, 125% (multiplica os tamanhos de `FieldHUD.text`) | 100% | 2 |
| `interface/guide_path` | ligado ou desligado: pontos de 3 px a cada 28 px nos próximos 6 pontos da rota, sumindo aos poucos | ligado em `FORTE` | 2 |

Leia as opções uma vez ao abrir cada cena e passe a intensidade para `draw_world` e `draw_screen`. As opções seguem o padrão de `difficulty` e `muted`, que já são salvas em `main.gd` (perto das linhas 599 a 608).

---

## 6. Primeira vez, pausa, mapa e som

- **Dica da seta:** na primeira entrada em Águas, Resíduos, Energia e Núcleo, aparece por 6 s um balão junto da seta: "SIGA A SETA DOURADA". Ele não pausa o jogo e some ao andar 120 px. Grave `tutorial/arrow_<distrito> = true` em `settings.cfg`.
- **Pausa (ESC):** mostre "OBJETIVO ATUAL" com o texto completo do painel e o nome do lugar. Quem se perdeu encontra ali.
- **Mapa (M):** o alvo aparece com o mesmo losango dourado e o nome do lugar. A Lia aparece como seta na direção em que está olhando. Inclua uma legenda curta: dourado = objetivo, ciano = concluído, magenta = IA.
- **Som `guide_ping`:** dois tons curtos e suaves, na síntese de `audio.gd`, usados no realce por inatividade e quando um objetivo novo aparece. Volume baixo; respeita `muted`.

---

## 7. Aplicação por cena

| Cena | Arquivo que desenha hoje | Próximo ponto (`next_point`) | Destino (`target`) | Observação |
|---|---|---|---|---|
| Prólogo (laboratório) | `prologue_presentation.gd::_draw_navigation` | o próprio `TARGETS[step]`, porque o laboratório não tem rota | `TARGETS[step]` | transformação manual (1.1); `PLACE_NAMES` novo |
| Águas | `main.gd::_draw_guidance` e `_draw_operation_beacon` | `guidance.next_point(sim)` | `guidance.objective(sim)` | o farol da seção 1.3 substitui `_draw_operation_beacon`, que fica só com o rótulo "n / TAREFA" |
| Resíduos | `residue_scenario.gd` (camada `_fx`), `residue_hud.gd` | `guidance_point()` | `objective_point()` | `_direction()` do HUD vira a seta desenhada (seção 2) |
| Energia | `power_scenario.gd` (camada `_fx`), `power_hud.gd` | `guidance_point()` | `objective_point()` | **só apresentação**: não mexa em `_update_guidance` nem em `guidance_point` |
| Núcleo (novo) | `core_scenario.gd`, `core_hud.gd` | rota da arena | seção 9 do plano final | nasce com o módulo |

**Ordem:**

1. Crie o módulo e o teste (etapa 1 do plano final), e use-o no Núcleo.
2. Depois que o jogo inteiro estiver jogável, na etapa 2:
   - troque as setas do prólogo, de Águas, de Resíduos e de Energia;
   - faça a passagem de fontes (seção 3);
   - unifique os prompts (seção 4);
   - aplique as opções e a dica (seções 5 e 6).

Commite a etapa 2 separada: "feat: guia de objetivo único e UI legível".

---

## 8. Testes e capturas

**`tests/test_objective_guide.gd`** (headless, lógica pura): imprime `OBJECTIVE_GUIDE_OK`.

- A menos de `NEAR`, o modo é `arrived` e a seta não aparece.
- A direção da seta segue `next_point`, não `target`. Teste com um alvo atrás de uma parede.
- Com o alvo fora da tela, o modo é `edge`, a posição fica dentro de `guide_safe_rect`, e isso vale em 960×540 e 1440×810.
- O marcador de borda nunca cai dentro de `MAP_BUTTON`, `PAUSE_BUTTON`, `CAMPAIGN_RECT`, do painel de objetivo, do painel de vida, das habilidades, do prompt ou do mapa pequeno. Varra 72 ângulos.
- O realce dispara após 8 s sem progresso, zera ao se aproximar 40 px e não repete antes de 12 s.
- `active = false` deixa o modo `hidden`.
- `distance_meters()` usa `PX_PER_METER`.

**Capturas:** estenda `tools/review_hud.gd`, que precisa de renderizador e roda sem `--headless`.

- Para cada cena, gere duas capturas: alvo na tela e alvo fora da tela.
- Gere tudo em 960×540 e em 1440×810, dentro de `captures/ui/`.
- Gere também uma captura de Energia no apagão, para provar que o farol aparece por cima da escuridão.
- Olhe cada captura e confirme:
  - a seta e o farol se veem de primeira;
  - nenhum texto está cortado ou abaixo de 9 px;
  - nada ficou embaixo de outro painel.

**Regressão:** `test_prologue`, `test_prologue_rendering`, `test_prologue_shell`, `test_water_rendering`, `test_water_layout`, `test_objectives`, `test_residues`, `test_residue_presentation`, `test_power`, `test_power_smoke`, `test_campaign_flow`, `test_beta_playthrough`. As falhas antigas da seção 0 do plano final continuam iguais.

**Teste com quem não joga** (o Luiz organiza): uma pessoa que não joga videogame joga 5 minutos de cada distrito sem explicação. Anote onde ela parou sem saber o que fazer.

- **Meta:** nunca mais que 10 s sem saber para onde ir.
- Se ela parar, ajuste o texto do objetivo ou o nome do lugar daquele trecho.

---

## 9. Lista de aceite da UI

- [ ] As quatro setas antigas foram removidas; todas as cenas usam `P17ObjectiveGuide`.
- [ ] Em toda cena jogável, com o alvo na tela, aparecem a seta junto da Lia, o farol com coluna de luz e o nome do lugar.
- [ ] Com o alvo fora da tela, o marcador de borda mostra o lugar e a distância, sem ficar embaixo de nenhum painel.
- [ ] O guia aparece por cima da escuridão de Energia e do Núcleo.
- [ ] Nenhum texto de jogo abaixo de 9 px; tudo que é necessário para jogar tem 10 px ou mais.
- [ ] Todo prompt tem tecla desenhada mais verbo, na mesma posição em todas as fases.
- [ ] A opção `interface/guide` funciona nos três níveis e é salva.
- [ ] A pausa mostra o objetivo atual; o mapa mostra o alvo com o mesmo losango.
- [ ] Energia joga exatamente como antes: `test_power` e `test_power_smoke` passam sem mudar números.
- [ ] Capturas de `captures/ui/` revisadas e teste com quem não joga feito.
