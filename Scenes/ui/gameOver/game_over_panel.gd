extends PanelContainer
# Tela de "morte": foto da família + recado carinhoso para
# tentar de novo.

func _ready():
	Engine.time_scale = 1.0
	Sfx.stop_music(0.4)
	Sfx.play("gameover", -4.0)
	Progress.save()
	%TitleLabel.text = Data.texts["gameover_title"]
	%MsgLabel.text = Data.texts["gameover_msg"]
	%SessionLabel.text = "+%d pontos de amor" % Progress.session_points
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
