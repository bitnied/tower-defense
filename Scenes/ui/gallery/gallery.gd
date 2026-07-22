extends Control
# Galeria do Amor: imagens (e um vídeo) da família, desbloqueadas com
# Pontos de Amor acumulados entre partidas. Tocar numa foto abre direto
# em tela cheia; swipe com "snap" navega entre elas. Segredo: E E E.

# paisagem: 4 colunas de 200x266 | retrato (celular): 3 colunas maiores
var card_w := 200.0
var card_h := 266.0

var cards: Array[PanelContainer] = []
var current := -1        # índice do item aberto em tela cheia
var secret_taps: Array[float] = []
# aberta por cima do jogo pausado (via menu de pause)?
var overlay_mode := false

func _ready():
	if overlay_mode:
		# galeria por cima do jogo pausado: silencia sem perder a posição
		Sfx.set_music_paused(true)
		$Top/Bar/BackButton.text = "Voltar"
	else:
		Engine.time_scale = 1.0
		Sfx.stop_music(0.3)
	_layout_grid()
	get_viewport().size_changed.connect(_layout_grid)
	var imgs: Array = Progress.images()
	var new_ones: Array = Progress.unseen_unlocked()
	%PointsLabel.text = "%d pontos de amor" % Progress.total_points
	for i in range(imgs.size()):
		var card := _make_card(i, imgs[i], new_ones.has(i))
		%Grid.add_child(card)
		cards.append(card)
	_animate_reveals(new_ones)
	for i in new_ones:
		Progress.mark_seen(imgs[i]["id"])
	Progress.save()

# ---------- segredo de teste: apertar E três vezes ----------
func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_E:
		var now := Time.get_ticks_msec() / 1000.0
		secret_taps.append(now)
		while secret_taps.size() > 0 and now - secret_taps[0] > 1.2:
			secret_taps.pop_front()
		if secret_taps.size() >= 3:
			Progress.unlock_all()
			Sfx.play("unlock", -4.0)
			get_tree().reload_current_scene()

# ---------- grid ----------
func _layout_grid():
	var portrait := _is_portrait()
	%Grid.columns = 3 if portrait else 4
	card_w = 300.0 if portrait else 200.0
	card_h = 400.0 if portrait else 266.0
	for card in cards:
		card.custom_minimum_size = Vector2(card_w, card_h)
	_layout_full()

func _is_portrait() -> bool:
	var vs := get_viewport_rect().size
	return vs.y > vs.x

# posiciona um Control por âncoras pontuais + retângulo em px
func _place(c: Control, ax: float, ay: float, x0: float, y0: float, x1: float, y1: float):
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = x0
	c.offset_top = y0
	c.offset_right = x1
	c.offset_bottom = y1

# Tela cheia: a imagem ocupa o miolo; controles nas bordas livres
# (X no topo-direito é fixo na cena; setas mudam com a orientação).
func _layout_full():
	if _is_portrait():
		img_base = [10.0, 116.0, -10.0, -168.0]
		_place(%FullPrev, 0.5, 1.0, -168, -150, -48, -38)
		_place(%FullNext, 0.5, 1.0, 48, -150, 168, -38)
	else:
		img_base = [136.0, 10.0, -136.0, -10.0]
		_place(%FullPrev, 0.0, 0.5, 14, -56, 122, 56)
		_place(%FullNext, 1.0, 0.5, -122, -56, -14, 56)
	_apply_swipe_visual(swipe_offset)

func _make_card(idx: int, entry: Dictionary, is_new: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(card_w, card_h)
	# PASS: o toque também chega ao ScrollContainer (senão a rolagem
	# por arrasto trava no celular)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	if Progress.is_unlocked(idx):
		var tex := TextureRect.new()
		tex.texture = load("res://Assets/gallery/" + _thumb_of(entry))
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tex)
		if entry["kind"] == "video":
			var play := Label.new()
			play.text = "▶"
			play.add_theme_font_size_override("font_size", 64)
			play.add_theme_color_override("font_outline_color", Color(0.3, 0.05, 0.15))
			play.add_theme_constant_override("outline_size", 10)
			play.set_anchors_preset(Control.PRESET_CENTER)
			play.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			play.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			card.add_child(play)
		if is_new:
			tex.modulate = Color(0.25, 0.18, 0.22)
		card.gui_input.connect(_card_input.bind(card, idx))
	else:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(box)
		var lock := TextureRect.new()
		lock.texture = load("res://Assets/ui/icon_lock.png")
		lock.custom_minimum_size = Vector2(56, 56)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lock)
		var lbl := Label.new()
		lbl.text = "%d pts" % Progress.threshold(idx + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.modulate = Color(1, 1, 1, 0.8)
		box.add_child(lbl)
	return card

# toque curto abre; arrasto (rolagem da lista) não abre nada
func _card_input(event, card: PanelContainer, idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card.set_meta("press_pos", event.position)
		elif card.has_meta("press_pos"):
			var moved: float = (event.position - card.get_meta("press_pos")).length()
			card.remove_meta("press_pos")
			if moved < 30.0:
				_open_full(idx)

func _thumb_of(entry: Dictionary) -> String:
	return entry["thumb"] if entry["kind"] == "video" else entry["file"]

func _animate_reveals(new_ones: Array):
	if new_ones.is_empty():
		return
	Sfx.play("unlock", -6.0)
	var delay := 0.35
	for i in new_ones:
		var card := cards[i]
		card.pivot_offset = Vector2(card_w, card_h) / 2.0
		var tex: TextureRect = card.get_child(0)
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(card, "scale", Vector2(1.18, 1.18), 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(tex, "modulate", Color.WHITE, 0.45)
		tween.tween_property(card, "scale", Vector2(1, 1), 0.25)
		delay += 0.4

# ---------- tela cheia ----------
var img_base := [0.0, 0.0, 0.0, 0.0]   # offsets base da imagem (l, t, r, b)
var swipe_offset := 0.0
var drag_active := false
var drag_from := Vector2.ZERO
var swipe_tween: Tween

func _open_full(idx: int):
	Sfx.play("click", -10.0)
	current = idx
	swipe_offset = 0.0
	_refresh_full()
	_apply_swipe_visual(0.0)
	%FullViewer.visible = true

func _on_close_full_pressed():
	Sfx.play("click", -10.0)
	%FullViewer.visible = false

func _refresh_full():
	var entry: Dictionary = Progress.images()[current]
	%FullImage.texture = load("res://Assets/gallery/" + _thumb_of(entry))
	%WatchButton.visible = entry["kind"] == "video"
	# esmaecida (mas ocupando o espaço) para os botões não pularem
	var has_prev := _step_from(current, -1) != -1
	var has_next := _step_from(current, 1) != -1
	%FullPrev.disabled = not has_prev
	%FullPrev.modulate.a = 1.0 if has_prev else 0.35
	%FullNext.disabled = not has_next
	%FullNext.modulate.a = 1.0 if has_next else 0.35

# próximo índice DESBLOQUEADO na direção dir; -1 se não houver
func _step_from(idx: int, dir: int) -> int:
	var n: int = Progress.images().size()
	var i := idx + dir
	while i >= 0 and i < n:
		if Progress.is_unlocked(i):
			return i
		i += dir
	return -1

# setas usam a mesma animação de snap do swipe
func _on_prev_pressed():
	_snap_advance(-1)

func _on_next_pressed():
	_snap_advance(1)

func _snap_advance(dir: int):
	if swipe_tween and swipe_tween.is_running():
		return
	if _step_from(current, dir) == -1:
		return
	Sfx.play("click", -12.0)
	_animate_snap(dir)

# ---------- swipe orgânico com snap ----------
func _slide_w() -> float:
	return get_viewport_rect().size.x

func _on_full_viewer_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if swipe_tween and swipe_tween.is_running():
				return
			drag_active = true
			drag_from = event.position
		elif drag_active:
			drag_active = false
			_end_swipe(event.position.x - drag_from.x)
	elif event is InputEventMouseMotion and drag_active:
		_drag_swipe(event.position.x - drag_from.x)

# a foto segue o dedo; na borda (sem vizinha) resiste como elástico
func _drag_swipe(dx: float):
	var has_neighbor := _step_from(current, 1 if dx < 0 else -1) != -1
	_apply_swipe_visual(dx if has_neighbor else dx * 0.3)

func _end_swipe(dx: float):
	var th := minf(150.0, _slide_w() * 0.18)
	var dir := 0
	if dx < -th and _step_from(current, 1) != -1:
		dir = 1
	elif dx > th and _step_from(current, -1) != -1:
		dir = -1
	if dir == 0:
		_animate_back()
	else:
		Sfx.play("click", -12.0)
		_animate_snap(dir)

func _animate_back():
	swipe_tween = create_tween()
	swipe_tween.tween_method(_apply_swipe_visual, swipe_offset, 0.0, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swipe_tween.tween_callback(_refresh_full)

func _animate_snap(dir: int):
	var to := -_slide_w() if dir == 1 else _slide_w()
	swipe_tween = create_tween()
	swipe_tween.tween_method(_apply_swipe_visual, swipe_offset, to, 0.24) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swipe_tween.tween_callback(func():
		current = _step_from(current, dir)
		_refresh_full()
		_apply_swipe_visual(0.0))

# aplica o deslocamento: a foto atual desliza e a vizinha entra do lado
func _apply_swipe_visual(off: float):
	swipe_offset = off
	var img: TextureRect = %FullImage
	img.offset_left = img_base[0] + off
	img.offset_top = img_base[1]
	img.offset_right = img_base[2] + off
	img.offset_bottom = img_base[3]
	var side: TextureRect = %FullImageSide
	if absf(off) < 1.0:
		side.visible = false
		return
	# botão de play não acompanha o slide: some durante o gesto
	%WatchButton.visible = false
	var target := _step_from(current, 1) if off < 0 else _step_from(current, -1)
	if target == -1:
		side.visible = false
		return
	var entry: Dictionary = Progress.images()[target]
	side.texture = load("res://Assets/gallery/" + _thumb_of(entry))
	var shift := off + (_slide_w() if off < 0 else -_slide_w())
	side.offset_left = img_base[0] + shift
	side.offset_top = img_base[1]
	side.offset_right = img_base[2] + shift
	side.offset_bottom = img_base[3]
	side.visible = true

# ---------- vídeo (player HTML5 nativo por cima do canvas) ----------
func _on_watch_pressed():
	Sfx.play("click", -10.0)
	if not OS.has_feature("web"):
		Globals_print_warning()
		return
	var js := """
	(function(){
	  if (document.getElementById('etd-video-wrap')) return;
	  var w = document.createElement('div');
	  w.id = 'etd-video-wrap';
	  w.style.cssText = 'position:fixed;inset:0;background:rgba(20,5,12,0.93);z-index:1000;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;';
	  var v = document.createElement('video');
	  v.src = 'gallery_video.mp4';
	  v.autoplay = true;
	  v.playsInline = true;
	  v.preload = 'auto';
	  v.style.cssText = 'max-width:92vw;max-height:74vh;border-radius:12px;';
	  var bar = document.createElement('div');
	  bar.style.cssText = 'display:flex;align-items:center;gap:12px;background:#8E4A5E;padding:10px 16px;border-radius:14px;width:min(92vw,560px);';
	  var btn = document.createElement('button');
	  btn.textContent = '||';
	  btn.style.cssText = 'font-size:18px;width:52px;height:40px;border-radius:10px;border:none;background:#FF5F8F;color:#fff;font-weight:bold;';
	  var line = document.createElement('input');
	  line.type = 'range'; line.min = 0; line.max = 1000; line.value = 0; line.step = 1;
	  line.style.cssText = 'flex:1;accent-color:#FF5F8F;height:26px;';
	  var tm = document.createElement('span');
	  tm.textContent = '0:00';
	  tm.style.cssText = 'color:#fff;font-family:sans-serif;font-size:14px;min-width:44px;text-align:right;';
	  var fmt = function(t){ t=Math.floor(t||0); return Math.floor(t/60)+':'+String(t%60).padStart(2,'0'); };
	  var drag = false;
	  v.addEventListener('timeupdate', function(){
	    if (!drag && v.duration) line.value = v.currentTime / v.duration * 1000;
	    tm.textContent = fmt(v.currentTime);
	  });
	  line.addEventListener('input', function(){
	    drag = true;
	    if (v.duration) { v.currentTime = line.value / 1000 * v.duration; tm.textContent = fmt(v.currentTime); }
	  });
	  line.addEventListener('change', function(){ drag = false; });
	  btn.onclick = function(){
	    if (v.paused) { v.play(); btn.textContent = '||'; }
	    else { v.pause(); btn.textContent = '>'; }
	  };
	  v.addEventListener('play', function(){ btn.textContent = '||'; });
	  v.addEventListener('pause', function(){ btn.textContent = '>'; });
	  var x = document.createElement('button');
	  x.textContent = 'X';
	  x.style.cssText = 'position:absolute;top:14px;right:18px;font-size:24px;padding:8px 18px;border-radius:12px;border:none;background:#FF5F8F;color:#fff;font-weight:bold;';
	  x.onclick = function(){ v.pause(); w.remove(); };
	  bar.appendChild(btn); bar.appendChild(line); bar.appendChild(tm);
	  w.appendChild(v); w.appendChild(bar); w.appendChild(x);
	  document.body.appendChild(w);
	})();
	"""
	JavaScriptBridge.eval(js)

func Globals_print_warning():
	# fora do navegador (editor), o player HTML não existe
	print("O vídeo toca na versão web do jogo.")

func _on_back_pressed():
	Sfx.play("click", -10.0)
	if overlay_mode:
		# volta para o jogo pausado (o menu de pause continua lá)
		Sfx.set_music_paused(false)
		get_parent().queue_free()
	else:
		get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")
