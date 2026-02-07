import pya
import os

# Get the directory of this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_GDS = os.path.join(SCRIPT_DIR, "..", "macros", "prawns_art", "prawns_art.gds")

# IHP SG13G2 layer numbers (from ihp-sg13g2.lyp)
# PR boundary - required for OpenLane
PR_BOUNDARY_LAYER = 189
PR_BOUNDARY_DT = 4

# Top metal for power rails - text goes here
MET5_LAYER = 67
MET5_DT = 0

# Load
ly = pya.Layout()
ly.dbu = 0.001  # 1 nm DBU (typical)
top = ly.create_cell("PRAWNS_ART")
dbu = ly.dbu
met5_shapes = top.shapes(ly.layer(MET5_LAYER, MET5_DT))

def box(x1, y1, x2, y2):
    return pya.Box(
        int(x1 / dbu), int(y1 / dbu),
        int(x2 / dbu), int(y2 / dbu)
    )

# ---- FONT SETUP ----
PIX = 0.7      # pixel size (µm)
GAP = 0.2
CHAR_W = 5
CHAR_H = 7

# 5x7 bitmap font (1 = hole, 0 = metal)
FONT = {
    "P": [
        "11110",
        "10001",
        "11110",
        "10000",
        "10000",
        "10000",
        "10000",
    ],
    "R": [
        "11110",
        "10001",
        "11110",
        "10100",
        "10010",
        "10001",
        "10001",
    ],
    "A": [
        "01110",
        "10001",
        "10001",
        "11111",
        "10001",
        "10001",
        "10001",
    ],
    "W": [
        "10001",
        "10001",
        "10001",
        "10101",
        "10101",
        "11011",
        "10001",
    ],
    "N": [
        "10001",
        "11001",
        "10101",
        "10011",
        "10001",
        "10001",
        "10001",
    ],
    "S": [
        "01111",
        "10000",
        "11110",
        "00001",
        "00001",
        "10001",
        "11110",
    ],
}

TEXT = "PRAWNS"

# ---- PLACEMENT ----
ox, oy = 0.0, 0.0

# Calculate dimensions
char_advance = CHAR_W * (PIX + GAP) + 0.8
block_w = len(TEXT) * char_advance + 2.0
block_h = CHAR_H * (PIX + GAP) + 2.0

# --- PR Boundary (must be first, defines macro extent) ---
pr_boundary = box(0, 0, block_w, block_h)
top.shapes(ly.layer(PR_BOUNDARY_LAYER, PR_BOUNDARY_DT)).insert(pr_boundary)

# NO background block - text only on Metal5
x = ox + 1.0
y = oy + 1.0

# ---- DRAW TEXT on Metal5 ----
for ch in TEXT:
    bitmap = FONT[ch]
    for row in range(CHAR_H):
        for col in range(CHAR_W):
            if bitmap[row][col] == "1":
                px = x + col * (PIX + GAP)
                py = y + (CHAR_H - 1 - row) * (PIX + GAP)
                met5_shapes.insert(box(px, py, px + PIX, py + PIX))
    x += CHAR_W * (PIX + GAP) + 0.8

ly.write(OUTPUT_GDS)
print("PRAWNS block font written")
