extends PanelContainer
# Tela de vitória — a mensagem de aniversário para a Elisa.

func _ready():
	Engine.time_scale = 1.0
	Sfx.stop_music(0.4)
	Sfx.play("victory", -2.0)
	Progress.add_points(50)
	# estrelas pela vida da mamãe: 3 = intacta, 2 = metade ou mais,
	# 1 = venceu sofrendo
	var n_stars := 1
	var map = Globals.currentMap
	if is_instance_valid(map) and map.baseMaxHp > 0:
		var frac: float = float(map.baseHP) / float(map.baseMaxHp)
		if frac >= 0.999:
			n_stars = 3
		elif frac >= 0.5:
			n_stars = 2
	Progress.record_victory(Globals.selected_difficulty, n_stars)
	%TitleLabel.text = Data.texts["victory_title"]
	%MsgLabel.text = Data.texts["victory_msg"]
	%SessionLabel.text = "+%d pontos de amor" % Progress.session_points
	%DiffLabel.text = "%s" % Globals.difficulty_cfg()["name"]
	var filled: Texture2D = preload("res://Assets/ui/star_filled.png")
	var empty: Texture2D = preload("res://Assets/ui/star_empty.png")
	var slots := [%Star1, %Star2, %Star3]
	for i in range(3):
		slots[i].texture = filled if i < n_stars else empty
	animate_appear()

func animate_appear():
	# espera o layout real e, se o painel for maior que a tela
	# (título longo, janela baixa), encolhe até caber inteiro
	await get_tree().process_frame
	var vs: Vector2 = get_viewport_rect().size
	var fit: float = minf(1.0,
		minf(vs.x / $CenterPanel.size.x, vs.y / $CenterPanel.size.y))
	$CenterPanel.pivot_offset = $CenterPanel.size / 2.0
	$CenterPanel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_property($CenterPanel, "scale", Vector2(fit, fit), 0.5)

func _on_retry_button_pressed():
	Globals.restart_current_level()
	queue_free()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")

func _on_gallery_button_pressed():
	Sfx.play("click", -10.0)
	get_tree().change_scene_to_file("res://Scenes/ui/gallery/gallery.tscn")
