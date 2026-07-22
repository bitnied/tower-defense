extends Control
# Home do Elisa TD. Primeira partida: Jogar abre as instruções e
# fechá-las inicia o jogo. Depois disso o [?] mostra as instruções
# (fechar volta pra home) e, com a primeira vitória, Jogar passa a
# abrir a escolha de dificuldade (Fácil / Médio / Vida Real) com as
# estrelas conquistadas em cada uma.

var howto_starts_game := false
var diff_dialog: Control
# key -> [TextureRect, TextureRect, TextureRect] (as 3 estrelas)
var star_rows := {}

const STAR_FILLED := preload("res://Assets/ui/star_filled.png")
const STAR_EMPTY := preload("res://Assets/ui/star_empty.png")

func _ready():
	Sfx.stop_music(0.3)
	Engine.time_scale = 1.0
	# Galeria só aparece depois da primeira imagem desbloqueada
	%GalleryButton.visible = Progress.is_unlocked(0)
	# [?] só faz sentido depois que as instruções já foram vistas
	%HelpButton.visible = Progress.played_once
	%Title.text = Data.texts["howto_title"]
	%HowtoLabel.text = Data.texts["howto"]
	_build_difficulty_dialog()

func _on_play_button_pressed():
	Sfx.play("click", -10.0)
	if not Progress.played_once:
		# primeira vez: instruções e o fechar inicia o jogo
		howto_starts_game = true
		%HowtoDialog.visible = true
	elif Progress.won_once:
		# já venceu: escolhe a dificuldade
		_refresh_stars()
		diff_dialog.visible = true
	else:
		# antes da primeira vitória, joga sempre no Fácil
		_start_game("facil")

func _on_help_button_pressed():
	Sfx.play("click", -10.0)
	howto_starts_game = false
	%HowtoDialog.visible = true

func _on_howto_closed():
	Sfx.play("click", -10.0)
	%HowtoDialog.visible = false
	if howto_starts_game:
		# primeira partida da vida: nível Fácil
		_start_game("facil")

func _start_game(diff_key: String):
	Globals.selected_difficulty = diff_key
	Globals.selected_map = "elisa"
	get_tree().change_scene_to_file("res://Scenes/main/main.tscn")

func _on_gallery_button_pressed():
	Sfx.play("click", -10.0)
	get_tree().change_scene_to_file("res://Scenes/ui/gallery/gallery.tscn")

# ---------- modal de escolha de dificuldade (construída em código) ----------

func _build_difficulty_dialog():
	diff_dialog = Control.new()
	diff_dialog.visible = false
	diff_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(diff_dialog)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.03, 0.07, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	diff_dialog.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	diff_dialog.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)
	var title := Label.new()
	title.text = "Escolha a dificuldade"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 44)
	title_row.add_child(title)
	var close := Button.new()
	close.text = "X"
	close.custom_minimum_size = Vector2(72, 72)
	close.add_theme_font_size_override("font_size", 36)
	close.pressed.connect(func():
		Sfx.play("click", -10.0)
		diff_dialog.visible = false)
	title_row.add_child(close)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	vbox.add_child(cards)
	for key in Data.difficulty_order:
		cards.add_child(_make_difficulty_card(key))

func _make_difficulty_card(key: String) -> Button:
	var cfg: Dictionary = Data.difficulties[key]
	var card := Button.new()
	card.custom_minimum_size = Vector2(290, 240)
	card.pressed.connect(func():
		Sfx.play("click", -10.0)
		_start_game(key))
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 10)
	card.add_child(inner)
	var name_l := Label.new()
	name_l.text = cfg["name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 40)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_l)
	var sub := Label.new()
	sub.text = cfg["subtitle"]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(240, 0)
	sub.add_theme_font_size_override("font_size", 22)
	sub.modulate = Color(1, 1, 1, 0.85)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(sub)
	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 6)
	stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(stars_row)
	star_rows[key] = []
	for i in range(3):
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(56, 56)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_row.add_child(tr)
		star_rows[key].append(tr)
	return card

func _refresh_stars():
	for key in star_rows.keys():
		var earned: int = int(Progress.stars.get(key, 0))
		for i in range(3):
			star_rows[key][i].texture = STAR_FILLED if i < earned else STAR_EMPTY
