extends SkillBase

const INVIS_DURATION = 4.0


func _execute_skill(_target_pos: Vector2):
	player.apply_invisibility.rpc(INVIS_DURATION)
