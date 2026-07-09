extends Control

var next_wait_time := 0
var waited := 0
var open_details_pane : PanelContainer

func _ready():
	Globals.hud = self
	Globals.baseHpChanged.connect(update_hp)
	Globals.goldChanged.connect(update_gold)
	Globals.waveStarted.connect(show_wave_count)
	Globals.waveCleared.connect(show_wave_timer)
	Globals.enemyDestroyed.connect(update_enemy_count)
	Globals.defenderUnlocked.connect(_on_defender_unlocked)

func max_waves() -> int:
	return int(Data.maps[Globals.selected_map]["spawner_settings"]["max_waves"])

func update_hp(newHp, maxHp):
	%HPLabel.text = "Mamãe: %d/%d" % [round(newHp), round(maxHp)]

func update_gold(newGold):
	%GoldLabel.text = "Corações: %d" % round(newGold)

func show_wave_count(current_wave, enemies):
	$WaveWaitTimer.stop()
	waited = 0
	%WaveLabel.text = "Onda %d/%d" % [current_wave, max_waves()]
	%RemainLabel.text = "A caminho: %d" % enemies
	%RemainLabel.visible = true

func show_wave_timer(wait_time):
	%RemainLabel.visible = false
	next_wait_time = wait_time-1
	$WaveWaitTimer.start()

func _on_wave_wait_timer_timeout():
	%WaveLabel.text = "Próxima onda em %d" % (next_wait_time - waited)
	waited += 1

func update_enemy_count(remain):
	%RemainLabel.text = "A caminho: %d" % remain

func _on_defender_unlocked(_key):
	show_banner(Data.texts["unlock_banner"])

func show_banner(message: String):
	var banner: Label = %BannerLabel
	banner.text = message
	banner.visible = true
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_property(banner, "scale", Vector2(1, 1), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(2.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): banner.visible = false)

func reset():
	if is_instance_valid(open_details_pane):
		open_details_pane.turret.close_details_pane()
