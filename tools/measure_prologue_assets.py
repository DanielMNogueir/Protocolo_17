"""Read alpha bounds and emit atlas metadata; preserves the original PNG files."""
from pathlib import Path
from PIL import Image
import statistics

ROOT = Path(__file__).resolve().parents[1] / "assets" / "prologue"
image = Image.open(ROOT / "beatrix.png").convert("RGBA")
width, height = image.size
frames = []
for row in range(3):
    for column in range(8):
        left, top = round(column * width / 8), round(row * height / 3)
        right, bottom = round((column + 1) * width / 8), round((row + 1) * height / 3)
        alpha = image.getchannel("A").crop((left, top, right, bottom))
        box = alpha.point(lambda value: 255 if value > 30 else 0).getbbox()
        if not box:
            raise ValueError(f"Empty sprite: {row}/{column}")
        x0, y0, x1, y1 = box
        # Bottom boot pixels supply a consistent ground anchor, independent of the tablet.
        boot_pixels = [(x, y) for y in range(max(y0, y1 - 10), y1)
                       for x in range(x0, x1) if alpha.getpixel((x, y)) > 80]
        anchor_x = statistics.mean(x for x, _ in boot_pixels)
        frames.append((left + x0, top + y0, x1 - x0, y1 - y0, left + anchor_x, top + y1))
lines = ["extends RefCounted", "const HEIGHT := %.1f" % statistics.median(f[3] for f in frames), "const FRAMES := ["]
for x, y, w, h, ax, ay in frames:
    lines.append(f'\t{{"region":Rect2({x},{y},{w},{h}),"anchor":Vector2({ax:.3f},{ay})}},')
lines.append("]\n")
(ROOT / "beatrix_frames.gd").write_text("\n".join(lines), encoding="utf-8")

image = Image.open(ROOT / "laboratory.png").convert("RGBA")
width, height = image.size
regions = [(0, 0, int(width * .53), int(height * .62)),
           (int(width * .53), 0, width, int(height * .62)),
           (0, int(height * .62), width // 2, height),
           (width // 2, int(height * .62), width, height)]
lines = ["extends RefCounted", "const REGIONS: Array[Rect2] = ["]
for region in regions:
    box = image.getchannel("A").crop(region).point(lambda value: 255 if value > 30 else 0).getbbox()
    if not box:
        raise ValueError("Empty laboratory prop")
    x0, y0, x1, y1 = box
    lines.append(f"\tRect2({region[0]+x0},{region[1]+y0},{x1-x0},{y1-y0}),")
lines.append("]\n")
(ROOT / "laboratory_frames.gd").write_text("\n".join(lines), encoding="utf-8")
print("MEASURED: 24 scientist poses, 4 laboratory props; original PNGs preserved")
