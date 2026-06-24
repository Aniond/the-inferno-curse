from PIL import Image

path = r"c:\Users\david\OneDrive\Desktop\Screenshot 2026-06-23 155336.png"
img = Image.open(path).convert("RGB")
w, h = img.size
print(f"Image: {w}x{h}")
pixels = img.load()


def is_cyan_grid(r, g, b):
    return g > 140 and b > 170 and r < 140 and (b - r) > 40


def is_green_highlight(r, g, b):
    return g > 120 and r < 100 and b < 120 and g > r + 30


def is_wood(r, g, b):
    return 60 < r < 180 and 40 < g < 120 and b < 90


cyan_pts = []
green_pts = []
wood_pts = []
for y in range(h):
    for x in range(w):
        r, g, b = pixels[x, y]
        if is_cyan_grid(r, g, b):
            cyan_pts.append((x, y))
        if is_green_highlight(r, g, b):
            green_pts.append((x, y))
        if is_wood(r, g, b):
            wood_pts.append((x, y))


def bbox(pts):
    if not pts:
        return None
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


print("Cyan grid bbox:", bbox(cyan_pts), "count:", len(cyan_pts))
print("Green highlight bbox:", bbox(green_pts), "count:", len(green_pts))
print("Wood bbox:", bbox(wood_pts), "count:", len(wood_pts))

cols, rows = 60, 35
for row in range(rows):
    line = ""
    for col in range(cols):
        x = int(col * w / cols)
        y = int(row * h / rows)
        r, g, b = pixels[x, y]
        if is_cyan_grid(r, g, b):
            line += "+"
        elif is_green_highlight(r, g, b):
            line += "G"
        elif is_wood(r, g, b):
            line += "."
        elif r + g + b < 80:
            line += "#"
        else:
            line += " "
    print(line)

for name, (cx, cy) in [("TL", (w * 0.25, h * 0.35)), ("C", (w * 0.5, h * 0.5)), ("BR", (w * 0.75, h * 0.65))]:
    x, y = int(cx), int(cy)
    r, g, b = pixels[x, y]
    print(f"{name} ({x},{y}) RGB=({r},{g},{b})")