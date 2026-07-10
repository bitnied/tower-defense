extends Control
# Galeria do Amor: imagens da família desbloqueadas com Pontos de
# Amor acumulados entre partidas. Novas revelações ganham animação.

const CARD_W := 168
const CARD_H := 224

var cards: Array[PanelContainer] = []

func _ready():
	Engine.time_scale = 1.0
	var imgs: Array = Progress.images()
	var new_ones: Array = Progress.unseen_unlocked()
	%PointsLabel.text = "%d pontos de amor" % Progress.total_points
	for i in range(imgs.size()):
		var card := _make_card(i, imgs[i], new_ones.has(i))
		%Grid.add_child(card)
		cards.append(card)
	_animate_reveals(new_ones)
	for i in new_ones:
		Progress.mark_seen(imgs[i])
	Progress.save()

func _make_card(idx: int, image_name: String, is_new: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	var unlocked := Progress.is_unlocked(idx)
	if unlocked:
		var tex := TextureRect.new()
		tex.texture = load("res://Assets/gallery/" + image_name)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card.add_child(tex)
		if is_new:
			# começa escondida para a animação de revelação
			tex.modulate = Color(0.25, 0.18, 0.22)
		card.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				_open_viewer(image_name))
	else:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		var lock := TextureRect.new()
		lock.texture = load("res://Assets/ui/icon_lock.png")
		lock.custom_minimum_size = Vector2(40, 40)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(lock)
		var lbl := Label.new()
		lbl.text = "%d pts" % Progress.threshold(idx + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.modulate = Color(1, 1, 1, 0.8)
		box.add_child(lbl)
	return card

func _animate_reveals(new_ones: Array):
	if new_ones.is_empty():
		return
	Sfx.play("unlock", -6.0)
	var delay := 0.35
	for i in new_ones:
		var card := cards[i]
		card.pivot_offset = Vector2(CARD_W, CARD_H) / 2.0
		var tex: TextureRect = card.get_child(0)
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(card, "scale", Vector2(1.18, 1.18), 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(tex, "modulate", Color.WHITE, 0.45)
		tween.tween_property(card, "scale", Vector2(1, 1), 0.25)
		delay += 0.4

func _open_viewer(image_name: String):
	Sfx.play("click", -10.0)
	%BigImage.texture = load("res://Assets/gallery/" + image_name)
	%Viewer.visible = true

func _on_viewer_close():
	%Viewer.visible = false

func _on_back_pressed():
	Sfx.play("click", -10.0)
	get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")
