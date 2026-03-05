extends SkillBase

const DASH_SPEED = 1200.0
const DASH_DURATION = 0.2


func _execute_skill(target_pos: Vector2):
	var direction = player.global_position.direction_to(target_pos)
	
	player.apply_dash.rpc(direction, DASH_SPEED, DASH_DURATION)
