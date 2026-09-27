# Estação de tratamento — arte do cenário

Integração visual dos conceitos aprovados para o Distrito das Águas. As fontes são PNGs de 1254 × 1254 criados com a ferramenta integrada `image_gen` e usados diretamente como atlas pelo Godot, sem substituir a geometria ou as colisões do mundo.

| Arquivo | Conteúdo | Fonte gerada |
| --- | --- | --- |
| `structures_atlas.png` | Decantador, filtros, bomba, sala de controle, tubulações e purificador | `exec-f916d428-a983-42be-a907-b607e5bec662.png` |
| `totems_atlas.png` | Captação, bombeamento, filtragem e distribuição; cada um inativo e ativo | `exec-4f14ff14-5027-4ad2-9cb3-86b8af51a59f.png` |
| `vegetation_atlas.png` | Juncos, taboas, plantas aquáticas, musgo, samambaias, flores, hera e variante contaminada | `exec-06db7efc-35d1-4233-8749-9137310e6419.png` |
| `stone_surface.png` | Textura de concreto envelhecido para as placas caminháveis | `exec-3d68bfe1-ac24-47c4-a59c-e82428de144f.png` |

`scripts/station_art.gd` contém os recortes de cada prancha. `scripts/world.gd` desenha o piso, máquinas e vegetação nas posições existentes. `scripts/main.gd` troca apenas a apresentação dos terminais pelos quatro totens, mantendo os mesmos pontos de ativação. A água recebe reflexos animados no próprio Godot.

Para revisar as cinco capturas reais, rode `godot --path . --script tools/review_station.gd`. As imagens são salvas em `.runtime/station_review/`. Os prompts completos estão em `PROMPTS.md`.
