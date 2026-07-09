extends PanelContainer
# Card de compra de um defensor (estilo BTD6): retrato + preço.
# Quando o defensor ainda é surpresa (Elisa), mostra "?" + cadeado.

var turret_type := "":
	set(value):
		turret_type = value
		$VBox/TextureRect.turretType = value
		refresh_icon()

var can_purchase := false:
	set(value):
		can_purchase = value
		$CantBuy.visible = not value

func _ready():
	Globals.defenderUnlocked.connect(_on_defender_unlocked)

# o card inteiro serve de alça de arrasto (não só o retrato)
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		var drag: TextureRect = $VBox/TextureRect
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
			$VBox/TextureRect.texture = load(Data.locked_icon)
			$VBox/CostRow/CostLabel.text = "?"
		else:
			# reforço a caminho: retrato + onda em que chega
			$VBox/TextureRect.texture = Globals.defender_icon(turret_type)
			$VBox/CostRow/CostLabel.text = "Onda %d" % int(cfg.get("unlock_wave", 1))
	else:
		$VBox/TextureRect.texture = Globals.defender_icon(turret_type)
		$VBox/CostRow/CostLabel.text = str(cfg["cost"])
		$LockIcon.visible = false

func _on_defender_unlocked(key):
	if key != turret_type:
		return
	refresh_icon()
	if is_instance_valid(Globals.currentMap):
		$VBox/TextureRect.check_can_purchase(Globals.currentMap.gold)
	unlock_pop()

func unlock_pop():
	pivot_offset = size / 2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.18)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25)
