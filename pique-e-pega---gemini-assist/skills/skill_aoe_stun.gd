extends SkillBase

const STUN_RADIUS = 250.0
const STUN_DURATION = 1.5

var current_vfx_radius: float = 0.0
var vfx_alpha: float = 0.0


func _execute_skill(_target_pos: Vector2):
	var players_container = get_node("/root/Map/Players")
	
	for other_player in players_container.get_children():
		if other_player != player:
			var distance = player.global_position.distance_to(other_player.global_position)
			if distance <= STUN_RADIUS:
				print("SERVER: Player ", other_player.name, " caught in Stun blast!")
				other_player.apply_stun.rpc(STUN_DURATION)
	
	play_vfx.rpc()


@rpc("any_peer", "call_local", "reliable")
func play_vfx():
	current_vfx_radius = 0.0
	vfx_alpha = 1.0
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "current_vfx_radius", STUN_RADIUS, 0.3)
	tween.tween_property(self, "vfx_alpha", 0.0, 0.4)
	
	while tween.is_running():
		queue_redraw()
		await get_tree().process_frame
	
	current_vfx_radius = 0
	queue_redraw()


func _draw():
	if current_vfx_radius > 0:
		var color = Color(0, 0.5, 1.0, vfx_alpha)
		draw_circle(Vector2.ZERO, current_vfx_radius, color)
