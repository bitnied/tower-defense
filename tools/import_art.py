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
    # frame idle (parado, sem alvo): Tiago tem arquivo próprio,
    # os demais usam o PNG individual do personagem
    idle_src = f"{ART}/Characters/Tiago Idle.png" if name == "Tiago" \
        else f"{ART}/Characters/{name}.png"
    idle = Image.open(idle_src).convert("RGBA")
    idle = autocrop(idle)
    idle = fit_cell(idle, CELL, CONTENT, bottom_anchor=True)
    idle.save(f"{ASSETS}/defenders/{name.lower()}_idle.png")
    print("defender ok:", name)

# guardiã: Elisa sendo atacada (fim da estrada)
g = Image.open(f"{ART}/Characters/Elisa Atacada.png").convert("RGBA")
g = autocrop(g)
g = fit_cell(g, 96, 92, bottom_anchor=True)
g.save(f"{ASSETS}/scenario/elisa_atacada.png")
print("guardia ok")

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

# corações: 3 níveis x 5 frames (48x48 por frame).
# Fatiamento ADAPTATIVO: em cada faixa horizontal, detecta os 5
# aglomerados de conteúdo pelas colunas com alpha (evita cortes).
def split_row(row_box, expected=5, gap_px=8):
    strip = drop_black_text(key_white(EL.crop(row_box)))
    a = strip.getchannel("A")
    w, h = strip.size
    cols = [0] * w
    data = list(a.getdata())
    for y in range(0, h, 2):
        base = y * w
        for x in range(w):
            if data[base + x] > 24:
                cols[x] += 1
    clusters = []
    x = 0
    while x < w:
        if cols[x] > 0:
            x0 = x
            gap = 0
            while x < w and gap < gap_px:
                gap = gap + 1 if cols[x] == 0 else 0
                x += 1
            clusters.append((x0, x - gap))
        else:
            x += 1
    clusters = [c for c in clusters if c[1] - c[0] > 30]
    # se dois corações se encostaram, divide o aglomerado mais largo
    while len(clusters) < expected and clusters:
        clusters.sort(key=lambda c: c[1] - c[0], reverse=True)
        x0, x1 = clusters.pop(0)
        mid = (x0 + x1) // 2
        clusters += [(x0, mid), (mid, x1)]
    clusters = sorted(clusters, key=lambda c: c[1] - c[0], reverse=True)[:expected]
    clusters.sort()
    out = []
    for (x0, x1) in clusters:
        cell = strip.crop((max(0, x0 - 4), 0, min(w, x1 + 4), h))
        out.append(autocrop(cell))
    return out

HEART_ROWS = {
    "heart_cracked":   B(40, 50, 1230, 235),
    "heart_broken":    B(40, 262, 1230, 448),
    "heart_shattered": B(40, 462, 1230, 668),
}
for name, row_box in HEART_ROWS.items():
    frames = split_row(row_box)
    assert len(frames) == 5, f"{name}: {len(frames)} frames"
    sheet = Image.new("RGBA", (48 * 5, 48), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        f = fit_cell(f, 48, 44)
        sheet.paste(f, (i * 48, 0), f)
    sheet.save(f"{ASSETS}/enemies/{name}.png")
    print("enemy ok:", name, len(frames))

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

# ---------------- 2b. Telas de fim (torcida / vitória) ----------------
for src, dst in [("Gameover.jpeg", "gameover.jpg"), ("Vitoria.jpeg", "vitoria.jpg")]:
    img = Image.open(f"{ART}/{src}").convert("RGB")
    sc = 720 / img.height
    img = img.resize((round(img.width * sc), 720), Image.LANCZOS)
    img.save(f"{ASSETS}/ui/{dst}", quality=88)
    print("end screen ok:", dst)

# ---------------- 2c. Galeria de conquistas ----------------
# Ordena alfabeticamente, com Final.jpeg SEMPRE por último. Gera a
# lista em Scenes/main/GalleryList.gd (ordem = ordem de desbloqueio).
import re as _re, unicodedata
gal_src = f"{ART}/Galeria"
gal_dst = f"{ASSETS}/gallery"
os.makedirs(gal_dst, exist_ok=True)
def slug(name):
    n = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    n = _re.sub(r"[^A-Za-z0-9]+", "_", n).strip("_").lower()
    return n[:48]
files = [f for f in os.listdir(gal_src)
         if f.lower().endswith((".jpg", ".jpeg", ".png")) and not f.startswith(".")]
finals = [f for f in files if slug(os.path.splitext(f)[0]) == "final"]
rest = sorted([f for f in files if f not in finals], key=lambda f: slug(f))
ordered = rest + finals
manifest = []
for i, f in enumerate(ordered):
    img = Image.open(f"{gal_src}/{f}").convert("RGB")
    sc = 640 / img.height
    img = img.resize((round(img.width * sc), 640), Image.LANCZOS)
    out_name = "g%02d_%s.jpg" % (i + 1, slug(os.path.splitext(f)[0]))
    img.save(f"{gal_dst}/{out_name}", quality=85)
    manifest.append(out_name)
with open(f"{ROOT}/Scenes/main/GalleryList.gd", "w") as fh:
    fh.write("# GERADO por tools/import_art.py — não editar à mão.\n")
    fh.write("# Ordem = ordem de desbloqueio (Final sempre por último).\n")
    fh.write("const IMAGES := [\n")
    for m in manifest:
        fh.write('\t"%s",\n' % m)
    fh.write("]\n")
print("galeria ok:", len(manifest), "imagens")

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
