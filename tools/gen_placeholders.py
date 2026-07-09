#!/usr/bin/env python3
"""Gera assets placeholder para Elisa TD.

Paleta base (Rosa & Dourado):
  fundo rosa suave #F7E1EA | painéis vinho #8E4A5E | borda #5C2E3D
  dourado #E8B923 | botão rosa #FF5F8F | verde confirmação #58B368
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

ROOT = "/Users/nied/Desktop/Tower Defence/Godot-4-Tower-Defense-Template-master/Assets"
FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

def font(sz):
    return ImageFont.truetype(FONT, sz)

def ensure(p):
    os.makedirs(p, exist_ok=True)

# ---------- helpers ----------
def draw_heart(d, cx, cy, size, fill, outline=None, ow=2):
    """Coração: dois círculos + triângulo."""
    r = size * 0.28
    ox = size * 0.26
    oy = size * 0.18
    top = cy - oy
    d.ellipse([cx-ox-r, top-r, cx-ox+r, top+r], fill=fill, outline=outline, width=ow)
    d.ellipse([cx+ox-r, top-r, cx+ox+r, top+r], fill=fill, outline=outline, width=ow)
    d.polygon([(cx-ox-r*0.99, top+r*0.35), (cx+ox+r*0.99, top+r*0.35), (cx, cy+size*0.48)],
              fill=fill, outline=outline)
    # remendo central para cobrir a junção
    d.rectangle([cx-ox-r*0.6, top-2, cx+ox+r*0.6, top+r*0.6], fill=fill)

def crack(d, cx, cy, size, n, color):
    """Rachaduras em zigue-zague."""
    import random
    rnd = random.Random(n * 7)
    for k in range(n):
        x = cx + (k - (n-1)/2) * size * 0.22
        pts = [(x, cy - size*0.32)]
        yy = cy - size*0.32
        xx = x
        step = size * 0.14
        for i in range(4):
            yy += step
            xx += (step*0.5 if i % 2 == 0 else -step*0.5) + rnd.uniform(-2, 2)
            pts.append((xx, yy))
        d.line(pts, fill=color, width=max(2, size//16))

# ---------- 1. Defensores: sheets 4 frames x 9 linhas ----------
DEFENDERS = {
    "tiago": ("#4A90D9", "T", "#2C5F94"),
    "luna":  ("#B57EDC", "Lu", "#7E4FA8"),
    "leo":   ("#58B368", "Le", "#357A44"),
    "elisa": ("#E8B923", "E", "#A87F0A"),
}
FRAME = 64
COLS, ROWS = 4, 9
# linhas 0..7 = E,SE,S,SW,W,NW,N,NE ; linha 8 = idle
DIR_ANGLES = [0, 45, 90, 135, 180, 225, 270, 315]

def gen_defender(name, color, initial, dark):
    img = Image.new("RGBA", (FRAME*COLS, FRAME*ROWS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f_big = font(20)
    for row in range(ROWS):
        for col in range(COLS):
            x0, y0 = col*FRAME, row*FRAME
            cx, cy = x0 + FRAME/2, y0 + FRAME/2
            # corpo
            d.rounded_rectangle([x0+14, y0+18, x0+50, y0+56], radius=10, fill=color, outline=dark, width=2)
            # cabeça
            d.ellipse([cx-11, y0+4, cx+11, y0+26], fill=color, outline=dark, width=2)
            # inicial
            d.text((cx, y0+42), initial, font=f_big, fill="white", anchor="mm")
            if row < 8:
                ang = math.radians(DIR_ANGLES[row])
                dx, dy = math.cos(ang), math.sin(ang)
                # seta de direção
                ax, ay = cx + dx*16, cy + dy*16
                bx, by = cx + dx*28, cy + dy*28
                d.line([(ax, ay), (bx, by)], fill="white", width=4)
                # animação de ataque: pontinhos avançando (frames 1-3)
                if col > 0:
                    for i in range(col):
                        px = cx + dx * (20 + i*7 + col*3)
                        py = cy + dy * (20 + i*7 + col*3)
                        d.ellipse([px-3, py-3, px+3, py+3], fill="white")
            else:
                # idle: brilho
                d.ellipse([cx-3, y0+12, cx+3, y0+18], fill="white")
            # índice do frame
            d.text((x0+6, y0+4), str(col), font=font(9), fill=(255, 255, 255, 160))
    ensure(f"{ROOT}/defenders")
    img.save(f"{ROOT}/defenders/{name}_sheet.png")

for n, (c, i, dk) in DEFENDERS.items():
    gen_defender(n, c, i, dk)

# ícone bloqueado "?"
img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([4, 4, 60, 60], radius=12, fill="#3A3A46", outline="#6E6E80", width=3)
d.text((32, 30), "?", font=font(34), fill="#E8B923", anchor="mm")
img.save(f"{ROOT}/defenders/locked.png")

# ---------- 2. Corações (inimigos): 6 frames de pulso ----------
HEARTS = {
    "heart_cracked":   ("#FF7BAC", 1, "#8F2D56"),
    "heart_broken":    ("#F0567F", 2, "#7A1E42"),
    "heart_shattered": ("#C93B60", 3, "#571228"),
}
HF = 48
def gen_heart_sheet(name, color, n_cracks, dark):
    img = Image.new("RGBA", (HF*6, HF), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for fidx in range(6):
        cx = fidx*HF + HF/2
        cy = HF/2
        pulse = 1.0 + 0.06 * math.sin(fidx / 6 * 2 * math.pi)
        size = 38 * pulse
        draw_heart(d, cx, cy, size, color, outline=dark, ow=2)
        crack(d, cx, cy, size, n_cracks, dark)
    ensure(f"{ROOT}/enemies")
    img.save(f"{ROOT}/enemies/{name}.png")

for n, (c, k, dk) in HEARTS.items():
    gen_heart_sheet(n, c, k, dk)

# coração curado (para animação de healing e ícone de moeda)
img = Image.new("RGBA", (HF, HF), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
draw_heart(d, HF/2, HF/2, 40, "#FF4D7E", outline="#FFD9E4", ow=3)
d.ellipse([12, 10, 20, 18], fill=(255, 255, 255, 200))
img.save(f"{ROOT}/enemies/heart_healed.png")

# ---------- 3. Projéteis (3 frames cada) ----------
ensure(f"{ROOT}/bullets")

# onda sonora (Tiago): arcos crescentes 32x32
img = Image.new("RGBA", (96, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for fidx in range(3):
    cx = fidx*32 + 8
    cy = 16
    for k in range(3):
        r = 6 + k*5 + fidx*2
        d.arc([cx-r, cy-r, cx+r, cy+r], start=-55, end=55, fill="#7EC8E3", width=3)
img.save(f"{ROOT}/bullets/sound_wave.png")

# boquinha (Leo): lábios 24x24
img = Image.new("RGBA", (72, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for fidx in range(3):
    cx = fidx*24 + 12
    cy = 12
    s = 1.0 + fidx*0.08
    d.ellipse([cx-9*s, cy-6*s, cx, cy+2*s], fill="#E0315A")
    d.ellipse([cx, cy-6*s, cx+9*s, cy+2*s], fill="#E0315A")
    d.ellipse([cx-8*s, cy-1, cx+8*s, cy+7*s], fill="#C71F47")
img.save(f"{ROOT}/bullets/kiss.png")

# coração dourado (Elisa) 24x24
img = Image.new("RGBA", (72, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for fidx in range(3):
    cx = fidx*24 + 12
    s = 18 + fidx*2
    draw_heart(d, cx, 12, s, "#FFD34E", outline="#B8860B", ow=2)
img.save(f"{ROOT}/bullets/gold_heart.png")

# ---------- 4. Mamãe ----------
ensure(f"{ROOT}/scenario")
img = Image.new("RGBA", (80, 100), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(40, 34), (16, 90), (64, 90)], fill="#E86A92", outline="#A83A60")
d.ellipse([26, 6, 54, 34], fill="#F5C9A8", outline="#A87B58", width=2)
d.arc([24, 2, 56, 34], start=150, end=390, fill="#5C3A21", width=6)
draw_heart(d, 40, 66, 26, "#FF4D7E", outline="#FFF", ow=2)
d.text((40, 96), "MAMAE", font=font(10), fill="#7A1E42", anchor="ms")
img.save(f"{ROOT}/scenario/mamae.png")

# ---------- 5. Background do mapa (U deitado, abertura à ESQUERDA) ----------
W, H = 1152, 648
img = Image.new("RGB", (W, H), "#F7E1EA")
d = ImageDraw.Draw(img)
import random
rnd = random.Random(42)
for _ in range(240):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H)
    r = rnd.uniform(1.5, 4)
    d.ellipse([x-r, y-r, x+r, y+r], fill="#F2D3DF")
for _ in range(26):
    x, y = rnd.uniform(20, W-20), rnd.uniform(20, H-20)
    s = rnd.uniform(10, 22)
    draw_heart(d, x, y, s, "#F0C4D4")
# caminho em U com abertura à esquerda: entrada topo-esquerdo -> direita ->
# curva descendo à direita -> volta para a esquerda embaixo (mamãe).
# (mesmos pontos do Path2D, world+(576,324))
path_pts = [(-44, 134), (876, 134), (926, 159), (961, 194), (976, 234),
            (976, 414), (961, 454), (926, 489), (876, 514), (76, 514)]
d.line(path_pts, fill="#E5B8C8", width=104, joint="curve")
d.line(path_pts, fill="#FFF6FA", width=88, joint="curve")
for p in path_pts[1:-1]:
    d.ellipse([p[0]-44, p[1]-44, p[0]+44, p[1]+44], fill="#FFF6FA")
def dashed(pts, gap=26, seg=12):
    for i in range(len(pts)-1):
        (x1, y1), (x2, y2) = pts[i], pts[i+1]
        L = math.hypot(x2-x1, y2-y1)
        n = int(L // gap)
        for k in range(n):
            t0 = k*gap / L
            t1 = min((k*gap+seg) / L, 1)
            d.line([(x1+(x2-x1)*t0, y1+(y2-y1)*t0), (x1+(x2-x1)*t1, y1+(y2-y1)*t1)],
                   fill="#EAB6C9", width=4)
dashed(path_pts)
# zona da mamãe (fim do caminho, embaixo à esquerda)
d.ellipse([76-58, 514-58, 76+58, 514+58], outline="#FF9DBB", width=5)
img.save(f"{ROOT}/maps/map_elisa.png")

# ---------- 6. Home background ----------
ensure(f"{ROOT}/menu")
img = Image.new("RGB", (W, H), "#FBE7EF")
d = ImageDraw.Draw(img)
for yy in range(H):
    t = yy / H
    r = int(0xFB - t*0x28); g = int(0xE7 - t*0x52); b = int(0xEF - t*0x30)
    d.line([(0, yy), (W, yy)], fill=(r, g, b))
rnd = random.Random(7)
for _ in range(40):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H)
    s = rnd.uniform(14, 60)
    a = int(rnd.uniform(20, 70))
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    do = ImageDraw.Draw(ov)
    draw_heart(do, x, y, s, (255, 120, 160, a))
    img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")
    d = ImageDraw.Draw(img)
img.save(f"{ROOT}/menu/home_bg.png")

# ---------- 7. Lettering do título ----------
img = Image.new("RGBA", (900, 200), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
t = "Elisa TD"
f = font(104)
d.text((452, 94), t, font=f, fill="#7A1E42", anchor="mm", stroke_width=10, stroke_fill="#7A1E42")
d.text((450, 90), t, font=f, fill="#FF5F8F", anchor="mm", stroke_width=6, stroke_fill="#FFF6FA")
draw_heart(d, 100, 90, 64, "#FF4D7E", outline="#FFF6FA", ow=4)
draw_heart(d, 803, 90, 64, "#E8B923", outline="#FFF6FA", ow=4)
d.text((450, 172), "PLACEHOLDER — substituir pelo logo final", font=font(18),
       fill=(122, 30, 66, 150), anchor="mm")
img.save(f"{ROOT}/menu/title_lettering.png")

# ---------- 8. Foto da família (polaroid) ----------
ensure(f"{ROOT}/ui")
img = Image.new("RGBA", (360, 300), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([4, 4, 356, 296], radius=8, fill="#FFFFFF", outline="#D8C8CE", width=2)
d.rectangle([22, 22, 338, 236], fill="#EBD8DF")
d.text((180, 110), "FOTO DA", font=font(30), fill="#B08698", anchor="mm")
d.text((180, 148), "FAMILIA", font=font(30), fill="#B08698", anchor="mm")
draw_heart(d, 60, 200, 30, "#F3A7BE")
draw_heart(d, 300, 200, 30, "#F3A7BE")
d.text((180, 264), "Tiago + Elisa + Leo + Luna", font=font(18), fill="#8F6E7C", anchor="mm")
img.save(f"{ROOT}/ui/familia_placeholder.png")

# ---------- 9. Ícones de UI (paleta rosa & dourado) ----------
# vida (coração vermelho)
img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
draw_heart(d, 18, 18, 30, "#E8382F", outline="#FFFFFF", ow=3)
img.save(f"{ROOT}/ui/icon_life.png")

# moeda (coração rosa em moeda dourada)
img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([1, 1, 35, 35], fill="#F5CE42", outline="#B8860B", width=3)
draw_heart(d, 18, 18, 20, "#FF5F8F", outline=None)
img.save(f"{ROOT}/ui/icon_coin.png")

# engrenagem
img = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for k in range(8):
    a = k * math.pi / 4
    x, y = 20 + math.cos(a)*15, 20 + math.sin(a)*15
    d.ellipse([x-5, y-5, x+5, y+5], fill="#FFF6FA")
d.ellipse([7, 7, 33, 33], fill="#FFF6FA")
d.ellipse([14, 14, 26, 26], fill="#8E4A5E")
img.save(f"{ROOT}/ui/icon_gear.png")

# play (triângulo)
img = Image.new("RGBA", (44, 44), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(12, 8), (12, 36), (38, 22)], fill="#FFFFFF")
img.save(f"{ROOT}/ui/icon_play.png")

# fast-forward (2 triângulos)
img = Image.new("RGBA", (44, 44), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(6, 10), (6, 34), (22, 22)], fill="#FFFFFF")
d.polygon([(22, 10), (22, 34), (38, 22)], fill="#FFFFFF")
img.save(f"{ROOT}/ui/icon_fast.png")

# cadeado
img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([7, 16, 29, 33], radius=5, fill="#F5CE42", outline="#8a6d00", width=2)
d.arc([11, 4, 25, 22], start=180, end=360, fill="#C9CDD4", width=4)
d.ellipse([15, 21, 21, 27], fill="#8a6d00")
img.save(f"{ROOT}/ui/icon_lock.png")

# chevron de entrada (seta apontando para a direita)
img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(8, 4), (22, 18), (8, 32), (16, 32), (30, 18), (16, 4)],
          fill="#FF5F8F", outline="#FFF6FA")
img.save(f"{ROOT}/ui/chevron.png")

# anel de destino (pulsa na mamãe)
img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([6, 6, 90, 90], outline="#FF5F8F", width=6)
draw_heart(d, 48, 16, 16, "#FF5F8F")
img.save(f"{ROOT}/ui/dest_ring.png")

print("OK - placeholders gerados")
