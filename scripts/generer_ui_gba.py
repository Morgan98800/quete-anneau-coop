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
    print(f"Generated UI PNG: {filename} ({width}x{height})")

def create_grid(w, h, fill=(0,0,0,0)):
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

# 1. Boîte de dialogue 9-Patch style GBA Zelda / Pokémon (32x32)
# Fond parchemin sombre avec double bordure dorée/marron et rivets de coin
def build_dialogue_box():
    grid = create_grid(32, 32, (0, 0, 0, 0))
    GOLD_DARK = (100, 70, 20, 255)
    GOLD_LIGHT = (245, 195, 60, 255)
    WOOD_DARK = (40, 26, 18, 255)
    PARCHMENT_DARK = (24, 28, 32, 235)
    
    # Remplissage centre
    draw_rect(grid, 2, 2, 29, 29, PARCHMENT_DARK)
    # Bordure extérieure sombre (1px)
    draw_rect(grid, 1, 1, 30, 1, WOOD_DARK)
    draw_rect(grid, 1, 30, 30, 30, WOOD_DARK)
    draw_rect(grid, 1, 1, 1, 30, WOOD_DARK)
    draw_rect(grid, 30, 1, 30, 30, WOOD_DARK)
    
    # Filet intérieur doré (1px)
    draw_rect(grid, 2, 2, 29, 2, GOLD_LIGHT)
    draw_rect(grid, 2, 29, 29, 29, GOLD_DARK)
    draw_rect(grid, 2, 2, 2, 29, GOLD_LIGHT)
    draw_rect(grid, 29, 2, 29, 29, GOLD_DARK)
    
    # Coins décoratifs 4x4
    for cx, cy in [(1,1), (27,1), (1,27), (27,27)]:
        draw_rect(grid, cx, cy, cx+3, cy+3, GOLD_LIGHT)
        draw_rect(grid, cx+1, cy+1, cx+2, cy+2, (255, 240, 120, 255))
        grid[cy][cx] = (0, 0, 0, 0)
    return grid

# 2. Bouton classique GBA (24x24 9-Patch)
def build_button_gba():
    grid = create_grid(24, 24, (0, 0, 0, 0))
    BORDER_DARK = (30, 20, 15, 255)
    BORDER_LIGHT = (180, 140, 70, 255)
    BG_BASE = (54, 42, 34, 255)
    BG_INNER = (72, 58, 46, 255)
    
    draw_rect(grid, 1, 1, 22, 22, BG_BASE)
    draw_rect(grid, 3, 3, 20, 20, BG_INNER)
    
    # Bordure 3D biseautée
    draw_rect(grid, 1, 1, 22, 1, BORDER_LIGHT)
    draw_rect(grid, 1, 1, 1, 22, BORDER_LIGHT)
    draw_rect(grid, 1, 22, 22, 22, BORDER_DARK)
    draw_rect(grid, 22, 1, 22, 22, BORDER_DARK)
    return grid

write_png("assets/ui/cadre_dialogue_gba.png", 32, 32, grid_to_bytes(build_dialogue_box()))
write_png("assets/ui/bouton_gba.png", 24, 24, grid_to_bytes(build_button_gba()))
