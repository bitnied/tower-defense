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
	if placement_is_free(ph) and check_can_purchase(Globals.currentMap.gold):
		Globals.currentMap.gold -= Data.turrets[turretType]["cost"]
		ph.build()
	else:
		ph.queue_free()

# Synchronous physics query so the decision never depends on the one-frame
# delay of Area2D overlap updates (fast taps/drags, duplicated web events).
func placement_is_free(ph) -> bool:
	var area: Area2D = ph.get_node("CollisionArea")
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = area.get_node("CollisionShape2D").shape
	params.transform = Transform2D(0.0, ph.global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = area.collision_mask
	params.exclude = [area.get_rid()]
	var space: PhysicsDirectSpaceState2D = ph.get_world_2d().direct_space_state
	return space.intersect_shape(params, 1).is_empty()

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
