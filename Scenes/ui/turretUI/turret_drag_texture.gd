extends TextureRect

var turretType := ""

var grabbing := false
var placeholder = null

func _ready():
	Globals.goldChanged.connect(check_can_purchase)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and check_can_purchase(Globals.currentMap.gold):
		start_grab()

func _input(event):
	if not grabbing:
		return
	if event is InputEventMouseMotion:
		update_placeholder_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		end_grab()
	elif event is InputEventScreenTouch and not event.pressed:
		end_grab()

func start_grab():
	if is_instance_valid(placeholder):
		return
	grabbing = true
	create_placeholder()
	update_placeholder_position()

func update_placeholder_position():
	if is_instance_valid(placeholder):
		placeholder.position = get_global_mouse_position() - get_viewport_rect().size / 2

func end_grab():
	grabbing = false
	if not is_instance_valid(placeholder):
		placeholder = null
		return
	update_placeholder_position()
	var ph = placeholder
	placeholder = null
	# posicionamento livre: pode construir em qualquer lugar do cenário
	if check_can_purchase(Globals.currentMap.gold):
		Globals.currentMap.gold -= Data.turrets[turretType]["cost"]
		ph.build()
	else:
		ph.queue_free()

func create_placeholder():
	var turretScene := load(Data.turrets[turretType]["scene"])
	var turret = turretScene.instantiate()
	turret.turret_type = turretType
	Globals.turretsNode.add_child(turret)
	placeholder = turret
	placeholder.set_placeholder()

func check_can_purchase(newGold):
	if turretType:
		if Globals.is_defender_locked(turretType):
			owner.can_purchase = false
			return false
		if newGold >= Data.turrets[turretType]["cost"]:
			owner.can_purchase = true
			return true
		owner.can_purchase = false
		return false
