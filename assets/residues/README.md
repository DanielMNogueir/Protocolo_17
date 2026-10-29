# Bairro industrial de Resíduos

Arte criada com a ferramenta integrada **image_gen**, a partir das referências fornecidas pelo usuário da introdução, do Distrito das Águas e de Aurora. O acabamento e a perspectiva são compartilhados em toda a composição. Os arquivos antigos de piso e máquinas isoladas foram substituídos.

| Arquivo | Conteúdo | Dimensões | Fonte |
| --- | --- | --- | --- |
| `district_city_v2.png` | Composição anterior, preservada como referência da revisão | 1536 × 1024 RGB | `exec-271861ac-3f59-43bd-a9a6-47f3d066b4cf.png` |
| `interactions_v2.png` | Oito recortes: metal, plástico, vidro, orgânico, controle, sucata, válvula de aeração e caçamba | 1774 × 887 RGBA | `exec-78c53b76-b0d1-45ad-9beb-d9e2995bed66.png` |
| `district_city_v3.png` | Composição de referência com pisos livres, doca ampla e biodigestores afastados | 1536 × 1024 RGB | `exec-073439ab-3527-4647-85fe-0e7062692a7c.png` |
| `district_northwest_v3.png` | Setor de triagem com mais detalhe nativo | 1536 × 1024 RGB | `exec-0f5ff37f-3005-4a8f-82f2-ce7d34dbe3c5.png` |
| `district_northeast_v3.png` | Setor de reciclagem com mais detalhe nativo | 1536 × 1024 RGB | `exec-cc60ce28-d52e-4323-9c54-99914163771a.png` |
| `district_southwest_v3.png` | Pátio logístico com a entrada livre | 1536 × 1024 RGB | `exec-7336ebc6-8431-4f5c-94eb-034ade44df97.png` |
| `district_southeast_v3.png` | Compostagem com mais detalhe nativo | 1536 × 1024 RGB | `exec-e4a62930-8ff5-4344-8d58-30cab3b8ab2c.png` |

O atlas tem quatro colunas e duas linhas; a região de cada célula deriva do tamanho real da textura. A geometria usa as coordenadas da composição com escala uniforme 1,25. Os quatro setores finais cobrem esse mesmo mundo em 3072 × 2048, com quatro vezes a quantidade de pixels da placa anterior. São novas versões detalhadas a partir dos enquadramentos exatos capturados no Godot, sem ampliar os prédios em relação à personagem. Os primeiros ensaios de zoom que mudaram o enquadramento foram descartados.

Materiais, controles, bloqueios, válvulas e atores são desenhados em profundidade; postes e tanques usam as próprias texturas dos setores para preservar oclusão. A filtragem e o shader de detalhe atuam só no fundo. Mipmaps reduzem ruído em vistas menores. O shader de iluminação mantém luz, emissão e brilho de transporte. Nenhuma imagem ou animação nova da Lia ou de sua arma foi criada nesta revisão: poses, recuo, clarão e pulso vêm dos mesmos módulos de Águas.

Prompts completos: [primeira versão](PROMPTS.md) e [revisão de circulação e detalhe v3](PROMPTS-V3.md).
