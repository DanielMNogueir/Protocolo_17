# Distrito de Energia — Operação Corrente

## Intenção

Energia é a última fase antes do confronto final. A IA desligou o distrito inteiro e usa a rede para alcançar os outros bairros, então **luz é segurança**.

- **Apagão:** a fase começa no escuro. A Lia carrega uma luz curta e uma lanterna na direção da mira.
- **Drones no escuro:** aparecem pelo brilho magenta do núcleo.
- **Restauração:** cada instalação restaurada acende o seu setor, abre o próximo portão e muda a música do clima "blackout" para "grid".

Cada instalação ensina uma mecânica nova. O chefe final reutiliza essas três mecânicas (ver `nucleo-aurora.md`).

A narrativa fecha os fios abertos em Águas e Resíduos:

- O **registro de Beatrix** chega em três fragmentos, um por instalação, com o retrato holográfico da Beatrix digital.
- O terceiro fragmento revela que a "origem do comando" redigida era a própria rede.
- Os materiais do núcleo, vindos de Resíduos, explicam por que a IA está aqui.
- Major 0 é o único nome do rádio; "COMANDO" deixou de existir.

ODS 7 — energia limpa e acessível.

## Implantação

```text
                         NORTE
┌──────────────────────┬─────────┬──────────────────────────┐
│ CENTRAL SOLAR AURORA │ telhado │ TORRE DE DISTRIBUIÇÃO     │
│ coletor, 3 fileiras  ├─────────┤ NORTE: treliça, relés R1  │
│ de painéis, 3 espe-  ║CORREDOR ║ R2 R3, transformador,     │
│ lhos, sala, terminal │⚡ cabos ⚡│ bobinas, pilones, terminal│
│      portaria        ├─────────┤      portão sul           │
╞══════════════════════╧═════════╧══════════════════════════╡
│          AVENIDA DE SERVIÇO (postes, faixa, valeta de cabo)│
╞══════════════════════╤═════════╤══════════╤═══════════════╡
│ PÁTIO DE MANUTENÇÃO  │ telhado │  portão  │ BANCO DE      │
│ gerador, oficina,    │         │ 3 bancos + 3 consoles    │
│ carretéis, contêiner │         │ anel de recarga  ◯   ║ELEV│
│ (início da Lia)      │         │ pilares              ║    │
└──────────────────────┴─────────┴──────────────────────────┘
```

- **Medidas:** mapa de 1.920 × 1.280 unidades. A geometria é medida sobre a placa de 1.536 × 1.024, em escala 1,25, como em Resíduos.
- **Arte:** quatro setores pintados de 1.536 × 1.024, cada um em duas versões, apagado e aceso. O jogo cruza as duas por instalação restaurada.
- **Sem arte pintada:** `power_art.gd` desenha uma placa provisória com a mesma geometria. As placas de enquadramento ficam em `assets/power/reference/`, e os prompts em `assets/power/PROMPTS.md`.

| Portão | Abre na etapa | Motivo |
| --- | --- | --- |
| Corredor de cabos | 1 | Central Solar restaurada |
| Portão sul da torre | 2 | Torre Norte restaurada |
| Portão do banco de baterias | 2 | Torre Norte restaurada |
| Porta do elevador | 3 | Banco de Baterias carregado |

## Instalações e mecânicas

| Instalação | Mecânica | O que o jogador faz | Erro |
| --- | --- | --- | --- |
| Central Solar Aurora | **Espelhos solares** e **Sobrecarga v2** | Atira nos três espelhos (cada pulso gira 45°) até o feixe ir do sol ao coletor. Vence os drones. No terminal, aperta E três vezes com a agulha na faixa verde; a faixa muda de lugar e encolhe a cada acerto | Apertar fora da faixa descarrega um arco (dano elétrico), zera a sequência e trava o console por 3 s |
| Torre de Distribuição Norte | **Pilones de arco**, **relés** e **Sobrecarga em surto** | Atravessa o corredor entre as descargas rítmicas, com aviso visual e sonoro; a esquiva é segura. Destrói o transformador que dá escudo aos drones. Energiza os três relés com tiros dentro da janela. Estabiliza a Sobrecarga, cuja agulha varia de velocidade | Arco ativo dá dano elétrico. Os arcos também ferem drones, então atrair drones é tática. Relé que esvazia precisa de novo tiro |
| Banco de Baterias Central | **Segurar a carga** | Fica no anel para carregar a reserva. Quando uma célula fica vermelha, corre ao console certo e aperta E para aliviá-la. Quatro ondas de drones chegam por limiares de carga | Célula que estoura descarrega no anel e tira 10% da carga |
| Elevador do Núcleo | Saída | Segura E por 1,1 s | — |

Ao concluir o Banco, um **EMP** devolve à rede todos os drones do setor. A cena do elevador encerra a fase e a vitória salva `energy_completed`.

## Inimigos

| Inimigo | Papel | Arte |
| --- | --- | --- |
| Explorador / Sentinela | Mesmo comportamento de Águas, com a pressão da dificuldade escolhida | `assets/enemies` |
| Faísca | Rápida. Avisa com uma linha de mira e investe em linha reta, deixando um rastro elétrico que fere por 1,3 s | Provisória; prompt 12 |
| Bobina | Torreta fixa que dispara dois orbes. Duas bobinas próximas formam um arco pulsante que bloqueia tiros e fere a Lia; destruir uma desfaz o arco | Provisória; prompt 13 |
| Transformador corrompido | Estático. Dá escudo hexagonal aos drones da mesma instalação em raio de 260. Tem prioridade | Provisória; atlas, prompt 10 |

A dificuldade escala a velocidade dos tiros (`HOSTILE_SPEED`), a cadência (`PRESSURE`), o aviso de disparo (`WINDUP`), o ritmo do corredor, a janela dos relés, a duração e o surto das células e o número de drones extras.

## Módulos (oficina depois de Resíduos)

| Módulo | Efeito em Energia |
| --- | --- |
| Isolamento | Metade do dano elétrico: arcos, descargas, rastros e orbes |
| Sobrecarga controlada | Janelas da Sobrecarga e dos relés 30% maiores, surto das células 30% mais lento |
| Pulso condutor | Cada pulso que acerta salta para outro drone a até 150 unidades |

Os módulos de Águas continuam valendo. A carga é compartilhada por `scripts/campaign_loadout.gd`.

## Arquivos

| Arquivo | Papel |
| --- | --- |
| `scenes/power.tscn` | Cena da fase |
| `scripts/power_scenario.gd` | Laço, estados, etapas, inimigos, tiros, luz e efeitos |
| `scripts/power_map.gd` | Piso, colisões nomeadas, portões, A*, posições |
| `scripts/power_mechanics.gd` | Regras puras: Sobrecarga, espelhos, arcos, relés e baterias |
| `scripts/power_art.gd` | Placa provisória, adereços e raios procedurais |
| `scripts/power_hud.gd` | HUD, medidor da Sobrecarga, painéis de sistema, mapa e telas |
| `scripts/power_lighting.gdshader` | Escuridão, lanterna, luzes dinâmicas e setores acesos |
| `scripts/power_story.gd` | Falas de Major 0, Lia, IA e Beatrix |
| `tools/review_power.gd` | Capturas em `captures/energia/` e placas de referência |

## Testes

| Teste | Cobertura |
| --- | --- |
| `test_power_mechanics` | Regras puras, 57 verificações |
| `test_power` | Missão completa a pé, sem teleporte: espelhos por tiro, Sobrecarga errada (dano e trava), arcos, escudo, bobinas, relés na janela, anel com alívio de células a pé, elevador e save. Também os três módulos, o rastro da Faísca e a derrota |
| `test_power_collision` | Varredura de todas as formas em todas as etapas e 1.800 ticks de IA real por instalação |
| `test_campaign_flow` | Águas → Resíduos → oficina → Energia → vitória → seleção de distritos, em perfil descartável |
| `test_power_smoke` | Cena com física real |
