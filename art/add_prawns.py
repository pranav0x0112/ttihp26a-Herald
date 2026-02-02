import pya

OUTPUT_GDS = "../macros/prawns_art/prawns_art.gds"

# MET4
LAYER = 71
DT    = 20

# MET3 for text pixels
TEXT_LAYER = 70   # MET3
TEXT_DT    = 20

# Load
ly = pya.Layout()
ly.dbu = 0.001  # 1 nm DBU (typical)
top = ly.create_cell("PRAWNS_ART")
dbu = ly.dbu
shapes = top.shapes(ly.layer(LAYER, DT))
text_shapes = top.shapes(ly.layer(TEXT_LAYER, TEXT_DT))

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
ox, oy = 5.0, 5.0

# Overall block
char_advance = CHAR_W * (PIX + GAP) + 0.8
block_w = len(TEXT) * char_advance + 1.2
block_h = CHAR_H * (PIX + GAP) + 2.0
shapes.insert(box(ox, oy, ox + block_w, oy + block_h))

# --- MET4 fill block (slightly larger than art block) ---
FILL_BLOCK_LAYER = 71   # same MET4 layer
FILL_BLOCK_DT    = 21   # fill-block datatype (safe, ignored by fab metal)

fill_margin = 0.5  # microns

fill_block = box(
    ox - fill_margin,
    oy - fill_margin,
    ox + block_w + fill_margin,
    oy + block_h + fill_margin
)

top.shapes(ly.layer(FILL_BLOCK_LAYER, FILL_BLOCK_DT)).insert(fill_block)

x = ox + 1.0
y = oy + 1.0

# ---- DRAW TEXT (negative space) ----
for ch in TEXT:
    bitmap = FONT[ch]
    for row in range(CHAR_H):
        for col in range(CHAR_W):
            if bitmap[row][col] == "1":
                px = x + col * (PIX + GAP)
                py = y + (CHAR_H - 1 - row) * (PIX + GAP)
                text_shapes.insert(box(px, py, px + PIX, py + PIX))
    x += CHAR_W * (PIX + GAP) + 0.8

ly.write(OUTPUT_GDS)
print("PRAWNS block font written")
