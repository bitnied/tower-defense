extends SceneTree
# Teste headless do enquadramento da câmera com o painel de defesas:
# em tela 4:3 (iPad) o fim da curva (x ~304) tem que aparecer FORA do
# painel, a Mamãe (x -478) tem que continuar visível e a câmera nunca
# pode mostrar além das bordas laterais da arte (1152 de largura).
# Rodar: Godot --headless --script res://tools/smoke_layout.gd
# (autoloads não compilam como identificador aqui; usar root.get_node)

var fails := 0

func check(cond: bool, msg: String):
	if not cond:
		push_error("FALHA: " + msg)
		fails += 1

func _initialize():
	_run()

func _check_frame(label: String, need_curve: bool):
	var main = current_scene
	var cam: Camera2D = main.get_node("Camera2D")
	var vs: Vector2 = main.get_viewport_rect().size
	var panel: Control = main.get_node("UI/HUD/SidePanel")
	var z: float = cam.zoom.x
	var left: float = cam.position.x - vs.x / (2.0 * z)
	var right: float = cam.position.x + vs.x / (2.0 * z)
	var play_right: float = right - panel.size.x / z
	check(left >= -576.5, "%s: mostrou além da borda esquerda da arte (%.1f)" % [label, left])
	check(right <= 576.5, "%s: mostrou além da borda direita da arte (%.1f)" % [label, right])
	check(left <= -526.0, "%s: Mamãe ficou fora da tela (borda %.1f)" % [label, left])
	if need_curve:
		check(play_right >= 310.0,
			"%s: fim da curva sob o painel (área livre até %.1f)" % [label, play_right])
	# altura além da arte precisa da arte espelhada
	var half_h: float = vs.y / (2.0 * z)
	if half_h > 342.6:
		var map = main.get_node_or_null("ElisaMap")
		if map == null:
			for c in main.get_children():
				if c.has_method("get_base_damage"):
					map = c
		check(map != null and map.get_node_or_null("BleedTop") != null \
			and map.get_node_or_null("BleedBottom") != null,
			"%s: faixas verticais sem arte espelhada" % label)

func _run() -> void:
	await process_frame

	# ---- iPad em webapp (4:3) ----
	root.size = Vector2i(1024, 768)
	change_scene_to_file("res://Scenes/main/main.tscn")
	for i in range(8):
		await process_frame
	_check_frame("iPad 4:3", true)

	# ---- desktop 16:9: comportamento antigo (cobre a tela toda) ----
	root.size = Vector2i(1280, 720)
	for i in range(4):
		await process_frame
	_check_frame("16:9", false)
	var cam: Camera2D = current_scene.get_node("Camera2D")
	check(absf(cam.zoom.x - 1.0) < 0.02,
		"16:9: zoom deveria seguir cobrindo a tela (%.3f)" % cam.zoom.x)

	# ---- celular largo (19.5:9): também sem regressão ----
	root.size = Vector2i(1560, 720)
	for i in range(4):
		await process_frame
	_check_frame("19.5:9", true)

	print("SMOKE_LAYOUT: ", "OK" if fails == 0 else "FALHOU %d" % fails)
	quit(0 if fails == 0 else 1)
