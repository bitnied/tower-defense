extends Control
# Home screen do Elisa's Defence — fase única, botão Jogar
# entra direto no jogo.

func _ready():
	Engine.time_scale = 1.0
	%HowtoLabel.text = Data.texts["howto"]
	%Congrats.text = Data.texts["congrats"]

func _on_play_button_pressed():
	Globals.selected_map = "elisa"
	get_tree().change_scene_to_file("res://Scenes/main/main.tscn")
