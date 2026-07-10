extends Node
@warning_ignore("unused_signal")
signal goldChanged(newGold)
@warning_ignore("unused_signal")
signal baseHpChanged(newHp, maxHp)
@warning_ignore("unused_signal")
signal waveStarted(wave_count, enemy_count)
@warning_ignore("unused_signal")
signal waveCleared(wait_time)
@warning_ignore("unused_signal")
signal enemyDestroyed(remain)
signal defenderUnlocked(defender_key)

# Fase única do presente
var selected_map := "elisa"
var mainNode : Node2D
var turretsNode : Node2D
var projectilesNode : Node2D
var currentMap : Node2D
var hud : Control

# Defensores surpresa já revelados nesta sessão (ex.: Elisa)
var unlocked_defenders: Array[String] = []

func _ready():
	waveStarted.connect(_check_unlocks)

func _check_unlocks(wave_count, _enemy_count):
	for key in Data.turrets.keys():
		var cfg: Dictionary = Data.turrets[key]
		if cfg.get("locked", false) and not unlocked_defenders.has(key) \
				and wave_count >= int(cfg.get("unlock_wave", 1)):
			unlocked_defenders.append(key)
			defenderUnlocked.emit(key)

# quantas cópias deste defensor já estão em campo
func deployed_count(key: String) -> int:
	if not is_instance_valid(turretsNode):
		return 0
	var n := 0
	for t in turretsNode.get_children():
		if "turret_type" in t and t.turret_type == key and t.deployed:
			n += 1
	return n

# preço atual: cada cópia do MESMO defensor custa 45% a mais
# (composto) — chamar reforço repetido fica caro; diversifique!
func defender_cost(key: String) -> int:
	var base: int = int(Tuning.value(key, "cost", Data.turrets[key]["cost"]))
	return roundi(base * pow(1.45, deployed_count(key)))

func is_defender_locked(key: String) -> bool:
	return Data.turrets[key].get("locked", false) and not unlocked_defenders.has(key)

# Ícone de preview de um defensor (retrato dedicado, se existir;
# senão recorta o frame frontal do sheet)
func defender_icon(key: String) -> Texture2D:
	var cfg: Dictionary = Data.turrets[key]
	if cfg.has("portrait"):
		return load(cfg["portrait"])
	var tex: Texture2D = load(cfg["sprite"])
	if cfg.get("directional_sheet", false):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, tex.get_width() / 3.0, tex.get_height())
		return at
	return tex

func restart_current_level():
	Progress.new_session()
	var currentLevelScene := load(currentMap.scene_file_path)
	currentMap.queue_free()
	var newMap = currentLevelScene.instantiate()
	newMap.map_type = selected_map
	mainNode.add_child(newMap)
	hud.reset()
