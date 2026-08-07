# Protocolo 17

Protótipo jogável da primeira missão de Lia no Distrito das Águas, em Aurora.

## O que já está funcionando

- menu principal com **Jogar**, **Configurações** e **Sair**;
- criação de novo jogo e save local em `user://`;
- opção **Continuar** habilitada quando existe um save;
- prólogo narrativo em cinco registros sobre o colapso de Aurora;
- configurações persistentes de volume geral e tela cheia;
- Lia com movimento, colisão, câmera e sprites em quatro direções;
- arma de pulso coletável e disparos direcionais;
- três drones inimigos e três pontos de reparo;
- HUD com filtros reparados e drones restantes;
- missão concluída somente quando os três filtros forem reparados **e** os três drones forem eliminados;
- tela final com resultados, repetição da missão e retorno ao menu.

## Como executar

1. Abra o projeto pelo arquivo `project.godot`.
2. Aguarde a importação dos recursos.
3. Pressione **F5** para iniciar pelo menu principal.

## Controles da missão

- `WASD` ou setas: movimentar Lia.
- `E`: reparar um ponto próximo.
- `Espaço`: atirar depois de coletar a arma.
- `F8`: encerrar o teste no editor.

## Fluxo atual

```text
Menu principal
  -> Jogar
     -> Novo jogo
        -> Prólogo de Aurora
           -> Missão 01: Operação Filtro
              -> Missão concluída
```

## Arquivos principais

```text
scenes/
  main_menu.tscn
  prologue.tscn
  main.tscn
scripts/
  game_state.gd
  main_menu.gd
  prologue.gd
  mission_controller.gd
  mission_complete.gd
  player.gd
  cenario_colisoes.gd
assets/
  cenario_distrito_das_aguas.png
  lia_movimento.png
  lia_acoes.png
  lia_acoes_armada_v2.png
  armas_protocolo17.png
  drones_inimigos.png
```

O save e as configurações ficam no diretório de dados do usuário da Godot e não precisam ser enviados ao GitHub.
