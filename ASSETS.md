# Guia de produção dos assets finais — Elisa TD

Todos os assets atuais são **placeholders gerados por código**
(regeneráveis com `python3 tools/gen_placeholders.py`). Este guia diz
exatamente o que produzir para substituí-los.

## Identidade visual (paleta Rosa & Dourado)

| Uso | Cor |
|---|---|
| Fundo rosa suave | `#F7E1EA` |
| Painéis/pills (vinho-rosado) | `#8E4A5E` (borda `#5C2E3D`) |
| Cards de defensor | `#A85A70` |
| Botões / destaque rosa | `#FF5F8F` (borda `#C23764`) |
| Dourado (moeda, Elisa, cadeado) | `#E8B923` / `#F5CE42` |
| Verde confirmação | `#58B368` |
| Texto | branco com sombra suave |

A UI (painéis, botões, ícones) já está pronta no jogo — os itens abaixo são
os que **você** vai produzir.

Regra geral:

- **Formato**: PNG com fundo transparente (exceto os backgrounds, que são opacos).
- **Mesmo nome e mesmo caminho de arquivo** do placeholder — basta sobrescrever
  o arquivo e reabrir o projeto no Godot (ele reimporta sozinho).
- Resolução moderada (o jogo roda no navegador do celular): os tamanhos abaixo
  já estão dimensionados para isso. Pode produzir em 2× e reduzir, mas salve no
  tamanho final indicado.
- Estilo livre (desenho, pixel art, foto recortada...) — só mantenha o conjunto
  coerente.

## 1. Defensores (spritesheets direcionais)

**Arquivos** (`Assets/defenders/`):

| Arquivo | Personagem | Ataque |
|---|---|---|
| `tiago_sheet.png` | Tiago | toca violão, solta ondas sonoras |
| `luna_sheet.png` | Luna | coração com as mãos, raio de amor |
| `leo_sheet.png` | Léo | manda beijo, joga boquinhas |
| `elisa_sheet.png` | Elisa | aponta o dedo, joga corações dourados |

**Especificação da folha**: 256×576 px no total = grade de **4 colunas × 9 linhas**,
cada frame com **64×64 px**. O personagem deve caber confortavelmente no frame
(deixe ~4 px de folga nas bordas).

- **Colunas (4)** = frames da animação de ataque, em sequência:
  `0` preparação → `1` ataque → `2` ápice → `3` retorno.
- **Linhas (0 a 7)** = direção para onde o personagem está olhando/atacando,
  nesta ordem exata:

| Linha | Direção |
|---|---|
| 0 | Leste (direita) |
| 1 | Sudeste (baixo-direita) |
| 2 | Sul (baixo) |
| 3 | Sudoeste (baixo-esquerda) |
| 4 | Oeste (esquerda) |
| 5 | Noroeste (cima-esquerda) |
| 6 | Norte (cima) |
| 7 | Nordeste (cima-direita) |
| 8 | **Parado/idle** (sem alvo — respiração, olhar para frente) |

**Dica de produção**: desenhe apenas 5 direções (L, SE, S, NE, N) e **espelhe
horizontalmente** para obter O, SO e NO — economiza quase metade do trabalho.
Ferramentas boas para isso: Aseprite, Piskel (grátis, no navegador), Procreate
com grade.

**Ícone do botão de compra**: é recortado automaticamente do frame 0 da linha 8
(idle) — capriche nesse frame.

## 2. Corações (inimigos) — `Assets/enemies/`

| Arquivo | O que é | Espec |
|---|---|---|
| `heart_cracked.png` | coração com UMA rachadura (fraco) | 288×48 px = 6 frames de 48×48 |
| `heart_broken.png` | coração partido em dois (médio) | 288×48 px = 6 frames |
| `heart_shattered.png` | coração despedaçado (forte) | 288×48 px = 6 frames |
| `heart_healed.png` | coração inteiro, curado, brilhando | 48×48 px, 1 frame |

Os 6 frames são um ciclo de "pulsação" enquanto o coração anda (bate como um
coração de verdade: cresce ~6% e volta). O `heart_healed` aparece na animação
de cura (o coração flutua para cima e some) — vale colocar brilho/sparkles.

## 3. Projéteis — `Assets/bullets/`

| Arquivo | De quem | Espec |
|---|---|---|
| `sound_wave.png` | Tiago | 96×32 px = 3 frames de 32×32 (arcos de onda sonora) |
| `kiss.png` | Léo | 72×24 px = 3 frames de 24×24 (boquinha de batom) |
| `gold_heart.png` | Elisa | 72×24 px = 3 frames de 24×24 (coração dourado) |

Os 3 frames giram em loop rápido durante o voo. O raio da Luna não é sprite —
é um shader (cor rosa/lilás já configurada em `rayTurret.tscn`).

## 4. Cenário

| Arquivo | O que é | Espec |
|---|---|---|
| `Assets/maps/map_elisa.png` | fundo da fase | **1152×648 px, opaco.** O caminho em U deitado precisa ficar EXATAMENTE onde está no placeholder (os corações andam por cima dele). Use o placeholder como camada-guia por baixo da sua arte. |
| `Assets/scenario/mamae.png` | a mamãe se protegendo no fim do caminho | 80×100 px |

## 5. Interface

| Arquivo | O que é | Espec |
|---|---|---|
| `Assets/menu/home_bg.png` | fundo da tela inicial | 1152×648 px, opaco |
| `Assets/menu/title_lettering.png` | **LOGO "Elisa TD"** | transparente, ~900×200 px (proporção livre até ~5:1) |
| `Assets/defenders/locked.png` | botão "?" da Elisa bloqueada | 64×64 px |
| `Assets/ui/familia_placeholder.png` | FOTO DA FAMÍLIA (aparece na derrota e na vitória) | 360×300 px — substitua por uma foto real! Moldura estilo polaroid fica ótima. |

## 6. Textos e balanceamento

Tudo em [Scenes/main/Data.gd](Scenes/main/Data.gd):

- **`texts`** — todas as mensagens (home, surpresa da Elisa, derrota, vitória).
  Edite à vontade, são recados para a Elisa.
- **`turrets`** — custos, alcance, poder de cura e o momento do desbloqueio da
  Elisa (`unlock_wave: 3` = começo da onda 3 de 5).
- **`enemies`** — vida ("amor que falta"), velocidade e recompensa de cada coração.
- **`maps` → `spawner_settings`** — número de ondas e dificuldade.

## 7. Depois de trocar os assets

```sh
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --import
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --export-release "Web" docs/index.html
git add -A && git commit -m "Arte final" && git push
```

O jogo atualiza em https://bitnied.github.io/tower-defense/ em ~2 minutos.
