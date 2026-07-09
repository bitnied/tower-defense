extends Control
# Home do Elisa TD: arte limpa + Jogar. As instruções aparecem num
# diálogo depois do Jogar; fechar o diálogo (X ou Vamos!) inicia o jogo.

func _ready():
	Engine.time_scale = 1.0
	%Congrats.text = Data.texts["congrats"]
	%Title.text = Data.texts["howto_title"]
	%HowtoLabel.text = Data.texts["howto"]

func _on_play_button_pressed():
	%HowtoDialog.visible = true

func _on_start_game():
	Globals.selected_map = "elisa"
	get_tree().change_scene_to_file("res://Scenes/main/main.tscn")
