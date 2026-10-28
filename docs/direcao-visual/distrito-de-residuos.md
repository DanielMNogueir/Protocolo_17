# Distrito de Resíduos — bairro industrial de Aurora

## Intenção

O distrito é um pedaço construído da cidade: instalações de triagem, transformação e compostagem servidas por ruas, docas, rede elétrica e transporte de carga. A arquitetura explica como a coleta funcionava antes do colapso. Acúmulo nas docas, esteiras obstruídas e vazamento orgânico mostram a interrupção desse sistema.

O acabamento segue a introdução e o Distrito das Águas: pixel art detalhada, perspectiva superior em três quartos, metal pintado em azul petróleo, ferragens de latão e sombras coerentes. Asfalto, concreto miúdo, alvenaria e telhas metálicas dão identidade industrial própria. A umidade fica localizada na compostagem.

## Implantação

```text
                    NORTE
┌─────────────────────────┬───────┬──────────────────────────┐
│ TRIAGEM AURORA          │ rua   │ RECICLAGEM PRISMA        │
│ quatro baias           │ de    │ triturador → prensa      │
│ entrada por esteira    │ apoio │ braço → forno → fardos   │
│ cabine e empilhadeiras │       │ passarela e ventilação   │
│   doca   doca   doca    │       │       doca principal     │
╞═════════════════════════╪═══════╪══════════════════════════╡
│       AVENIDA DE SERVIÇO / CALÇADAS / FAIXA DE PEDESTRES   │
╞═════════════════════════╪═══════╪══════════════════════════╡
│ quarteirão logístico   │ rua   │ portão da COMPOSTAGEM    │
│ galpões fechados       │ de    │ depósito e ventilação    │
│ caminhão de coleta     │ carga │ dois biodigestores       │
│ escritórios, pátio     │       │ leiras cobertas e painel │
└─────────────────────────┴───────┴──────────────────────────┘
```

A avenida fica acessível desde o início. O jogador se orienta pela esquina, pela faixa de pedestres, pelas portas de carga e pelos postes. A progressão bloqueia apenas as entradas da reciclagem e da compostagem. Galpões logísticos permanecem fechados; seus telhados não são piso caminhável.

O mapa tem **1.920 × 1.280 unidades**, com arte de **1.536 × 1.024** aplicada em escala uniforme de 1,25. A altura da Lia permanece a da beta. Portas de pessoal, docas, empilhadeiras, controles e barreiras são conferidos junto dela nas capturas. A avenida possui aproximadamente 140 unidades de leito viário; docas e corredores são dimensionados para a colisão circular da personagem. Não há escalas independentes para alargar ou esticar máquinas.

## Instalações e leitura funcional

| Instalação | Estrutura | Sinais do colapso | Ação do jogador |
| --- | --- | --- | --- |
| Centro de Triagem Aurora | Galpão aberto em corte, três docas, esteira atravessando a parede, quatro baias, cabine de controle, empilhadeiras e fardos | Materiais recebidos ficaram no pátio e a classificação foi interrompida | Recolher quatro materiais com E, entregar na baia correspondente e restaurar o painel |
| Usina de Reciclagem Prisma | Triturador, prensa, braço mecânico, forno, esteiras ligadas e tubulações de exaustão | Duas obstruções na entrada e na área de trabalho; drones ocupam o corredor | Limpar os bloqueios com E, neutralizar as máquinas hostis e restaurar o painel |
| Unidade de Compostagem Íris | Pátio cercado, dois biodigestores, leiras de matéria orgânica, galpão de ventilação e rede de aeração | Válvulas fechadas, vazamento localizado e coletora pesada | Reabrir duas válvulas com E, vencer a coletora e ativar o painel |

As quatro batidas da missão são classificação, desobstrução, recuperação da reciclagem e recuperação orgânica com mini chefe. A classificação usa nome, forma e cor: fardo metálico, saco de plástico, caixa de vidro e saco orgânico. A entrega errada devolve o item à doca, trava temporariamente a triagem e alerta um drone. O material permanece disponível.

## Arte, profundidade e iluminação

- A base urbana é uma composição única: fachadas, calçadas, docas, postes, fiação, coberturas, produção e estoques compartilham perspectiva e acabamento. Os recortes interativos usam uma prancha da mesma família visual.
- Consoles, materiais, sucata e válvulas são sprites ilustrados; Lia, drones e coletora usam a arte animada existente do jogo. Primitivas simples são reservadas a interface, indicadores e efeitos.
- Objetos interativos, postes, empilhadeiras e vergas das docas respeitam a profundidade. Colisões seguem chão, paredes e bases medidas na arte. A personagem não pode atravessar prédios ou subir em telhados.
- Os postes mantêm luz âmbar. Telas e indicadores recebem ciano ao restaurar uma instalação. O forno oscila suavemente; exaustão e vazamento têm efeitos discretos. Restaurar as válvulas reduz a emissão orgânica. Brilhos de material acompanham as esteiras recuperadas.
- O shader trabalha em coordenadas da arte, ancoradas ao mundo. HUD e mapa ficam em uma camada própria. A trilha e os sons da beta acompanham combate, coleta, reparos e máquinas; o zumbido industrial varia com a proximidade de sistemas ativos.

## Orientação e percurso humano

O HUD ocupa os cantos, deixando a rua e as portas visíveis. A seta próxima à Lia e a direção do objetivo seguem uma rota que passa pelas entradas. O minimapa mostra posição, alvo e percurso; M abre o plano completo do bairro. O comando E aparece ao alcançar um objeto disponível. A barra de reparo fica junto da instrução contextual.

A navegação usa o mesmo chão e os mesmos obstáculos da movimentação. O teste percorre a fase com `_move_player`, em pequenos passos, verificando os acessos sem teleportar Lia até os objetivos. Também há uma busca independente para todas as baias e materiais. As células de navegação são armazenadas por estado dos portões e bloqueios.

## Validação e limites

`tests/test_residues.gd` cobre circulação, escala física dos corpos, docas, baias, bloqueios, válvulas, vitória, alerta de drone e transferência de melhorias. `tests/check_residue_transition.sh` cobre a passagem de Águas para Resíduos sem exceções de entrada.

`tools/review_residues.gd` produz cinco vistas de jogo em 1.440 × 810, visão geral sem HUD, mapa e vista nativa em 960 × 540. As evidências ficam em `captures/residuos/`. A revisão compara portas e equipamentos com Lia, confere sobreposições, legibilidade e identidade urbana.

O progresso e as melhorias são transferidos em memória ao sair de Águas. Save de Resíduos entre sessões, escolha da próxima melhoria e transição para Energia continuam pendentes. O teste de percurso cobre circulação e interações; balanceamento de combate e duração precisam de playtest humano.

Fontes e prompts: [arte do bairro](../../assets/residues/README.md).
