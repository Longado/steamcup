# Draws Steamcup's 32×32 pixel icon (a steaming coffee cup) and builds AppIcon.icns. Run: python3 icon/make_icon.py
import os, subprocess, shutil
from PIL import Image

N = 32
BG = (58, 36, 26)                              # espresso brown
CREAM, CREAM_D = (250, 238, 210), (216, 192, 154)
COFFEE, COFFEE_L = (122, 70, 38), (158, 100, 58)
SAUCER, SAUCER_D = (196, 160, 118), (150, 114, 78)
STEAM = [(255, 248, 232), (232, 214, 184)]

img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
px = img.load()

def rounded(x, y, r=6, lo=1, hi=30):
    # pixel-stepped squircle mask
    cx = min(max(x, lo + r), hi - r); cy = min(max(y, lo + r), hi - r)
    return lo <= x <= hi and lo <= y <= hi and (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 2

for y in range(N):
    for x in range(N):
        if rounded(x, y):
            px[x, y] = BG

def rect(x0, x1, y, c):
    for x in range(x0, x1 + 1): px[x, y] = c

DY = 1  # vertical nudge to centre the whole drawing in the tile

# saucer
rect(4, 26, 26 + DY, SAUCER); rect(6, 24, 27 + DY, SAUCER_D)
# cup body (tapers at the bottom), right edge shaded
for y in range(15, 26):
    x0, x1 = (7, 22) if y < 24 else (8, 21) if y == 24 else (9, 20)
    rect(x0, x1, y + DY, CREAM)
    rect(x1 - 1, x1, y + DY, CREAM_D)
# rim + coffee surface
rect(7, 22, 14 + DY, CREAM)
rect(8, 21, 15 + DY, COFFEE); rect(8, 21, 16 + DY, COFFEE)
rect(10, 13, 15 + DY, COFFEE_L)
# handle (hole at x 23-24, y 19-20)
for y, x0 in {17: 23, 18: 23, 19: 25, 20: 25, 21: 24, 22: 23}.items():
    rect(x0, 26, y + DY, CREAM)
rect(23, 26, 17 + DY, CREAM_D)

# steam: three 2px-wide wavy strands, middle one taller
WAVE = [0, 0, 1, 1, 1, 0, 0, 0, -1, -1]
for base, top in ((10, 5), (15, 3), (20, 5)):
    for i, y in enumerate(range(top, 13)):
        x = base + WAVE[(i + 2 * base) % len(WAVE)]
        px[x, y + DY] = STEAM[0]; px[x + 1, y + DY] = STEAM[1]

here = os.path.dirname(os.path.abspath(__file__))
# macOS icon grid: artwork ~824 of 1024 → 32 px × 26 = 832, centred, crisp nearest-neighbour
big = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
big.paste(img.resize((832, 832), Image.NEAREST), (96, 96))
if os.environ.get("STEAMCUP_PREVIEW"):            # optional: write a PNG preview to the given path
    big.resize((256, 256), Image.NEAREST).save(os.environ["STEAMCUP_PREVIEW"])

iconset = os.path.join(here, "AppIcon.iconset")
shutil.rmtree(iconset, ignore_errors=True); os.makedirs(iconset)
for s in (16, 32, 128, 256, 512):
    big.resize((s, s), Image.NEAREST).save(f"{iconset}/icon_{s}x{s}.png")
    big.resize((s * 2, s * 2), Image.NEAREST).save(f"{iconset}/icon_{s}x{s}@2x.png")
subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(here, "AppIcon.icns")], check=True)
shutil.rmtree(iconset)
print("wrote icon/AppIcon.icns")
