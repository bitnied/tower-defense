extends CanvasLayer
# Aviso "gire o celular": em mobile (web) segurando o aparelho em pé,
# cobre a tela e pausa o jogo até virar para a horizontal.
# Para testar no desktop: abrir o jogo com ?forcerotate na URL.

var overlay: Control
var phone: Panel
var was_paused := false
var force_debug := false

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	force_debug = _has_debug_flag()
	_build_overlay()
	get_viewport().size_changed.connect(_refresh)
	_refresh()

func _is_mobile_web() -> bool:
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	# outros navegadores mobile (ex.: tablets) caem aqui
	return OS.has_feature("web") and DisplayServer.is_touchscreen_available()

func _has_debug_flag() -> bool:
	if not OS.has_feature("web"):
		return false
	var search = JavaScriptBridge.eval("window.location.search", true)
	return search is String and search.contains("forcerotate")

func _refresh():
	var vs := get_viewport().get_visible_rect().size
	var portrait: bool = vs.y > vs.x
	var should_show: bool = portrait and (_is_mobile_web() or force_debug)
	if should_show == overlay.visible:
		return
	if should_show:
		was_paused = get_tree().paused
		get_tree().paused = true
		overlay.visible = true
		_animate_phone()
	else:
		overlay.visible = false
		get_tree().paused = was_paused

func _build_overlay():
	overlay = Control.new()
	overlay.visible = false
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.36, 0.12, 0.2, 1.0)
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)

	# "celular" desenhado (gira sozinho para mostrar o gesto)
	var phone_wrap := CenterContainer.new()
	phone_wrap.custom_minimum_size = Vector2(280, 280)
	box.add_child(phone_wrap)
	phone = Panel.new()
	phone.custom_minimum_size = Vector2(110, 190)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.85, 0.91)
	sb.border_color = Color(0.55, 0.2, 0.33)
	sb.set_border_width_all(8)
	sb.set_corner_radius_all(22)
	phone.add_theme_stylebox_override("panel", sb)
	phone_wrap.add_child(phone)

	var label := Label.new()
	label.text = "Gire o celular para jogar!"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.08, 0.16))
	label.add_theme_constant_override("outline_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(500, 0)
	box.add_child(label)

var phone_tween: Tween

func _animate_phone():
	if phone_tween and phone_tween.is_running():
		phone_tween.kill()
	phone.pivot_offset = phone.custom_minimum_size / 2.0
	phone.rotation = 0.0
	phone_tween = create_tween().set_loops()
	phone_tween.tween_interval(0.6)
	phone_tween.tween_property(phone, "rotation", -PI / 2.0, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	phone_tween.tween_interval(0.9)
	phone_tween.tween_property(phone, "rotation", 0.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
