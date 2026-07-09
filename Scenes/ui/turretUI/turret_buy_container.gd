extends PanelContainer

var turret_type := "":
	set(value):
		turret_type = value
		$TextureRect.turretType = value
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
		# Surpresa ainda não revelada: mostra "?"
		$TextureRect.texture = load(Data.locked_icon)
		$CostLabel.text = "?"
	else:
		$TextureRect.texture = Globals.defender_icon(turret_type)
		$CostLabel.text = str(Data.turrets[turret_type]["cost"])

func _on_defender_unlocked(key):
	if key != turret_type:
		return
	refresh_icon()
	if is_instance_valid(Globals.currentMap):
		$TextureRect.check_can_purchase(Globals.currentMap.gold)
	unlock_pop()

func unlock_pop():
	pivot_offset = size / 2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.18)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25)
