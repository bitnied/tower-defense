extends PanelContainer
# Tela de vitória — a mensagem de aniversário para a Elisa.

func _ready():
	Engine.time_scale = 1.0
	Sfx.play("victory", -2.0)
	%TitleLabel.text = Data.texts["victory_title"]
	%MsgLabel.text = Data.texts["victory_msg"]
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
