# Distrito das Águas — primeira implementação

Registro histórico da primeira etapa. A composição atual dos quatro setores,
as capturas e os resultados novos estão em [remodelamento do mapa](remodelamento-mapa.md).

## Entrega

O destino do remodelamento é `C:/Users/macha/Downloads/protocolo/Protocolo_17`.
O trabalho foi inicialmente desenvolvido e testado em uma cópia em
`C:/Users/macha/Downloads/protocolo-17` e transferido para o projeto correto após
o usuário esclarecer o destino. Os arquivos substituídos foram preservados na
pasta `.runtime/destino-original-backup-20261007` da cópia de trabalho.

Abra `C:/Users/macha/Downloads/protocolo/Protocolo_17/project.godot` no Godot e pressione F5.

## O que mudou

- Piso bege substituído por concreto úmido cinza azulado, com tintas discretamente
  diferentes para captação, energia, filtragem e distribuição.
- Poças rasas com reflexos e manchas de musgo distribuem a umidade pelo chão.
  Essas marcas e a vegetação decorativa não acrescentam colisões.
- 777 colocações adicionais de vegetação formam grupos nas margens e perto de
  vazamentos, saídas e reservatórios. As rotas, objetivos, bases dos equipamentos,
  entradas dos inimigos e acessos às novas travessias possuem áreas reservadas.
- Plantas adicionais participam da ordenação por contato com o chão, junto de Lia
  e dos demais elementos elevados. As sombras e o musgo ficam abaixo dos atores.
- Um canal atravessa o cais até as águas externas. Um segundo trecho recebe a
  descarga ilustrada do clarificador e se liga ao canal principal.
- Duas travessias de grelha conectam as plataformas. A travessia principal atende
  a rota existente; a segunda está a oeste do tanque, com aproximação livre.
- Canais abertos bloqueiam movimento e esquiva, mas permitem disparos. Máquinas,
  bases, limites externos e portões continuam bloqueando os tiros.
- O mapa e o minimapa mostram canais e travessias.
- Água tem uma paleta mais turquesa. A descarga do cais ganha movimento mais
  rápido após a restauração da captação.

O atlas da água mantém os reservatórios existentes e inclui os dois novos trechos,
preservando a escala de amostragem. Os dados de vegetação, poças e geometria são
preparados uma vez; o desenho seleciona elementos conforme a câmera.

## Capturas reais

Cada comparação usa a mesma câmera, posição de Lia, relógio e estado da simulação.
As vistas sem inimigos passam a simulação para o estado de reparo pelo método real
de atualização, para que o HUD corresponda ao cenário apresentado.

| Vista | Antes | Depois |
|---|---|---|
| Terminal do cais | [Abrir](../../captures/wetlands/before/01_cais_terminal.png) | [Abrir](../../captures/wetlands/01_cais_terminal.png) |
| Canal e clarificador | [Abrir](../../captures/wetlands/before/02_cais_canal.png) | [Abrir](../../captures/wetlands/02_cais_canal.png) |
| Combate no cais | [Abrir](../../captures/wetlands/before/03_cais_combate.png) | [Abrir](../../captures/wetlands/03_cais_combate.png) |
| Pátio de energia | [Abrir](../../captures/wetlands/before/04_energia.png) | [Abrir](../../captures/wetlands/04_energia.png) |
| Filtragem | [Abrir](../../captures/wetlands/before/05_filtros.png) | [Abrir](../../captures/wetlands/05_filtros.png) |
| Distribuição | [Abrir](../../captures/wetlands/before/06_distribuicao.png) | [Abrir](../../captures/wetlands/06_distribuicao.png) |
| Cais restaurado | [Abrir](../../captures/wetlands/before/07_cais_restaurado.png) | [Abrir](../../captures/wetlands/07_cais_restaurado.png) |

## Verificação

Godot 4.7.2, renderer Compatibility, AMD Radeon RX 6600. Todos os testes abaixo
passaram na versão final, sem falhas de asserção:

| Verificação | Resultado |
|---|---|
| Mundo | 2269 asserções, 1097 amostras de rotas, 16 combinações de acesso/progressão |
| Novas travessias e canais | 2567 verificações; ida/volta, faixas laterais, esquiva, disparos reais através da água e atlas |
| Arte do ambiente | 54 verificações de recursos, bases e ordenação |
| Integração do ambiente | 9329 verificações, 128 bordas percorridas e 137 aproximações de bases |
| Simulação | 91 verificações; bot concluiu quatro setores, derrotou 17 inimigos e restaurou os sistemas |
| Origem dos tiros | 963 verificações |
| Dados da água | 21 verificações |
| Renderização da água | 436 verificações; câmera, movimento e ordem das camadas |
| Revisão visual | Sete capturas antes e sete depois, inspecionadas nos recortes principais |

O bot de progressão usa invulnerabilidade para isolar a conclusão do percurso;
movimento, inimigos, disparos e danos causados aos inimigos continuam reais.
Isso verifica acesso e progressão, sem avaliar a dificuldade para um jogador.

A medição visual de 120 quadros no cais foi de aproximadamente 4,02 ms antes e
7,32 ms depois, com 690 e 914 chamadas de desenho, respectivamente. A câmera e os
inimigos ficaram parados, a água avançou, e VSync foi desativado. Esses valores são
uma amostra local de custo de renderização, não uma medição de combate intenso ou
garantia de desempenho em outras máquinas. Os registros estão nos `review.json`
das pastas de capturas.

Durante a revisão em ambiente restrito, o Godot não pôde gravar seu cache de shaders
em `user://`. As imagens foram renderizadas sem esse cache, e o teste gráfico passou.
Uma cópia local portátil do executável foi usada somente para os testes.

## Recurso novo e proveniência

A textura [wet_concrete.png](../../assets/station/wet_concrete.png) foi criada com
a ferramenta integrada **imagegen**. O [prompt completo](../../assets/station/wet_concrete-PROMPT.txt)
solicita concreto úmido de baixo contraste, vista superior plana, pixel art detalhada,
sem objetos, poças ou grade embutida. A antiga `stone_surface.png` permanece no projeto.
As plantas, personagens e máquinas usam os recursos já existentes.

## Escopo desta versão

Piso, vegetação, poças e paleta da água foram aplicados aos quatro setores. A nova
geometria de canais e travessias foi aplicada primeiro ao cais de captação. O tanque
circular conserva a água incorporada no sprite; a descarga externa e os canais
recebem efeitos adicionais. A imagem-conceito continua sendo uma referência artística,
e não uma promessa de reprodução pixel a pixel.
