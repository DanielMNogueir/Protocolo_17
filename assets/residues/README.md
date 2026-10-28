# Bairro industrial de Resíduos

Arte criada com a ferramenta integrada **image_gen**, a partir das referências fornecidas pelo usuário da introdução, do Distrito das Águas e de Aurora. O acabamento e a perspectiva são compartilhados em toda a composição. Os arquivos antigos de piso e máquinas isoladas foram substituídos.

| Arquivo | Conteúdo | Dimensões | Fonte |
| --- | --- | --- | --- |
| `district_city_v2.png` | Bairro completo com galpões em corte, três docas abertas, avenida, ruas de acesso, postes, rede industrial e compostagem | 1536 × 1024 RGB | `exec-271861ac-3f59-43bd-a9a6-47f3d066b4cf.png` |
| `interactions_v2.png` | Oito recortes: metal, plástico, vidro, orgânico, controle, sucata, válvula de aeração e caçamba | 1774 × 887 RGBA | `exec-78c53b76-b0d1-45ad-9beb-d9e2995bed66.png` |

O atlas tem quatro colunas e duas linhas; a região de cada célula deriva do tamanho real da textura, sem presumir a resolução solicitada ao gerador. A cidade é aplicada com escala uniforme 1,25. O layout e as bases físicas ficam em `scripts/residue_map.gd`.

A placa mantém os objetos estáticos coesos. Materiais, controles, bloqueios, válvulas e atores são desenhados em profundidade; postes, empilhadeiras e vergas usam recortes da própria placa para preservar oclusão. O shader anima luz, emissão e brilho de transporte, mantendo a textura e o HUD separados.

Prompts completos e etapas de geração: [PROMPTS.md](PROMPTS.md).
