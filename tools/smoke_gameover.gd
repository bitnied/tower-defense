extends SceneTree
# Teste headless: game over congela a árvore (paused) e os botões
# destravam; boss pulsa devagar e 15% maior.
# Rodar: Godot --headless --script res://tools/smoke_gameover.gd
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
	var globals = root.get_node("Globals")

	# ---- boss: pulso lento + 15% maior ----
	var mover = load("res://Scenes/enemies/enemy_mover.tscn").instantiate()
	mover.enemy_type = "coracaoGigante"
	check(absf(mover.get_node("AnimationPlayer").speed_scale - 0.4) < 0.001,
		"boss deveria pulsar a 0.4x")
	check(absf(mover.get_node("Sprite2D").scale.x - 2.76) < 0.001,
		"boss deveria ter escala 2.76")
	mover.enemy_type = "coracaoRachado"
	check(absf(mover.get_node("AnimationPlayer").speed_scale - 1.0) < 0.001,
		"coração comum deveria pulsar a 1x")
	mover.free()

	# ---- game over pausa e retry despausa ----
	change_scene_to_file("res://Scenes/main/main.tscn")
	for i in range(8):
		await process_frame
	var map = globals.currentMap
	check(map != null, "mapa não carregou")
	if map != null:
		map.get_base_damage(999.0)
		await process_frame
		check(paused, "game over deveria pausar a árvore")
		check(map.gameOver, "flag gameOver deveria estar ligada")
		var panel = null
		for c in globals.hud.get_children():
			if c.get_script() != null \
					and String(c.get_script().resource_path).contains("game_over"):
				panel = c
		check(panel != null, "painel de game over não apareceu no HUD")
		if panel != null:
			check(panel.process_mode == Node.PROCESS_MODE_ALWAYS,
				"painel precisa processar durante a pausa")
			panel._on_retry_button_pressed()
			await process_frame
			check(not paused, "retry deveria despausar a árvore")
	print("SMOKE_GAMEOVER: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
