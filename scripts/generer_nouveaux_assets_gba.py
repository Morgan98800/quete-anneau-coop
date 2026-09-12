import zlib
import struct
import os

def write_png(filename, width, height, rgba_bytes):
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)
        start = y * width * 4
        end = start + width * 4
        raw_data.extend(rgba_bytes[start:end])
    compressed = zlib.compress(raw_data)
    
    def chunk(tag, data):
        c = tag + data
        crc = zlib.crc32(c) & 0xffffffff
        return struct.pack(">I", len(data)) + c + struct.pack(">I", crc)
    
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png.extend(chunk(b"IHDR", ihdr_data))
    png.extend(chunk(b"IDAT", compressed))
    png.extend(chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "wb") as f:
        f.write(png)
    print(f"Generated: {filename} ({width}x{height})")

TRANSPARENT = (0, 0, 0, 0)
BLACK = (18, 20, 24, 255)
WHITE = (245, 248, 250, 255)
SKIN = (248, 208, 160, 255)
SKIN_SHADOW = (212, 156, 112, 255)

# Palettes Aragorn
ARAGORN_HAIR = (52, 42, 34, 255)
ARAGORN_BEARD = (42, 32, 26, 255)
LEATHER_DARK = (68, 50, 36, 255)
LEATHER_LIGHT = (112, 82, 56, 255)
STEEL_BLADE = (200, 215, 235, 255)
STEEL_DARK = (130, 145, 165, 255)
TORCH_WOOD = (120, 75, 40, 255)
FIRE_ORANGE = (255, 140, 20, 255)
FIRE_YELLOW = (255, 230, 80, 255)

# Palettes Gandalf
GANDALF_ROBE = (165, 175, 185, 255)
GANDALF_ROBE_DARK = (115, 125, 140, 255)
GANDALF_HAT = (90, 100, 115, 255)
GANDALF_BEARD = (235, 240, 245, 255)
GANDALF_STAFF = (105, 75, 45, 255)
MAGIC_CYAN = (120, 230, 255, 255)

# Palettes Orque / Gobelin
ORC_SKIN = (95, 128, 75, 255)
ORC_SKIN_DARK = (65, 90, 50, 255)
ORC_ARMOR = (45, 45, 50, 255)
ORC_EYES = (240, 40, 40, 255)
RUST_BLADE = (140, 75, 60, 255)

# Palettes Objets & Donjon
GOLD_KEY = (255, 210, 40, 255)
GOLD_SHADOW = (195, 145, 15, 255)
WOOD_BOX = (145, 95, 50, 255)
WOOD_DARK = (90, 55, 25, 255)
STONE_PLATE = (130, 135, 145, 255)
STONE_PRESSED = (75, 80, 90, 255)
CHEST_BODY = (160, 105, 45, 255)
CHEST_METAL = (195, 205, 215, 255)
WEB_COLOR = (225, 235, 245, 190)
HEART_RED = (235, 45, 65, 255)
HEART_DARK = (140, 20, 35, 255)

def create_grid(w, h):
    return [[TRANSPARENT for _ in range(w)] for _ in range(h)]

def draw_rect(grid, x1, y1, x2, y2, color):
    for y in range(max(0, y1), min(len(grid), y2 + 1)):
        for x in range(max(0, x1), min(len(grid[0]), x2 + 1)):
            grid[y][x] = color

def grid_to_bytes(grid):
    b = bytearray()
    for row in grid:
        for p in row:
            b.extend(p)
    return b

# -------------------------------------------------------------
# 1. ARAGORN SPRITESHEET (128x128 : 4 lignes, 4 colonnes 32x32)
# -------------------------------------------------------------
def build_aragorn_sheet():
    grid = create_grid(128, 128)
    for row in range(4): # 0: BAS, 1: GAUCHE, 2: DROITE, 3: HAUT
        y_offset = row * 32
        for col in range(4):
            x_offset = col * 32
            foot = -2 if col == 1 else (2 if col == 3 else 0)
            bob = 1 if (col == 1 or col == 3) else 0
            attack = (col == 2)

            draw_rect(grid, x_offset + 8, y_offset + 29, x_offset + 24, y_offset + 31, (0, 0, 0, 70))

            if row == 0: # --- FACE (BAS) ---
                draw_rect(grid, x_offset + 10 + foot, y_offset + 26, x_offset + 14 + foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 18 - foot, y_offset + 26, x_offset + 22 - foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 8, y_offset + 13 + bob, x_offset + 24, y_offset + 25 + bob, LEATHER_DARK)
                draw_rect(grid, x_offset + 11, y_offset + 14 + bob, x_offset + 21, y_offset + 24 + bob, LEATHER_LIGHT)
                draw_rect(grid, x_offset + 14, y_offset + 20 + bob, x_offset + 18, y_offset + 22 + bob, STEEL_BLADE)
                draw_rect(grid, x_offset + 10, y_offset + 6 + bob, x_offset + 22, y_offset + 12 + bob, SKIN)
                draw_rect(grid, x_offset + 11, y_offset + 11 + bob, x_offset + 21, y_offset + 13 + bob, ARAGORN_BEARD)
                grid[y_offset + 9 + bob][x_offset + 13] = BLACK
                grid[y_offset + 9 + bob][x_offset + 19] = BLACK
                draw_rect(grid, x_offset + 9, y_offset + 3 + bob, x_offset + 23, y_offset + 6 + bob, ARAGORN_HAIR)
                draw_rect(grid, x_offset + 8, y_offset + 6 + bob, x_offset + 10, y_offset + 12 + bob, ARAGORN_HAIR)
                draw_rect(grid, x_offset + 22, y_offset + 6 + bob, x_offset + 24, y_offset + 12 + bob, ARAGORN_HAIR)
                if attack:
                    draw_rect(grid, x_offset + 23, y_offset + 16, x_offset + 26, y_offset + 27, STEEL_BLADE)
                    draw_rect(grid, x_offset + 22, y_offset + 17, x_offset + 27, y_offset + 18, STEEL_DARK)
                else:
                    draw_rect(grid, x_offset + 5, y_offset + 14, x_offset + 7, y_offset + 22, TORCH_WOOD)
                    draw_rect(grid, x_offset + 4, y_offset + 10, x_offset + 8, y_offset + 13, FIRE_ORANGE)
                    draw_rect(grid, x_offset + 5, y_offset + 11, x_offset + 7, y_offset + 12, FIRE_YELLOW)

            elif row == 3: # --- DOS (HAUT) ---
                draw_rect(grid, x_offset + 10 + foot, y_offset + 26, x_offset + 14 + foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 18 - foot, y_offset + 26, x_offset + 22 - foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 7, y_offset + 12 + bob, x_offset + 25, y_offset + 26 + bob, (32, 48, 36, 255))
                draw_rect(grid, x_offset + 9, y_offset + 3 + bob, x_offset + 23, y_offset + 13 + bob, ARAGORN_HAIR)

            elif row == 1: # --- GAUCHE ---
                draw_rect(grid, x_offset + 11 + foot, y_offset + 26, x_offset + 16 + foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 10, y_offset + 13 + bob, x_offset + 20, y_offset + 25 + bob, LEATHER_LIGHT)
                draw_rect(grid, x_offset + 18, y_offset + 12 + bob, x_offset + 23, y_offset + 26 + bob, (32, 48, 36, 255))
                draw_rect(grid, x_offset + 10, y_offset + 6 + bob, x_offset + 19, y_offset + 12 + bob, SKIN)
                draw_rect(grid, x_offset + 10, y_offset + 10 + bob, x_offset + 15, y_offset + 13 + bob, ARAGORN_BEARD)
                draw_rect(grid, x_offset + 11, y_offset + 3 + bob, x_offset + 21, y_offset + 8 + bob, ARAGORN_HAIR)
                if attack:
                    draw_rect(grid, x_offset + 1, y_offset + 15, x_offset + 10, y_offset + 17, STEEL_BLADE)

            elif row == 2: # --- DROITE ---
                draw_rect(grid, x_offset + 16 - foot, y_offset + 26, x_offset + 21 - foot, y_offset + 29, LEATHER_DARK)
                draw_rect(grid, x_offset + 12, y_offset + 13 + bob, x_offset + 22, y_offset + 25 + bob, LEATHER_LIGHT)
                draw_rect(grid, x_offset + 9, y_offset + 12 + bob, x_offset + 14, y_offset + 26 + bob, (32, 48, 36, 255))
                draw_rect(grid, x_offset + 13, y_offset + 6 + bob, x_offset + 22, y_offset + 12 + bob, SKIN)
                draw_rect(grid, x_offset + 17, y_offset + 10 + bob, x_offset + 22, y_offset + 13 + bob, ARAGORN_BEARD)
                draw_rect(grid, x_offset + 11, y_offset + 3 + bob, x_offset + 21, y_offset + 8 + bob, ARAGORN_HAIR)
                if attack:
                    draw_rect(grid, x_offset + 22, y_offset + 15, x_offset + 31, y_offset + 17, STEEL_BLADE)

    return grid_to_bytes(grid)

# -------------------------------------------------------------
# 2. GANDALF SPRITESHEET (128x128 : 4 lignes, 4 colonnes 32x32)
# -------------------------------------------------------------
def build_gandalf_sheet():
    grid = create_grid(128, 128)
    for row in range(4):
        y_offset = row * 32
        for col in range(4):
            x_offset = col * 32
            foot = -2 if col == 1 else (2 if col == 3 else 0)
            bob = 1 if (col == 1 or col == 3) else 0
            cast = (col == 2)

            draw_rect(grid, x_offset + 8, y_offset + 29, x_offset + 24, y_offset + 31, (0, 0, 0, 70))

            if row == 0: # --- BAS ---
                draw_rect(grid, x_offset + 8, y_offset + 14 + bob, x_offset + 24, y_offset + 28, GANDALF_ROBE)
                draw_rect(grid, x_offset + 10, y_offset + 16 + bob, x_offset + 22, y_offset + 27, GANDALF_ROBE_DARK)
                draw_rect(grid, x_offset + 12, y_offset + 7 + bob, x_offset + 20, y_offset + 12 + bob, SKIN)
                draw_rect(grid, x_offset + 10, y_offset + 11 + bob, x_offset + 22, y_offset + 19 + bob, GANDALF_BEARD)
                draw_rect(grid, x_offset + 12, y_offset + 19 + bob, x_offset + 20, y_offset + 23 + bob, GANDALF_BEARD)
                grid[y_offset + 9 + bob][x_offset + 14] = BLACK
                grid[y_offset + 9 + bob][x_offset + 18] = BLACK
                draw_rect(grid, x_offset + 7, y_offset + 6 + bob, x_offset + 25, y_offset + 7 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 11, y_offset + 2 + bob, x_offset + 21, y_offset + 5 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 13, y_offset + 0 + bob, x_offset + 19, y_offset + 1 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 4, y_offset + 6, x_offset + 6, y_offset + 28, GANDALF_STAFF)
                draw_rect(grid, x_offset + 3, y_offset + 4, x_offset + 7, y_offset + 6, MAGIC_CYAN)
                if cast:
                    draw_rect(grid, x_offset + 2, y_offset + 2, x_offset + 8, y_offset + 8, (200, 245, 255, 180))

            elif row == 3: # --- HAUT ---
                draw_rect(grid, x_offset + 8, y_offset + 14 + bob, x_offset + 24, y_offset + 28, GANDALF_ROBE)
                draw_rect(grid, x_offset + 9, y_offset + 6 + bob, x_offset + 23, y_offset + 14 + bob, GANDALF_BEARD)
                draw_rect(grid, x_offset + 7, y_offset + 6 + bob, x_offset + 25, y_offset + 7 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 11, y_offset + 2 + bob, x_offset + 21, y_offset + 5 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 4, y_offset + 6, x_offset + 6, y_offset + 28, GANDALF_STAFF)

            elif row == 1: # --- GAUCHE ---
                draw_rect(grid, x_offset + 10, y_offset + 14 + bob, x_offset + 22, y_offset + 28, GANDALF_ROBE)
                draw_rect(grid, x_offset + 9, y_offset + 10 + bob, x_offset + 17, y_offset + 22 + bob, GANDALF_BEARD)
                draw_rect(grid, x_offset + 8, y_offset + 6 + bob, x_offset + 24, y_offset + 7 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 12, y_offset + 2 + bob, x_offset + 20, y_offset + 5 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 3, y_offset + 5, x_offset + 5, y_offset + 27, GANDALF_STAFF)
                draw_rect(grid, x_offset + 2, y_offset + 3, x_offset + 6, y_offset + 5, MAGIC_CYAN)

            elif row == 2: # --- DROITE ---
                draw_rect(grid, x_offset + 10, y_offset + 14 + bob, x_offset + 22, y_offset + 28, GANDALF_ROBE)
                draw_rect(grid, x_offset + 15, y_offset + 10 + bob, x_offset + 23, y_offset + 22 + bob, GANDALF_BEARD)
                draw_rect(grid, x_offset + 8, y_offset + 6 + bob, x_offset + 24, y_offset + 7 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 12, y_offset + 2 + bob, x_offset + 20, y_offset + 5 + bob, GANDALF_HAT)
                draw_rect(grid, x_offset + 26, y_offset + 5, x_offset + 28, y_offset + 27, GANDALF_STAFF)
                draw_rect(grid, x_offset + 25, y_offset + 3, x_offset + 29, y_offset + 5, MAGIC_CYAN)

    return grid_to_bytes(grid)

# -------------------------------------------------------------
# 3. ORQUE SPRITESHEET (128x128 : 4 lignes, 4 colonnes 32x32)
# -------------------------------------------------------------
def build_orc_sheet():
    grid = create_grid(128, 128)
    for row in range(4):
        y_offset = row * 32
        for col in range(4):
            x_offset = col * 32
            foot = -2 if col == 1 else (2 if col == 3 else 0)
            bob = 1 if (col == 1 or col == 3) else 0

            draw_rect(grid, x_offset + 9, y_offset + 28, x_offset + 23, y_offset + 30, (0, 0, 0, 70))
            draw_rect(grid, x_offset + 10 + foot, y_offset + 25, x_offset + 14 + foot, y_offset + 28, ORC_ARMOR)
            draw_rect(grid, x_offset + 18 - foot, y_offset + 25, x_offset + 22 - foot, y_offset + 28, ORC_ARMOR)
            draw_rect(grid, x_offset + 8, y_offset + 14 + bob, x_offset + 24, y_offset + 24 + bob, ORC_ARMOR)
            draw_rect(grid, x_offset + 10, y_offset + 7 + bob, x_offset + 22, y_offset + 14 + bob, ORC_SKIN)
            draw_rect(grid, x_offset + 9, y_offset + 4 + bob, x_offset + 23, y_offset + 8 + bob, (50, 50, 55, 255))
            draw_rect(grid, x_offset + 7, y_offset + 2 + bob, x_offset + 9, y_offset + 6 + bob, (70, 70, 75, 255))
            draw_rect(grid, x_offset + 23, y_offset + 2 + bob, x_offset + 25, y_offset + 6 + bob, (70, 70, 75, 255))

            if row == 0:
                grid[y_offset + 10 + bob][x_offset + 13] = ORC_EYES
                grid[y_offset + 10 + bob][x_offset + 19] = ORC_EYES
                draw_rect(grid, x_offset + 24, y_offset + 12, x_offset + 26, y_offset + 24, RUST_BLADE)
                draw_rect(grid, x_offset + 22, y_offset + 10, x_offset + 25, y_offset + 12, RUST_BLADE)

    return grid_to_bytes(grid)

# -------------------------------------------------------------
# 4. OBJETS DONJON & HUD (128x128 : Dalles, Coffres, Cœurs, Clés)
# -------------------------------------------------------------
def build_dungeon_objects():
    grid = create_grid(128, 128)

    # 1. Dalle de pression relâchée (0..31, 0..31)
    draw_rect(grid, 2, 2, 29, 29, STONE_PLATE)
    draw_rect(grid, 4, 4, 27, 27, (160, 165, 175, 255))
    draw_rect(grid, 10, 10, 21, 21, (110, 115, 125, 255))

    # 2. Dalle de pression enfoncée (32..63, 0..31)
    draw_rect(grid, 34, 2, 61, 29, STONE_PRESSED)
    draw_rect(grid, 36, 4, 59, 27, (90, 95, 105, 255))
    draw_rect(grid, 42, 10, 53, 21, (50, 210, 90, 255))

    # 3. Coffre fermé (64..95, 0..31)
    draw_rect(grid, 68, 8, 92, 28, CHEST_BODY)
    draw_rect(grid, 66, 12, 94, 15, CHEST_METAL)
    draw_rect(grid, 78, 15, 82, 21, GOLD_KEY)

    # 4. Coffre ouvert (96..127, 0..31)
    draw_rect(grid, 100, 14, 124, 28, CHEST_BODY)
    draw_rect(grid, 98, 4, 126, 13, WOOD_DARK)
    draw_rect(grid, 106, 16, 118, 24, (255, 240, 120, 255))

    # 5. Caisse en bois poussable (0..31, 32..63)
    draw_rect(grid, 2, 34, 29, 61, WOOD_BOX)
    draw_rect(grid, 4, 36, 27, 59, WOOD_DARK)
    for i in range(24):
        grid[36 + i][4 + i] = WOOD_BOX
        grid[36 + i][27 - i] = WOOD_BOX

    # 6. Clé d'or (32..63, 32..63)
    draw_rect(grid, 40, 38, 48, 46, GOLD_KEY)
    draw_rect(grid, 43, 41, 45, 43, TRANSPARENT)
    draw_rect(grid, 43, 46, 45, 58, GOLD_KEY)
    draw_rect(grid, 45, 54, 48, 56, GOLD_KEY)

    # 7. Toile d'araignée coupable (64..95, 32..63)
    draw_rect(grid, 66, 34, 94, 62, (255, 255, 255, 30))
    for i in range(28):
        grid[34 + i][66 + i] = WEB_COLOR
        grid[34 + i][94 - i] = WEB_COLOR
        grid[48][66 + i] = WEB_COLOR
        grid[34 + i][80] = WEB_COLOR

    # 8. Pain de Lembas (96..127, 32..63)
    draw_rect(grid, 100, 40, 122, 54, (40, 120, 50, 255))
    draw_rect(grid, 104, 43, 118, 51, (245, 220, 160, 255))

    # 9. Cœur plein (0..15, 64..79)
    draw_rect(grid, 2, 66, 6, 68, HEART_RED)
    draw_rect(grid, 9, 66, 13, 68, HEART_RED)
    draw_rect(grid, 1, 68, 14, 73, HEART_RED)
    draw_rect(grid, 3, 73, 12, 76, HEART_RED)
    draw_rect(grid, 5, 76, 10, 78, HEART_RED)
    draw_rect(grid, 7, 78, 8, 79, HEART_RED)
    grid[67][3] = WHITE

    # 10. Cœur vide (16..31, 64..79)
    draw_rect(grid, 18, 66, 22, 68, HEART_DARK)
    draw_rect(grid, 25, 66, 29, 68, HEART_DARK)
    draw_rect(grid, 17, 68, 30, 73, HEART_DARK)
    draw_rect(grid, 19, 73, 28, 76, HEART_DARK)
    draw_rect(grid, 21, 76, 26, 78, HEART_DARK)
    draw_rect(grid, 23, 78, 24, 79, HEART_DARK)

    return grid_to_bytes(grid)

def build_spider_sprite():
    grid = create_grid(32, 32)
    # Ombre
    draw_rect(grid, 6, 22, 26, 26, (0, 0, 0, 80))
    # Corps bulbeux
    draw_rect(grid, 10, 10, 22, 22, (30, 25, 35, 255))
    draw_rect(grid, 12, 12, 20, 20, (55, 45, 65, 255))
    # Tête
    draw_rect(grid, 12, 6, 20, 11, (20, 18, 25, 255))
    # Yeux rouges multiples
    grid[8][14] = (255, 30, 40, 255)
    grid[8][18] = (255, 30, 40, 255)
    grid[10][13] = (220, 20, 30, 255)
    grid[10][19] = (220, 20, 30, 255)
    # 8 pattes articulées
    pattes = [
        [(8, 6), (4, 4), (2, 8)],
        [(8, 12), (3, 12), (1, 16)],
        [(8, 18), (3, 20), (2, 24)],
        [(8, 22), (5, 26), (4, 28)],
        [(24, 6), (28, 4), (30, 8)],
        [(24, 12), (29, 12), (31, 16)],
        [(24, 18), (29, 20), (30, 24)],
        [(24, 22), (27, 26), (28, 28)],
    ]
    for seg in pattes:
        for p in seg:
            grid[p[1]][p[0]] = (40, 35, 48, 255)
    return grid_to_bytes(grid)

if __name__ == "__main__":
    write_png("assets/sprites/personnages/aragorn_spritesheet.png", 128, 128, build_aragorn_sheet())
    write_png("assets/sprites/personnages/gandalf_spritesheet.png", 128, 128, build_gandalf_sheet())
    write_png("assets/sprites/personnages/orque_spritesheet.png", 128, 128, build_orc_sheet())
    write_png("assets/sprites/personnages/araignee_petite.png", 32, 32, build_spider_sprite())
    write_png("assets/sprites/decors/objets_donjon.png", 128, 128, build_dungeon_objects())
    print("Tous les nouveaux assets ont ete generes avec succes !")
