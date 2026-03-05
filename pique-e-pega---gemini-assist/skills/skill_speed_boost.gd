extends SkillBase

const BOOST_MULTIPLIER = 1.8
const BOOST_DURATION = 3.0


func _execute_skill(_target_pos: Vector2):
	player.apply_speed_boost.rpc(BOOST_MULTIPLIER, BOOST_DURATION)
