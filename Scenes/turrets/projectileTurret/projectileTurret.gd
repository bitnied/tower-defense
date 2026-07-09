extends Turret

var bulletSpeed := 200.0
var bulletPierce := 1

func attack():
	if is_instance_valid(current_target):
		attack_punch()
		var projectileScene := preload("res://Scenes/turrets/projectileTurret/bullet/bulletBase.tscn")
		var projectile := projectileScene.instantiate()
		projectile.bullet_type = Data.turrets[turret_type]["bullet"]
		projectile.damage = damage
		projectile.speed = bulletSpeed
		projectile.pierce = bulletPierce
		# sai da frente do personagem; só fica atrás quando ele
		# está de costas (mirando para cima)
		projectile.z_index = 1 if is_facing_up() else 3
		Globals.projectilesNode.add_child(projectile)
		projectile.position = position + Vector2(0, -34)
		projectile.target = current_target.position
	else:
		try_get_closest_target()
