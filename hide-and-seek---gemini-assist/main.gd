extends Node2D

@export var player_scene: PackedScene

const VISION_RADIUS = 300.0


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	var players = $Players.get_children() as Array[Node2D]
	
	var space_state = get_world_2d().direct_space_state
	
	for seeker in players:
		for hider in players:
			if seeker == hider: continue
			
			var distance = seeker.global_position.distance_to(hider.global_position) 
			var is_close_enough = distance <= VISION_RADIUS
			var has_line_of_sight = false
			
			if is_close_enough:
				var query = PhysicsRayQueryParameters2D.create(seeker.global_position, hider.global_position)
				query.exclude = [seeker.get_rid(), hider.get_rid()]
				var result = space_state.intersect_ray(query)
				
				if result.is_empty():
					has_line_of_sight = true
			
			var should_be_visible = is_close_enough and has_line_of_sight
			var hider_sync = hider.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
			var seeker_id = seeker.name.to_int()
			var is_currently_streaming = hider_sync.get_visibility_for(seeker_id)
			
			if should_be_visible and not is_currently_streaming:
				hider_sync.set_visibility_for(seeker_id, true)
			elif not should_be_visible and is_currently_streaming:
				hider_sync.set_visibility_for(seeker_id, false)
		
			if seeker_id == 1:
				hider.visible  = should_be_visible


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()


func spawn_player(id: int):
	var p = player_scene.instantiate()
	p.name = str(id)
	
	p.global_position = Vector2(randf_range(100, 1000), randf_range(100, 600))
	$Players.add_child(p, true)
