# Auditoria e critérios da beta — 21/10/2026

Base: ZIP `Protocolo_17-main.zip` fornecido em 21/10. A cópia antiga da raiz foi preservada. Este projeto dentro de `beta/Protocolo_17-main` é a base de trabalho.

## Escopo recuperado da conversa

Operação Filtro completa, quatro setores do Distrito das Águas, prólogo existente, ODS 6, melhorias entre setores, chefe e conclusão. A última decisão do usuário foi meta provisória de **10 minutos de gameplay**, sem menus e prólogo, sujeita a medição humana. Os outros distritos são expansão futura; o documento de regras no ZIP mistura protótipo e campanha completa e não representa implementação já pronta.

## Diagnóstico da versão recebida

- Quatro setores e 17 inimigos; uma leva por setor. Repetição de eliminar → segurar E.
- Sem dificuldade selecionável; cadência, antecipação e padrões fixos.
- Lia com um disparo; projéteis discretos em meio ao cenário detalhado.
- Linhas de previsão desenhadas no ataque inimigo.
- Chefe alterna apenas dois ataques, sem fases de vida.
- Recuperação parcial de vida entre setores, divergindo da regra de vida por cenário.
- Checkpoint salva somente setor e melhorias; tempo e contagem são perdidos ao continuar.
- Prólogo, arte, água, navegação, pausa, mapa, áudio e melhorias já existem. Não recriar.
- Duração humana, legibilidade com jogadores novos e funcionamento em outro PC sem editor não demonstrados.
- README mantém números de validações históricas; não confundir com validação desta beta.

## Pendências e aceitação

| Prioridade | Entrega | Critério |
| --- | --- | --- |
| P0 | Dificuldade | História, Operação e Veterano alteram pressão, antecipação e recursos; persistem no save. |
| P0 | Tirar raio de ataque | Remover linhas e círculo de alcance dos avisos inimigos; manter animação e som de preparação. |
| P0 | Ampliar tiros/ataques | Pulsos mais legíveis, cadência maior, rajada secundária com recarga, padrões por inimigo e chefe por fases. |
| P0 | Variar os setores | Admissão, sincronização de energia, análise de água e abertura de redes; cada um exige tarefa e combate. |
| P0 | Progressão/derrota | Objetivos e levas do setor reiniciam; setores e melhorias anteriores permanecem; vida cheia no novo setor. |
| P0 | Persistência | Save validado antes de mutação, compatibilidade com versão 1, dificuldade e estatísticas preservadas. |
| P0 | Partida completa | Percurso real, combates, tarefas, escolhas e vitória nos três níveis; separar teste invulnerável de dano normal. |
| P1 | Duração | Medir primeiras partidas humanas; buscar 10 minutos de conteúdo útil, sem obrigar espera para atingir a meta. |
| P1 | Acessibilidade | Checar 960×540 e 1440×810; opções legíveis; ações, recarga, objetivo e feedback visíveis. |
| P1 | Distribuição | Pacote executável abre sem editor; testar instalação limpa e outro computador. |
| P1 | Teste externo | Observar sem explicar controles, registrar tempo, mortes, perda de orientação e opiniões. Corrigir principais problemas. |
| P1 | Entrega acadêmica | APS 1, vídeo APS 2 de 1–3 minutos com feedback externo, evolução por aula, equipe e datas dependem de material humano. |
| P2 | Expansão | Resíduos, Energia como distritos próprios, outros poderes e campanha integral após fechar Operação Filtro. |

O estado final e as evidências desta rodada ficam em `BETA_RESULTADOS.md`. A meta de duração e o teste externo não são comprovados por um bot.
