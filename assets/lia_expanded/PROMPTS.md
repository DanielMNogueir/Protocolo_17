# Prompts de geração — Lia, 16/09/2026

Ferramenta: image_gen integrada (sem CLI/API externa). Referências locais oficiais source_actions.png e source_walk.png de assets/lia_official. As primeiras saídas foram revisadas para corrigir fundo, passagem das pernas e orientação da arma. Somente as versões finais são consumidas no projeto.

Fonte caminhada final: exec-8c94f0a3-5046-47cc-9855-db2571ba1aa9.png → source_walk.png.
Fonte repouso final: exec-6d588672-35a5-44a8-9b15-d002c5d35907.png → source_idle.png.

## liaWalkPrompt

Use case: identity-preserve.
Asset type: production pixel-art game spritesheet, expanded armed walk cycle for Lia in Protocolo 17.
Input image 1: official character identity and weapon grip reference. Use the SECOND ROW (armed Lia) as the exact design reference. Input image 2: official walking character reference for proportions and gait.
Create ONE new spritesheet, landscape 2048x1024, with exactly 8 equal columns and 4 equal rows, 32 separate complete full-body figures. Every cell is 256x256. Transparent background, no labels, text, grid lines, ground shadows or scenery. Keep every sprite entirely within its cell, generous empty margins.
ROW 1: facing camera/down, holding the cyan pulse rifle down-forward with both hands as official reference.
ROW 2: strict side profile facing LEFT, rifle barrel points LEFT, both hands maintain physical grip.
ROW 3: strict side profile facing RIGHT, rifle barrel points RIGHT, both hands maintain physical grip.
ROW 4: rear view facing UP/away, backpack visible, rifle barrel above head points UP, as official reference.
Each row is one coherent eight-frame WALK LOOP left to right: left-foot contact, compression, passing, rise, right-foot contact, compression, passing, rise. Clear distinct alternating leg positions, slight synchronized shoulder movement, elbows flexing, ponytail follow-through. The last phase connects smoothly back to the first. Arm and weapon motion is subtle while hands stay visibly attached. NO repeated static poses or same leg repeatedly lifted. Each sprite SAME size and body proportions, pelvis horizontally centered within cell, boots contact baseline y=232 within each cell, standing height about 210px. Weapon side extension must not move the body center.
Lock identity: the exact small chibi pixel-art Lia shown in both images, warm medium-brown skin, youthful female face, deep teal high ponytail with yellow tie, teal shoulder armor, navy utility jumpsuit, gold/ochre harness and small backpack with green leaf emblem, fingerless dark gloves, chunky brown boots, original compact grey/ochre/cyan pulse rifle. Crisp dark stepped pixel outlines, tight pixel clusters, consistent original 16-bit style and top/front lighting. No redesign, no photorealism, no painterly blur, no new accessories. Include the weapon and gripping hands as integral parts of every full-body sprite.

## liaWalkRefinePrompt

Edit target: the first supplied walking spritesheet. Reference image2 is the exact original official character.
Correct this WALK CYCLE. Keep the character design, size, detailed pixel-art style, four directional rows and exactly eight columns.
CRITICAL corrections:
1. Replace the painted checkerboard background with perfectly solid flat #FF00FF magenta everywhere outside figures, including all gaps between limbs. NO checkerboard and NO ground shadows.
2. The existing side-view rows repeat one bent-leg pose; redraw LEGS in a proper eight-pose walk sequence, clearly distinct: col1 WIDE STRIDE near leg extended forward, rear leg back; col2 weight-down knees bent; col3 PASSING feet close together near leg planted and far knee forward; col4 rising near leg back far knee advancing; col5 OPPOSITE WIDE STRIDE far leg extended forward near leg back; col6 second weight-down; col7 opposite PASSING with near knee forward; col8 rising into col1. In left profile forward means left. In right profile forward means right. Vary the leg silhouettes visibly, narrow and wide, DO NOT repeat the same split-leg stance in every column. Darker farther leg preserves the alternating anatomy.
3. Front and rear rows must also alternate opposite legs and have passing poses every four columns. Head and shoulders follow a subtle two-beat bob, ponytail moves subtly, both hands remain attached to held weapon.
4. In rear row: upper arms bent FORWARD holding rifle, both hands occluded ahead of torso, no arms hanging by hips, no disconnected gun.
All32 poses are fullbody, feet aligned at a consistent row baseline, stable pelvis anchor horizontally at same relative cell coordinate. Rifle and hands retain identical geometry in each direction, moving gently with chest. Do not change original character identity or framing. No labels or text.

## liaWalkPolishPrompt

Edit image1 only (8-column, 4-row armed walking sprite sheet). Image2 is a supporting exact grip reference.
Apply ONLY two final corrections, preserve every other pixel-art design choice and flat magenta background:
A. Bottom row of image1: copy the RAISED forward-bent elbows and absence of hanging hands from bottom row of image2. The rifle must be held in front of torso, hands occluded; no hands at waist. Preserve each walking leg pose, all eight figures, character size and positions.
B. Side-profile rows2 and3: in columns3 and7 ONLY, create real PASSING poses with the two legs overlapping under pelvis, one supporting leg vertical, the other knee just ahead and bent. Both feet close horizontally under torso, NOT a wide stride. Keep col1 and5 wide strides and other columns. At col3 near leg supports, at col7 far leg supports. Keep chest/face/rifle and upper arms exactly unchanged.
Output SAME32 sprites/same grid/same solid magenta. No other edits, no text or shadows.

## liaIdlePrompt

Use case: identity-preserve.
Asset type: production pixel-art game spritesheet, armed idle breathing poses of Lia in Protocolo 17.
Input image is the official character reference. Specifically follow SECOND ROW armed Lia for exact outfit, rifle geometry, pose proportions and two-handed grip.
Create ONE new 1024x1024 spritesheet: exactly 4 equal columns and 4 equal rows (16 complete figures). 256x256 cells. Truly transparent background. NO text, labels, cell lines, shadows, ground, effects or scenery. All figures completely inside their cells. Each character about 210px tall, hip center aligned at cell x128, feet on cell y232. Same scale across every cell.
ROW 1 all four face DOWN/front, hold cyan pulse rifle down-forward with two hands, as reference.
ROW 2 all four strict side profile LEFT, held rifle points LEFT.
ROW 3 all four strict side profile RIGHT, held rifle points RIGHT.
ROW 4 all four rear view facing UP, backpack visible and held rifle points UP beyond head, as reference.
COLUMNS per row form restrained armed idle animation: (1) relaxed neutral exhale, (2) slight inhale shoulders lift and elbows soften, (3) peak breath chest expands slightly, ponytail tip shifts, (4) same neutral pose as column1 with a natural brief blink (back view instead subtle ponytail settling). Tiny natural differences, do NOT rotate or change aim, do not change foot placement. Both hands firmly on weapon throughout. These must be complete coherent full-body sprites, not disconnected body parts.
IDENTITY LOCK: warm medium-brown skin, female youthful face, deep teal high ponytail tied yellow, teal shoulder pads, navy utility jumpsuit, ochre backpack/harness and green leaf emblem, fingerless dark gloves, brown boots, exact compact grey/ochre/cyan pulse rifle from reference. Original crisp dark stepped pixel outlines and compact pixel clusters, faithful 16-bit art. No redesign, no enlarged head, no anime smoothing, no painting, no floating rifle.

## liaIdleRefinePrompt

Edit target image1 armed idle spritesheet; image2 is official design reference.
Keep all16 sprites, 4x4 layout, pixel-art style, character size, face, clothing, tiny breathing differences and blink in fourth column exactly as they are. Change only:
1. Entire checkerboard background to perfectly uniform flat #FF00FF magenta, including enclosed gaps between limbs. No checkerboard, shadows or text.
2. Top row: point the rifle DOWN toward bottom of image, as SECOND ROW FIRST COLUMN of official reference image2; both hands hold it visibly. Do not hold it diagonally across chest. Keep neutral/inhale/peak/blink variations.
3. Bottom row: arms must bend forward to hold upward-facing rifle. Elbows can be visible to sides of chest, hands hidden ahead of torso. Remove hanging forearms/hands at hips. Gun still points up above head and leaf backpack remains visible.
Preserve middle LEFT/RIGHT rows exactly except background. Same crisp stepped pixel outlines and original palette, no redesign.
