from PIL import Image

path = r"c:\Users\david\OneDrive\Desktop\Screenshot 2026-06-23 155336.png"
img = Image.open(path).convert("RGB")
w, h = img.size
pixels = img.load()


def is_cyan_grid(r, g, b):
    return g > 140 and b > 170 and r < 140 and (b - r) > 40


def is_wood(r, g, b):
    return 60 < r < 180 and 40 < g < 120 and b < 90


# Per-column cyan density in lower 60% of image (game view)
y0, y1 = int(h * 0.15), int(h * 0.92)
col_cyan = []
for x in range(w):
    count = 0
    for y in range(y0, y1):
        r, g, b = pixels[x, y]
        if is_cyan_grid(r, g, b):
            count += 1
    col_cyan.append(count)

# Per-row
row_cyan = []
for y in range(y0, y1):
    count = 0
    for x in range(w):
        r, g, b = pixels[x, y]
        if is_cyan_grid(r, g, b):
            count += 1
    row_cyan.append(count)

def first_last_above(threshold, arr):
    first = last = None
    for i, v in enumerate(arr):
        if v > threshold:
            if first is None:
                first = i
            last = i
    return first, last

cx0, cx1 = first_last_above(5, col_cyan)
ry0, ry1 = first_last_above(5, row_cyan)
print(f"Cyan span columns: {cx0}-{cx1} (width {cx1-cx0 if cx0 else 0})")
print(f"Cyan span rows: {y0+ry0}-{y0+ry1} (height {ry1-ry0 if ry0 else 0})")

# Wood floor span
col_wood = []
for x in range(w):
    count = sum(1 for y in range(y0, y1) if is_wood(*pixels[x, y]))
    col_wood.append(count)
wx0, wx1 = first_last_above(20, col_wood)
print(f"Wood span columns: {wx0}-{wx1} (width {wx1-wx0 if wx0 else 0})")

# Compare grid vs wood margins
if cx0 and wx0:
    print(f"Grid extends left of wood by: {wx0 - cx0}px")
    print(f"Grid extends right of wood by: {cx1 - wx1}px")

# Zoomed ASCII of game floor region only
x_start, x_end = max(0, (wx0 or 150) - 20), min(w, (wx1 or w) + 20)
y_start, y_end = y0, y1
cols, rows = 50, 28
print("\nFloor region map (.=wood +=grid G=green #=dark):")
for row in range(rows):
    line = ""
    for col in range(cols):
        x = int(x_start + col * (x_end - x_start) / cols)
        y = int(y_start + row * (y_end - y_start) / rows)
        r, g, b = pixels[x, y]
        if is_cyan_grid(r, g, b):
            line += "+"
        elif g > 120 and r < 100:
            line += "G"
        elif is_wood(r, g, b):
            line += "."
        elif r + g + b < 100:
            line += "#"
        else:
            line += " "
    print(line)