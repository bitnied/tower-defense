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
	var tween = create_tween()
	tween.tween_property($CenterPanel, "pivot_offset", Vector2(100,100), 0.05)
	tween.tween_property($CenterPanel, "scale", Vector2(0.1,0.1), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_property($CenterPanel, "scale", Vector2(1,1), 0.5)

func _on_retry_button_pressed():
	Globals.restart_current_level()
	queue_free()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")

func _on_gallery_button_pressed():
	Sfx.play("click", -10.0)
	get_tree().change_scene_to_file("res://Scenes/ui/gallery/gallery.tscn")
