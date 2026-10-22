# Distrito de Resíduos — direção, mapa e mecânicas

## Premissa e posição na campanha

Este é o segundo cenário da campanha, após a Operação Filtro. A coleta de Aurora envia resíduos misturados a uma instalação com esteiras travadas e biodigestores isolados. Lia recupera o fluxo de materiais e encontra, nos registros da usina, a composição do núcleo usado pela IA. A progressão prevista é **Águas → escolha de melhoria → Resíduos → escolha de melhoria → Energia**. A versão jogável atual abre a partir da conclusão de Águas e recebe a dificuldade e as melhorias já escolhidas. Salvar o progresso de Resíduos entre sessões, oferecer uma nova melhoria e seguir para Energia são passos futuros da campanha.

## Mapa e percurso

Mapa externo em visão superior, com escala e silhueta de personagens compatíveis com o restante do jogo, mas **identidade ambiental própria**. É um pátio industrial de resíduos, seco, poeirento e congestionado, sem canais, reservatórios, piso úmido ou vegetação de brejo. A área de jogo mede 2.400 × 1.500 unidades. O eixo principal é oeste → leste, com um circuito sul que permite contornar a linha de esteiras. Cada trecho de passagem deve manter pelo menos 130 unidades livres para Lia, drones e tiros. As bordas industriais têm volume visual; o centro das arenas fica relativamente calmo.

```text
OESTE / entrada da rede hídrica                     LESTE / saída para Energia
┌───────────────────┬───────────────────┬──────────────────────────┐
│ TRIAGEM AURORA    │ RECICLAGEM PRISMA │ COMPOSTAGEM ÍRIS        │
│ doca, balança     │ fornos frios,     │ biodigestores,          │
│ quatro baias      │ prensa, depósito  │ leitos vivos            │
│ M P V O           │                   │                          │
│                   │                   │                          │
│ esteira e passadiço de manutenção, com travessias e cruzamentos       │
│                   │                   │                          │
│ pátio de coleta   │ corredor de carga │ jardins filtrantes      │
└───────────────────┴───────────────────┴──────────────────────────┘
```

1. **Pátio de Triagem Aurora (x 100–790):** desembarque, aprendizagem da classificação, contêineres e um terminal central. O caminhamento abre em torno das baias; uma pilha de descarte delimita a rota sul. Risco inicial legível e poucos drones.
2. **Núcleo de Reciclagem Prisma (x 830–1580):** esteiras, prensagem e armazenamento, com travessias metálicas sobre o circuito. Duas rotas entre norte e sul permitem reposicionamento em combate. A máquina ocupa a borda, o centro permanece aberto.
3. **Jardins de Compostagem Íris (x 1620–2300):** tanques e canteiros ligados por tubos, vapor e vegetação retomando juntas. Resíduos orgânicos têm destino visível. O caminho final passa pelo biodigestor e pelo terminal de saída.

O roteiro de origem pede **quatro fases com um mini chefe final**. As quatro batidas da missão são: (1) separar os quatro materiais na Triagem; (2) liberar o corredor de sucata; (3) recuperar a prensagem no Prisma; (4) reabrir o fluxo orgânico em Íris, enfrentar a unidade coletora pesada e ativar o biodigestor. As três regiões físicas abrigam essas quatro etapas sem repetir o padrão de quatro setores de Águas.

### Camadas e colisão

- Piso de concreto **seco**, grafite e cinza quente, com pneus, pó, ferrugem, cacos e marcas laranja de carga. Nada de reflexos aquáticos ou musgo do Distrito das Águas. Lotes de detalhe são fixos no mundo; nada muda de lugar quando a câmera se move.
- Esteiras, trilhos, dutos, bocas de ventilação e placas de manutenção explicam o fluxo **coleta → separação → reciclagem/compostagem**. As esteiras são acessíveis nas travessias; bordas e máquinas possuem colisão coerente com sua base.
- Sucata e pilhas criam paredes localizadas, com contornos sólidos claros. Zonas tóxicas têm piso e brilho magenta esverdeado, produzem dano periódico e podem ser contornadas. Bloqueios interativos liberam rotas sem exigir que Lia atravesse a pilha.
- Objetivos e drones ficam acima do piso; silhuetas usam o mesmo desenho de Lia e da arma da beta. Sombras acompanham bases, respeitam profundidade e não cobrem o HUD.

## Mecânicas e objetivos

| Etapa | Ação | Feedback e falha |
| --- | --- | --- |
| Classificar | Recolher um item por vez com **E** e levar à baia correta: metal, plástico, vidro, orgânico. Pictograma, nome e cor sempre aparecem juntos. | Acerto acende a baia e avança a esteira. Erro devolve o item à origem, trava brevemente a baia e chama a atenção de drones. Nunca se perde o material. |
| Religação | Depois das quatro entregas, manter **E** no terminal Aurora. | Barras de progresso e luzes âmbar → ciano; a esteira principal se move. |
| Rota de carga | Limpar três bloqueios com **E**, sob pressão de drones de coleta. | Sucata desaparece por estágios; a linha de piso e a direção da esteira ficam visíveis. |
| Prisma | Acionar prensagem e recuperação do vidro, em duas estações, depois o terminal. | Linhas de energia e luz de serviço passam a ciano; máquina não liga antes de receber material separado. |
| Íris | Reabrir dois dutos orgânicos, depois ativar o biodigestor. | Vapor contaminado cessa e luz vegetal cresce nos leitos. |
| Saída | Neutralizar a patrulha restante e acessar o registro. | Registro revela liga metálica, polímero e vidro técnico usados no núcleo da IA. |

Vida começa cheia ao entrar no cenário. Morte reinicia apenas este distrito, incluindo puzzle, inimigos e máquinas; melhorias obtidas em Águas devem persistir quando a campanha for integrada. Os drones de coleta são os inimigos da beta com aparência e comportamento já reconhecíveis. A separação é a decisão central: combate protege o trabalho, mas não substitui a classificação.

## Linguagem visual

Preservar apenas a **escala dos personagens, acabamento da arte, legibilidade e qualidade de iluminação** do Distrito das Águas. A paleta de Resíduos é distinta: grafite, concreto seco cinza quente, pó marrom, laranja de segurança, ferrugem, metal prensado, plástico fosco, vidro pálido, matéria orgânica ocre/oliva e contaminação magenta. O ciano aparece só em telas e indicadores de Aurora. Cores de classificação são acompanhadas de ícones e texto, inclusive no HUD, para não depender só de cor. Íris concentra a pouca vegetação do mapa em leitos de composto; não há brejo nem água aparente.

Usar detalhes em grupos funcionais: parafusos em estruturas, trilhos paralelos nas esteiras, correntes perto de docas, números nas baias, sacos e fardos junto dos estoques, poeira e papéis nas juntas, solo orgânico apenas em Íris. Luz direcional constante cria sombras de contato e projeções curtas. Fontes locais âmbar indicam falha; ciano indica sistema recuperado. Perigos pulsam em magenta. Shaders usam coordenadas do mundo e atualização limitada a áreas visíveis; efeitos não incidem na interface.

## Revisão de qualidade

Capturar entrada, as quatro baias, arena Prisma e jardins Íris em 960×540 e 1440×810, com e sem HUD. Conferir: rota e próximo alvo legíveis em menos de três segundos; itens distinguíveis sem cor; pulsos e Lia em primeiro plano; obstáculos com bases honestas; nenhum salto de luz ao mover câmera; tratamento visual perceptível ao restaurar cada sistema; desempenho da animação de esteira, vapor e luz no renderer Compatibility.

## Entrega incremental

1. **Recorte jogável:** mapa, separação, terminais, drones, bloqueios, vida e reinício do distrito.
2. **Acabamento:** atlas próprio de máquinas e resíduos, animações de esteira e dutos, shader de luz e contaminação, som localizado e capturas revisadas.
3. **Campanha:** transferência de melhorias e dificuldade da beta (feita em memória), save entre distritos, tela de recompensa e ligação ao Distrito de Energia.

O recorte jogável deve ficar acessível após a vitória em Águas e como cena isolada para revisão. Este documento descreve também o alvo de campanha completo; itens da terceira etapa não são condições para avaliar o mapa atual.
