extends PanelContainer

var turret : Node2D
const sell_modifier := 0.7

func _ready():
	Globals.goldChanged.connect(check_can_upgrade)
	turret.turretUpdated.connect(set_props)
	set_props()
	animate_appear()
	check_can_upgrade()

func animate_appear():
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(-400,0), 0.01).as_relative()
	tween.tween_property(self, "position", Vector2(400,0), 0.3).as_relative()

func set_props():
	%TurretTexture.texture = Globals.defender_icon(turret.turret_type)
	%TurretName.text = Data.turrets[turret.turret_type]["name"]
	%TurretLevel.text = "Nível "+str(turret.turret_level)
	%UpgradeButton.text = "Melhorar ("+str(get_upgrade_price())+")"
	%SellButton.text = "Vender ("+str(get_sell_price())+")"
	for c in %Stats.get_children():
		c.queue_free()
	var statLabelScene := preload("res://Scenes/ui/turretUI/stat_label.tscn")
	for stat in Data.turrets[turret.turret_type]["stats"].keys():
		var statLabel := statLabelScene.instantiate()
		# mostra casas decimais só quando existem (1.2 não vira "1.0")
		var v: float = snappedf(float(turret.get(stat)), 0.05)
		var v_txt := str(int(v)) if fmod(v, 1.0) == 0.0 else str(v)
		statLabel.text = Data.stats[stat]["name"]+" "+v_txt
		%Stats.add_child(statLabel)

func _on_upgrade_button_pressed():
	if check_can_upgrade():
		Globals.currentMap.gold -= get_upgrade_price()
		turret.upgrade_turret()
		check_can_upgrade()

func get_upgrade_price():
	return turret.turret_level * Data.turrets[turret.turret_type]["upgrade_cost"]

func get_sell_price():
	var total_cost = turret.paid_cost if turret.paid_cost > 0 		else Data.turrets[turret.turret_type]["cost"]
	for i in range(turret.turret_level):
		total_cost += i*Data.turrets[turret.turret_type]["upgrade_cost"]
	return round(total_cost * sell_modifier)

func check_can_upgrade(_new_gold=0):
	if turret.turret_level == Data.turrets[turret.turret_type]["max_level"]:
		%UpgradeButton.text = "No máximo"
		%UpgradeButton.disabled = true
	else:
		%UpgradeButton.disabled = Globals.currentMap.gold < get_upgrade_price()
	return not %UpgradeButton.disabled


func _on_sell_button_pressed():
	Sfx.play("heal", -10.0)
	queue_free()
	Globals.currentMap.gold += get_sell_price()
	turret.queue_free()

func _on_close_button_pressed():
	turret.close_details_pane()
