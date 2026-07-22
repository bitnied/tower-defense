extends PanelContainer
# Card de compra de um defensor (estilo BTD6): retrato + preço.
# Quando o defensor ainda é surpresa (Elisa), mostra "?" + cadeado.

var turret_type := "":
	set(value):
		turret_type = value
		$HBox/TextureRect.turretType = value
		refresh_icon()

var can_purchase := false:
	set(value):
		can_purchase = value
		$CantBuy.visible = not value

func _ready():
	Globals.defenderUnlocked.connect(_on_defender_unlocked)
	Globals.goldChanged.connect(_on_gold_changed)

func _on_gold_changed(_g):
	# o preço sobe a cada cópia construída
	if turret_type != "" and not Globals.is_defender_locked(turret_type):
		$HBox/CostRow/CostLabel.text = str(Globals.defender_cost(turret_type))

# o card inteiro serve de alça de arrasto (não só o retrato)
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		var drag: TextureRect = $HBox/TextureRect
		if drag.check_can_purchase(Globals.currentMap.gold):
			drag.start_grab()

func refresh_icon():
	if turret_type == "":
		return
	var cfg: Dictionary = Data.turrets[turret_type]
	if Globals.is_defender_locked(turret_type):
		$LockIcon.visible = true
		if cfg.get("mystery", false):
			# surpresa não revelada (Elisa): só um "?"
			$HBox/TextureRect.texture = load(Data.locked_icon)
			$HBox/CostRow/CoinIcon.visible = true
			$HBox/CostRow/CostLabel.add_theme_font_size_override("font_size", 38)
			$HBox/CostRow/CostLabel.text = "?"
		else:
			# reforço a caminho: retrato + onda em que chega
			$HBox/TextureRect.texture = Globals.defender_icon(turret_type)
			$HBox/CostRow/CoinIcon.visible = false
			$HBox/CostRow/CostLabel.add_theme_font_size_override("font_size", 28)
			$HBox/CostRow/CostLabel.text = "Onda %d" % int(cfg.get("unlock_wave", 1))
	else:
		$HBox/TextureRect.texture = Globals.defender_icon(turret_type)
		$HBox/CostRow/CoinIcon.visible = true
		$HBox/CostRow/CostLabel.add_theme_font_size_override("font_size", 38)
		$HBox/CostRow/CostLabel.text = str(Globals.defender_cost(turret_type))
		$LockIcon.visible = false

func _on_defender_unlocked(key):
	if key != turret_type:
		return
	refresh_icon()
	if is_instance_valid(Globals.currentMap):
		$HBox/TextureRect.check_can_purchase(Globals.currentMap.gold)
	unlock_pop()

func unlock_pop():
	pivot_offset = size / 2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.18)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25)
