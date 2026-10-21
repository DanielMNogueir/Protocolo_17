# Protocolo 17 — beta candidata 0.2.1

Rodada de ajustes após o teste do usuário. O projeto desta publicação está na raiz do repositório: abra `project.godot` no Godot 4.7.1. Os pacotes Windows e do projeto foram gerados separadamente na pasta de trabalho local e não integram o histórico Git.

## Pedidos implementados

| Item | Resultado |
| --- | --- |
| Nomes da dificuldade | Fácil, Médio e Difícil em seleção, HUD e configurações. Chaves internas antigas preservadas para compatibilidade dos saves. |
| Retirar tiros maiores | Pulso, rajada e projéteis inimigos voltaram à escala e colisão originais. Flash da arma também voltou ao tamanho anterior. A rajada continua sendo cinco projéteis comuns. |
| Tarefa escondida na etapa 2 | O ponto da bateria estava em (940,360), dentro da imagem do gerador e fora de sua pequena base de colisão. Mudou para (940,480), na área livre à frente. A tarefa ativa ganhou identificação desenhada acima do cenário. |
| Tiros inimigos mais rápidos | Multiplicadores de velocidade de 1,35 / 1,65 / 1,95 sobre os padrões básicos. Mantidos os sinais de preparação e o bloqueio da mira durante o ataque. |
| Mais inimigos por dificuldade | Fácil: 37; Médio: 57; Difícil: 77 por campanha sem derrotas. A quantidade varia tanto na primeira leva quanto nos reforços. |

| Nível | Vida inicial | Inimigos por setor | Pulso básico do explorador |
| --- | ---: | --- | ---: |
| Fácil | 9 | 8 / 9 / 10 / 10 | 256,5 unidades/s |
| Médio | 6 | 13 / 14 / 15 / 15 | 313,5 unidades/s |
| Difícil | 5 | 18 / 19 / 20 / 20 | 370,5 unidades/s |

## Erros e inconsistências corrigidos

1. **Visibilidade não equivalia a acessibilidade:** a tarefa da bateria era acessível, mas a imagem do gerador a encobria. Reposicionamento e verificação do retângulo visual corrigem ambos os critérios.
2. **Toque curto em E era perdido:** o jogo lia apenas o estado da tecla no próximo quadro. Agora registra o pressionamento para a sincronização, mesmo se a tecla tiver sido solta entre quadros.
3. **Estado de E persistia durante o combate:** soltar E entre duas tarefas não atualizava o detector da operação. Agora a soltura é observada também durante as levas.
4. **Ataques/esquivas enfileirados em diálogo ou pausa:** entradas não podiam ser executadas imediatamente, mas eram consumidas depois. Diálogos bloqueiam esses comandos e mudanças de tela descartam ações pendentes.
5. **Avisos do mundo misturados ao HUD:** o objetivo central ganhou fundo para impedir sobreposição com placas dos equipamentos.
6. **Configurações mostravam a chave interna da dificuldade:** passaram a apresentar o nome em português e, durante uma operação, o nível do save ativo.
7. **Texto de cura incompatível com vida por setor:** tela de melhorias e descrições agora informam corretamente vida cheia no próximo setor e aumento da integridade máxima.
8. **Desvio de inimigos validava apenas um ponto adiante:** o movimento alternativo passou a verificar também a posição exata de destino, preservando colisão perto de bordas.
9. **Liberação de áudio ao sair:** jogadores de áudio são parados, seus streams são soltos e os caches são limpos na saída da árvore. Algumas execuções encerraram sem avisos, mas testes rápidos da interface e do pacote ainda registram de dois a sete objetos remanescentes de forma intermitente. A causa ainda não está totalmente resolvida.

## Partidas e depuração

Foram executadas **21 campanhas de teste com dano normal**, somando 3.657,26 segundos de simulação, cerca de 61 minutos. O controlador não altera vida, dano, posições ou invulnerabilidade para vencer. Ele usa navegação automática, mira precisa, tiros, rajada, esquivas e interações reais. Esses números não representam partidas humanas.

- 3 campanhas com combinação mista de melhorias: vitória nos três níveis, sem derrotas.
- 9 campanhas com combinações de ataque, mobilidade e defesa: 7 vitórias; 2 combinações no Difícil não concluídas dentro do limite de tentativas.
- 9 campanhas adicionais, variando direção de deslocamento, distância de combate e até oito tentativas por setor: 8 vitórias; a combinação de mobilidade no Difícil chegou ao último setor, mas não concluiu a campanha.
- Total: **18 vitórias em 21 campanhas iniciadas**, com **24 derrotas e retomadas**. Não foi observada perda dos setores anteriores ou melhorias ao reiniciar.

A última suíte de resistência **não está integralmente aprovada**: apresentou duas asserções de conclusão não atendidas pela combinação de mobilidade no Difícil. Elas correspondem a derrotas do controlador no combate, não a erro de script ou objetivo bloqueado. Não foram ocultadas nem convertidas em sucesso. Os outros níveis e combinações chegaram ao encerramento.

| Verificação | Resultado |
| --- | --- |
| Regras de dificuldade, tamanho de tiro, tarefas, saves, fases e spawns | 817 checagens aprovadas |
| Entradas reais da interface | 9 checagens aprovadas |
| Testes aleatórios em todos os setores e dificuldades | 134 checagens, 28.800 quadros e quatro derrotas naturais; sem atravessar obstáculos, dados inválidos ou quantidades de recursos fora dos limites |
| Duas baterias de campanhas por combinações | 85.738 e 101.221 quadros; resultados de conclusão descritos acima |
| Progressão isolada, com invulnerabilidade do bot | 112 checagens; oito tarefas, quatro reparos, melhorias e 57 inimigos; vitória |
| Persistência real em disco | 5 checagens aprovadas |
| Mundo e origem dos tiros | 2.269 e 963 checagens aprovadas |
| Objetivos, prólogo e interface do prólogo | 3.560, 394 e 30 checagens aprovadas |
| Apresentação dos inimigos | 251 checagens aprovadas |
| Arma e personagem renderizadas | 3.752 checagens, 24 direções, sem falhas |
| Interface em 960×540 e 1440×810 | 68 checagens; dificuldade, bateria, tarefas, melhorias, mapa, chefe e vitória |
| Pacote exportado | Recursos exportados, dificuldade, início, pular prólogo, combate, save, pausa, voltar ao início, continuar e renderização aprovados |

Somente as duas baterias de combinações e o teste aleatório já somam **215.759 quadros simulados**, sem contar a campanha inicial e outras suítes.

Evidências brutas:

- `evidencias/partidas_dano_normal_021.json`: três campanhas iniciais.
- `evidencias/endurance_021_primeira_rodada.json`: nove combinações na primeira bateria.
- `evidencias/endurance_021_estrategias_variadas.json`: nove combinações com estratégias variadas.
- `../captures/beta_021/04_bateria_visivel_960.png`: bateria acessível e visível.
- `../captures/beta_021/01_dificuldade_960.png`: nomes, quantidades e descrições atuais.
- `../captures/beta_021/10_pacote_executavel.png`: renderização do pacote exportado.

## Pendências que permanecem

- Avaliar com pessoas a combinação de mobilidade no Difícil. O teste automático não demonstrou conclusão com essa combinação; pode haver necessidade de ajuste de equilíbrio, mas as derrotas do bot não provam impossibilidade para jogadores.
- Confirmar duração, aprendizado da sincronização e leitura dos tiros menores com jogadores novos. A meta provisória de dez minutos humanos permanece sem comprovação.
- Testar a distribuição em outro computador e medir desempenho em hardware modesto.
- Trocar o motor incluído pelo modelo de exportação de release para reduzir o tamanho final.
- Continuar acompanhando os avisos intermitentes de objetos na saída de testes gráficos; a última execução do ZIP extraído registrou quatro objetos remanescentes ao encerrar, sem erro durante o jogo.

As pendências acadêmicas e de teste externo da auditoria anterior continuam válidas. Não foi adicionada nova campanha ou outro distrito nesta rodada.
