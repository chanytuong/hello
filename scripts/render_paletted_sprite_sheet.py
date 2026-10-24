from pathlib import Path
import sys
import json, math
from PIL import Image, ImageDraw, ImagePalette

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
BLEND = ROOT / "artifacts/iven_roll_redesign" / "IVEN_ROLL.blend"
SHEET = ROOT / "artifacts/iven_roll_redesign" / "IVEN_ROLL_sheet.png"

FPS = 30
DURATION = 0.5
N = int(DURATION * FPS)
W_DEFAULT, H_DEFAULT = 256, 256
MARGIN = 4

PALETTE_DEEP = [
    (12, 12, 14),
    (28, 30, 33),
    (44, 47, 52),
    (60, 64, 70),
    (78, 83, 90),
    (96, 102, 110),
    (116, 123, 132),
    (138, 146, 156),
    (162, 171, 182),
    (188, 198, 210),
    (215, 226, 238),
    (240, 246, 252),
]

PALETTE_FLAME = [
    (180, 40, 20),
    (220, 80, 30),
    (255, 120, 40),
    (255, 160, 60),
    (255, 200, 90),
    (255, 230, 140),
    (255, 250, 200),
]

PALETTE_SHADOW = [
    (0, 0, 0),
    (10, 10, 12),
    (20, 20, 22),
    (30, 30, 33),
]

def _make_palette():
    pal = [0, 0, 0]
    for rgb in PALETTE_DEEP + PALETTE_FLAME + PALETTE_SHADOW:
        pal.extend(rgb)
    while len(pal) < 256 * 3:
        pal.extend((0, 0, 0))
    return ImagePalette.ImagePalette("RGB", bytes(pal[:256*3]))

def _draw_cell(img, cx, cy, shade, flame):
    d = ImageDraw.Draw(img)
    base = shade if not flame else PALETTE_FLAME[2]
    x0, y0 = cx, cy
    x1, y1 = cx + W - 2 * MARGIN, cy + H - 2 * MARGIN
    d.rectangle([x0, y0, x1, y1], fill=base)
    if flame:
        d.ellipse([x0 + 14, y0 + 10, x1 - 14, y1 - 10], fill=PALETTE_FLAME[4])
        d.ellipse([x0 + 22, y0 + 18, x1 - 22, y1 - 18], fill=PALETTE_FLAME[5])

def _cel_paths():
    return sorted((BLEND.parent / "renders").glob("roll_*.png"))


def _cel_count():
    return len(list(_cel_paths()))

def _cel_count():
    return len(list(_cel_paths()))

def _apply_palette(img):
    img = img.convert("RGB")
    pal_img = Image.new("P", (W, H))
    pal_img.putpalette(_make_palette())
    pal_img.paste(img)	return pal_img


def main():
	paths = _cel_paths()
	n = len(paths)
	if n == 0:
		img = Image.new("P", (W_DEFAULT * N, H_DEFAULT), 0)
		img.putpalette(_make_palette())
		SHEET.parent.mkdir(parents=True, exist_ok=True)
		img.save(SHEET)
		print("wrote blank sheet", SHEET)
		return
	first = Image.open(paths[0]).convert("RGB")
	_w = min(W_DEFAULT, first.size[0])
	_h = min(H_DEFAULT, first.size[1])
	n_frames = N
	sheet_w = _w * n_frames + (n_frames - 1) * MARGIN
	sheet_h = _h
	sheet = Image.new("P", (sheet_w, sheet_h), 0)
	sheet.putpalette(_make_palette())
	for i in range(n_frames):
		p = paths[i % n]
		cel = Image.open(p).convert("RGB")
		cel = cel.resize((_w, _h), Image.LANCZOS)
		pal_cel = _apply_palette(cel)
		x = i * (_w + MARGIN)
		sheet.paste(pal_cel, (x, 0))
	SHEET.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(SHEET)
	print("wrote", SHEET, sheet.size, "frames", n)

if __name__ == "__main__":
    main()
