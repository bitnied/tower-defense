extends SceneTree
# Teste headless dos dois bugs do fantasma:
#  1) fantasma espantado enquanto CARREGA a defesa -> a defesa volta ao
#     lugar de origem e ataca de novo (não fica congelada na tela);
#  2) vender a defesa agarrada paga o preço UMA vez só (toques repetidos
#     no "Vender" não podem virar chuva de corações).
# Rodar: Godot --headless --script res://tools/test_ghost_grab.gd

var fails := 0

func check(cond: bool, msg: String):
	if not cond:
		push_error("FALHA: " + msg)
		fails += 1

func _initialize():
	_run()

func _make_turret(globals, pos: Vector2):
	var turret = load("res://Scenes/turrets/projectileTurret/projectileTurret.tscn").instantiate()
	turret.turret_type = "tiago"
	globals.turretsNode.add_child(turret)
	turret.global_position = pos
	turret.paid_cost = 100
	turret.build()
	return turret

func _make_ghost(globals, turret):
	var ghost = load("res://Scenes/enemies/ghost.tscn").instantiate()
	globals.currentMap.add_child(ghost)
	ghost.global_position = turret.global_position + Vector2(0, -30)
	ghost.target = turret
	return ghost

func _run() -> void:
	await process_frame
	var globals = root.get_node("Globals")
	change_scene_to_file("res://Scenes/main/main.tscn")
	for i in range(8):
		await process_frame
	check(globals.currentMap != null, "mapa não carregou")

	# ---------- BUG 1: fantasma espantado carregando a defesa ----------
	var turret = _make_turret(globals, Vector2(120, 60))
	var home: Vector2 = turret.global_position
	var ghost = _make_ghost(globals, turret)
	await process_frame
	ghost._start_grab()
	ghost.grab_t = 99.0
	await process_frame
	check(turret.get_parent() == ghost, "fantasma deveria estar carregando a defesa")
	check(not turret.deployed, "defesa carregada não deveria estar ativa")
	ghost.get_damage(9999.0)
	await create_timer(1.2).timeout
	check(is_instance_valid(turret), "defesa não deveria ser destruída com o fantasma")
	if is_instance_valid(turret):
		check(turret.get_parent() == globals.turretsNode,
			"defesa devolvida deveria voltar para o nó de defesas")
		check(turret.deployed, "defesa devolvida deveria voltar a atacar (deployed)")
		check(turret.process_mode == Node.PROCESS_MODE_INHERIT,
			"defesa devolvida deveria voltar a processar")
		check(turret.global_position.distance_to(home) < 2.0,
			"defesa devolvida deveria voltar ao lugar de origem (%s vs %s)"
			% [turret.global_position, home])
		check(absf(turret.get_node("Sprite2D").position.x) < 0.01,
			"sprite da defesa devolvida deveria estar centralizado")
		# processando de novo? (bob só avança dentro do _process dela)
		var bob0: float = turret.bob_t
		var cd_running: bool = not turret.get_node("AttackCooldown").is_stopped()
		await create_timer(0.3).timeout
		check(turret.bob_t > bob0,
			"defesa devolvida deveria voltar a rodar o _process (bob parado)")
		check(cd_running, "cooldown de ataque da defesa devolvida deveria voltar a correr")

	# ---------- BUG 1b: espantado no meio do agarrão (ainda no chão) ----------
	var t1b = _make_turret(globals, Vector2(220, 140))
	var g1b = _make_ghost(globals, t1b)
	await process_frame
	g1b._start_grab()
	g1b.grab_t = 1.0
	await process_frame
	g1b.get_damage(9999.0)
	await create_timer(0.6).timeout
	check(t1b.deployed and t1b.process_mode == Node.PROCESS_MODE_INHERIT,
		"defesa só agarrada deveria seguir ativa depois do fantasma sumir")
	check(absf(t1b.get_node("Sprite2D").position.x) < 0.01,
		"defesa só agarrada deveria parar de se debater")

	# ---------- BUG 2: vender enquanto o fantasma agarra ----------
	# (a) toques repetidos no mesmo frame pagam UMA vez
	var t2 = _make_turret(globals, Vector2(-120, 60))
	var g2 = _make_ghost(globals, t2)
	await process_frame
	g2._start_grab()
	await process_frame
	t2.open_details_pane()
	await process_frame
	var pane = globals.hud.open_details_pane
	var price: int = pane.get_sell_price()
	var gold_before: float = globals.currentMap.gold
	pane._on_sell_button_pressed()
	pane._on_sell_button_pressed()
	pane._on_sell_button_pressed()
	await create_timer(1.0).timeout
	var delta_a: float = globals.currentMap.gold - gold_before
	check(is_equal_approx(delta_a, float(price)),
		"3 toques em Vender deveriam pagar %d (veio %s)" % [price, delta_a])
	check(not is_instance_valid(t2), "defesa vendida deveria sair do jogo")
	check(not is_instance_valid(pane), "painel deveria fechar na venda")
	check(globals.hud.open_details_pane == null,
		"HUD não deveria ficar com ponteiro de painel vendido")

	# (b) o painel fecha quando o fantasma rouba a defesa (nada de vender
	#     alguém que já está no colo do fantasma)
	var t3 = _make_turret(globals, Vector2(0, -60))
	var g3 = _make_ghost(globals, t3)
	await process_frame
	t3.open_details_pane()
	var pane3 = globals.hud.open_details_pane
	g3._start_grab()
	g3.grab_t = 99.0
	await process_frame
	check(t3.get_parent() == g3, "fantasma deveria estar carregando a defesa (caso b)")
	check(not is_instance_valid(pane3),
		"painel deveria fechar quando o fantasma rouba a defesa")
	check(globals.hud.open_details_pane == null,
		"HUD não deveria ficar com painel de defesa roubada")

	# (c) fantasma foge com a defesa: nada de painel órfão nem ouro do nada
	var t4 = _make_turret(globals, Vector2(-220, -60))
	var g4 = _make_ghost(globals, t4)
	await process_frame
	t4.open_details_pane()
	g4._start_grab()
	g4.grab_t = 99.0
	await process_frame
	var gold_c: float = globals.currentMap.gold
	g4.queue_free()   # saiu da tela com a defesa
	await create_timer(0.4).timeout
	check(not is_instance_valid(t4), "defesa roubada deveria ir embora com o fantasma")
	check(globals.hud.open_details_pane == null,
		"painel da defesa roubada deveria ter fechado")
	check(is_equal_approx(globals.currentMap.gold, gold_c),
		"fuga do fantasma não deveria mexer no ouro")

	# (d) dois fantasmas não disputam a mesma defesa
	var t5 = _make_turret(globals, Vector2(160, -140))
	var ga = _make_ghost(globals, t5)
	var gb = _make_ghost(globals, t5)
	gb.target = null
	await process_frame
	ga._start_grab()
	await process_frame
	gb.state = gb.State.seeking
	await process_frame
	check(gb.target != t5,
		"segundo fantasma não deveria mirar a defesa já agarrada pelo primeiro")

	print("TEST_GHOST_GRAB: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
