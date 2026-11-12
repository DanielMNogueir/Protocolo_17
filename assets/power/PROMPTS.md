# Prompts do Distrito de Energia — Operação Corrente

Arte gerada no Codex com a ferramenta integrada `image_gen`, no mesmo fluxo de `assets/residues/PROMPTS-V3.md` e `assets/enemies/PROMPTS.md`.

Enquanto a arte não chega, o jogo desenha tudo em código. O jogo troca sozinho para a arte pintada quando os arquivos abaixo existirem com estes nomes exatos.

## Como usar

1. **Gere na ordem dos números.** Cada prompt diz o **arquivo de saída** e as **imagens a anexar**, na ordem: imagem 1, imagem 2…
2. **Salve em `assets/power/`** com o nome indicado. As referências de enquadramento já estão em `assets/power/reference/`. Para refazê-las, rode `Godot --path . --script tools/review_power.gd`.
3. **Me avise quando terminar.** Eu faço o recorte dos atlas, os oclusores (Lia passando atrás de prédios), o ajuste fino de colisão sobre a arte final e reviso as capturas.

### Por que as placas de referência importam

A colisão, a navegação dos drones, os portões e as luzes do shader já estão calibrados sobre a geometria das placas `reference/sector_*.png`. Cada setor pintado precisa manter **exatamente** o mesmo enquadramento, as mesmas paredes, portas e larguras de piso. Se um prédio mudar de lugar, a Lia atravessa paredes ou bate no vazio.

### Planta do distrito (espaço de origem 1536 × 1024)

```
 x→ 0        270  390   610        900        1250 1360   1536
y 50 ┌─────────────────────┐┌─────────┐┌──────────────────────┐
     │ CENTRAL SOLAR AURORA ││ telhados││ TORRE DE DISTRIBUIÇÃO│
     │ coletor ● ▓▓▓ painéis││         ││ NORTE     ╱╲ treliça  │
 190 │  espelhos ┼     ┼    │├─CORREDOR┤│ relé R1        R2 ●   │
     │                      ║ ⚡ ⚡ cabos║│ transformador  ⚡ pilones
 290 │ sala ▣  ┼ espelho 3  │├─────────┤│                R3 ●   │
     │ terminal ▭  inversor │|telhados ││ terminal ▭  sala ▣    │
 430 └────┤portaria├────────┘└─────────┘└──────┤portão├────────┘
 470 ═══════════════════ AVENIDA DE SERVIÇO ═══════════════════
 590 ┌──────────────────────┐┌─────────┐┌──┤portão├────────────┐
     │ PÁTIO DE MANUTENÇÃO   ││ telhados││ BANCO DE BATERIAS   │
     │ gerador  oficina      ││         ││ ▥banco ▥banco ▥banco│
     │ (início da Lia)       ││         ││ ▭cons. ▭cons. ▭cons.│
     │ carretéis  contêiner  ││         ││ ▮pilar  (◯ anel) ▮  ║ELEVADOR
 980 └──────────────────────┘└─────────┘└─────────────────────┘
```

**Paleta da casa:** azul-petróleo, metal escuro, latão, núcleo magenta (#e36b92) só nos inimigos.

- **Apagado:** âmbar de emergência (#e8bd74).
- **Aceso:** ciano (#7be4ce) e elétrico (#9fe9ff).
- **Câmera:** superior 3/4, luz vinda de cima à esquerda, contornos escuros, pixel art nítida.

---

## 1. Placa de conceito do distrito
**Saída:** `assets/power/concept_district.png` (opcional; serve de referência de estilo para os prompts 2–9)
**Anexar:**
1. `assets/power/reference/district_on.png`
2. `assets/residues/district_city_v3.png`

> Use case: stylized-concept. Edit target: image 1 is the exact LAYOUT of a top-down game district at night, drawn as flat placeholder blocks. Image 2 is the approved finished art of a neighbouring district in the same game: copy its exact pixel-art craft, orthographic overhead 3/4 viewpoint, palette, line weight, material rendering and level of detail. Repaint image 1 as a finished production game background of the ENERGY DISTRICT of the eco-city Aurora, preserving its layout exactly: same building footprints, walls, door openings, floor areas, avenue, plazas and every object position. Top-left: CENTRAL SOLAR AURORA, a gravel solar yard with three rows of dark-blue photovoltaic panel tables, a tall cylindrical solar collector tower with a brass receiver dome at top-left, a small control room building at the left, an inverter cabinet block bottom-right, a junction box top-right. Centre top: a narrow CABLE CORRIDOR between two roofs, with cable benches on both sides. Top-right: TORRE DE DISTRIBUIÇÃO NORTE, a concrete transmission yard dominated by a tall steel lattice pylon with insulator strings, a command building at the right, insulator crates, spare coil spools. Middle: a horizontal SERVICE AVENUE with lamp posts on both curbs, a pedestrian crossing, a glowing underground cable trench running along it. Bottom-left: MAINTENANCE YARD with an emergency generator, a workshop building, cable reels, a shipping container and a disconnected transformer. Bottom-right: BANCO DE BATERIAS CENTRAL, three long battery bank cabinets along the north wall with glowing charge cells, a circular recharge ring of brass segments in the floor, two support pillars, and the CORE ELEVATOR shaft door embedded in the east wall. Powered state: cool cyan indicator lights, lit windows, glowing cable trench. Crisp detailed pixel clusters, no blur, no painterly strokes, no bloom. Broad floors stay EMPTY and walkable. No characters, robots, weapons, HUD, text or labels. 1536x1024.

## 2–5. Setores apagados (blackout)
Um prompt por setor. Troque `<SETOR>` por northwest, northeast, southwest ou southeast.

**Saída:** `assets/power/district_<SETOR>_off.png` (1536 × 1024)
**Anexar:**
1. `assets/power/reference/sector_<SETOR>_off.png`
2. `assets/residues/district_<SETOR>_v3.png` (mesmo canto do distrito vizinho, só referência de acabamento)
3. `assets/power/concept_district.png` (se gerado)

> Edit target: image 1 is an EXACTLY FRAMED game tile of a top-down game district, drawn as flat placeholder blocks. Repaint it as a finished, crisply detailed 1536x1024 pixel-art game background tile of the SAME exact scene in the SAME exact framing. Image 2 is the approved finished art of a neighbouring district in the same game: match its pixel-art craft, orthographic overhead 3/4 viewpoint, palette, outline weight, material rendering and detail density exactly. Image 3 (if attached) is the approved concept of this district for materials and mood.
> This tile will be placed in its exact location in a larger game map whose collision data already matches image 1. Preserve every silhouette, footprint, wall line, door opening, floor width, curb, lamp post position, pipe and building EXACTLY in place. No camera change, no zoom, no crop, no pan, do not extend or show anything beyond any of the four edges, do not centre or complete objects cut by the edges.
> Subject: the ENERGY DISTRICT of eco-city Aurora during a BLACKOUT. Everything is unpowered: dead dark-blue photovoltaic panels, unlit windows, cold dark cable trenches, battery bank cells nearly empty with a faint amber reading, lamp posts unlit with only a tiny amber emergency diode, brass and steel surfaces lit by neutral moonlight from the upper left. Keep it readable, not black — the game adds its own darkness shader on top. Give materials real texture: gravel, cracked concrete, ribbed roofing, riveted steel, braided cables, hazard stripes on thresholds, small wear and dust. Broad clear floors must stay EMPTY and traversable; no extra props or clutter on walkable areas. No characters, robots, weapons, HUD, text, labels or interface. No photorealism, painterly blur or baked bloom.

## 6–9. Setores acesos (energia restaurada)
**Saída:** `assets/power/district_<SETOR>_on.png` (1536 × 1024)
**Anexar:**
1. `assets/power/district_<SETOR>_off.png` (o resultado aprovado do passo anterior)
2. `assets/power/reference/sector_<SETOR>_on.png`

> Edit target: image 1 is a finished pixel-art game background tile. Produce the SAME image, pixel-aligned, with IDENTICAL framing, geometry, objects, materials and composition — only the lighting state changes, because the district's power has been restored. The two versions are cross-faded in game, so nothing may move, appear or disappear. Image 2 shows which elements light up. Changes allowed: photovoltaic panels show a subtle sky-blue sheen; building windows glow soft cyan; indicator diodes and console screens turn cyan; lamp posts carry a small cool-white lamp with a tight pool of light on the pavement; the underground cable trench glows with a thin cyan line and evenly spaced cyan nodes; battery bank cells are full and glowing cyan; the solar collector dome glows warm white; the core elevator door frame glows cyan. Keep glows tight and pixel-crisp — no large bloom, haze or lens effects, and no change to shadows, palette of materials or level of detail. No characters, robots, HUD, text or labels. 1536x1024.

## 10. Atlas de interações
**Saída:** `assets/power/props_atlas.png` (1024 × 1024, transparente)
**Anexar:**
1. `assets/lia_directional/idle.png` (escala e acabamento)
2. `assets/power/district_northwest_off.png`
3. `assets/residues/interactions_v2.png` (formato de atlas já usado no jogo)

> Use case: stylized-concept. Production transparent pixel-art prop atlas for Protocolo 17. Image 1 is the player character Lia: match her exact pixel-art craft, outline weight and 3/4 overhead camera, and keep props at the SAME human scale (Lia is about 64 px tall in this sheet's scale; props sit on the same floor). Image 2 is the background these props stand on: match its palette and materials. Image 3 shows the atlas convention used by the game. EXACT uniform 4-column by 4-row grid, 16 equal 256x256 cells, one isolated prop per cell, each prop centred horizontally with its FOOT (floor contact point) on the same baseline about 200 px from the top of every cell, generous transparent gutters. Row 1 and row 2: a HELIOSTAT MIRROR — short brass-and-steel pedestal with a single square reflective mirror panel on a tilting yoke, about Lia's height; the mirror's reflective face points in eight compass headings, row-major: RIGHT, DOWN-RIGHT, DOWN, DOWN-LEFT, then LEFT, UP-LEFT, UP, UP-RIGHT; same pedestal in every cell, true redrawn perspective views, never a flat rotation. Row 3: (1) power RELAY post unpowered — slim insulator stack with a dark glass bulb on top, (2) the same relay ENERGISED with a cyan glowing bulb and tiny sparks, (3) ARC PYLON idle — short ceramic insulator column with a copper ring electrode on top and a hazard-striped base, (4) the same arc pylon CHARGED with a crackling pale-blue electrode. Row 4: (1) battery CELL CONSOLE, waist-high steel lectern with a small screen, idle amber screen, (2) the same console CRITICAL with a magenta flashing screen and warning light, (3) CORRUPTED TRANSFORMER, a squat chunky electrical transformer box with three ceramic bushings on top, teal panels, a magenta corrupted core glowing through a vent, (4) the same transformer DAMAGED, cracked casing, sparking, core flickering. Crisp outlined pixel clusters with upper-left highlights. Transparent alpha background, no floor, no cast shadows, no text, labels or gridlines. Square 1024x1024. Preserve real transparency.

## 11. Terminais e elevador
**Saída:** `assets/power/terminals_atlas.png` (1024 × 256, transparente)
**Anexar:**
1. `assets/lia_directional/idle.png`
2. `assets/power/props_atlas.png`

> Use case: stylized-concept. Production transparent pixel-art prop strip for Protocolo 17. Image 1 is Lia for exact craft and human scale; image 2 is the approved prop atlas of the same district — same finish, palette and baseline convention. EXACT 4 columns by 1 row, four equal 256x256 cells, one isolated object per cell, foot on a common baseline about 210 px from the top, transparent gutters. (1) GRID CONTROL TERMINAL unpowered — a wide industrial control desk with a slanted panel, a horizontal analog gauge strip, a big brass lever and dark screens, amber standby diode. (2) the same terminal ONLINE — cyan screens, gauge strip lit, small status lights. (3) CORE ELEVATOR DOOR closed — tall narrow armoured shaft door seen from the west at 3/4, heavy steel leaves with yellow-black hazard bands, magenta lock light. (4) the same CORE ELEVATOR DOOR open — leaves retracted, a cyan-lit lift cabin visible inside with vertical light lines. Crisp outlined pixel art, upper-left light. Transparent alpha, no floor, shadows, text or gridlines. 1024x256.

## 12. Faísca (inimigo)
**Saída:** `assets/power/spark.png` (1024 × 1024, transparente)
**Anexar:**
1. `assets/lia_directional/idle.png`
2. `assets/enemies/scout.png`

> Use case: stylized-concept. Production transparent pixel-art enemy spritesheet for Protocolo 17. Image 1 is Lia, exact pixel-cluster rendering and 3/4 overhead camera reference. Image 2 is the approved SCOUT: same family materials and scale, do NOT copy its silhouette. New subject: SPARK (Faísca), a small, fast, aggressive electrical drone shaped like a streamlined arrowhead capsule with a single rear ducted thruster, two short stubby conductor fins that crackle with pale-blue electricity, a glowing magenta corrupted core visible through a slot on its back, brass contact prongs at the nose that it uses to ram, gunmetal shell with teal enamel panels and tiny yellow hazard marks. It reads as lightning-quick and dangerous. Real crisp pixel clusters, dark outlines, upper-left light, no smooth 3D look. EXACT uniform 4-column by 4-row grid, 16 equal 256x256 cells, each drone the same scale and centred at the same position, generous transparent gutters. Frames row-major: row1 headings RIGHT, DOWN-RIGHT, DOWN, DOWN-LEFT; row2 LEFT, UP-LEFT, UP, UP-RIGHT; row3 repeats row1 as a second frame with the thruster flame flickered and the fin arcs in a different crackle shape; row4 repeats row2 likewise. True redrawn directional perspective views, never a rotated flat sprite. Transparent background, no floor, shadows, text or gridlines. Square 1024x1024. Preserve real alpha.

## 13. Bobina (inimigo fixo)
**Saída:** `assets/power/coil.png` (1024 × 1024, transparente)
**Anexar:**
1. `assets/lia_directional/idle.png`
2. `assets/enemies/sentry.png`

> Use case: stylized-concept. Production transparent pixel-art enemy spritesheet for Protocolo 17. Image 1 is Lia, exact pixel craft and 3/4 overhead camera. Image 2 is the approved SENTRY for family materials, do NOT copy its silhouette. New subject: COIL (Bobina), a stationary corrupted Tesla-coil turret bolted to the floor: a square riveted steel base with hazard-striped corners, a tall copper-wound coil column, a rotating spherical electrode head on top with a single magenta sensor eye and two short emitter horns that point toward its target, braided cables running from the base. Two coils project an arc between their heads in game, so keep the head clearly separated at the top. Crisp outlined pixel clusters with upper-left highlights. EXACT uniform 4-column by 4-row grid, 16 equal 256x256 cells, identical base position in every cell (the base never moves), generous transparent gutters. Row1: head facing RIGHT, DOWN-RIGHT, DOWN, DOWN-LEFT; row2: LEFT, UP-LEFT, UP, UP-RIGHT; row3 repeats row1 with the coil windings glowing magenta and small sparks around the head (charging frame); row4 repeats row2 likewise. Only the head turns; true redrawn perspective. Transparent alpha, no floor, shadows, text or gridlines. Square 1024x1024.

## 14. Beatrix digital
**Saída:** `assets/power/beatrix_digital.png` (512 × 512, transparente)
**Anexar:**
1. `assets/prologue/beatrix_portrait_v1.png`
2. `assets/prologue/ai_portrait_v1.png` (moldura e acabamento dos retratos de diálogo)

> Use case: stylized-concept. Dialogue portrait for Protocolo 17. Image 1 is the approved portrait of Dr. Beatrix: keep her EXACT identity, face, curly hair, lab coat, expression and framing. Image 2 shows the finish of the game's dialogue portraits. Create BEATRIX AS A PRESERVED DIGITAL RECORD replayed through the restored power grid: the same portrait rendered as a pixel-art hologram — cyan and pale-blue monochrome palette with soft white highlights, fine horizontal scanlines, a few displaced glitch slices, faint data-noise speckles at the edges, slight transparency so the dark background shows through her silhouette, a thin projector glow rising from the bottom edge. Calm, warm, trustworthy expression. Crisp pixel art matching image 1's resolution and framing, head and shoulders, centred. Transparent background outside the hologram. No text, frame, UI or labels. 512x512.

---

## O que entra em código, sem arquivo

- **Raios e arcos:** postes, bobinas, descargas da Sobrecarga e rastro da Faísca.
- **Feixe solar** entre os espelhos e o coletor.
- **Escudos hexagonais** do transformador, onda do EMP, anel de carga e brilho dos núcleos no escuro.
- **Escuridão e luz:** o shader `scripts/power_lighting.gdshader`.
- **Áudio:** todo procedural, em `scripts/audio.gd` (climas "blackout" e "grid"; efeitos de arco, descarga, relé, espelho, alívio de célula e EMP).
