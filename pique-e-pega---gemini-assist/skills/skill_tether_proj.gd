extends SkillBase


func _execute_skill(target_pos: Vector2):
	var dir = player.global_position.direction_to(target_pos)
	
	var payload = {
		"position": global_position,
		"direction": dir,
		"type": "tether",
		"shooter_id": player.name.to_int()
	}
	
	var map_node = get_node("/root/Map")
	map_node.spawn_projectile(payload)
