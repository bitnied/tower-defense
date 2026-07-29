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
# dificuldade escolhida na home (ver Data.difficulties)
var selected_difficulty := "medio"

func difficulty_cfg() -> Dictionary:
	return Data.difficulties[selected_difficulty]
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
	Sfx.play_music()
	var currentLevelScene := load(currentMap.scene_file_path)
	currentMap.queue_free()
	var newMap = currentLevelScene.instantiate()
	newMap.map_type = selected_map
	mainNode.add_child(newMap)
	hud.reset()

# ---------- utilidades da versão web (navegador) ----------

# Área "segura" da tela (notch / barra de status / home indicator do
# celular), convertida de pixels CSS para pixels do jogo. Fora do
# navegador retorna tudo zero.
func web_safe_insets() -> Dictionary:
	var out := {"top": 0.0, "right": 0.0, "bottom": 0.0, "left": 0.0}
	if not OS.has_feature("web"):
		return out
	var js := "(function(){var d=document.createElement('div');" \
		+ "d.style.cssText='position:fixed;visibility:hidden;" \
		+ "top:env(safe-area-inset-top,0px);right:env(safe-area-inset-right,0px);" \
		+ "bottom:env(safe-area-inset-bottom,0px);left:env(safe-area-inset-left,0px)';" \
		+ "document.body.appendChild(d);var cs=getComputedStyle(d);" \
		+ "var r=[parseFloat(cs.top)||0,parseFloat(cs.right)||0," \
		+ "parseFloat(cs.bottom)||0,parseFloat(cs.left)||0," \
		+ "window.innerWidth||1].join(',');d.remove();return r;})()"
	var raw = JavaScriptBridge.eval(js, true)
	if raw is String:
		var p := (raw as String).split(",")
		if p.size() >= 5:
			var win_w := maxf(1.0, p[4].to_float())
			var scale := get_viewport().get_visible_rect().size.x / win_w
			out["top"] = p[0].to_float() * scale
			out["right"] = p[1].to_float() * scale
			out["bottom"] = p[2].to_float() * scale
			out["left"] = p[3].to_float() * scale
	return out

# Mostra/esconde o botão ⛶ de fullscreen do navegador (criado no
# index.html). Ele só fica visível no menu principal: nas outras telas
# cobria a engrenagem de pause e o contador da galeria.
func set_fs_button(show_it: bool):
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.setFsBtn&&window.setFsBtn(%s)" \
			% ("true" if show_it else "false"))
