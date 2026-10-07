"""Measure the six alpha silhouettes; never edit the generated atlas pixels."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1] / "assets" / "prologue"
image = Image.open(root / "laboratory_details.png")
alpha = image.getchannel("A")
# Actual row gutters and silhouette extents, inspected on the original output.
cells = [(0, 0, 566, 550), (566, 0, 1024, 550),
         (0, 550, 500, 1080), (500, 550, 1024, 1080),
         (0, 1080, 610, 1536), (610, 1080, 1024, 1536)]
lines = ["extends RefCounted", "const REGIONS: Array[Rect2] = ["]
for cell in cells:
    bounds = alpha.crop(cell).point(lambda value: 255 if value > 30 else 0).getbbox()
    if not bounds:
        raise ValueError(f"Empty prop: {cell}")
    x0, y0, x1, y1 = bounds
    lines.append(f"\tRect2({cell[0]+x0},{cell[1]+y0},{x1-x0},{y1-y0}),")
lines.append("]\n")
(root / "laboratory_details_frames.gd").write_text("\n".join(lines), encoding="utf-8")
print("MEASURED: six detail sprites; original RGBA atlas preserved")
