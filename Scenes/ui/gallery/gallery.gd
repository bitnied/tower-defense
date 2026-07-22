extends Control
# Galeria do Amor: imagens (e um vídeo) da família, desbloqueadas com
# Pontos de Amor acumulados entre partidas. No viewer dá para navegar
# com setas entre os itens desbloqueados. Segredo de teste: E E E.

# paisagem: 4 colunas de 200x266 | retrato (celular): 3 colunas maiores
var card_w := 200.0
var card_h := 266.0

var cards: Array[PanelContainer] = []
var current := -1        # índice do item aberto no viewer
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
	_layout_viewer_buttons()
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

# Botões do viewer nunca cobrem a foto:
# desktop (paisagem) ficam ao lado; celular (retrato) acima/abaixo.
func _layout_viewer_buttons():
	if _is_portrait():
		# tela cheia embaixo da foto; Assistir (vídeo) acima
		_place(%FullButton, 0.5, 1.0, -39, 14, 39, 82)
		_place(%WatchButton, 0.5, 0.0, -120, -80, 120, -14)
	else:
		# tela cheia à direita (abaixo do X); Assistir à esquerda no topo
		_place(%FullButton, 1.0, 0.0, 12, 84, 90, 152)
		_place(%WatchButton, 0.0, 0.0, -214, 0, -14, 56)

# Tela cheia: a imagem ocupa o miolo; controles nas bordas livres.
func _layout_full():
	var img: TextureRect = %FullImage
	if _is_portrait():
		img.anchor_left = 0.0
		img.anchor_top = 0.0
		img.anchor_right = 1.0
		img.anchor_bottom = 1.0
		img.offset_left = 10
		img.offset_top = 116
		img.offset_right = -10
		img.offset_bottom = -168
		_place(%MinimizeButton, 0.5, 0.0, -42, 18, 42, 102)
		_place(%FullPrev, 0.5, 1.0, -168, -150, -48, -38)
		_place(%FullNext, 0.5, 1.0, 48, -150, 168, -38)
	else:
		img.anchor_left = 0.0
		img.anchor_top = 0.0
		img.anchor_right = 1.0
		img.anchor_bottom = 1.0
		img.offset_left = 136
		img.offset_top = 10
		img.offset_right = -136
		img.offset_bottom = -10
		_place(%MinimizeButton, 1.0, 0.0, -110, 18, -26, 102)
		_place(%FullPrev, 0.0, 0.5, 14, -56, 122, 56)
		_place(%FullNext, 1.0, 0.5, -122, -56, -14, 56)

func _make_card(idx: int, entry: Dictionary, is_new: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(card_w, card_h)
	if Progress.is_unlocked(idx):
		var tex := TextureRect.new()
		tex.texture = load("res://Assets/gallery/" + _thumb_of(entry))
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
		card.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				_open_viewer(idx))
	else:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		var lock := TextureRect.new()
		lock.texture = load("res://Assets/ui/icon_lock.png")
		lock.custom_minimum_size = Vector2(56, 56)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(lock)
		var lbl := Label.new()
		lbl.text = "%d pts" % Progress.threshold(idx + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.modulate = Color(1, 1, 1, 0.8)
		box.add_child(lbl)
	return card

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

# ---------- viewer com navegação ----------
func _open_viewer(idx: int):
	Sfx.play("click", -10.0)
	current = idx
	_refresh_viewer()
	%Viewer.visible = true

func _refresh_viewer():
	var entry: Dictionary = Progress.images()[current]
	var tex := load("res://Assets/gallery/" + _thumb_of(entry))
	%BigImage.texture = tex
	%FullImage.texture = tex
	%WatchButton.visible = entry["kind"] == "video"
	# invisível (mas ocupando o espaço) para a imagem não pular
	var has_prev := _step_from(current, -1) != -1
	var has_next := _step_from(current, 1) != -1
	%PrevButton.disabled = not has_prev
	%PrevButton.modulate.a = 1.0 if has_prev else 0.0
	%NextButton.disabled = not has_next
	%NextButton.modulate.a = 1.0 if has_next else 0.0
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

func _on_prev_pressed():
	var i := _step_from(current, -1)
	if i != -1:
		Sfx.play("click", -12.0)
		current = i
		_refresh_viewer()

func _on_next_pressed():
	var i := _step_from(current, 1)
	if i != -1:
		Sfx.play("click", -12.0)
		current = i
		_refresh_viewer()

func _on_viewer_close():
	%Viewer.visible = false

# ---------- tela cheia ----------
var swipe_start := Vector2.ZERO

func _on_full_button_pressed():
	_open_fullscreen()

# tocar na imagem grande também abre a tela cheia
func _on_big_image_gui_input(event):
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_open_fullscreen()

func _open_fullscreen():
	Sfx.play("click", -10.0)
	_refresh_viewer()
	%Viewer.visible = false
	%FullViewer.visible = true

func _on_minimize_pressed():
	Sfx.play("click", -10.0)
	# volta para a visualização anterior (viewer com moldura)
	%FullViewer.visible = false
	%Viewer.visible = true

# swipe esquerda/direita navega entre as fotos
# (no navegador o toque vira evento de mouse, então basta tratar mouse)
func _on_full_viewer_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			swipe_start = event.position
		else:
			var d: Vector2 = event.position - swipe_start
			if absf(d.x) > 70.0 and absf(d.x) > absf(d.y):
				if d.x < 0:
					_on_next_pressed()
				else:
					_on_prev_pressed()

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
