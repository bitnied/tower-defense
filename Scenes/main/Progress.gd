extends Node
# Progresso persistente do Elisa TD: "Pontos de Amor" acumulados
# entre partidas desbloqueiam as imagens da Galeria.
# Ganhos: coração curado +1, chefão +10, onda perfeita +5, vitória +50.
#
# PERSISTÊNCIA NO NAVEGADOR (o motivo do save "às vezes" falhar):
# no web o "user://" mora num IndexedDB que o Godot só descarrega
# no FRAME SEGUINTE à escrita, e a gravação em si é assíncrona. Se o
# jogador trava o celular, troca de app ou fecha a aba nesse intervalo,
# os frames param e o arquivo nunca chega ao disco. Por isso todo save
# é espelhado no localStorage, que é síncrono e já vale na hora.
# Na leitura os dois lados são combinados pelo MAIOR valor: uma falha
# de leitura (ou um espelho velho) nunca reduz o progresso.

const SAVE_PATH := "user://progress.cfg"
const WEB_MIRROR_KEY := "elisa_td_progress"

# pontos ganhos mas ainda não gravados são descarregados a cada
# INTERVALO (tempo real), além dos saves de checkpoint
const FLUSH_INTERVAL_MS := 1500

var total_points := 0
var session_points := 0
# nomes de imagens cuja revelação o jogador já viu na galeria
var seen: PackedStringArray = PackedStringArray()
# já jogou pelo menos uma partida? (a modal de instruções só
# aparece automaticamente na primeira vez)
var played_once := false
# já venceu pelo menos uma vez? (libera a escolha de dificuldade)
var won_once := false
# melhor resultado (0-3 estrelas) por dificuldade
var stars := {"facil": 0, "medio": 0, "vida_real": 0}

var _dirty := false
var _last_flush_ms := 0
# a referência precisa viver enquanto o jogo rodar, senão o
# navegador perde o callback registrado nos eventos de saída
var _web_flush_cb

func _ready():
	# o game over pausa a árvore; sem isto o flush pararia junto
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()
	get_tree().set_auto_accept_quit(true)
	_install_web_flush_hooks()

# pontos soltos (corações curados no meio da onda) chegam ao disco
# mesmo se o jogador abandonar a partida antes de limpar a onda
func _process(_delta):
	if not _dirty:
		return
	var now := Time.get_ticks_msec()
	if now - _last_flush_ms >= FLUSH_INTERVAL_MS:
		save()

# sair do jogo / perder o foco / fechar a aba: grava o que faltava
func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST, \
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_EXIT_TREE:
			if _dirty:
				save()

func images() -> Array:
	return preload("res://Scenes/main/GalleryList.gd").IMAGES

# pontos necessários para a imagem i (1-based)
func threshold(i: int) -> int:
	return roundi(14.0 * pow(float(i), 1.5))

func is_unlocked(idx: int) -> bool:
	return total_points >= threshold(idx + 1)

func unlocked_count() -> int:
	var n := 0
	for i in range(images().size()):
		if is_unlocked(i):
			n += 1
	return n

# índices desbloqueados que o jogador ainda não viu na galeria
func unseen_unlocked() -> Array:
	var out := []
	for i in range(images().size()):
		if is_unlocked(i) and not seen.has(images()[i]["id"]):
			out.append(i)
	return out

# libera tudo (atalho secreto de teste na galeria)
func unlock_all():
	total_points = maxi(total_points, threshold(images().size()))
	won_once = true
	played_once = true
	save()

# apaga TODO o progresso (botão "Zerar pontuação" das opções):
# pontos, estrelas, galeria e instruções voltam ao estado de
# primeira vez. O save é sobrescrito nas duas pontas (disco e
# espelho), então o "combinar pelo maior" do load não ressuscita nada.
func reset_all():
	total_points = 0
	session_points = 0
	seen = PackedStringArray()
	played_once = false
	won_once = false
	for k in stars.keys():
		stars[k] = 0
	save()

# vitória: guarda o melhor número de estrelas da dificuldade
func record_victory(diff_key: String, n_stars: int):
	won_once = true
	if stars.has(diff_key):
		stars[diff_key] = maxi(stars[diff_key], n_stars)
	save()

func mark_seen(image_name: String):
	if not seen.has(image_name):
		seen.append(image_name)
		_dirty = true

func new_session():
	session_points = 0

func add_points(n: int):
	total_points += n
	session_points += n
	_dirty = true

# ---------- gravar ----------

func save():
	_dirty = false
	_last_flush_ms = Time.get_ticks_msec()
	var cfg := _to_config()
	var text := cfg.encode_to_text()
	# espelho síncrono primeiro: se a aba morrer no meio, este já valeu
	_web_mirror_write(text)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Progress: falha ao gravar %s (erro %d)" % [SAVE_PATH, err])

func _to_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_points", total_points)
	cfg.set_value("progress", "seen", seen)
	cfg.set_value("progress", "played_once", played_once)
	cfg.set_value("progress", "won_once", won_once)
	cfg.set_value("progress", "stars", stars)
	return cfg

# ---------- carregar ----------

func load_save():
	var found := false
	var disk := ConfigFile.new()
	if disk.load(SAVE_PATH) == OK:
		_absorb(disk)
		found = true
	var text := _web_mirror_read()
	if text != "":
		var mirror := ConfigFile.new()
		if mirror.parse(text) == OK:
			_absorb(mirror)
			found = true
	# saves antigos não tinham "played_once": quem já tem pontos jogou
	if total_points > 0:
		played_once = true
	if found and not OS.is_userfs_persistent():
		# navegador sem IndexedDB (aba anônima): só o espelho persiste
		push_warning("Progress: user:// não é persistente neste navegador")

# Combina uma fonte com o que já está carregado ficando sempre com o
# MAIOR progresso. Assim um arquivo corrompido, uma leitura que falha
# ou um espelho desatualizado nunca apagam o que o jogador conquistou.
func _absorb(cfg: ConfigFile):
	total_points = maxi(total_points,
		int(cfg.get_value("progress", "total_points", 0)))
	for img_id in PackedStringArray(
			cfg.get_value("progress", "seen", PackedStringArray())):
		if not seen.has(img_id):
			seen.append(img_id)
	played_once = played_once or bool(cfg.get_value("progress", "played_once", false))
	won_once = won_once or bool(cfg.get_value("progress", "won_once", false))
	var s: Dictionary = cfg.get_value("progress", "stars", {})
	for k in stars.keys():
		stars[k] = maxi(int(stars[k]), int(s.get(k, 0)))

# ---------- espelho no localStorage (só no navegador) ----------

# base64 para o texto (com quebras de linha e aspas) caber inteiro
# dentro do trecho de JavaScript sem escapar nada
func _web_mirror_write(text: String):
	if not OS.has_feature("web"):
		return
	var js := "try{window.localStorage.setItem('%s','%s')}catch(e){}" \
		% [WEB_MIRROR_KEY, Marshalls.utf8_to_base64(text)]
	JavaScriptBridge.eval(js, true)

func _web_mirror_read() -> String:
	if not OS.has_feature("web"):
		return ""
	var js := "(function(){try{return window.localStorage.getItem('%s')||''}" \
		% WEB_MIRROR_KEY + "catch(e){return ''}})()"
	var raw = JavaScriptBridge.eval(js, true)
	if not (raw is String) or raw == "":
		return ""
	return Marshalls.base64_to_utf8(raw)

# O navegador não dá frames depois que a aba some, e é exatamente aí
# que o save do Godot ainda estaria a caminho do IndexedDB. Estes
# eventos gravam o espelho antes disso acontecer.
func _install_web_flush_hooks():
	if not OS.has_feature("web"):
		return
	_web_flush_cb = JavaScriptBridge.create_callback(_on_web_flush)
	# trocar de app / travar o celular dispara visibilitychange no
	# document; fechar a aba dispara pagehide na window
	var doc = JavaScriptBridge.get_interface("document")
	if doc != null:
		doc.addEventListener("visibilitychange", _web_flush_cb)
	var win = JavaScriptBridge.get_interface("window")
	if win != null:
		win.addEventListener("pagehide", _web_flush_cb)
		win.addEventListener("blur", _web_flush_cb)

func _on_web_flush(_args):
	if _dirty:
		save()
