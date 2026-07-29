extends CanvasLayer
# Aviso "gire o celular" (só mobile web): o gameplay e o menu pedem
# paisagem; a GALERIA funciona em qualquer orientação.
# No iPhone com notch, também pede para virar o aparelho quando o
# notch fica à DIREITA (ali ele cobre os botões da UI do jogo).
# Cobre a tela e pausa até a orientação ficar certa. Se isso pegou
# uma PARTIDA em andamento, a volta é por um botão "Continuar" —
# sem ele o jogo retomava sozinho e o jogador nem percebia.
# Para testar no desktop: ?forcerotate ou ?forceflip na URL.

const GALLERY_SCENE := "res://Scenes/ui/gallery/gallery.tscn"
const GAME_SCENE := "res://Scenes/main/main.tscn"

enum Need {NONE, ROTATE, FLIP}

var overlay: Control
var box: VBoxContainer
var phone_wrap: CenterContainer
var phone: Panel
var label: Label
var resume_btn: Button
var was_paused := false
var force_rotate := false
var force_flip := false
var showing: Need = Need.NONE
var resume_pending := false
var poll_accum := 0.0

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	force_rotate = _has_url_flag("forcerotate")
	force_flip = _has_url_flag("forceflip")
	_build_overlay()
	get_viewport().size_changed.connect(_refresh)
	_refresh()

func _process(delta):
	# polling: trocar de cena (galeria) e o flip de 180° não disparam
	# size_changed, então conferimos de tempos em tempos
	poll_accum += delta
	if poll_accum >= 0.3:
		poll_accum = 0.0
		_refresh()

func _is_mobile_web() -> bool:
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	# outros navegadores mobile (ex.: tablets) caem aqui
	return OS.has_feature("web") and DisplayServer.is_touchscreen_available()

func _has_url_flag(flag: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var search = JavaScriptBridge.eval("window.location.search", true)
	return search is String and search.contains(flag)

func _in_gameplay() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path == GAME_SCENE

# O que a tela atual exige. A galeria aberta como cena própria é livre
# (funciona em pé e deitada); o resto do jogo pede paisagem, e no
# iPhone pede o notch virado para a esquerda.
func _needed() -> Need:
	var cs := get_tree().current_scene
	if cs != null and cs.scene_file_path == GALLERY_SCENE:
		return Need.NONE
	var vs := get_viewport().get_visible_rect().size
	var portrait: bool = vs.y > vs.x
	if force_rotate:
		return Need.ROTATE if portrait else Need.NONE
	if force_flip:
		return Need.NONE if portrait else Need.FLIP
	if not _is_mobile_web():
		return Need.NONE
	if portrait:
		return Need.ROTATE
	if _notch_on_right():
		return Need.FLIP
	return Need.NONE

# iPhone deitado com o notch à direita cobre a UI. Ângulo da tela:
# 90° = notch à esquerda (bom), 270° = notch à direita (virar).
# Só vale para iPhone com notch (inset lateral > 0 em paisagem);
# iPads e Androids sem recorte ficam de fora.
func _notch_on_right() -> bool:
	if not OS.has_feature("web_ios"):
		return false
	var ins: Dictionary = Globals.web_safe_insets()
	if ins["left"] + ins["right"] < 1.0:
		return false
	var raw = JavaScriptBridge.eval(
		"(screen.orientation&&typeof screen.orientation.angle=='number')" +
		"?screen.orientation.angle" +
		":(typeof window.orientation=='number'?(window.orientation+360)%360:90)",
		true)
	return raw is float and int(raw) == 270

func _refresh():
	if overlay.visible:
		_fit_box()
	var need := _needed()
	if resume_pending:
		if need == Need.NONE:
			return  # esperando o jogador tocar em Continuar
		resume_pending = false  # desvirou de novo: volta ao aviso
	if need == showing:
		return
	if need == Need.NONE:
		showing = Need.NONE
		if overlay.visible and _in_gameplay() and not was_paused:
			# a partida estava rolando: só retoma pelo botão
			resume_pending = true
			_show_resume()
			return
		overlay.visible = false
		get_tree().paused = was_paused
		return
	if not overlay.visible:
		was_paused = get_tree().paused
		get_tree().paused = true
	showing = need
	phone_wrap.visible = true
	resume_btn.visible = false
	label.text = "Gire o celular para jogar!" if need == Need.ROTATE \
		else "Vire o celular para o outro lado!\nA câmera fica à esquerda."
	overlay.visible = true
	_fit_box()
	_animate_phone()

# Convite para retomar a partida depois de corrigir a orientação
func _show_resume():
	if phone_tween and phone_tween.is_running():
		phone_tween.kill()
	phone_wrap.visible = false
	label.text = "Tudo pronto!"
	resume_btn.visible = true
	overlay.visible = true
	_fit_box()

func _on_resume_pressed():
	Sfx.play("click", -10.0)
	resume_pending = false
	overlay.visible = false
	get_tree().paused = false

# Os tamanhos abaixo foram desenhados para o RETRATO (viewport de
# ~1152 de largura). Em paisagem o viewport encolhe para ~648 de
# altura e os mesmos pixels ficam quase 2x maiores na tela — escala
# o bloco inteiro pela dimensão curta para o tamanho físico bater.
func _fit_box():
	var vs := get_viewport().get_visible_rect().size
	var f: float = clampf(minf(vs.x, vs.y) / 1152.0, 0.5, 1.0)
	box.scale = Vector2(f, f)

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

	box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 40)
	box.resized.connect(func(): box.pivot_offset = box.size / 2.0)
	center.add_child(box)

	# "celular" desenhado (gira sozinho para mostrar o gesto)
	phone_wrap = CenterContainer.new()
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
	# "notch" do celularzinho: mostra qual lado deve ficar a câmera
	var notch := Panel.new()
	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0.55, 0.2, 0.33)
	nb.set_corner_radius_all(6)
	notch.add_theme_stylebox_override("panel", nb)
	notch.custom_minimum_size = Vector2(40, 12)
	notch.position = Vector2((110.0 - 40.0) / 2.0, 10.0)
	notch.size = Vector2(40, 12)
	phone.add_child(notch)

	label = Label.new()
	label.text = "Gire o celular para jogar!"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.08, 0.16))
	label.add_theme_constant_override("outline_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(880, 0)
	box.add_child(label)

	resume_btn = Button.new()
	resume_btn.visible = false
	resume_btn.text = "Continuar"
	resume_btn.custom_minimum_size = Vector2(360, 110)
	resume_btn.add_theme_font_size_override("font_size", 44)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.pressed.connect(_on_resume_pressed)
	box.add_child(resume_btn)

var phone_tween: Tween

func _animate_phone():
	if phone_tween and phone_tween.is_running():
		phone_tween.kill()
	phone.pivot_offset = phone.custom_minimum_size / 2.0
	# girar: em pé -> deitado (notch à esquerda)
	# virar: deitado com notch à direita -> meia-volta (notch à esquerda)
	var from_rot := 0.0 if showing == Need.ROTATE else PI / 2.0
	var to_rot := -PI / 2.0
	phone.rotation = from_rot
	phone_tween = create_tween().set_loops()
	phone_tween.tween_interval(0.6)
	phone_tween.tween_property(phone, "rotation", to_rot, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	phone_tween.tween_interval(0.9)
	phone_tween.tween_property(phone, "rotation", from_rot, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
