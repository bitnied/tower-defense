extends Control
# Menu de pause: volume/mudo de música e efeitos, continuar,
# recomeçar ou voltar ao menu.

func _ready():
	%MusicSlider.value = Sfx.music_volume
	%SfxSlider.value = Sfx.sfx_volume
	%MusicMute.button_pressed = Sfx.music_muted
	%SfxMute.button_pressed = Sfx.sfx_muted
	_refresh_mute_looks()

func _refresh_mute_looks():
	%MusicMute.modulate = Color(1, 1, 1, 0.4) if Sfx.music_muted else Color.WHITE
	%SfxMute.modulate = Color(1, 1, 1, 0.4) if Sfx.sfx_muted else Color.WHITE
	%MusicSlider.editable = not Sfx.music_muted
	%SfxSlider.editable = not Sfx.sfx_muted

func _on_music_mute_toggled(pressed: bool):
	Sfx.music_muted = pressed
	_refresh_mute_looks()

func _on_sfx_mute_toggled(pressed: bool):
	Sfx.sfx_muted = pressed
	_refresh_mute_looks()
	if not pressed:
		Sfx.play("click", -10.0)

func _on_music_volume_changed(v: float):
	Sfx.music_volume = v

func _on_sfx_volume_changed(v: float):
	Sfx.sfx_volume = v

func _on_continue_pressed():
	get_tree().paused = false
	queue_free()

func _on_restart_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0
	Globals.restart_current_level()
	queue_free()

func _on_menu_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")
