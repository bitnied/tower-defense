extends Control
# Home do Elisa TD: arte limpa + Jogar. As instruções aparecem num
# diálogo depois do Jogar; fechar o diálogo (X ou Vamos!) inicia o jogo.

func _ready():
	Sfx.stop_music(0.3)
	Engine.time_scale = 1.0
	# Galeria só aparece depois da primeira imagem desbloqueada
	%GalleryButton.visible = Progress.is_unlocked(0)
	%Title.text = Data.texts["howto_title"]
	%HowtoLabel.text = Data.texts["howto"]

func _on_play_button_pressed():
	Sfx.play("click", -10.0)
	%HowtoDialog.visible = true

func _on_start_game():
	Globals.selected_map = "elisa"
	get_tree().change_scene_to_file("res://Scenes/main/main.tscn")

func _on_gallery_button_pressed():
	Sfx.play("click", -10.0)
	get_tree().change_scene_to_file("res://Scenes/ui/gallery/gallery.tscn")
