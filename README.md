# Protocolo 17 - Primeiro Cenario

Este e o primeiro prototipo jogavel do Distrito das Aguas. Ele contem:

- uma fase desenhada diretamente pela Godot;
- a personagem Lia com animacoes em quatro direcoes;
- movimento por WASD ou setas;
- camera com acompanhamento suave;
- colisoes nas bordas, no canal, nas arvores, nos paineis e na estacao;
- interface provisoria com titulo, objetivo e controles.

## Como abrir

1. Abra o Godot Project Manager.
2. Clique em **Import**.
3. Selecione o arquivo `project.godot` desta pasta.
4. Clique em **Import & Edit**.
5. Pressione **F6** ou **F5** para jogar.

## Controles

- `WASD`: movimentar Lia.
- Setas direcionais: movimentar Lia.
- `F8`: encerrar o jogo durante um teste pelo editor.

## Estrutura

```text
assets/
  lia_movimento.png
  lia_acoes.png
scenes/
  main.tscn
scripts/
  cenario_agua.gd
  player.gd
project.godot
```

## Como o movimento funciona

O arquivo `scripts/player.gd` le o teclado com `Input.get_vector`, define a
velocidade do `CharacterBody2D`, chama `move_and_slide()` e escolhe uma das
animacoes `walk_down`, `walk_left`, `walk_right` ou `walk_up`.

Quando o jogador solta as teclas, o script troca para `idle_down`,
`idle_left`, `idle_right` ou `idle_up`.

## Proxima evolucao sugerida

1. Adicionar uma peca coletavel.
2. Criar um contador de pecas na interface.
3. Adicionar a estacao reparavel.
4. Criar o primeiro drone inimigo.
5. Implementar a condicao de vitoria.

## Observacao

O cenario atual e uma base provisoria. Ele foi criado para validar movimento,
animacao, camera e colisoes antes da equipe investir na arte definitiva.

