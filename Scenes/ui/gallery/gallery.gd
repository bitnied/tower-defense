extends Control
# Galeria do Amor: imagens (e um vídeo) da família, desbloqueadas com
# Pontos de Amor acumulados entre partidas. No viewer dá para navegar
# com setas entre os itens desbloqueados. Segredo de teste: E E E.

const CARD_W := 168
const CARD_H := 224

var cards: Array[PanelContainer] = []
var current := -1        # índice do item aberto no viewer
var secret_taps: Array[float] = []
# aberta por cima do jogo pausado (via menu de pause)?
var overlay_mode := false

func _ready():
	if overlay_mode:
		$Top/Bar/BackButton.text = "Voltar"
	else:
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
func _make_card(idx: int, entry: Dictionary, is_new: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	if Progress.is_unlocked(idx):
		var tex := TextureRect.new()
		tex.texture = load("res://Assets/gallery/" + _thumb_of(entry))
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card.add_child(tex)
		if entry["kind"] == "video":
			var play := Label.new()
			play.text = "▶"
			play.add_theme_font_size_override("font_size", 44)
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

func _thumb_of(entry: Dictionary) -> String:
	return entry["thumb"] if entry["kind"] == "video" else entry["file"]

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

# ---------- viewer com navegação ----------
func _open_viewer(idx: int):
	Sfx.play("click", -10.0)
	current = idx
	_refresh_viewer()
	%Viewer.visible = true

func _refresh_viewer():
	var entry: Dictionary = Progress.images()[current]
	%BigImage.texture = load("res://Assets/gallery/" + _thumb_of(entry))
	%WatchButton.visible = entry["kind"] == "video"
	# invisível (mas ocupando o espaço) para a imagem não pular
	var has_prev := _step_from(current, -1) != -1
	var has_next := _step_from(current, 1) != -1
	%PrevButton.disabled = not has_prev
	%PrevButton.modulate.a = 1.0 if has_prev else 0.0
	%NextButton.disabled = not has_next
	%NextButton.modulate.a = 1.0 if has_next else 0.0

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
		get_parent().queue_free()
	else:
		get_tree().change_scene_to_file("res://Scenes/ui/mainMenu/mainMenu.tscn")
