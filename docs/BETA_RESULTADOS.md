# Beta candidata 0.2 — resultado da rodada de 21/10/2026

## Entrega

Projeto Godot: `beta/Protocolo_17-main/project.godot` dentro da pasta de trabalho. Distribuição jogável: `build/Jogar.cmd`, junto do executável e do pacote PCK. Arquivos compactados em `outputs/Protocolo17_Beta_0.2_Windows.zip` e `outputs/Protocolo17_Beta_0.2_Projeto.zip`, na raiz da pasta de trabalho.

Esta é uma candidata para avaliação. Os critérios humanos abaixo ainda impedem declarar a beta validada.

## Implementado

- História, Operação e Veterano. Vida inicial de 9/6/5; pressão, antecipação, velocidade de projéteis, reforços e tolerância da sincronização variam por nível. A seleção ocorre antes do prólogo e permanece no checkpoint.
- Linhas direcionais e círculo de aviso dos ataques inimigos removidos. Preparação animada, brilho, som e exclamação continuam legíveis.
- Pulso primário: intervalo de 0,20 s para 0,145 s, cerca de 38% mais disparos por segundo. Arte do projétil ampliada em 65%, colisão de 3 para 5 unidades; origem continua no cano.
- Q ou botão direito: rajada de cinco pulsos, com dano maior e recarga de 3,8 s. Não atravessa paredes; a recarga aparece no HUD.
- Projéteis inimigos maiores; sentinelas usam leques, exploradores variam disparos por setor, unidades de investida combinam avanço e projéteis nos setores avançados.
- Chefe com três padrões e mudança de fase a 66% e 33% de vida. Surge na última leva da distribuição.
- Oito tarefas de campo: desobstrução e admissão; sincronização do gerador e bateria; amostra e escolha de filtração; abertura das redes norte e sul.
- Três levas por setor, com reforços acionados pelas tarefas. Totais sem derrotas: 29/37/45 inimigos. Reforços têm posições válidas, corpos separados e intervalo antes de atacar.
- Marcadores no mundo, mapa e minimapa; indicação de tarefa e leva; leitura do terminal bloqueada até os pré-requisitos.
- Vida restaurada integralmente ao entrar em outro setor. Morte reinicia objetivos e levas do setor atual; mantém setores e melhorias anteriores.
- Save versão 2 valida metadados antes de alterar a campanha e preserva dificuldade, tempo, tiros, rajadas, dano e mortes. Leitura de dados da versão 1 continua suportada pela simulação. A distribuição beta usa pasta própria e não importa automaticamente os arquivos da alpha.
- Pacote PCK e motor incluído para executar sem instalar o editor. Avisos de licença do motor e de bibliotecas acompanham o pacote.

## Evidências

Antes das alterações, seis suítes da versão recebida passaram: mundo, simulação, origem do tiro, objetivos, prólogo e apresentação dos inimigos. O percurso automatizado da base levou 60,73 segundos, com 17 inimigos; era um teste de progressão invulnerável.

Após as alterações:

| Verificação | Resultado |
| --- | --- |
| Regras novas, reforços, dificuldade, tarefas, saves, derrota e fases do chefe | 372 checagens aprovadas |
| Campanha e rotas com invulnerabilidade para isolar progressão | 112 checagens; 37 inimigos e oito tarefas |
| Campanhas com dano normal | Vitória nas três dificuldades, 21 checagens; sem invulnerabilidade, teleporte ou edição de dano |
| Persistência em disco | 5 checagens: gravação real, renomeação, leitura, continuar e rejeição de corrupção |
| Renderização | 59 checagens, capturas em 960×540 e 1440×810, botões dentro da tela |
| Pacote exportado com motor incluído | Aprovados: recursos exportados, dificuldade, pular prólogo, combate, save em disco, pausa, início, continuar e renderização |
| Regressão de mundo/arte/ambiente | Mundo 2269; origem dos tiros 963; objetivos 3560; prólogo 394; interface do prólogo 30; inimigos 251; animação da Lia 22; recursos da Lia 97; estação 25; áreas úmidas 3051; ambiente integrado 8294; arquitetura e luz 1886; diálogo 772; solo 446; silhuetas 102 — todos aprovados |

Partidas finais do controlador com dano normal:

| Nível | Inimigos | Mortes | Dano recebido | Tempo simulado |
| --- | ---: | ---: | ---: | ---: |
| História | 29 | 0 | 1 | 1min42,5s |
| Operação | 37 | 0 | 2 | 1min53,5s |
| Veterano | 45 | 0 | 3 | 2min15,2s |

O controlador conhece o mapa, usa navegação automática, mira precisa e desvia analisando trajetórias. Esses tempos não estimam a duração nem a dificuldade da primeira partida humana. A expansão aumentou o conteúdo, mas não comprova os 10 minutos planejados.

Capturas estão em `captures/beta/`; `10_pacote_executavel.png` foi gerada pelo PCK exportado. O relatório bruto das partidas fica em `.runtime/beta_playthrough.json` e sua cópia legível em `docs/evidencias/partidas_dano_normal.json`.

## Pendências reais para fechar a beta

1. **Duração e ritmo:** realizar primeiras partidas humanas sem orientação, cronometradas. Meta provisória de dez minutos, excluindo prólogo e menus. Se o tempo ficar curto, ampliar decisões/objetivos a partir do teste; não inserir esperas para completar o relógio.
2. **Balanceamento humano:** observar se a rajada domina os combates e se a sincronização é compreendida. O controlador terminar Veterano com pouco dano não demonstra que o nível está equilibrado para pessoas.
3. **Teste em outro PC:** executar o ZIP extraído, incluindo save/continuação, áudio, tela cheia, desempenho e controles. A máquina local usa RTX 3050 Laptop; hardware modesto ainda não foi medido.
4. **Exportação final:** instalar os modelos Windows de release do Godot 4.7.1 para substituir o motor de desenvolvimento incluído e reduzir a distribuição. O pacote atual já inicia sem abrir o editor.
5. **Memória no encerramento:** algumas verificações da interface e do pacote geram avisos de 2–5 objetos remanescentes ao encerrar o Godot. Não houve erro durante as partidas; investigar o ciclo de liberação antes do congelamento final.
6. **Revisão externa e semestre:** registrar feedback, vídeo APS 2 de 1–3 minutos, situação da APS 1, evolução por aula e datas/equipe. Essas evidências exigem participação das pessoas envolvidas.

Distritos de Resíduos e Energia como mapas completos continuam como expansão posterior. Nesta rodada não foram adicionados à campanha.

## Reproduzir

No Godot 4.7.1, abrir este `project.godot` e usar F5. Para validação sem interface: `tests/test_simulation.gd`, `tests/test_beta_rules.gd`, `tests/test_beta_playthrough.gd` e `tests/test_beta_storage.gd`, executados como scripts. `tools/review_beta.gd` requer renderer gráfico. As suítes de arquitetura, diálogo, água e comparação de imagens também exigem renderer gráfico; não executá-las com renderer dummy.
