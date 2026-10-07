# Objetivos — equipamentos de missão

Aplicado ao projeto principal em `C:/Users/macha/Downloads/protocolo/Protocolo_17`.

Os quatro pontos de reparo agora pertencem visualmente a equipamentos reconhecíveis:
bomba de admissão, controle da rede elétrica, núcleo dos filtros e central de vazão.
Captação, filtragem e distribuição reutilizam as ilustrações aprovadas do atlas
`assets/station/totems_atlas.png`, com escala maior e pés ancorados no chão.
O controle da energia é um gabinete desenhado em pixel art, ligado ao gerador.
Nenhum PNG foi alterado ou gerado nesta etapa.

Uma plataforma de manutenção com grelha, cabos e marcações conecta cada máquina
ao ponto de interação. As placas identificam o setor e mostram avaria, disponibilidade,
progresso real do reparo e funcionamento. Indicadores vermelhos, âmbar e ciano
complementam textos e símbolos próprios, sem depender somente da cor.
Os círculos genéricos de interação foram substituídos por marcações no piso.

As três máquinas externas receberam colisões proporcionais às bases ampliadas;
o gabinete de energia conserva a colisão declarada na cena. Os quatro pontos de
interação, o raio de reparo, rotas, surgimentos, combate e regras de progressão
permanecem. As reservas de vegetação consideram as novas bases.

## Capturas reais

São 16 vistas em `captures/objetivos`, com quatro estados por equipamento.
As versões anteriores ficam em `captures/objetivos/antes`, com a mesma câmera,
posição de Lia e relógio. Disponibilidade é obtida pela simulação após remover
inimigos na preparação das vistas. A vista de reparo fixa o progresso em 62%;
a vista restaurada usa o método de ativação real. Essas capturas demonstram
apresentação; não são partidas completas ou imagens-conceito.

| Setor | Antes | Disponível | Reparando | Restaurado |
|---|---|---|---|---|
| Captação | [Abrir](../../captures/objetivos/antes/01_disponivel.png) | [Abrir](../../captures/objetivos/01_disponivel.png) | [Abrir](../../captures/objetivos/01_reparando.png) | [Abrir](../../captures/objetivos/01_restaurado.png) |
| Energia | [Abrir](../../captures/objetivos/antes/02_disponivel.png) | [Abrir](../../captures/objetivos/02_disponivel.png) | [Abrir](../../captures/objetivos/02_reparando.png) | [Abrir](../../captures/objetivos/02_restaurado.png) |
| Filtragem | [Abrir](../../captures/objetivos/antes/03_disponivel.png) | [Abrir](../../captures/objetivos/03_disponivel.png) | [Abrir](../../captures/objetivos/03_reparando.png) | [Abrir](../../captures/objetivos/03_restaurado.png) |
| Distribuição | [Abrir](../../captures/objetivos/antes/04_disponivel.png) | [Abrir](../../captures/objetivos/04_disponivel.png) | [Abrir](../../captures/objetivos/04_reparando.png) | [Abrir](../../captures/objetivos/04_restaurado.png) |

## Manutenção e verificação

`scripts/objective_visual.gd` compartilha posicionamento, desenho, símbolos e
estados dos quatro objetivos. `world.gd` usa esses dados para colisão e profundidade.
`main.gd` passa disponibilidade e progresso da simulação. `objective_panel.gd`
reproduz o gabinete na cena nativa de energia, com o mesmo ponto de origem.

Execute `godot --headless --path . --script tests/test_objectives.gd` para verificar
aproximações reais, colisões, disparos, reparos e sincronização com a cena de energia.
`tools/review_objectives.gd` produz as 16 capturas; `P17_OBJECTIVE_OUTPUT` escolhe
a pasta de saída. Execute também as suítes de mundo, simulação e integração.

O bot da campanha mantém invulnerabilidade para verificar acesso e progressão;
não mede dificuldade humana. A revisão foi realizada com Godot 4.7.2,
Compatibility, AMD Radeon RX 6600. O ambiente restrito impede o cache de shaders
em `user://`, sem impedir a renderização das capturas.

As nove suítes abaixo passaram novamente no projeto principal após a aplicação,
totalizando 19.337 verificações, sem falhas de asserção:

| Suíte | Verificações |
|---|---:|
| Objetivos: aproximação, colisões, reparos e cena nativa | 3.560 |
| Mundo e rotas | 2.269 |
| Campanha: quatro sistemas e 17 inimigos | 92 |
| Integração do ambiente | 8.172 |
| Estação de energia | 25 |
| Arte do ambiente | 54 |
| Água, plantas e travessias | 3.753 |
| Solo e poças | 449 |
| Origem dos disparos | 963 |

Os pontos de reparo têm respectivamente 10, 4, 8 e 7 aproximações desobstruídas
na amostragem de 12 direções. A energia fica próxima ao gerador, que ocupa
algumas aproximações. As rotas existentes permanecem livres.

Backups dos arquivos substituídos ficam em
`C:/Users/macha/Downloads/protocolo-17/.runtime/objectives4/backup`.
