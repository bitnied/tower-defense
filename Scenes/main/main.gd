extends Node2D

func _ready():
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

# Aproxima a câmera até a arte do mapa cobrir a tela inteira
# (sem faixas pretas nas bordas, principalmente no celular).
func _update_zoom():
	var vs: Vector2 = get_viewport_rect().size
	var z: float = maxf(vs.x / 1152.0, vs.y / 685.0)
	$Camera2D.zoom = Vector2(z, z)
