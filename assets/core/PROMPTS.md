# Núcleo Aurora — prompts de arte (Codex `image_gen`)

Gere na ordem abaixo. Cada prompt diz o arquivo de destino e as imagens de referência que devem ser anexadas, em ordem ("Image 1", "Image 2"…). Todos seguem o padrão de `assets/power/PROMPTS.md` e `assets/residues/PROMPTS-V3.md`:

- pixel art nítida, câmera superior 3/4, contornos escuros, luz de cima à esquerda;
- paleta azul petróleo, metal escuro, latão, ciano e magenta só para a IA;
- sem texto, sem UI e sem personagens nos cenários.

Depois de gerar, registre o prompt usado e a data em `assets/core/SOURCES.json`, como nos outros distritos. A Lia mede cerca de 64 px de altura na escala dos cenários de 1536×1024.

---

## 1. `assets/core/arena_night.png` — Coroa da Torre, noite

Anexar:
1. `assets/power/district_southeast_on.png`
2. `assets/lia_directional/idle.png`
3. `assets/prologue/aurora_before.png`

> Use case: stylized-concept. Production background for Protocolo 17, final boss arena, opaque 1536x1024. Image 1 is the approved Energy district background: match its exact pixel-art finish, palette, materials and 3/4 overhead camera. Image 2 is Lia for human scale (about 64 px tall at this scale). Image 3 is Aurora city: the same city seen FAR BELOW. Subject: THE CROWN OF AURORA TOWER at night, a circular open-air steel platform about 1180 px wide and 860 px tall on screen (3/4 view of a circle), centred slightly above the middle of the canvas. Riveted concentric floor plates, a hazard-striped inner ring (about 360 px wide) around an empty central pedestal socket, four square cable hatches at north, east, south and west at about 62% of the radius where power pillars will stand, three empty heliostat mounts on the west and north-west part of the rim, two pairs of small floor sockets at about 40% of the radius (north-east and south-west) for arc pylons, a brass guard rail with posts around the whole edge, a short service stair landing breaking the rail at the south edge. Beyond the rail the platform's side drops away and Aurora city lies far below in darkness: tiny lit canals to the west, recycling plant chimneys to the south, a dark power grid to the east, a single warm lit laboratory building to the north. Thin cloud wisps drift below the platform. Cold moonlight from upper left, amber rail lamps every few metres, no magenta except two dormant warning lights near the central socket. Keep the floor readable and uncluttered for combat. No characters, no enemies, no text, no UI. Crisp outlined pixel clusters, no blur.

## 2. `assets/core/arena_dawn.png` — Coroa da Torre, amanhecer

Anexar:
1. `assets/core/arena_night.png` (aprovada)
2. `assets/prologue/aurora_before.png`

> Use case: stylized-concept. Same composition and the same pixels for every structure as image 1, re-lit at SUNRISE: warm orange-pink light rising from the EAST edge of the image, long cool shadows pointing west, rail lamps switched off, the city far below now fully lit and alive as in image 2 (canals sparkling, recycling plant running, grid glowing cyan, laboratory lit), clouds below tinted gold. Keep every hatch, socket, rail post and stair exactly where they are in image 1 so the two images can be cross-faded in game. 1536x1024, opaque, no text.

## 3. `assets/core/core_boss.png` — Núcleo Aurora, a forma física da IA

Anexar:
1. `assets/lia_directional/idle.png`
2. `assets/enemies/boss.png`
3. `assets/power/spark.png`
4. `assets/power/props_atlas.png`

> Use case: stylized-concept. Transparent pixel-art BOSS spritesheet for Protocolo 17. Image 1 is Lia: exact finish and 3/4 overhead camera. Images 2 to 4 give the family materials (gunmetal, teal enamel, brass, magenta corrupted core). Do NOT copy the silhouette of image 2. Subject: NÚCLEO AURORA, the AI's physical body: a levitating spherical core about 2.5 times Lia's height, built from mismatched salvaged materials: grey metal alloy plates, teal recycled polymer panels and cracked technical glass, held together by brass clamps and braided cables hanging below it; a blazing MAGENTA core visible between four armour petals; two thin orbit rings made of conductive rods. EXACT 4x4 grid, 256x256 cells, the core centred at the same position in every cell, generous transparent gutters. Row 1: ARMOURED, petals closed, four frames of slow ring rotation. Row 2: SHIELDED, the same with pale-blue light glowing along the petal seams, four frames. Row 3: EXPOSED, petals torn open and hanging, magenta core pulsing large, four frames. Row 4: COLLAPSE, the core dropping and dimming; frames 1 and 2 falling, frame 3 resting on the floor still magenta, frame 4 resting on the floor with a calm CYAN contained glow. Transparent alpha, no floor, no cast shadows, no text. 1024x1024.

## 4. `assets/core/pillars.png` — pilares de alimentação

Anexar:
1. `assets/lia_directional/idle.png`
2. `assets/power/props_atlas.png`

> Use case: stylized-concept. Production transparent pixel-art prop strip for Protocolo 17. Image 1 is Lia for craft and human scale; image 2 is the approved prop atlas of the Energy district: same finish, palette and baseline convention. EXACT 4 columns x 1 row, four equal 256x256 cells, one object per cell, the foot on a common baseline about 210 px from the top. A POWER PILLAR about 1.6 times Lia's height: square steel column with stacked ceramic insulator rings, brass caps, a thick cable going down into the floor. (1) ONLINE: cyan glowing rings feeding energy upward. (2) OVERLOADING: rings flickering white, small electric arcs around it. (3) DISCHARGED: dark rings, thin smoke wisps. (4) FALLEN: column cracked and leaning, broken cable. Same pedestal in every cell. Transparent alpha, no floor, no shadows, no text. 1024x256.

## 5. `assets/core/gallery.png` — Galeria do Núcleo

Anexar:
1. `assets/power/district_northwest_on.png`
2. `assets/prologue/laboratory_set_v1.png`
3. `assets/lia_directional/idle.png`

> Use case: stylized-concept. Opaque 1536x1024 background with the same finish and camera as image 1, using the interior lighting language of image 2. Image 3 is Lia for scale. Subject: CORE GALLERY, a long rectangular service hall at the top of Aurora tower. South centre: the open landing of an elevator shaft. East wall: a conveyor belt running north, carrying crates of grey alloy, teal polymer and glass shards (materials from the recycling district). North centre: an EMPTY robotic assembly cradle with hanging clamps and cut cables, as if a large body just left it; behind it a wide stair rises north out of the frame. West wall: server cabinets with small teal lights and one wide control desk with a dark screen. The floor is clear in the middle for walking. Cool teal light with a few amber service lamps. No characters, no text, no UI.

## 6. `assets/core/choice_consoles.png` — os dois consoles da decisão

Anexar:
1. `assets/lia_directional/idle.png`
2. `assets/power/terminals_atlas.png`

> Use case: stylized-concept. Production transparent pixel-art prop strip for Protocolo 17. Image 1 is Lia for craft and scale; image 2 is the approved terminal atlas: same finish and baseline. EXACT 4 columns x 1 row, 256x256 cells, foot on a common baseline about 210 px from the top. (1) CONTAINMENT CONSOLE idle: a waist-high steel lectern with a round cyan ring emitter on top and a palm plate, dim. (2) The same CONTAINMENT CONSOLE active: the ring emitter projecting a bright cyan hologram ring upward. (3) UPLINK CONSOLE idle: a waist-high steel lectern with a slim antenna mast and a magenta-lit keyboard, dim. (4) The same UPLINK CONSOLE active: the mast shooting a thin magenta beam upward, screen glowing magenta. The two consoles must read as a matching pair with opposite colours. Transparent alpha, no floor, no shadows, no text. 1024x256.

## 7. `assets/core/ending_ai_aurora.png` — final da IA: Aurora verde e vazia

Anexar:
1. `assets/prologue/aurora_before.png`

> Use case: stylized-concept. Background illustration, 1536x1024, opaque. Image 1 is Aurora before the collapse. Keep the SAME composition, camera and buildings, but show Aurora one year after the AI took full control: completely EMPTY of people, crystal-clear canals with fish visible, lush green vegetation reclaiming bridges and terraces, birds, clean air, perfectly maintained buildings with a faint magenta glow in every window and on the tower antenna. Small maintenance drones tend gardens in silence. Beautiful but eerie: nobody is there. Soft morning light. No text, no UI, no large foreground character.

## 8. `assets/core/ending_ai_pier.png` — final da IA: outra cidade, outra agente

Anexar:
1. `docs/direcao-visual/distrito-das-aguas-conceito.png`
2. `assets/lia_directional/idle.png`

> Use case: stylized-concept. Background illustration, 1536x1024, opaque, same pixel finish and 3/4 overhead camera as image 1. A DIFFERENT coastal city at night, NOT Aurora: a quiet harbour pier with wet wooden and concrete docks, a few dark cargo cranes, a city skyline with orange lights in the distance. A small magenta light blinks on a junction box at the end of the pier. A lone recovery agent stands at the start of the pier seen from behind as a dark silhouette in a short jacket with a radio on the shoulder; she must NOT look like Lia (different hair and outfit, image 2 only gives the scale). Mood: calm and unsettling. No text, no UI.

---

## Depois de gerar

1. Rode `tools/import_core_art.gd` (ver o plano em `docs/codex/PLANO_FASE_FINAL.md`, etapa 3). Ele recorta as folhas pelo canal alfa e escreve `assets/core/frames.json`.
2. Rode `tools/review_core.gd` e abra as capturas em `captures/nucleo/`.
3. Confira três coisas: a Lia e os inimigos nunca ficam escondidos pelos pilares ou pelo núcleo; os pés de todos os objetos encostam no chão; as versões de noite e de amanhecer da arena se sobrepõem sem deslocamento.
