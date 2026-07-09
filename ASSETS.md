# Assets do Elisa TD — estado e formatos

A arte final fica em `Art/` e é convertida para `Assets/` pelo pipeline
`python3 tools/import_art.py` (chroma-key magenta dos personagens,
remoção de fundo branco dos elementos, fatiamento e normalização).
Depois de mexer em `Art/`, rode o pipeline e reimporte no Godot.

## O que já está integrado

| Origem (`Art/`) | Vira (`Assets/`) | Formato no jogo |
|---|---|---|
| `Characters/{Nome} Spritesheet.png` (3 poses, fundo magenta) | `defenders/{nome}_sheet.png` | 228×76 = 3 células [baixo, direita, cima]; esquerda = espelho |
| `Characters/{Nome}.png` (PNG transparente) | `defenders/{nome}_portrait.png` | 96×96, card de compra e painel de detalhes |
| `corações - projéteis - cadeado.jpeg` | `enemies/heart_*.png` (5 frames de 48×48), `bullets/kiss.png`/`gold_heart.png` (3×24), `defenders/locked.png` | fatiamento adaptativo |
| `Stage map.jpeg` | `maps/map_elisa.png` | 1152 de largura; a estrada vira o caminho dos inimigos |
| `Home Screen.jpeg` | `menu/home_bg.png` | fundo da home (logo embutido) |

Notas:
- A **onda sonora do Tiago é procedural** (arcos desenhados em código) — o
  sprite `sound_wave` não é mais usado visualmente.
- O **raio da Luna** é shader + glow + partículas, saindo das mãos.
- A **guardiã no fim da estrada é a Elisa** (frame frontal do sheet dela).
- Animação dos personagens é por código (respiração + recuo no ataque),
  com os pés ancorados no chão.

## O que ainda falta produzir

| Arquivo | O que é | Espec |
|---|---|---|
| `Assets/ui/familia_placeholder.png` | **FOTO REAL DA FAMÍLIA** (telas de derrota e vitória) | 360×300 px, moldura polaroid fica ótima |

Opcional: `Art/Fundo da tela.jpeg` ainda não é usado (candidato a fundo
das telas de vitória/derrota).

## Se refizer o mapa

O caminho dos inimigos (`Scenes/maps/map_elisa.tscn`) foi medido sobre a
estrada da arte atual (braços em y=-65 e y=66 do mundo, ápice da curva em
x=268, mamãe em x=-545). Se a estrada mudar de lugar, me avise para
remedir o Path2D e os obstáculos.

## Textos e balanceamento

Tudo em [Scenes/main/Data.gd](Scenes/main/Data.gd): `texts` (mensagens),
`turrets` (custos/cura/alcance, `unlock_wave` da Elisa), `enemies`
(vida/velocidade/recompensa), `maps → spawner_settings` (10 ondas,
dificuldade).

## Publicar

```sh
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --export-release "Web" docs/index.html
git add -A && git commit -m "Atualiza build" && git push
```
