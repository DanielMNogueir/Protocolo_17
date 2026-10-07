# Distrito das Águas — remodelamento do mapa

Implementado em 07/10/2026 no projeto real:
`C:/Users/macha/Downloads/protocolo/Protocolo_17`.
Abra o `project.godot` dessa pasta no Godot e pressione F5.

## Composição aplicada

A água agora ocupa partes dos antigos pátios, com margens construídas,
vegetação aquática e tubulações que explicam sua relação com as instalações.
O concreto úmido e a paleta da primeira etapa foram mantidos. As principais
rotas têm uma faixa discreta no piso e áreas de combate desocupadas.

| Setor | Composição |
|---|---|
| Cais de captação | Canal transversal ampliado, alimentação do clarificador, área alagada a leste e reservatório ao norte alimentado por uma bomba. Duas grelhas permitem cruzar o canal. |
| Pátio de energia | Faixa alagada a oeste, retenção ao norte e drenagem vegetal ao sul com passagem de serviço. |
| Filtragem | Jardim de tratamento alagado próximo aos filtros, retenção ao norte e canal lateral com descarga. O jardim tem uma malha submersa discreta. |
| Distribuição | Margens alagadas, reservatório de retenção, drenagem ao sul e conexão do tanque ao canal transversal com uma passagem de grelha. Tubulação do coletor solar chega ao canal oriental. |

São 16 retângulos de água, incluindo alimentações conectadas, e quatro novas
travessias de serviço. Eles se somam aos reservatórios e pontes existentes.
As 827 colocações de vegetação adicional ocupam bancos, vazamentos e água rasa;
juncos, folhas flutuantes e samambaias usam a arte já existente. Há musgo,
manchas úmidas, reflexos, ondulações junto às raízes e três saídas com comportas.
Os indicadores e a intensidade das descargas respondem à restauração do setor.

Água profunda bloqueia movimento/esquiva e deixa os pulsos atravessarem.
As grelhas recortam aberturas exatas na colisão dos canais. O mapa e o minimapa
mostram essas alterações. Objetivos, equipamentos e portões existentes foram
preservados; três pontos de surgimento de inimigos foram afastados da nova água.

## Capturas reais do jogo

As imagens foram renderizadas pelo Godot no projeto acima. As comparações
abaixo mostram a primeira etapa e a composição atual, usando a mesma câmera,
posição de Lia e relógio. São vistas de revisão sem inimigos, com a simulação
atualizada para o estado correspondente do HUD.

| Vista | Primeira etapa | Mapa remodelado |
|---|---|---|
| Cais | [Antes](../../captures/mapa-remodelado/antes/02_cais_canal.png) | [Depois](../../captures/mapa-remodelado/02_cais_canal.png) |
| Energia | [Antes](../../captures/mapa-remodelado/antes/04_energia.png) | [Depois](../../captures/mapa-remodelado/04_energia.png) |
| Filtragem | [Antes](../../captures/mapa-remodelado/antes/05_filtros.png) | [Depois](../../captures/mapa-remodelado/05_filtros.png) |
| Distribuição | [Antes](../../captures/mapa-remodelado/antes/06_distribuicao.png) | [Depois](../../captures/mapa-remodelado/06_distribuicao.png) |

Mais recortes: [combate no cais](../../captures/mapa-remodelado/03_cais_combate.png),
[jardim de filtragem](../../captures/mapa-remodelado/08_jardim_filtragem.png),
[drenagem de energia](../../captures/mapa-remodelado/09_drenagem_energia.png),
[conexão da distribuição](../../captures/mapa-remodelado/10_comportas_distribuicao.png)
e [captação leste](../../captures/mapa-remodelado/11_captacao_leste.png).
Na vista de combate, a câmera foi preservada, mas Lia e três surgimentos foram
reposicionados para não começar dentro da nova água; não é um par de estados idênticos.

## Verificação

Godot 4.7.2, Compatibility, AMD Radeon RX 6600. Oito suítes passaram,
totalizando 15.626 verificações, sem falhas de asserção:

| Teste | Resultado |
|---|---|
| Mundo | 2.269 verificações; 1.097 amostras de rotas e 16 combinações de acesso/progressão |
| Água e travessias novas | 3.753 verificações; ida/volta, faixas laterais, esquiva, pulsos atravessando água e atlas |
| Integração do ambiente | 8.002 verificações; 107 bordas percorridas, 126 aproximações de bases e cobertura nas quatro direções |
| Simulação | 92 verificações; quatro sistemas restaurados, 17 inimigos derrotados, 208 disparos e 3.233 quadros do bot |
| Origem dos disparos | 963 verificações |
| Arte do ambiente | 54 verificações |
| Dados da água | 21 verificações |
| Renderização gráfica da água | 472 verificações; câmera, movimento, camadas e animação das 18 regiões do atlas (dois reservatórios e 16 trechos novos) |

Os dois testes que dependiam do mapa seco foram atualizados: a esquiva começa
em chão seguro junto ao limite oeste, e a cobertura dos perímetros verifica
ao menos dez bordas acessíveis em cada direção, já que algumas margens passaram
a ser água. Os testes continuam exercitando o movimento real da simulação.

O bot usa invulnerabilidade para isolar acesso e progressão. Inimigos, movimento,
disparos e dano aos inimigos são reais; o teste não mede dificuldade humana.
Foram produzidas e inspecionadas 11 capturas da composição atual.

A amostra de 120 quadros no cais mediu aproximadamente 8,99 ms por quadro e
976 chamadas de desenho, ante 7,32 ms/914 na primeira etapa. Água e efeitos
avançaram, com câmera/inimigos parados e VSync desativado. Isso registra o custo
local de renderização; não equivale a um teste de combate intenso nem garante
o mesmo desempenho em outras máquinas. Os dados estão nos `review.json`.

## Manutenção

`scripts/wetlands.gd` concentra água, habitats, travessias, plantas, margens,
tubulações e saídas. `world.gd` integra geometria, profundidade e pontos de
surgimento. `water_surface.gd` organiza os reservatórios em um atlas compartilhado
por linhas, mantendo a escala original e evitando uma faixa vertical excessiva.

Não foram necessários novos sprites nesta etapa. A textura de concreto criada
na primeira etapa conserva seu [prompt e proveniência](../../assets/station/wet_concrete-PROMPT.txt).
O tanque circular conserva a água incorporada em seu sprite; sua descarga externa
tem animação adicional. A imagem-conceito continua sendo uma referência artística.

As versões substituídas nesta etapa foram preservadas em
`C:/Users/macha/Downloads/protocolo-17/.runtime/map2/backup`.
As alterações do jogo foram aplicadas à pasta real, e não à cópia de trabalho.
