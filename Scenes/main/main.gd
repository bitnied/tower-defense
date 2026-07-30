extends Node2D

func _ready():
	Globals.set_fs_button(false)
	Progress.new_session()
	# a partir da primeira partida a home não abre mais as
	# instruções automaticamente (ficam no botão [?])
	if not Progress.played_once:
		Progress.played_once = true
		Progress.save()
	Globals.mainNode = self
	var selectedMapScene := load(Data.maps[Globals.selected_map]["scene"])
	var map = selectedMapScene.instantiate()
	map.map_type = Globals.selected_map
	add_child(map)
	Sfx.play_music()
	_update_zoom()
	get_viewport().size_changed.connect(_update_zoom)

const ART := Vector2(1152.0, 685.0)
# Trecho do mapa que PRECISA aparecer fora do painel de defesas:
# da borda esquerda da arte (estrada + mamãe) até o fim da curva à
# direita (pedras terminam em ~x 304; 320 dá uma folga de grama).
const CRIT_LEFT := -576.0
const CRIT_RIGHT := 320.0

# Aproxima a câmera até a arte do mapa cobrir a tela inteira
# (sem faixas pretas nas bordas, principalmente no celular).
func _update_zoom():
	var vs: Vector2 = get_viewport_rect().size
	var panel_px: float = absf($UI/HUD/SidePanel.offset_left)
	var z: float = maxf(vs.x / ART.x, vs.y / ART.y)
	# em telas mais quadradas (iPad) esse zoom escondia o fim da curva
	# atrás do painel: afasta até o trecho crítico caber na área livre
	# (as faixas que sobram em cima/embaixo mostram a arte espelhada)
	z = minf(z, maxf(vs.x - panel_px, 1.0) / (CRIT_RIGHT - CRIT_LEFT))
	$Camera2D.zoom = Vector2(z, z)
	# desloca a câmera para centralizar o trecho crítico na área livre,
	# sem nunca mostrar além das bordas laterais da arte
	var half_w: float = vs.x / (2.0 * z)
	var cx: float = (CRIT_LEFT + CRIT_RIGHT) / 2.0 + panel_px / (2.0 * z)
	if half_w >= ART.x / 2.0:
		cx = 0.0
	else:
		cx = clampf(cx, -ART.x / 2.0 + half_w, ART.x / 2.0 - half_w)
	$Camera2D.position.x = cx
