extends Path2D
class_name EnemyPath

var map_type := "":
	set(val):
		map_type = val
		for config in Data.maps[val]["spawner_settings"].keys():
			set(config, Data.maps[val]["spawner_settings"][config])
		_apply_difficulty()

# sobrepõe as configurações do mapa com a dificuldade escolhida
# (Fácil / Médio / Vida Real) — ver Data.difficulties
var hp_per_wave := 0.08
var hp_mult := 1.0
var boss_escort := 14
var spawn_wait_mult := 1.0

func _apply_difficulty():
	var d: Dictionary = Globals.difficulty_cfg()
	difficulty = difficulty.duplicate()
	difficulty["increase"] = d.get("increase", difficulty["increase"])
	ghost_waves = d.get("ghost_waves", ghost_waves).duplicate()
	meteor_waves = d.get("meteor_waves", meteor_waves).duplicate()
	hp_per_wave = d.get("hp_per_wave", 0.08)
	hp_mult = d.get("hp_mult", 1.0)
	boss_escort = d.get("escort", 14)
	spawn_wait_mult = d.get("spawn_wait_mult", 1.0)

var difficulty := {}
var ghost_waves := []
var meteor_waves := []
var spawnable_enemies := []
var max_waves := 3
var special_waves := {}
var wave_spawn_count := 10

var current_wave_spawn_count := 0
var current_difficulty := 1.0
var current_wave := 0
var enemies_spawned_this_wave := 0
var killed_this_wave := 0
var leaked_this_wave := 0
var boss_spawned := false
var base_wave_wait := 9.0

func _ready():
	base_wave_wait = $WaveDelayTimer.wait_time

# corações ainda vivos na estrada (ignora os já curados/animando)
func hearts_on_road() -> int:
	var n := 0
	for c in get_children():
		if c is PathFollow2D and not c.is_destroyed:
			n += 1
	return n

func enemy_leaked():
	leaked_this_wave += 1

func spawn_new_enemy():
	var enemyScene := preload("res://Scenes/enemies/enemy_mover.tscn")
	var enemy = enemyScene.instantiate()
	var special: Dictionary = special_waves.get(str(current_wave), {})
	if not boss_spawned and special.has("boss"):
		enemy.enemy_type = special["boss"]
		enemy.hp *= hp_mult
		boss_spawned = true
	else:
		enemy.enemy_type = spawnable_enemies.pick_random()
		# corações ficam mais "machucados" a cada onda; o quanto
		# depende da dificuldade escolhida
		enemy.hp *= hp_mult * (1.0 + hp_per_wave * (current_wave - 1))
	add_child(enemy)
	enemies_spawned_this_wave += 1

func get_spawnable_enemies():
	var enemies := []
	for enemy in Data.enemies.keys():
		if current_difficulty >= Data.enemies[enemy]["difficulty"]:
			enemies.append(enemy)
	if enemies.is_empty():
		# nunca deixar a onda sem inimigos (dificuldade < 1.0)
		enemies.append("coracaoRachado")
	return enemies

func get_current_difficulty() -> float:
	var default_diff = difficulty["initial"]
	var increase = difficulty["increase"]
	var calculated_diff = default_diff * pow(increase, current_wave) if difficulty["multiplies"] else default_diff + increase * current_wave
	return calculated_diff

func _on_spawn_delay_timeout():
	if enemies_spawned_this_wave < current_wave_spawn_count:
		spawn_new_enemy()
		$SpawnDelay.start()

func is_waiting_for_wave() -> bool:
	return not $WaveDelayTimer.is_stopped()

func start_next_wave_early():
	if is_waiting_for_wave():
		$WaveDelayTimer.stop()
		_on_wave_delay_timer_timeout()

func _on_wave_delay_timer_timeout():
	# nunca começa a onda seguinte com corações ainda na estrada
	# (eles sumiriam "do nada" no meio da troca de contadores)
	if hearts_on_road() > 0:
		$WaveDelayTimer.wait_time = 1.0
		$WaveDelayTimer.start()
		return
	$WaveDelayTimer.wait_time = base_wave_wait
	#Move to next wave
	current_wave += 1
	boss_spawned = false
	killed_this_wave = 0
	enemies_spawned_this_wave = 0
	current_difficulty = get_current_difficulty()
	current_wave_spawn_count = round(wave_spawn_count * current_difficulty)
	spawnable_enemies = get_spawnable_enemies()
	var special: Dictionary = special_waves.get(str(current_wave), {})
	if special.has("boss"):
		current_wave_spawn_count = boss_escort + 1
	leaked_this_wave = 0
	# corações-meteoro caem do céu no meio da onda; eles contam na
	# cota da onda mas chegam pelos timers (não pelo SpawnDelay)
	var n_meteors := meteor_waves.count(current_wave)
	current_wave_spawn_count += n_meteors
	enemies_spawned_this_wave += n_meteors
	# ondas finais spawnam mais rápido (mais pressão); a dificuldade
	# acelera ou alivia o ritmo
	$SpawnDelay.wait_time = clampf(0.95 - current_wave * 0.045, 0.5, 0.95) \
		* spawn_wait_mult
	Globals.waveStarted.emit(current_wave, current_wave_spawn_count)
	$SpawnDelay.start()
	for i in range(n_meteors):
		get_tree().create_timer(6.0 + i * 7.0).timeout.connect(spawn_meteor)
	# fantasmas chegam alguns segundos depois, por qualquer borda
	var n_ghosts := ghost_waves.count(current_wave)
	for i in range(n_ghosts):
		get_tree().create_timer(4.0 + i * 6.0).timeout.connect(spawn_ghost)

func spawn_meteor():
	if not is_instance_valid(Globals.currentMap) or Globals.currentMap.gameOver:
		return
	var enemyScene := preload("res://Scenes/enemies/enemy_mover.tscn")
	var enemy = enemyScene.instantiate()
	enemy.enemy_type = "coracaoMeteoro"
	enemy.hp *= hp_mult
	add_child(enemy)
	enemy.begin_sky_drop()

func spawn_ghost():
	if not is_instance_valid(Globals.currentMap) or Globals.currentMap.gameOver:
		return
	var ghostScene := preload("res://Scenes/enemies/ghost.tscn")
	var ghost := ghostScene.instantiate()
	Globals.currentMap.add_child(ghost)
	# entra por uma borda aleatória da tela (qualquer ângulo)
	var vp := Globals.currentMap.get_viewport()
	var cam := vp.get_camera_2d()
	var zoom_f: float = cam.zoom.x if cam != null else 1.0
	var half: Vector2 = vp.get_visible_rect().size / (2.0 * zoom_f)
	match randi() % 4:
		0: ghost.position = Vector2(randf_range(-half.x, half.x), -half.y - 60.0)
		1: ghost.position = Vector2(half.x + 60.0, randf_range(-half.y, half.y))
		2: ghost.position = Vector2(randf_range(-half.x, half.x), half.y + 60.0)
		_: ghost.position = Vector2(-half.x - 60.0, randf_range(-half.y, half.y))

func enemy_destroyed():
	killed_this_wave += 1
	Globals.enemyDestroyed.emit(current_wave_spawn_count - killed_this_wave)
	check_wave_clear()
	
func check_wave_clear():
	if killed_this_wave == current_wave_spawn_count:
		#Wave cleared
		if leaked_this_wave == 0 and is_instance_valid(Globals.currentMap) \
				and not Globals.currentMap.gameOver:
			# onda perfeita: nenhum coração chegou na mamãe
			Globals.currentMap.gold += 8
			Progress.add_points(5)
			Sfx.play("upgrade", -12.0)
			if is_instance_valid(Globals.hud):
				Globals.hud.show_banner("Onda perfeita! +8", 1.6)
		Progress.save()
		if not current_wave == max_waves:
			Globals.waveCleared.emit($WaveDelayTimer.wait_time)
			$WaveDelayTimer.start()
			return
		#game completion
		var mapCompletedScene := preload("res://Scenes/ui/mapCompleted/mapCompleted.tscn")
		var mapCompleted := mapCompletedScene.instantiate()
		Globals.hud.add_child(mapCompleted)
