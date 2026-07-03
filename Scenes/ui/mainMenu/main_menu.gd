extends Control

var mapSelectContainer : PanelContainer

func _ready():
	if OS.has_feature("web"):
		$MenuButtons/VBoxContainer/quitButton.visible = false

func _on_quit_button_pressed():
	get_tree().quit()

func _on_start_button_pressed():
	if not mapSelectContainer:
		var mscScene := preload("res://Scenes/ui/mainMenu/select_map_container.tscn")
		var msc := mscScene.instantiate()
		mapSelectContainer = msc
		add_child(msc)
