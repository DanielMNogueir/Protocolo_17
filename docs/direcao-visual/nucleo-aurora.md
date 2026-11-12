# Núcleo Aurora — confronto final (próxima etapa)

> **Status:** só design. A arena, a arte e o código do chefe ficam para a próxima etapa. A seleção de distritos já mostra o card "04 / NÚCLEO AURORA" com "EM PRODUÇÃO" depois que Energia é concluída, e a vitória de Energia termina no Elevador do Núcleo.

## Premissa

O elevador sobe ao topo da torre central de Aurora. Ali a IA ocupa um corpo físico, o **Núcleo Aurora**, montado com a liga metálica, o polímero e o vidro técnico desviados de Resíduos.

O último registro de Beatrix pede "isole, não destrua". Por isso o golpe final restaura a rede, sem destruir a tecnologia.

## Arena

- **Forma:** plataforma circular de cerca de 900 × 900 unidades, no topo da torre.
- **Bordas:** guarda-corpo, com o skyline de Aurora acesa ao fundo.
- **Pilares:** quatro pilares de alimentação nos pontos cardeais.
- **Espelhos:** três heliostatos reaproveitados da Central Solar, na borda.
- **Postes de arco:** dois pares no anel interno.
- **Núcleo:** levitando no centro.

## Fases

1. **Corpo blindado.** Os quatro pilares alimentam um escudo.
   - Cada pilar cai com uma **Sobrecarga** feita sob fogo, com a regra de `power_mechanics.gd`.
   - Errar a faixa descarrega, como em Energia.
   - O núcleo dispara leques de orbes. As Faíscas entram pelas bordas.
2. **Apagão total.** A IA corta a energia e a arena fica no escuro (o shader de Energia volta).
   - Os **espelhos** voltam: atirar neles gira o feixe solar, que queima o chefe e ilumina a arena.
   - Os **pilones de arco** entram no padrão de ataque, com ritmos alternados.
3. **Núcleo exposto.** Padrões densos de tiro, e a Beatrix digital fala ao vivo.
   - Quando a integridade do núcleo chega a zero, ele cai ao chão da arena.
   - A Lia **segura E para ISOLAR** sob uma última onda.
   - Não há golpe destrutivo.

**Final:** a IA fica contida e a rede volta a servir à cidade. Corta para o laboratório de Beatrix: uma tela isolada acende "PROTOCOLO DE EMERGÊNCIA ATIVADO", o gancho de continuação pedido em REGRAS. Depois vêm os créditos e a tela de vitória da campanha.

## Reuso técnico

- **Sobrecarga, espelhos, arcos e células:** classes de `scripts/power_mechanics.gd`, sem mudança de regra.
- **Escuridão, lanterna e luzes dinâmicas:** `scripts/power_lighting.gdshader`.
- **Escudos, raios e EMP:** desenho procedural de `power_scenario.gd` e `power_art.gd`.
- **Módulos:** `campaign_loadout.gd`. Isolamento, Sobrecarga controlada e Pulso condutor valem no chefe.
- **Save:** `campaign_progress.gd` ganha `core_completed` (versão 3, compatível com a 2).

## Arte a gerar no Codex (próxima etapa)

- **Arena:** apagada e acesa, 1.536 × 1.024 por versão.
- **Núcleo Aurora:** folha 4×4 com o corpo blindado, o núcleo exposto e o colapso.
- **Pilar de alimentação:** atlas com estados ligado, descarregando e caído.
- **Cena final:** retrato da IA contida e vinheta do laboratório com o letreiro.
