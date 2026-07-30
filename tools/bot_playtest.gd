extends SceneTree
# Bot que JOGA a fase de verdade (headless) para responder à pergunta
# "dá para vencer?". Estratégia de um jogador competente: defensores na
# faixa entre os dois braços do U (cada um cobre os dois braços),
# prioriza evoluir os fortes, diversifica compras (o preço da cópia
# sobe 45%) e adianta ondas com a estrada vazia. Roda a 4x — o mesmo
# máximo do botão de velocidade do jogo.
# Rodar: Godot --headless --path . --script res://tools/bot_playtest.gd
# (autoloads não compilam como identificador aqui; usar root.get_node)

var globals

# faixa central: y=0 fica a ~80px dos corações dos dois braços
# (alcances são 170-220). Primeiros pontos cobrem a curva da direita
# (fim do U + queda dos meteoros) e o funil perto da mamãe.
const SPOTS := [
	Vector2(240, 0), Vector2(-430, 0), Vector2(150, 0), Vector2(-40, 0),
	Vector2(-240, 0), Vector2(60, 0), Vector2(-140, 0), Vector2(-340, 0),
	Vector2(270, 0), Vector2(200, 0), Vector2(-290, 0), Vector2(-480, 30),
	Vector2(100, 0), Vector2(-90, 0), Vector2(0, 0), Vector2(-390, 0),
]
# valor relativo por defensor, para escolher a compra da vez
const WEIGHT := {"tiago": 1.0, "luna": 0.85, "leo": 1.7, "elisa": 2.6}

var spot_i := 0

func _initialize():
	_run()

func _run() -> void:
	await process_frame
	globals = root.get_node("Globals")
	var results := {}
	for run in [["medio", 1], ["vida_real", 1], ["vida_real", 2]]:
		var label: String = "%s #%d" % [run[0], run[1]]
		print("\n########## PARTIDA: %s ##########" % label)
		results[label] = await _play(run[0])
	print("")
	for k in results.keys():
		print("%-14s -> %s" % [k, results[k]])
	quit(0)

func _play(diff_key: String) -> String:
	paused = false
	Engine.time_scale = 1.0
	spot_i = 0
	globals.selected_difficulty = diff_key
	globals.selected_map = "elisa"
	globals.unlocked_defenders.clear()
	var old_map = globals.currentMap
	change_scene_to_file("res://Scenes/main/main.tscn")
	# espera o mapa novo assumir
	while globals.currentMap == old_map or not is_instance_valid(globals.currentMap):
		await process_frame
	await process_frame
	var map = globals.currentMap
	var t0 := Time.get_ticks_msec()
	var last_wave := 0
	while true:
		Engine.time_scale = 4.0
		for i in range(12):
			await process_frame
		if not is_instance_valid(map):
			return "mapa sumiu (?)"
		var spawner = map.get_node("PathSpawner")
		if spawner.current_wave != last_wave:
			last_wave = spawner.current_wave
			print("  onda %2d | vida %2d/%2d | ouro %4d | defesas %d" % [
				last_wave, int(map.baseHP), int(map.baseMaxHp),
				int(map.gold), _deployed_count()])
		if is_instance_valid(globals.hud) \
				and globals.hud.get_node_or_null("MapCompleted") != null:
			print("  VITORIA com vida %d/%d, ouro sobrando %d, defesas %d" % [
				int(map.baseHP), int(map.baseMaxHp), int(map.gold), _deployed_count()])
			return "VITORIA (vida %d/%d)" % [int(map.baseHP), int(map.baseMaxHp)]
		if map.gameOver:
			print("  DERROTA na onda %d (defesas %d, ouro %d)" % [
				last_wave, _deployed_count(), int(map.gold)])
			return "DERROTA na onda %d" % last_wave
		if Time.get_ticks_msec() - t0 > 480000:
			return "TIMEOUT na onda %d" % last_wave
		_bot_actions(map, spawner)
	return "?"

func _deployed_count() -> int:
	var n := 0
	if is_instance_valid(globals.turretsNode):
		for t in globals.turretsNode.get_children():
			if "deployed" in t and t.deployed:
				n += 1
	return n

func _bot_actions(map, spawner):
	# jogador apressado: estrada vazia = próxima onda já
	if spawner.is_waiting_for_wave() and spawner.hearts_on_road() == 0:
		spawner.start_next_wave_early()
	# evoluir primeiro (melhor custo-benefício que a 2ª cópia cara),
	# do defensor mais valioso para o mais barato
	var did := true
	while did:
		did = _try_upgrade(map)
	while _try_buy(map):
		pass

func _try_upgrade(map) -> bool:
	if not is_instance_valid(globals.turretsNode):
		return false
	var best = null
	var best_w := -1.0
	for t in globals.turretsNode.get_children():
		if not ("deployed" in t) or not t.deployed:
			continue
		if t.turret_level >= int(Data.turrets[t.turret_type]["max_level"]):
			continue
		var price: int = t.turret_level * int(Data.turrets[t.turret_type]["upgrade_cost"])
		if map.gold < price:
			continue
		var w: float = WEIGHT.get(t.turret_type, 1.0)
		if w > best_w:
			best_w = w
			best = t
	if best == null:
		return false
	map.gold -= best.turret_level * int(Data.turrets[best.turret_type]["upgrade_cost"])
	best.upgrade_turret()
	return true

func _try_buy(map) -> bool:
	if spot_i >= SPOTS.size():
		return false
	var best := ""
	var best_v := 1e18
	for key in Data.turrets.keys():
		if globals.is_defender_locked(key):
			continue
		var cost: int = globals.defender_cost(key)
		if cost > map.gold:
			continue
		var v: float = cost / WEIGHT.get(key, 1.0)
		if v < best_v:
			best_v = v
			best = key
	if best == "":
		return false
	var cost: int = globals.defender_cost(best)
	var turret = load(Data.turrets[best]["scene"]).instantiate()
	turret.turret_type = best
	globals.turretsNode.add_child(turret)
	turret.position = SPOTS[spot_i]
	spot_i += 1
	map.gold -= cost
	turret.paid_cost = cost
	turret.build()
	return true
