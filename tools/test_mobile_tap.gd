extends SceneTree
# Teste headless: no celular UM toque na torre chega como
# InputEventScreenTouch E InputEventMouseButton emulado. O painel de
# detalhes (com o botão Melhorar) precisa continuar aberto mesmo assim.
# Rodar: Godot --headless --script res://tools/test_mobile_tap.gd
# (autoloads não compilam como identificador aqui; usar root.get_node)

var fails := 0

func check(cond: bool, msg: String):
	if not cond:
		push_error("FALHA: " + msg)
		fails += 1

func _initialize():
	_run()

func _make_touch() -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	return ev

func _make_click() -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.device = InputEvent.DEVICE_ID_EMULATION
	return ev

func _run() -> void:
	await process_frame
	var globals = root.get_node("Globals")
	change_scene_to_file("res://Scenes/main/main.tscn")
	for i in range(8):
		await process_frame
	check(globals.currentMap != null, "mapa não carregou")

	var turret = load("res://Scenes/turrets/projectileTurret/projectileTurret.tscn").instantiate()
	turret.turret_type = "tiago"
	globals.turretsNode.add_child(turret)
	turret.build()
	await process_frame

	# ---- toque de celular: ScreenTouch + mouse emulado no mesmo instante ----
	turret._on_collision_area_input_event(null, _make_touch(), 0)
	turret._on_collision_area_input_event(null, _make_click(), 0)
	await process_frame
	check(is_instance_valid(globals.hud.open_details_pane),
		"painel deveria ficar aberto após o toque duplicado do celular")
	if is_instance_valid(globals.hud.open_details_pane):
		check(globals.hud.open_details_pane.turret == turret,
			"painel aberto deveria ser o da torre tocada")

	# ---- segundo toque (no frame seguinte) fecha o painel ----
	await process_frame
	turret._on_collision_area_input_event(null, _make_touch(), 0)
	turret._on_collision_area_input_event(null, _make_click(), 0)
	await process_frame
	check(not is_instance_valid(globals.hud.open_details_pane),
		"segundo toque deveria fechar o painel")

	# ---- tocar outra torre troca o painel (sem fechar no mesmo tap) ----
	await process_frame
	turret._on_collision_area_input_event(null, _make_touch(), 0)
	turret._on_collision_area_input_event(null, _make_click(), 0)
	var turret2 = load("res://Scenes/turrets/projectileTurret/projectileTurret.tscn").instantiate()
	turret2.turret_type = "tiago"
	globals.turretsNode.add_child(turret2)
	turret2.build()
	await process_frame
	turret2._on_collision_area_input_event(null, _make_touch(), 0)
	turret2._on_collision_area_input_event(null, _make_click(), 0)
	await process_frame
	check(is_instance_valid(globals.hud.open_details_pane) \
		and globals.hud.open_details_pane.turret == turret2,
		"tocar outra torre deveria trocar o painel para ela")

	# ---- upgrade pelo botão do painel funciona ----
	if is_instance_valid(globals.hud.open_details_pane):
		var pane = globals.hud.open_details_pane
		globals.currentMap.gold = 9999
		var lvl: int = turret2.turret_level
		pane._on_upgrade_button_pressed()
		check(turret2.turret_level == lvl + 1,
			"botão Melhorar deveria subir o nível da torre")

	print("TEST_MOBILE_TAP: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
