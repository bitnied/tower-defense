#!/usr/bin/env python3
"""Importa a arte final de Art/ para Assets/ nos formatos do jogo.

- Personagens: chroma-key magenta, 3 direções (baixo, direita, cima)
  em sheet horizontal de 3 células de 76x76; retratos 96x96.
- Elementos (corações/projéteis/cadeado): fatia a folha, remove fundo
  branco, normaliza células.
- Mapa: redimensiona o stage map para o mundo do jogo (1152 de largura).
- Home: redimensiona a home screen.
"""
import os
from PIL import Image, ImageFilter

ROOT = "/Users/nied/Desktop/Tower Defence/Godot-4-Tower-Defense-Template-master"
ART = f"{ROOT}/Art"
ASSETS = f"{ROOT}/Assets"

# ---------------- helpers ----------------

def key_magenta(img):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 150 and b > 150 and g < 110 and abs(r - b) < 80:
                px[x, y] = (r, g, b, 0)
            elif r > 120 and b > 120 and g < 140 and r - g > 60 and b - g > 60:
                # franja de magenta parcial
                px[x, y] = (r, g, b, 60)
    return img

def key_white(img, thr=232, sat=20):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            mx, mn = max(r, g, b), min(r, g, b)
            if mn > thr and (mx - mn) < sat:
                px[x, y] = (255, 255, 255, 0)
            elif mn > thr - 22 and (mx - mn) < sat:
                px[x, y] = (r, g, b, int(255 * (thr - mn) / 22) if thr > mn else 0)
    return img

def drop_black_text(img, thr=75):
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and max(r, g, b) < thr:
                px[x, y] = (r, g, b, 0)
    return img

def autocrop(img, alpha_thr=24):
    a = img.getchannel("A").point(lambda v: 255 if v > alpha_thr else 0)
    box = a.getbbox()
    return img.crop(box) if box else img

def fit_cell(img, cell, content, bottom_anchor=False, margin=3):
    """Escala para caber em content px e centraliza numa célula cell x cell."""
    w, h = img.size
    s = min(content / w, content / h)
    img = img.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
    out = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    x = (cell - img.width) // 2
    y = (cell - img.height - margin) if bottom_anchor else (cell - img.height) // 2
    out.paste(img, (x, y), img)
    return out

# ---------------- 1. Personagens ----------------
CELL = 76
CONTENT = 72
for name in ["Tiago", "Luna", "Leo", "Elisa"]:
    sheet = Image.open(f"{ART}/Characters/{name} Spritesheet.png")
    w, h = sheet.size
    cw = w // 3
    # ordem no arquivo: frontal(baixo), perfil direito(direita), costas(cima)
    frames = []
    for i in range(3):
        cellimg = sheet.crop((i * cw, 0, (i + 1) * cw, h))
        cellimg = key_magenta(cellimg)
        cellimg = autocrop(cellimg)
        frames.append(fit_cell(cellimg, CELL, CONTENT, bottom_anchor=True))
    out = Image.new("RGBA", (CELL * 3, CELL), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * CELL, 0), f)
    out.save(f"{ASSETS}/defenders/{name.lower()}_sheet.png")
    # retrato para o card
    port = Image.open(f"{ART}/Characters/{name}.png").convert("RGBA")
    port = autocrop(port)
    port = fit_cell(port, 96, 92)
    port.save(f"{ASSETS}/defenders/{name.lower()}_portrait.png")
    print("defender ok:", name)

# ---------------- 2. Elementos ----------------
EL = Image.open(f"{ART}/corações - projéteis - cadeado.jpeg").convert("RGB")

def slice_el(box, black_text=False):
    img = EL.crop(box)
    img = key_white(img)
    if black_text:
        img = drop_black_text(img)
    return autocrop(img)

F = 1.38  # display->original
def B(x0, y0, x1, y1):
    return (int(x0 * F), int(y0 * F), int(x1 * F), int(y1 * F))

# corações: 3 níveis x 5 frames (48x48 por frame)
HEART_ROWS = {
    "heart_cracked":  [B(75, 55, 255, 225), B(300, 55, 470, 225), B(530, 55, 700, 225), B(780, 55, 950, 225), B(1030, 55, 1195, 225)],
    "heart_broken":   [B(70, 275, 250, 435), B(295, 275, 465, 435), B(525, 275, 700, 435), B(770, 275, 945, 435), B(1020, 275, 1190, 435)],
    "heart_shattered":[B(60, 480, 250, 660), B(280, 480, 480, 660), B(510, 480, 710, 660), B(760, 480, 950, 660), B(1000, 480, 1190, 660)],
}
for name, boxes in HEART_ROWS.items():
    sheet = Image.new("RGBA", (48 * 5, 48), (0, 0, 0, 0))
    for i, box in enumerate(boxes):
        f = fit_cell(slice_el(box), 48, 44)
        sheet.paste(f, (i * 48, 0), f)
    sheet.save(f"{ASSETS}/enemies/{name}.png")
    print("enemy ok:", name)

# coração curado (o de baixo-esquerda, com brilhos)
healed = fit_cell(slice_el(B(50, 735, 440, 1090)), 48, 46)
healed.save(f"{ASSETS}/enemies/heart_healed.png")

# projéteis: 3 frames cada
def proj_sheet(boxes, cell, content, out_name):
    sheet = Image.new("RGBA", (cell * 3, cell), (0, 0, 0, 0))
    for i, box in enumerate(boxes):
        f = fit_cell(slice_el(box, black_text=True), cell, content)
        sheet.paste(f, (i * cell, 0), f)
    sheet.save(f"{ASSETS}/bullets/{out_name}")
    print("bullet ok:", out_name)

proj_sheet([B(600, 762, 775, 852), B(590, 862, 785, 962), B(535, 968, 830, 1080)], 32, 30, "sound_wave.png")
proj_sheet([B(915, 762, 1085, 852), B(915, 862, 1085, 958), B(915, 962, 1085, 1068)], 24, 22, "kiss.png")
proj_sheet([B(1160, 755, 1340, 852), B(1160, 858, 1340, 952), B(1160, 958, 1340, 1062)], 24, 22, "gold_heart.png")

# cadeado "?" (tile)
tile = fit_cell(slice_el(B(1478, 632, 1995, 1112)), 64, 62)
tile.save(f"{ASSETS}/defenders/locked.png")
print("locked ok")

# ---------------- 3. Mapa ----------------
m = Image.open(f"{ART}/Stage map.jpeg").convert("RGB")
s = 1152 / m.width
m = m.resize((1152, round(m.height * s)), Image.LANCZOS)
m.save(f"{ASSETS}/maps/map_elisa.png")
print("map ok:", m.size)

# ---------------- 4. Home ----------------
hme = Image.open(f"{ART}/Home Screen.jpeg").convert("RGB")
s = 1280 / hme.width
hme = hme.resize((1280, round(hme.height * s)), Image.LANCZOS)
hme.save(f"{ASSETS}/menu/home_bg.png")
print("home ok:", hme.size)

print("IMPORT COMPLETO")
