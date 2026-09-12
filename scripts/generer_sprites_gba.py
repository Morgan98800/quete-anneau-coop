import zlib
import struct

def write_png(filename, width, height, rgba_bytes):
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # filter type 0
        start = y * width * 4
        end = start + width * 4
        raw_data.extend(rgba_bytes[start:end])
    
    compressed = zlib.compress(raw_data)
    
    def chunk(tag, data):
        c = tag + data
        crc = zlib.crc32(c) & 0xffffffff
        return struct.pack(">I", len(data)) + c + struct.pack(">I", crc)
    
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    # IHDR: width(4), height(4), bit_depth(1=8), color_type(1=6 RGBA), comp(0), filter(0), interlace(0)
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png.extend(chunk(b"IHDR", ihdr_data))
    png.extend(chunk(b"IDAT", compressed))
    png.extend(chunk(b"IEND", b""))
    
    with open(filename, "wb") as f:
        f.write(png)
    print(f"Generated PNG: {filename} ({width}x{height})")

# Palette GBA Zelda / Pokémon
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
ROBE_GREY = (160, 168, 176, 255)
BEARD_WHITE = (245, 245, 250, 255)
NAZGUL_ROBE = (16, 18, 22, 255)
NAZGUL_RED = (230, 40, 30, 255)

def create_sprite_grid(w=32, h=32, fill=TRANSPARENT):
    return [[fill for _ in range(w)] for _ in range(h)]

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

# ----------------------------------------------------
# 1. FRODON SACQUET (32x32 Pixel Art)
# ----------------------------------------------------
def build_frodon():
    grid = create_sprite_grid(32, 32)
    # Ombre sous les pieds
    draw_rect(grid, 9, 29, 23, 30, (0, 0, 0, 80))
    # Pieds nus hobbit
    draw_rect(grid, 10, 27, 14, 29, SKIN_SHADOW)
    draw_rect(grid, 18, 27, 22, 29, SKIN_SHADOW)
    # Pantalon court
    draw_rect(grid, 11, 22, 14, 26, PANTS_GREY)
    draw_rect(grid, 18, 22, 21, 26, PANTS_GREY)
    # Cape elfique verte (large silhouette arrière)
    draw_rect(grid, 7, 13, 25, 25, CLOAK_DARK)
    draw_rect(grid, 8, 13, 24, 24, CLOAK_GREEN)
    # Tunique blanche & gilet
    draw_rect(grid, 12, 14, 20, 21, SHIRT_WHITE)
    draw_rect(grid, 11, 15, 13, 21, CLOAK_DARK)
    draw_rect(grid, 19, 15, 21, 21, CLOAK_DARK)
    # L'Anneau Unique au cou
    draw_rect(grid, 15, 16, 17, 18, GOLD)
    grid[17][16] = GLOW_RING
    # Tête & visage
    draw_rect(grid, 10, 7, 22, 13, SKIN)
    draw_rect(grid, 10, 13, 22, 14, SKIN_SHADOW)
    # Yeux bleus/noirs
    grid[10][13] = BLACK
    grid[10][19] = BLACK
    # Cheveux bouclés bruns
    draw_rect(grid, 9, 4, 23, 7, HAIR_FRODO)
    draw_rect(grid, 8, 6, 10, 10, HAIR_FRODO)
    draw_rect(grid, 22, 6, 24, 10, HAIR_FRODO)
    grid[4][14] = HAIR_FRODO
    grid[4][17] = HAIR_FRODO
    return grid

# ----------------------------------------------------
# 2. SAM GAMEGIE (32x32 Pixel Art)
# ----------------------------------------------------
def build_sam():
    grid = create_sprite_grid(32, 32)
    # Ombre sous les pieds
    draw_rect(grid, 8, 29, 24, 30, (0, 0, 0, 80))
    # Pieds nus hobbit
    draw_rect(grid, 9, 27, 14, 29, SKIN_SHADOW)
    draw_rect(grid, 18, 27, 23, 29, SKIN_SHADOW)
    # Pantalon court brun foncé
    draw_rect(grid, 10, 22, 14, 26, PANTS_DARK)
    draw_rect(grid, 18, 22, 22, 26, PANTS_DARK)
    # Gilet brun et chemise claire
    draw_rect(grid, 10, 13, 22, 22, VEST_BROWN)
    draw_rect(grid, 13, 14, 19, 21, SHIRT_WHITE)
    # Sacoche en bandoulière de Sam
    for i in range(12, 22):
        grid[i][i - 2] = (90, 50, 25, 255)
    draw_rect(grid, 19, 19, 24, 25, (110, 65, 30, 255))
    # Poêle en fer à la hanche
    draw_rect(grid, 6, 18, 9, 23, STEEL)
    draw_rect(grid, 5, 17, 6, 18, BLACK)
    # Tête & visage
    draw_rect(grid, 10, 7, 22, 13, SKIN)
    draw_rect(grid, 10, 13, 22, 14, SKIN_SHADOW)
    # Yeux chaleureux
    grid[10][13] = BLACK
    grid[10][19] = BLACK
    # Cheveux blonds/roux ébouriffés
    draw_rect(grid, 9, 4, 23, 7, HAIR_SAM)
    draw_rect(grid, 8, 6, 10, 11, HAIR_SAM)
    draw_rect(grid, 22, 6, 24, 11, HAIR_SAM)
    return grid

# ----------------------------------------------------
# 3. GANDALF LE GRIS (32x48 Pixel Art)
# ----------------------------------------------------
def build_gandalf():
    grid = create_sprite_grid(32, 48)
    # Ombre
    draw_rect(grid, 8, 45, 24, 47, (0, 0, 0, 90))
    # Robe grise ample
    draw_rect(grid, 7, 24, 25, 45, ROBE_GREY)
    draw_rect(grid, 8, 26, 24, 44, (180, 188, 196, 255))
    # Grand Bâton de magicien
    draw_rect(grid, 4, 8, 6, 45, (100, 65, 35, 255))
    draw_rect(grid, 3, 6, 7, 8, (130, 90, 50, 255))
    grid[6][5] = (255, 255, 220, 255)
    # Barbe blanche longue
    draw_rect(grid, 11, 21, 21, 35, BEARD_WHITE)
    draw_rect(grid, 13, 35, 19, 39, BEARD_WHITE)
    # Visage
    draw_rect(grid, 11, 16, 21, 21, SKIN)
    grid[18][14] = BLACK
    grid[18][18] = BLACK
    # Chapeau pointu bleu/gris courbé
    draw_rect(grid, 6, 14, 26, 16, (80, 90, 110, 255))
    draw_rect(grid, 10, 10, 22, 14, (70, 80, 100, 255))
    draw_rect(grid, 12, 6, 20, 10, (60, 70, 90, 255))
    draw_rect(grid, 14, 2, 18, 6, (55, 65, 85, 255))
    draw_rect(grid, 15, 0, 20, 2, (55, 65, 85, 255))
    return grid

# ----------------------------------------------------
# 4. CAVALIER NOIR / NAZGÛL (32x40 Pixel Art)
# ----------------------------------------------------
def build_nazgul():
    grid = create_sprite_grid(32, 40)
    # Ombre brumeuse
    draw_rect(grid, 6, 37, 26, 39, (0, 0, 0, 120))
    # Robe noire déchiquetée
    draw_rect(grid, 7, 14, 25, 37, NAZGUL_ROBE)
    for x in range(7, 26, 3):
        grid[38][x] = NAZGUL_ROBE
    # Lame de Morgul
    draw_rect(grid, 4, 18, 5, 34, STEEL)
    draw_rect(grid, 3, 33, 6, 35, (80, 80, 80, 255))
    # Capuchon noir béant
    draw_rect(grid, 9, 6, 23, 16, (8, 10, 12, 255))
    draw_rect(grid, 11, 4, 21, 6, (8, 10, 12, 255))
    # Ténèbres intérieures et reflets rouges sinistres
    draw_rect(grid, 12, 9, 20, 15, (0, 0, 0, 255))
    grid[11][14] = NAZGUL_RED
    grid[11][18] = NAZGUL_RED
    return grid

# ----------------------------------------------------
# 5. TILESET COMTÉ GBA (96x96 composé de tuiles 32x32)
# ----------------------------------------------------
def build_tileset_comte():
    grid = create_sprite_grid(96, 96)
    # Palette herbe verte Comté
    GRASS_LIGHT = (112, 184, 56, 255)
    GRASS_BASE = (96, 168, 48, 255)
    GRASS_DARK = (80, 144, 40, 255)
    DIRT_BASE = (200, 160, 104, 255)
    DIRT_SHADOW = (176, 136, 80, 255)
    WOOD_LIGHT = (168, 116, 68, 255)
    WOOD_DARK = (120, 76, 40, 255)
    
    # Remplissage par défaut en herbe
    draw_rect(grid, 0, 0, 95, 95, GRASS_BASE)
    # Petites fleurs et brins d'herbe
    for y in range(0, 96, 4):
        for x in range(0, 96, 4):
            if (x * 7 + y * 13) % 11 == 0:
                grid[y][x] = GRASS_LIGHT
            elif (x * 3 + y * 17) % 13 == 0:
                grid[y][x] = GRASS_DARK
    
    # Tuile (1, 0) : Chemin de terre (32 à 63 en x, 0 à 31 en y)
    draw_rect(grid, 32, 0, 63, 31, DIRT_BASE)
    for y in range(0, 32, 3):
        for x in range(32, 64, 5):
            if (x + y) % 7 == 0:
                grid[y][x] = DIRT_SHADOW
                
    # Tuile (2, 0) : Barrière en bois
    draw_rect(grid, 68, 12, 92, 15, WOOD_LIGHT)
    draw_rect(grid, 68, 20, 92, 23, WOOD_LIGHT)
    draw_rect(grid, 72, 8, 76, 28, WOOD_DARK)
    draw_rect(grid, 84, 8, 88, 28, WOOD_DARK)
    
    # Tuile (0, 1) : Maison Hobbit (Porte ronde jaune/bois)
    draw_rect(grid, 4, 34, 28, 62, (140, 120, 100, 255))
    # Porte ronde
    draw_rect(grid, 8, 38, 24, 60, (216, 160, 48, 255))
    draw_rect(grid, 10, 36, 22, 61, (216, 160, 48, 255))
    grid[48][16] = GOLD # poignée centrale ronde
    return grid

write_png("assets/sprites/personnages/frodon.png", 32, 32, grid_to_bytes(build_frodon()))
write_png("assets/sprites/personnages/sam.png", 32, 32, grid_to_bytes(build_sam()))
write_png("assets/sprites/personnages/gandalf.png", 32, 48, grid_to_bytes(build_gandalf()))
write_png("assets/sprites/personnages/nazgul.png", 32, 40, grid_to_bytes(build_nazgul()))
write_png("assets/sprites/decors/tileset_comte.png", 96, 96, grid_to_bytes(build_tileset_comte()))
