# Protocolo 17 — Aurora

Alpha em Godot: Lia recupera os sistemas do Distrito das Águas enquanto enfrenta drones e investiga o colapso de Aurora. Esta versão contém quatro setores, combate, esquiva, reparos, melhorias e confronto final.

## Executar

1. Abra `project.godot` no **Godot 4.7.1**, versão usada na validação.
2. Aguarde a importação dos recursos.
3. Pressione **F5** para iniciar.

O projeto usa o renderer Compatibility. Saves e configurações ficam em `user://`; não fazem parte do repositório. Não há dependências externas para jogar.

## Controles

| Ação | Controle |
| --- | --- |
| Movimento | WASD ou setas |
| Mira | Mouse |
| Disparo | Botão esquerdo ou Espaço |
| Esquiva | Shift |
| Reparar | Segurar E próximo ao sistema |
| Mapa | M |
| Pausa | Esc |
| Tela cheia | F11 |
| Alternar áudio | F10 |

## Lia: 24 direções

A personagem armada possui **24 orientações em intervalos de 15°**, com oito quadros de caminhada por direção, repouso, respiração e piscada. Os 240 quadros mantêm corpo, mãos e arma integrados. A mira e os tiros reais continuam livres em 360°.

![Lia nas 24 orientações](captures/lia_24_idle.png)

Abra [a prévia animada](captures/lia_24_preview.html) em um navegador após clonar o projeto. Ela reproduz capturas do próprio Godot e permite reduzir a velocidade da caminhada.

[Documentação dos sprites](assets/lia_directional/README.md) · [Prompts de geração](assets/lia_directional/PROMPTS.md) · [Fontes e proveniência](assets/lia_directional/SOURCES.json).

## Validação

Na raiz do projeto, substitua `godot` pelo caminho do executável instalado:

```sh
godot --headless --path . --editor --import --quit
godot --path . --script tests/test_weapon_visual.gd
godot --headless --path . --script tests/test_lia_animation.gd
godot --headless --path . --script tests/test_lia_official.gd
godot --headless --path . --script tests/test_world.gd
godot --headless --path . --script tests/test_simulation.gd
```

Resultados da integração direcional: 3752 verificações visuais, 22 do relógio de animação, 97 dos recursos oficiais e 2405 do mundo aprovadas. O teste visual requer renderer gráfico para gerar as capturas e verificar a cena real.

O teste de simulação mantém **uma falha conhecida de preparação do cenário**, em `tests/test_simulation.gd:63`: posiciona Lia a 5 unidades de um obstáculo apesar do raio de colisão 14, e exige que essa posição esteja livre. São 90/91 verificações aprovadas; o bot conclui as quatro etapas. Essa falha e as regras do jogo não foram alteradas pela atualização visual.

## Organização

- `scripts/`: simulação, apresentação, áudio e interface.
- `scenes/`: cena principal.
- `assets/lia_directional/`: apresentação armada atual da Lia.
- `assets/lia_official/` e `assets/lia_expanded/`: referências e versões anteriores preservadas.
- `tests/`: verificações do mundo, combate e apresentação.
- `tools/`: extração dos atlas e capturas de desenvolvimento.
- `captures/`: revisão visual da versão atual.

Os atlas prontos são usados diretamente pelo jogo. As ferramentas de extração não precisam ser executadas para jogar.

A adaptação artística do cenário é a próxima etapa e ainda não faz parte desta versão. A manutenção com ferramenta conserva suas quatro poses oficiais anteriores.
