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

func refresh_icon():
	if turret_type == "":
		return
	if Globals.is_defender_locked(turret_type):
		$VBox/TextureRect.texture = load(Data.locked_icon)
		$VBox/CostRow/CostLabel.text = "?"
		$LockIcon.visible = true
	else:
		$VBox/TextureRect.texture = Globals.defender_icon(turret_type)
		$VBox/CostRow/CostLabel.text = str(Data.turrets[turret_type]["cost"])
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
