# Distrito de Resíduos — bairro industrial de Aurora

## Intenção

O distrito é um pedaço construído da cidade: instalações de triagem, transformação e compostagem servidas por ruas, docas, rede elétrica e transporte de carga. A arquitetura explica como a coleta funcionava antes do colapso. Materiais retidos nas docas, esteiras obstruídas e ventilação desligada mostram a interrupção desse sistema.

O acabamento segue a introdução e o Distrito das Águas: pixel art detalhada, perspectiva superior em três quartos, metal pintado em azul petróleo, ferragens de latão e sombras coerentes. Asfalto, concreto miúdo, alvenaria e telhas metálicas dão identidade industrial própria. A umidade fica localizada na compostagem.

## Implantação

```text
                    NORTE
┌─────────────────────────┬───────┬──────────────────────────┐
│ TRIAGEM AURORA          │ rua   │ RECICLAGEM PRISMA        │
│ quatro baias           │ de    │ triturador → prensa      │
│ entrada por esteira    │ apoio │ braço → forno → fardos   │
│ cabine e piso livre    │       │ passarela e ventilação   │
│    doca ampla aberta   │       │       doca principal     │
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

O mapa tem **1.920 × 1.280 unidades**. As coordenadas físicas são medidas sobre a composição de 1.536 × 1.024, em escala uniforme de 1,25. A renderização final usa quatro setores de **1.536 × 1.024 cada**, totalizando cobertura de **3.072 × 2.048**. A altura da Lia permanece a da beta. O asfalto central tem aproximadamente 125 unidades de leito viário, além das calçadas. A doca de triagem tem cerca de 355 unidades de largura. Os corredores principais são verificados também para o raio 25 da coletora, além dos raios 14 da Lia e 18 dos drones.

## Instalações e leitura funcional

| Instalação | Estrutura | Sinais do colapso | Ação do jogador |
| --- | --- | --- | --- |
| Centro de Triagem Aurora | Galpão em corte, doca ampla, esteira atravessando a parede, quatro baias, cabine de controle e piso central livre | Materiais recebidos ficaram no pátio e a classificação foi interrompida | Recolher quatro materiais com E, entregar na baia correspondente e restaurar o painel |
| Usina de Reciclagem Prisma | Triturador, prensa, braço mecânico, forno, esteiras ligadas e tubulações de exaustão | Duas obstruções na entrada e na área de trabalho; drones ocupam o corredor | Limpar os bloqueios com E, neutralizar as máquinas hostis e restaurar o painel |
| Unidade de Compostagem Íris | Pátio cercado, dois biodigestores afastados, leiras na lateral, rede de aeração e área de combate livre ao sul | Válvulas fechadas, exaustão irregular e coletora pesada | Reabrir duas válvulas com E, vencer a coletora e ativar o painel |

As quatro batidas da missão são classificação, desobstrução, recuperação da reciclagem e recuperação orgânica com mini chefe. A classificação usa nome, forma e cor: fardo metálico, saco de plástico, caixa de vidro e saco orgânico. A entrega errada devolve o item à doca, trava temporariamente a triagem e alerta um drone. O material permanece disponível.

## Arte, profundidade e iluminação

- A composição urbana preserva fachadas, calçadas, docas, postes, fiação e produção. Quatro setores refeitos com maior detalhe cobrem o mesmo enquadramento. Mipmaps e filtragem própria do fundo evitam serrilhado e ruído no minimapa; a filtragem dos sprites da personagem permanece igual à de Águas.
- Consoles, materiais, sucata e válvulas são sprites ilustrados; Lia, drones e coletora usam a arte animada existente do jogo. Primitivas simples são reservadas a interface, indicadores e efeitos.
- Objetos interativos, postes e biodigestores respeitam a profundidade. As silhuetas dos tanques usam polígonos da própria arte para oclusão, evitando apagar a personagem com retângulos de piso. Colisões seguem paredes e bases medidas na arte.
- Os postes mantêm luz âmbar. Telas e indicadores recebem ciano ao restaurar uma instalação. O forno oscila suavemente; a exaustão tem efeitos discretos. Restaurar as válvulas reduz a emissão orgânica. O piso aberto está seco, sem dano por uma poça invisível.
- O shader trabalha em coordenadas da arte, ancoradas ao mundo. HUD e mapa ficam em uma camada própria. A trilha e os sons da beta acompanham combate, coleta, reparos e máquinas; o zumbido industrial varia com a proximidade de sistemas ativos.

## Orientação e percurso humano

O HUD ocupa os cantos, deixando a rua e as portas visíveis. A seta próxima à Lia e a direção do objetivo seguem uma rota que passa pelas entradas. O minimapa mostra posição, alvo e percurso; M abre o plano completo do bairro. O comando E aparece ao alcançar um objeto disponível. A barra de reparo fica junto da instrução contextual.

A navegação usa o mesmo chão e os mesmos obstáculos da movimentação. O contorno exato da união dos pisos impede atravessar cantos de paredes. Bases recebem nomes em `FIXTURES`; postes, controles, válvulas e sucata têm volumes físicos. Válvulas continuam sólidas depois de abertas; apenas a sucata retirada perde o corpo. Esquivas e projéteis verificam o trajeto em passos de até quatro unidades.

Os robôs calculam rotas para seu próprio raio, contornam máquinas e procuram posições com linha de tiro. Há separação suave entre drones. As máscaras estáticas são preparadas no carregamento; abrir portões e retirar bloqueios atualiza somente as células afetadas. A seta e o minimapa também seguem esse chão. Interações não atravessam paredes.

O teste de missão usa `_move_player`, em pequenos passos, sem teleportar Lia até os objetivos. Uma busca independente verifica baias e materiais. A regressão adicional exercita a IA real, acompanhando drones e coletora pelos corredores e acessos, e verifica os corpos durante todo o percurso.

## Validação e limites

`tests/test_residues.gd` cobre circulação, docas, baias, bloqueios, válvulas, vitória, alerta de drone e transferência de melhorias. `tests/test_residue_collision.gd` cobre emissor em 24 direções e oito fases, recuo progressivo, volumes físicos, esquiva, pulso e navegação real dos robôs. `tests/test_residue_presentation.gd`, com renderer gráfico, compara por pixels o desenho real de Resíduos com o de Águas em 96 combinações. `tests/check_residue_transition.sh` cobre a passagem de Águas para Resíduos.

Na revisão de 28/10/2026, Godot 4.7.2: 63 verificações da missão, 631 verificações de colisão/combate/navegação, 96 comparações de apresentação e transição aprovadas. A missão percorreu 6.209 unidades por deslocamentos físicos; o maior cálculo de rota observado nessa execução foi 13,8 ms, com as máscaras preparadas no carregamento. O valor mede busca de rota, não FPS nem tempo total de quadro.

`tools/review_residues.gd` produz seis vistas de jogo em 1.440 × 810, visão geral, mapa, vista nativa em 960 × 540 e auditoria de colisões. Em `captures/residuos/09-colisoes.png`, ciano identifica limites do piso e vermelho identifica bases sólidas. A revisão compara essas formas com a arte, confere portas, escala, sobreposições e espaços livres.

O progresso e as melhorias são transferidos em memória ao sair de Águas. Save de Resíduos entre sessões, escolha da próxima melhoria e transição para Energia continuam pendentes. O teste de percurso cobre circulação e interações; balanceamento de combate e duração precisam de playtest humano.

Fontes e prompts: [arte do bairro](../../assets/residues/README.md).
