extends Node
# Progresso persistente do Elisa TD: "Pontos de Amor" acumulados
# entre partidas desbloqueiam as imagens da Galeria.
# Ganhos: coração curado +1, chefão +10, onda perfeita +5, vitória +50.

const SAVE_PATH := "user://progress.cfg"

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

func _ready():
	load_save()
	get_tree().set_auto_accept_quit(true)

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

# vitória: guarda o melhor número de estrelas da dificuldade
func record_victory(diff_key: String, n_stars: int):
	won_once = true
	if stars.has(diff_key):
		stars[diff_key] = maxi(stars[diff_key], n_stars)
	save()

func mark_seen(image_name: String):
	if not seen.has(image_name):
		seen.append(image_name)

func new_session():
	session_points = 0

func add_points(n: int):
	total_points += n
	session_points += n

func save():
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_points", total_points)
	cfg.set_value("progress", "seen", seen)
	cfg.set_value("progress", "played_once", played_once)
	cfg.set_value("progress", "won_once", won_once)
	cfg.set_value("progress", "stars", stars)
	cfg.save(SAVE_PATH)

func load_save():
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	total_points = int(cfg.get_value("progress", "total_points", 0))
	seen = PackedStringArray(cfg.get_value("progress", "seen", PackedStringArray()))
	played_once = bool(cfg.get_value("progress", "played_once", total_points > 0))
	won_once = bool(cfg.get_value("progress", "won_once", false))
	var s: Dictionary = cfg.get_value("progress", "stars", {})
	for k in stars.keys():
		stars[k] = int(s.get(k, 0))
