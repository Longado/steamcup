# Draws Steamcup's 18x18 menu bar template icons (black + alpha only, no anti-aliasing).
# Run from the steamcup folder: python3 icon/make_menubar.py
import os
from PIL import Image

N = 18
here = os.path.dirname(os.path.abspath(__file__))

def new():
    return Image.new("RGBA", (N, N), (0, 0, 0, 0))

def dot(img, x, y):
    img.putpixel((x, y), (0, 0, 0, 255))

def rect(img, x0, x1, y):
    for x in range(x0, x1 + 1): dot(img, x, y)

def cup(img, dy, filled):
    """Same cup as the app icon: rim, tapered body, handle, two-row saucer."""
    top = 8 + dy
    for y in range(top, top + 7):
        x0, x1 = (2, 12) if y < top + 6 else (3, 11)
        if filled or y in (top, top + 6):
            rect(img, x0, x1, y)
        else:
            dot(img, x0, y); dot(img, x1, y)
    # handle: outlined loop on the right
    rect(img, 13, 15, top + 1)
    dot(img, 15, top + 2); dot(img, 15, top + 3)
    rect(img, 13, 15, top + 4)
    # saucer
    rect(img, 1, 15, top + 7)
    rect(img, 3, 13, top + 8)

def steam(img):
    """Three 1px wavy wisps, the middle one taller."""
    for x, y0, phase in ((4, 2, 0), (7, 1, 3), (10, 2, 0)):
        for i, y in enumerate(range(y0, 7)):
            dot(img, x + (0, 0, 1, 1, 0, 0)[(i + phase) % 6], y)

def padlock(img):
    """Lid-closed badge, top right."""
    rect(img, 11, 15, 1)                       # shackle
    dot(img, 11, 2); dot(img, 15, 2)
    for y in range(3, 7): rect(img, 10, 16, y)  # body
    img.putpixel((13, 4), (0, 0, 0, 0)); img.putpixel((13, 5), (0, 0, 0, 0))  # keyhole

def build(name, fn):
    img = new(); fn(img)
    img.save(os.path.join(here, f"{name}.png"))
    img.resize((N * 2, N * 2), Image.NEAREST).save(os.path.join(here, f"{name}@2x.png"))

def off(img):  cup(img, -3, False)
def on(img):   cup(img, 0, True); steam(img)
def lid(img):  cup(img, 0, True); padlock(img)

if __name__ == "__main__":
    for name, fn in (("menubar-off", off), ("menubar-on", on), ("menubar-lid", lid)):
        build(name, fn)
    print("wrote icon/menubar-{off,on,lid}[@2x].png")
