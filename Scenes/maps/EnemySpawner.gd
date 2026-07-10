extends Path2D
class_name EnemyPath

var map_type := "":
	set(val):
		map_type = val
		for config in Data.maps[val]["spawner_settings"].keys():
			set(config, Data.maps[val]["spawner_settings"][config])

var difficulty := {}
var ghost_waves := []
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

func enemy_leaked():
	leaked_this_wave += 1

func spawn_new_enemy():
	var enemyScene := preload("res://Scenes/enemies/enemy_mover.tscn")
	var enemy = enemyScene.instantiate()
	var special: Dictionary = special_waves.get(str(current_wave), {})
	if enemies_spawned_this_wave == 0 and special.has("boss"):
		enemy.enemy_type = special["boss"]
	else:
		enemy.enemy_type = spawnable_enemies.pick_random()
		# corações ficam mais "machucados" a cada onda (+6% de cura
		# necessária por onda)
		enemy.hp *= 1.0 + 0.08 * (current_wave - 1)
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
	#Move to next wave
	current_wave += 1
	killed_this_wave = 0
	enemies_spawned_this_wave = 0
	current_difficulty = get_current_difficulty()
	current_wave_spawn_count = round(wave_spawn_count * current_difficulty)
	spawnable_enemies = get_spawnable_enemies()
	var special: Dictionary = special_waves.get(str(current_wave), {})
	if special.has("boss"):
		current_wave_spawn_count = int(special.get("escort", 10)) + 1
	leaked_this_wave = 0
	# ondas finais spawnam mais rápido (mais pressão)
	$SpawnDelay.wait_time = clampf(0.95 - current_wave * 0.045, 0.5, 0.95)
	Globals.waveStarted.emit(current_wave, current_wave_spawn_count)
	$SpawnDelay.start()
	# fantasmas entram pela direita alguns segundos depois
	var n_ghosts := ghost_waves.count(current_wave)
	for i in range(n_ghosts):
		get_tree().create_timer(4.0 + i * 6.0).timeout.connect(spawn_ghost)

func spawn_ghost():
	if not is_instance_valid(Globals.currentMap) or Globals.currentMap.gameOver:
		return
	var ghostScene := preload("res://Scenes/enemies/ghost.tscn")
	var ghost := ghostScene.instantiate()
	Globals.currentMap.add_child(ghost)
	ghost.position = Vector2(700, randf_range(-110, 110))

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
