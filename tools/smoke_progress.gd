extends SceneTree
# Teste headless do save: grava/recarrega, confere que uma leitura
# que falha ou um espelho velho NÃO apagam progresso, e que pontos
# soltos são descarregados sozinhos.
# Rodar: Godot --headless --script res://tools/smoke_progress.gd
# (autoloads não compilam como identificador aqui; usar root.get_node)

var fails := 0

func check(cond: bool, msg: String):
	if not cond:
		push_error("FALHA: " + msg)
		fails += 1

func _initialize():
	_run()

func _run() -> void:
	await process_frame
	var p = root.get_node("Progress")
	var path: String = p.SAVE_PATH

	# ---- ida e volta simples ----
	p.total_points = 0
	p.seen = PackedStringArray()
	p.stars = {"facil": 0, "medio": 0, "vida_real": 0}
	p.won_once = false
	p.played_once = false
	p.add_points(137)
	p.record_victory("medio", 2)
	p.mark_seen("g01")
	p.save()
	check(FileAccess.file_exists(path), "arquivo de save não foi criado")

	p.total_points = 0
	p.seen = PackedStringArray()
	p.stars = {"facil": 0, "medio": 0, "vida_real": 0}
	p.won_once = false
	p.load_save()
	check(p.total_points == 137, "pontos não voltaram (%d)" % p.total_points)
	check(p.stars["medio"] == 2, "estrelas não voltaram")
	check(p.won_once, "won_once não voltou")
	check(p.seen.has("g01"), "imagem vista não voltou")
	check(p.played_once, "played_once deveria vir de total_points > 0")

	# ---- estrelas só sobem: um resultado pior não rebaixa ----
	p.record_victory("medio", 1)
	check(p.stars["medio"] == 2, "estrela pior não pode rebaixar a melhor")

	# ---- save antigo/menor não pode reduzir o progresso ----
	# (é o que acontecia quando uma fonte falhava e a outra era gravada
	# por cima: bastava um espelho velho para zerar tudo)
	var older := ConfigFile.new()
	older.set_value("progress", "total_points", 40)
	older.set_value("progress", "stars", {"medio": 0, "facil": 3})
	p._absorb(older)
	check(p.total_points == 137, "save mais velho reduziu os pontos (%d)" % p.total_points)
	check(p.stars["medio"] == 2, "save mais velho rebaixou as estrelas")
	check(p.stars["facil"] == 3, "estrela mais alta do outro save foi ignorada")

	# ---- leitura que falha não pode zerar o que está em memória ----
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	p.load_save()
	check(p.total_points == 137,
		"leitura sem arquivo zerou os pontos (%d)" % p.total_points)

	# ---- pontos soltos são descarregados sozinhos ----
	p.save()
	p.add_points(5)
	check(p._dirty, "add_points deveria marcar como pendente")
	p._last_flush_ms -= p.FLUSH_INTERVAL_MS + 1
	p._process(0.016)
	check(not p._dirty, "flush automático não gravou os pontos pendentes")
	var reread := ConfigFile.new()
	check(reread.load(path) == OK, "arquivo não regravado pelo flush")
	check(int(reread.get_value("progress", "total_points", 0)) == 142,
		"flush gravou pontos errados")

	# ---- sair do jogo grava o que faltava ----
	p.add_points(3)
	p._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(not p._dirty, "fechar o jogo deveria gravar os pontos pendentes")

	print("SMOKE_PROGRESS: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
