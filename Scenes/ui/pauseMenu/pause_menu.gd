extends Control
# Menu de pause (engrenagem): continuar, recomeçar ou voltar ao menu.

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
