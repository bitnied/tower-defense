extends SceneTree
# Teste headless do "Zerar pontuação": reset_all() apaga tudo (inclusive
# no save regravado, para o "combinar pelo maior" do load não ressuscitar
# nada) e a home volta ao estado de primeira vez. Também confere o fluxo
# "Jogar de novo" da vitória -> home com a escolha de dificuldade aberta.
# Rodar: Godot --headless --script res://tools/smoke_reset.gd
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
	var g = root.get_node("Globals")

	# ---- progresso cheio, depois reset ----
	p.add_points(500)
	p.record_victory("medio", 3)
	p.mark_seen("g01")
	p.played_once = true
	p.save()
	check(p.unlocked_count() > 0, "cenário do teste deveria ter galeria aberta")

	p.reset_all()
	check(p.total_points == 0, "reset não zerou os pontos")
	check(p.session_points == 0, "reset não zerou os pontos da sessão")
	check(p.seen.is_empty(), "reset não esqueceu as imagens vistas")
	check(not p.played_once, "reset deveria voltar a primeira vez (played_once)")
	check(not p.won_once, "reset deveria esquecer a vitória (won_once)")
	for k in p.stars.keys():
		check(int(p.stars[k]) == 0, "reset não zerou as estrelas de " + k)
	check(p.unlocked_count() == 0, "reset não trancou a galeria")

	# ---- o save regravado também tem que estar zerado ----
	p.load_save()
	check(p.total_points == 0,
		"load depois do reset ressuscitou pontos (%d)" % p.total_points)
	check(not p.won_once, "load depois do reset ressuscitou won_once")
	check(p.stars["medio"] == 0, "load depois do reset ressuscitou estrelas")

	# ---- "Jogar de novo" da vitória: home abre a escolha ----
	p.won_once = true
	g.open_difficulty_chooser = true
	var menu = load("res://Scenes/ui/mainMenu/mainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	check(not g.open_difficulty_chooser, "home deveria consumir a flag")
	check(menu.diff_dialog != null and menu.diff_dialog.visible,
		"home não abriu a escolha de dificuldade")
	menu.queue_free()

	# ---- sem a flag a escolha continua fechada ----
	var menu2 = load("res://Scenes/ui/mainMenu/mainMenu.tscn").instantiate()
	root.add_child(menu2)
	await process_frame
	check(menu2.diff_dialog != null and not menu2.diff_dialog.visible,
		"home abriu a escolha sem ninguém pedir")
	menu2.queue_free()

	# ---- o menu de pause tem o botão e a confirmação ----
	var pause = load("res://Scenes/ui/pauseMenu/pause_menu.tscn").instantiate()
	root.add_child(pause)
	await process_frame
	var reset_btn = pause.get_node_or_null("Center/Panel/Margin/VBox/ResetButton")
	check(reset_btn != null, "pause sem o botão Zerar pontuação")
	var confirm = pause.get_node_or_null("%ConfirmReset")
	check(confirm != null and not confirm.visible,
		"confirmação deveria existir e começar escondida")
	if reset_btn != null and confirm != null:
		pause._on_reset_pressed()
		check(confirm.visible, "botão não abriu a confirmação")
		pause._on_reset_cancel_pressed()
		check(not confirm.visible, "Cancelar não fechou a confirmação")
	pause.queue_free()

	print("SMOKE_RESET: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
