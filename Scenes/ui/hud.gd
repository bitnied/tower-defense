extends Control

var next_wait_time := 0
var waited := 0
var open_details_pane : PanelContainer

# Velocidades do jogo: o 1x novo já é acelerado (time_scale 2).
# O botão mostra o nível atual e cicla 1x → 2x → 3x.
const SPEEDS := [2.0, 3.0, 4.0]
var speed_idx := 0

func _ready():
	Globals.hud = self
	Globals.baseHpChanged.connect(update_hp)
	Globals.goldChanged.connect(update_gold)
	Globals.waveStarted.connect(show_wave_count)
	Globals.waveCleared.connect(show_wave_timer)
	Globals.enemyDestroyed.connect(update_enemy_count)
	Globals.defenderUnlocked.connect(_on_defender_unlocked)
	Engine.time_scale = SPEEDS[speed_idx]
	_refresh_play_button()

func max_waves() -> int:
	return int(Data.maps[Globals.selected_map]["spawner_settings"]["max_waves"])

func update_hp(newHp, maxHp):
	%HPLabel.text = "%d/%d" % [round(newHp), round(maxHp)]

func update_gold(newGold):
	%GoldLabel.text = str(round(newGold))

func show_wave_count(current_wave, enemies):
	$WaveWaitTimer.stop()
	waited = 0
	%WaveLabel.text = "Onda %d/%d" % [current_wave, max_waves()]
	%RemainLabel.text = "Faltam: %d" % enemies
	%RemainLabel.visible = true
	if current_wave == max_waves():
		show_banner("Onda final! Curem o coração gigante!", 2.4)
	_refresh_play_button()

func show_wave_timer(wait_time):
	%RemainLabel.visible = false
	next_wait_time = wait_time-1
	$WaveWaitTimer.start()
	_refresh_play_button()

func _on_wave_wait_timer_timeout():
	%WaveLabel.text = "Próxima: %d" % (next_wait_time - waited)
	waited += 1

func update_enemy_count(remain):
	%RemainLabel.text = "Faltam: %d" % remain

# ---------- botão play / acelerar (estilo BTD6) ----------

func _on_play_button_pressed():
	Sfx.play("click", -10.0)
	var spawner = _spawner()
	if spawner and spawner.is_waiting_for_wave():
		spawner.start_next_wave_early()
	else:
		speed_idx = (speed_idx + 1) % SPEEDS.size()
		Engine.time_scale = SPEEDS[speed_idx]
	_refresh_play_button()

func _spawner():
	if is_instance_valid(Globals.currentMap):
		return Globals.currentMap.get_node_or_null("PathSpawner")
	return null

func _refresh_play_button(_a = 0, _b = 0):
	var spawner = _spawner()
	var waiting: bool = spawner == null or spawner.is_waiting_for_wave()
	if waiting:
		# entre ondas: play para começar já
		%PlayButton.icon = load("res://Assets/ui/icon_play.png")
		%PlayButton.text = ""
		%PlayButton.self_modulate = Color.WHITE
	else:
		# durante a onda: nível atual (3x dourado)
		%PlayButton.icon = null
		%PlayButton.text = "%dx" % (speed_idx + 1)
		%PlayButton.self_modulate = Color(1.0, 0.84, 0.35) if speed_idx == 2 			else Color.WHITE

# ---------- pause ----------

func _on_pause_button_pressed():
	Sfx.play("click", -10.0)
	var pauseScene := preload("res://Scenes/ui/pauseMenu/pause_menu.tscn")
	add_child(pauseScene.instantiate())
	get_tree().paused = true

# ---------- avisos ----------

func _on_defender_unlocked(key):
	Sfx.play("unlock", -4.0)
	if key == "elisa":
		show_banner(Data.texts["unlock_banner"])
	else:
		show_banner("%s entrou na defesa!" % Data.turrets[key]["name"])

var banner_tween: Tween

func show_banner(message: String, hold := 2.6):
	var banner: Label = %BannerLabel
	if banner_tween and banner_tween.is_running():
		banner_tween.kill()
	banner.text = message
	banner.visible = true
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.6, 0.6)
	banner_tween = create_tween()
	banner_tween.set_parallel()
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	banner_tween.tween_property(banner, "scale", Vector2(1, 1), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.set_parallel(false)
	banner_tween.tween_interval(hold)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	banner_tween.tween_callback(func(): banner.visible = false)

func reset():
	speed_idx = 0
	Engine.time_scale = SPEEDS[speed_idx]
	_refresh_play_button()
	if is_instance_valid(open_details_pane):
		open_details_pane.turret.close_details_pane()
