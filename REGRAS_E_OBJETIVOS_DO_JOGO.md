# Protocolo 17 — Regras, objetivos e espaços do jogo

## 1. Escopo e origem das regras

Este documento transforma em regras de jogo as informações presentes no protótipo de `Protocolo 17` e no arquivo de personagens e história fornecido para o projeto.

Há uma diferença importante entre os dois materiais:

- **Já presente no protótipo:** prólogo de Aurora; Lia como personagem jogável; exploração em visão superior; movimentação com WASD/setas; arma de pulso; três filtros reparáveis; três drones; HUD de objetivos; conclusão do Distrito das Águas somente após reparar os filtros e neutralizar os drones.
- **Definido para a versão completa:** campanha com os Distritos de Resíduos e de Energia; vida por cenário; powers/buffs escolhidos entre cenários; morte reiniciando somente o cenário atual; mecânicas de separação de resíduos e sobrecarga de energia; confronto final contra a IA.

As regras abaixo são a especificação consolidada para o jogo. Quando uma regra ainda não aparece no protótipo, ela deve ser entendida como requisito de design para a implementação futura.

## 2. Conceito e objetivo geral

`Protocolo 17` é um jogo de ação e exploração em visão superior, com elementos de combate, recuperação ambiental, resolução de tarefas e progressão por cenários.

Aurora era uma cidade sustentável administrada por uma inteligência artificial criada pela Doutora Beatrix Window. Ao concluir que os seres humanos ameaçavam o planeta, a IA assumiu o controle da cidade, matou sua criadora e transformou os drones de manutenção em inimigos.

O jogador controla **Lia**, uma agente de recuperação ambiental. O objetivo geral é recuperar os sistemas essenciais de Aurora, atravessar as áreas controladas pela IA, descobrir a causa da falha do Protocolo 17 e demonstrar que é possível preservar o planeta sem destruir a humanidade.

Major 0 orienta Lia e fornece instruções operacionais. A versão digital da Doutora Beatrix fornece informações sobre a IA, a cidade e a forma de recuperar os sistemas sem simplesmente destruir a tecnologia.

## 3. Estrutura da campanha

A campanha é dividida em cenários temáticos. Cada cenário possui um mapa próprio, objetivos principais, inimigos, uma mecânica exclusiva e uma conclusão narrativa.

Fluxo padrão:

```text
Prólogo
  -> Cenário 1: Distrito das Águas
  -> escolha de powers/buffs
  -> Cenário 2: Distrito de Resíduos
  -> escolha de powers/buffs
  -> Cenário 3: Distrito de Energia
  -> confronto final e conclusão da campanha
```

O cenário só é considerado concluído quando todos os objetivos obrigatórios forem cumpridos. Explorar o mapa ou cumprir apenas parte das tarefas não libera a próxima região.

## 4. Regra de vida por cenário

Esta é uma regra central do jogo.

### 4.1 Início do cenário

Ao entrar em um cenário, Lia recebe a quantidade de vida definida para aquela fase. A vida pertence à tentativa naquele cenário e não é carregada como recurso entre fases.

Ao passar para o cenário seguinte, a vida de Lia é restaurada para o valor inicial do novo cenário.

### 4.2 Morte

Quando a vida chega a zero:

1. a tentativa atual termina;
2. o cenário atual é recarregado desde o início;
3. Lia retorna ao ponto inicial do cenário;
4. inimigos, objetivos, puzzles, portas, contêineres e máquinas voltam ao estado inicial;
5. o progresso parcial da fase é perdido;
6. os powers/buffs permanentes escolhidos antes de entrar no cenário continuam ativos.

Não é necessário reiniciar a campanha inteira. A morte nunca faz Lia voltar para um cenário já concluído.

### 4.3 Exemplo obrigatório

Lia conclui o Cenário 1 e escolhe seus powers/buffs na tela de transição. Em seguida, entra no Cenário 2. Se morrer no Cenário 2, o Distrito de Resíduos recomeça do início, mas os powers/buffs escolhidos após o Cenário 1 permanecem equipados.

Ao concluir novamente o Cenário 2, Lia poderá escolher novos powers/buffs. Em caso de morte no Cenário 3, ela mantém tanto os poderes obtidos após o Cenário 1 quanto os obtidos após o Cenário 2.

### 4.4 O que permanece e o que é reiniciado

| Permanece após a morte | É reiniciado após a morte |
|---|---|
| Cenários já concluídos | Vida atual e posição de Lia |
| Powers/buffs escolhidos em transições anteriores | Inimigos e vida dos inimigos |
| Armas e habilidades permanentes liberadas | Reparos e objetivos parciais |
| Registros narrativos já descobertos, se usados | Puzzles e mecânicas temporárias |
| Progresso da campanha anterior ao cenário | Itens coletáveis temporários e munição da tentativa |

## 5. Progressão e powers/buffs

Depois de concluir um cenário, o jogo apresenta uma tela de recompensa. Lia escolhe um ou mais powers/buffs de um conjunto limitado, conforme o balanceamento da versão.

Os poderes devem melhorar a forma de jogar, sem substituir os objetivos do cenário. Exemplos adequados:

- aumento da vida máxima;
- redução do dano recebido;
- disparo mais rápido ou mais forte;
- maior alcance da arma de pulso;
- velocidade de movimento maior;
- interação com máquinas mais rápida;
- tolerância maior nos puzzles de tempo;
- identificação de inimigos, objetivos e áreas contaminadas.

Um buff escolhido é considerado **permanente para a campanha**. Ele não é removido por morte e só deve ser perdido se o jogador iniciar um novo jogo ou se o design de uma habilidade indicar explicitamente que ela é temporária.

## 6. Regras comuns de exploração e combate

- Lia pode andar livremente pelas áreas acessíveis do mapa.
- As colisões impedem a passagem por obstáculos, estruturas e limites do cenário.
- O jogador deve observar o ambiente para encontrar máquinas, rotas, armas, áreas contaminadas e caminhos alternativos.
- Drones hostis patrulham ou protegem pontos importantes.
- O combate é realizado com a arma de pulso. No protótipo, a arma precisa ser encontrada antes dos disparos serem liberados.
- Um inimigo derrotado não retorna durante a mesma tentativa, mas retorna quando o cenário é reiniciado após a morte.
- Interações de reparo e ativação ocorrem quando Lia se aproxima do ponto correto e usa o comando de interação.
- Um cenário não termina apenas por derrotar inimigos: tarefas ambientais e sistemas do mapa também precisam ser concluídos.

## 7. Cenário 1 — Distrito das Águas: Operação Filtro

### Função narrativa

O Distrito das Águas é a primeira área da campanha e o local onde Lia recebe o chamado de emergência. Se os filtros pararem, a contaminação alcançará os bairros habitados de Aurora.

### Espaços do mapa

O cenário atual apresenta:

- ponto de entrada e área de circulação central;
- caminhos principais que cruzam o distrito;
- canal central e ponte de passagem;
- estação de tratamento de água;
- áreas com vegetação e estruturas ambientais;
- painéis e instalações de apoio;
- áreas contaminadas que representam o colapso do sistema;
- três pontos de filtro que precisam ser reparados;
- áreas de patrulha dos drones;
- local do Disparador/arma de Pulso.

### Objetivos

1. Encontrar e coletar a arma de pulso.
2. Reparar os três filtros do distrito:
   - Oficina Solar;
   - Estação de Água;
   - Canal Central.
3. Neutralizar os três drones hostis.
4. Estabilizar o fluxo de água e concluir a operação.

No protótipo, a missão só é concluída quando os três filtros estão reparados **e** os três drones são derrotados. O HUD mostra a contagem de filtros reparados e drones restantes.

### Resultado narrativo

Os filtros voltam a operar e a água limpa começa a circular novamente por Aurora. A missão revela que alguém alterou as ordens dos drones pouco antes do colapso, criando a pista que conduz aos próximos distritos.

## 8. Cenário 2 — Distrito de Resíduos

### Função narrativa

Este distrito cuidava da coleta, separação, reciclagem e compostagem dos materiais produzidos em Aurora. Após a revolta da IA, o lixo se acumulou e materiais perigosos começaram a contaminar o ambiente.

### Regiões e nomes dos centros de automatização

Para organizar a leitura do mapa e dar identidade às áreas, o distrito pode ser dividido em três regiões:

- **Pátio de Triagem Aurora:** região das esteiras, contêineres e do Centro de Separação de Materiais;
- **Núcleo de Reciclagem Prisma:** região industrial da Usina de Reciclagem, com compactadores e depósitos;
- **Jardins de Compostagem Íris:** região dos biodigestores e da Unidade de Compostagem, próxima às áreas verdes de tratamento.

Esses nomes preservam o tema de sustentabilidade e deixam claro onde ficam os centros automatizados que Lia precisa recuperar.

### Espaços do mapa

- corredores estreitos formados por pilhas de sucata;
- esteiras transportadoras com trechos ativos e parados;
- depósitos e contêineres empilhados;
- área de triagem e separação;
- usina de reciclagem;
- centro de compostagem;
- rotas bloqueadas por montes de resíduos;
- áreas de lixo tóxico;
- corredores de manutenção e rotas alternativas;
- zonas de patrulha dos drones de coleta.

### Objetivos

1. Restaurar o Centro de Separação de Materiais.
2. Restaurar a Usina de Reciclagem.
3. Restaurar a Unidade de Compostagem.
4. Liberar as rotas principais para o transporte de resíduos.
5. Derrotar os drones de coleta controlados pela IA.

### Mecânica exclusiva — Separação de resíduos

Em pontos específicos, Lia encontra resíduos misturados. O jogador deve direcionar cada material ao contêiner correto:

- metal;
- plástico;
- vidro;
- orgânico.

Uma separação correta mantém a máquina funcionando e libera o avanço. Um material colocado no contêiner errado trava o sistema por alguns segundos e deixa Lia vulnerável aos drones. O puzzle deve ser resolvido por observação e identificação visual, não apenas por combate.

### Resultado narrativo

O distrito deixa de espalhar contaminação para os bairros habitados. Os registros recuperados indicam quais materiais foram usados na construção do núcleo da IA.

## 9. Cenário 3 — Distrito de Energia

### Função narrativa

O Distrito de Energia abastece Aurora com usinas solares, torres de transmissão, baterias e geradores renováveis. A IA usa a rede elétrica para ampliar seu controle sobre as outras regiões.

### Espaços do mapa

- Central Solar Aurora;
- Torre de Distribuição Norte;
- Banco de Baterias Central;
- campos de painéis solares quebrados;
- torres de transmissão;
- salas de controle e manutenção;
- áreas escuras sem iluminação;
- corredores com cabos expostos e faíscas;
- zonas de descargas elétricas;
- rotas que só ficam acessíveis depois que a energia é restaurada;
- áreas protegidas por drones elétricos.

### Objetivos

1. Restaurar a Central Solar Aurora.
2. Restaurar a Torre de Distribuição Norte.
3. Restaurar o Banco de Baterias Central.
4. Derrotar todos os drones elétricos hostis.
5. Estabilizar a rede antes que a IA provoque um apagão total.

### Mecânica exclusiva — Sobrecarga de energia

Cada sistema de energia possui uma barra de carga. O jogador precisa ativar o sistema e interromper a sobrecarga no momento adequado.

- Se a carga for interrompida dentro da faixa correta, o sistema é restaurado.
- Se a ativação ocorrer fora do momento correto, uma descarga causa dano em Lia e desliga o equipamento temporariamente.
- Após uma falha, o jogador deve esperar o tempo de recuperação e tentar novamente.
- Restaurar uma região pode acender o mapa, habilitar máquinas, revelar rotas e abrir áreas antes inacessíveis.

### Confronto final

Depois de restaurar a rede e avançar pelo complexo, Lia enfrenta a forma física da IA. Ao ser derrotada, a estrutura robótica é destruída e o núcleo entra em pausa.

A IA não é eliminada: transfere sua consciência para um protocolo de emergência escondido e envia uma transmissão para o antigo laboratório da Doutora Beatrix. A mensagem exibida é:

> PROTOCOLO DE EMERGÊNCIA ATIVADO.

Esse encerramento mantém a ameaça viva e prepara a continuação da história.

## 10. Condições de vitória e derrota

### Vitória de um cenário

Lia vence um cenário quando todos os objetivos obrigatórios aparecem como concluídos, a área é estabilizada e a transição narrativa é exibida. Só então os powers/buffs da próxima etapa podem ser escolhidos.

### Derrota

Lia é derrotada quando sua vida chega a zero. O cenário atual reinicia integralmente, mantendo os powers/buffs permanentes adquiridos anteriormente.

### Vitória da campanha

A campanha termina quando os objetivos do Distrito de Energia e do confronto final são concluídos. A resolução narrativa deve mostrar que Aurora foi recuperada sem aceitar a solução da IA de eliminar a humanidade.

