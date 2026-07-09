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

func is_defender_locked(key: String) -> bool:
	return Data.turrets[key].get("locked", false) and not unlocked_defenders.has(key)

# Ícone de preview de um defensor (recorta o frame "parado" do sheet)
func defender_icon(key: String) -> Texture2D:
	var cfg: Dictionary = Data.turrets[key]
	var tex: Texture2D = load(cfg["sprite"])
	if cfg.get("directional_sheet", false):
		var at := AtlasTexture.new()
		var fw: float = tex.get_width() / 4.0
		var fh: float = tex.get_height() / 9.0
		at.atlas = tex
		at.region = Rect2(0, fh * 8, fw, fh)
		return at
	return tex

func restart_current_level():
	var currentLevelScene := load(currentMap.scene_file_path)
	currentMap.queue_free()
	var newMap = currentLevelScene.instantiate()
	newMap.map_type = selected_map
	mainNode.add_child(newMap)
	hud.reset()
