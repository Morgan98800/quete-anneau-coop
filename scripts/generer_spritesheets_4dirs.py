import zlib
import struct

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
    with open(filename, "wb") as f:
        f.write(png)
    print(f"Generated Spritesheet: {filename} ({width}x{height})")

TRANSPARENT = (0, 0, 0, 0)
BLACK = (20, 24, 28, 255)
SKIN = (252, 216, 168, 255)
SKIN_SHADOW = (224, 168, 120, 255)
HAIR_FRODO = (76, 44, 24, 255)
HAIR_SAM = (180, 116, 48, 255)
CLOAK_GREEN = (44, 104, 56, 255)
CLOAK_DARK = (28, 68, 36, 255)
VEST_BROWN = (140, 84, 40, 255)
SHIRT_WHITE = (240, 236, 220, 255)
PANTS_GREY = (88, 80, 72, 255)
PANTS_DARK = (60, 52, 44, 255)
GOLD = (255, 204, 32, 255)
GLOW_RING = (255, 240, 140, 200)
STEEL = (176, 188, 204, 255)

def create_grid(w=128, h=128):
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

# Planche 128x128 : 4 lignes (Bas, Gauche, Droite, Haut), 4 colonnes (frames 0, 1, 2, 3)
def build_frodon_sheet():
    grid = create_grid(128, 128)
    for row in range(4): # 0: BAS, 1: GAUCHE, 2: DROITE, 3: HAUT
        y_offset = row * 32
        for col in range(4): # 0: repos, 1: pas G, 2: repos, 3: pas D
            x_offset = col * 32
            foot_shift = -2 if col == 1 else (2 if col == 3 else 0)
            bob = 1 if (col == 1 or col == 3) else 0
            
            # Ombre
            draw_rect(grid, x_offset + 9, y_offset + 29, x_offset + 23, y_offset + 30, (0, 0, 0, 80))
            
            if row == 0: # --- BAS (FACE) ---
                draw_rect(grid, x_offset + 10 + foot_shift, y_offset + 27, x_offset + 14 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 18 - foot_shift, y_offset + 27, x_offset + 22 - foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 11, y_offset + 22, x_offset + 14, y_offset + 26, PANTS_GREY)
                draw_rect(grid, x_offset + 18, y_offset + 22, x_offset + 21, y_offset + 26, PANTS_GREY)
                draw_rect(grid, x_offset + 7, y_offset + 13 + bob, x_offset + 25, y_offset + 25 + bob, CLOAK_DARK)
                draw_rect(grid, x_offset + 8, y_offset + 13 + bob, x_offset + 24, y_offset + 24 + bob, CLOAK_GREEN)
                draw_rect(grid, x_offset + 12, y_offset + 14 + bob, x_offset + 20, y_offset + 21 + bob, SHIRT_WHITE)
                draw_rect(grid, x_offset + 15, y_offset + 16 + bob, x_offset + 17, y_offset + 18 + bob, GOLD)
                draw_rect(grid, x_offset + 10, y_offset + 7 + bob, x_offset + 22, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 13] = BLACK
                grid[y_offset + 10 + bob][x_offset + 19] = BLACK
                draw_rect(grid, x_offset + 9, y_offset + 4 + bob, x_offset + 23, y_offset + 7 + bob, HAIR_FRODO)
                draw_rect(grid, x_offset + 8, y_offset + 6 + bob, x_offset + 10, y_offset + 10 + bob, HAIR_FRODO)
                draw_rect(grid, x_offset + 22, y_offset + 6 + bob, x_offset + 24, y_offset + 10 + bob, HAIR_FRODO)
                
            elif row == 3: # --- HAUT (DOS) ---
                draw_rect(grid, x_offset + 10 + foot_shift, y_offset + 27, x_offset + 14 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 18 - foot_shift, y_offset + 27, x_offset + 22 - foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 11, y_offset + 22, x_offset + 21, y_offset + 26, PANTS_GREY)
                # Cape elfique qui couvre tout le dos
                draw_rect(grid, x_offset + 7, y_offset + 12 + bob, x_offset + 25, y_offset + 25 + bob, CLOAK_DARK)
                draw_rect(grid, x_offset + 8, y_offset + 13 + bob, x_offset + 24, y_offset + 24 + bob, CLOAK_GREEN)
                # Cheveux vus de dos
                draw_rect(grid, x_offset + 9, y_offset + 4 + bob, x_offset + 23, y_offset + 13 + bob, HAIR_FRODO)
                draw_rect(grid, x_offset + 10, y_offset + 13 + bob, x_offset + 22, y_offset + 14 + bob, (56, 30, 15, 255))
                
            elif row == 1: # --- GAUCHE (PROFIL) ---
                draw_rect(grid, x_offset + 9 + foot_shift, y_offset + 27, x_offset + 15 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 12, y_offset + 22, x_offset + 17, y_offset + 26, PANTS_GREY)
                draw_rect(grid, x_offset + 14, y_offset + 13 + bob, x_offset + 23, y_offset + 25 + bob, CLOAK_DARK)
                draw_rect(grid, x_offset + 10, y_offset + 14 + bob, x_offset + 16, y_offset + 21 + bob, SHIRT_WHITE)
                draw_rect(grid, x_offset + 9, y_offset + 7 + bob, x_offset + 18, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 11] = BLACK
                draw_rect(grid, x_offset + 11, y_offset + 4 + bob, x_offset + 21, y_offset + 8 + bob, HAIR_FRODO)
                draw_rect(grid, x_offset + 16, y_offset + 8 + bob, x_offset + 22, y_offset + 12 + bob, HAIR_FRODO)
                
            elif row == 2: # --- DROITE (PROFIL) ---
                draw_rect(grid, x_offset + 17 + foot_shift, y_offset + 27, x_offset + 23 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 15, y_offset + 22, x_offset + 20, y_offset + 26, PANTS_GREY)
                draw_rect(grid, x_offset + 9, y_offset + 13 + bob, x_offset + 18, y_offset + 25 + bob, CLOAK_DARK)
                draw_rect(grid, x_offset + 16, y_offset + 14 + bob, x_offset + 22, y_offset + 21 + bob, SHIRT_WHITE)
                draw_rect(grid, x_offset + 14, y_offset + 7 + bob, x_offset + 23, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 21] = BLACK
                draw_rect(grid, x_offset + 11, y_offset + 4 + bob, x_offset + 21, y_offset + 8 + bob, HAIR_FRODO)
                draw_rect(grid, x_offset + 10, y_offset + 8 + bob, x_offset + 16, y_offset + 12 + bob, HAIR_FRODO)
    return grid

write_png("assets/sprites/personnages/frodon_spritesheet.png", 128, 128, grid_to_bytes(build_frodon_sheet()))

def build_sam_sheet():
    grid = create_grid(128, 128)
    for row in range(4): # 0: BAS, 1: GAUCHE, 2: DROITE, 3: HAUT
        y_offset = row * 32
        for col in range(4):
            x_offset = col * 32
            foot_shift = -2 if col == 1 else (2 if col == 3 else 0)
            bob = 1 if (col == 1 or col == 3) else 0
            
            # Ombre
            draw_rect(grid, x_offset + 8, y_offset + 29, x_offset + 24, y_offset + 30, (0, 0, 0, 80))
            
            if row == 0: # --- BAS ---
                draw_rect(grid, x_offset + 9 + foot_shift, y_offset + 27, x_offset + 14 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 18 - foot_shift, y_offset + 27, x_offset + 23 - foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 10, y_offset + 22, x_offset + 14, y_offset + 26, PANTS_DARK)
                draw_rect(grid, x_offset + 18, y_offset + 22, x_offset + 22, y_offset + 26, PANTS_DARK)
                draw_rect(grid, x_offset + 10, y_offset + 13 + bob, x_offset + 22, y_offset + 22 + bob, VEST_BROWN)
                draw_rect(grid, x_offset + 13, y_offset + 14 + bob, x_offset + 19, y_offset + 21 + bob, SHIRT_WHITE)
                # Sacoche
                for i in range(12, 22):
                    grid[y_offset + i + bob][x_offset + i - 2] = (90, 50, 25, 255)
                # Poêle
                draw_rect(grid, x_offset + 6, y_offset + 18 + bob, x_offset + 9, y_offset + 23 + bob, STEEL)
                # Tête
                draw_rect(grid, x_offset + 10, y_offset + 7 + bob, x_offset + 22, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 13] = BLACK
                grid[y_offset + 10 + bob][x_offset + 19] = BLACK
                draw_rect(grid, x_offset + 9, y_offset + 4 + bob, x_offset + 23, y_offset + 7 + bob, HAIR_SAM)
                draw_rect(grid, x_offset + 8, y_offset + 6 + bob, x_offset + 10, y_offset + 11 + bob, HAIR_SAM)
                draw_rect(grid, x_offset + 22, y_offset + 6 + bob, x_offset + 24, y_offset + 11 + bob, HAIR_SAM)
                
            elif row == 3: # --- HAUT (DOS) ---
                draw_rect(grid, x_offset + 9 + foot_shift, y_offset + 27, x_offset + 14 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 18 - foot_shift, y_offset + 27, x_offset + 23 - foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 10, y_offset + 22, x_offset + 22, y_offset + 26, PANTS_DARK)
                # Gros sac à dos de voyage de Sam
                draw_rect(grid, x_offset + 9, y_offset + 12 + bob, x_offset + 23, y_offset + 23 + bob, (110, 65, 30, 255))
                draw_rect(grid, x_offset + 10, y_offset + 10 + bob, x_offset + 22, y_offset + 13 + bob, (130, 80, 40, 255))
                # Poêle attachée au sac
                draw_rect(grid, x_offset + 13, y_offset + 14 + bob, x_offset + 19, y_offset + 20 + bob, STEEL)
                # Cheveux
                draw_rect(grid, x_offset + 9, y_offset + 4 + bob, x_offset + 23, y_offset + 10 + bob, HAIR_SAM)
                
            elif row == 1: # --- GAUCHE ---
                draw_rect(grid, x_offset + 9 + foot_shift, y_offset + 27, x_offset + 15 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 11, y_offset + 22, x_offset + 17, y_offset + 26, PANTS_DARK)
                draw_rect(grid, x_offset + 11, y_offset + 13 + bob, x_offset + 18, y_offset + 22 + bob, VEST_BROWN)
                draw_rect(grid, x_offset + 18, y_offset + 13 + bob, x_offset + 23, y_offset + 23 + bob, (110, 65, 30, 255)) # sac dos
                draw_rect(grid, x_offset + 9, y_offset + 7 + bob, x_offset + 18, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 11] = BLACK
                draw_rect(grid, x_offset + 10, y_offset + 4 + bob, x_offset + 21, y_offset + 8 + bob, HAIR_SAM)
                draw_rect(grid, x_offset + 16, y_offset + 8 + bob, x_offset + 22, y_offset + 12 + bob, HAIR_SAM)
                
            elif row == 2: # --- DROITE ---
                draw_rect(grid, x_offset + 17 + foot_shift, y_offset + 27, x_offset + 23 + foot_shift, y_offset + 29, SKIN_SHADOW)
                draw_rect(grid, x_offset + 15, y_offset + 22, x_offset + 21, y_offset + 26, PANTS_DARK)
                draw_rect(grid, x_offset + 14, y_offset + 13 + bob, x_offset + 21, y_offset + 22 + bob, VEST_BROWN)
                draw_rect(grid, x_offset + 9, y_offset + 13 + bob, x_offset + 14, y_offset + 23 + bob, (110, 65, 30, 255)) # sac dos
                draw_rect(grid, x_offset + 14, y_offset + 7 + bob, x_offset + 23, y_offset + 13 + bob, SKIN)
                grid[y_offset + 10 + bob][x_offset + 21] = BLACK
                draw_rect(grid, x_offset + 11, y_offset + 4 + bob, x_offset + 22, y_offset + 8 + bob, HAIR_SAM)
                draw_rect(grid, x_offset + 10, y_offset + 8 + bob, x_offset + 16, y_offset + 12 + bob, HAIR_SAM)
    return grid

write_png("assets/sprites/personnages/sam_spritesheet.png", 128, 128, grid_to_bytes(build_sam_sheet()))
