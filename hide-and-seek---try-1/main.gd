extends Node2D

const PLAYER_SCENE = preload("res://player.tscn")
const VISION_DISTANCE: float = 300.0

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var ui: CanvasLayer = $UI


func _ready() -> void:
	multiplayer_spawner.spawn_function = custom_spawn_player


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server(): return
	
	var players = $Players.get_children() as Array[Node2D]
	var space_state = get_world_2d().direct_space_state
	
	for p1 in players:
		for p2 in players:
			if p1 == p2: continue
			
			var distance = p1.global_position.distance_to(p2.global_position)
			var p2_should_be_visible = distance <= VISION_DISTANCE
			var p1_synchronizer = p1.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
			var p2_id = p2.name.to_int()
			var p2_is_visible = p1_synchronizer.get_visibility_for(p2_id)
			
			if p2_should_be_visible:
				var query = PhysicsRayQueryParameters2D.create(p1.global_position, p2.global_position)
				query.exclude = [p1.get_rid(), p2.get_rid()]
				var result = space_state.intersect_ray(query)
				var has_obstacles = not result.is_empty()
				p2_should_be_visible = not has_obstacles
			
			if p2_should_be_visible and not p2_is_visible:
				p1_synchronizer.set_visibility_for(p2_id, true)
			if not p2_should_be_visible and p2_is_visible:
				p1_synchronizer.set_visibility_for(p2_id, false)
			
			if p1.name.to_int() == 1:
				p2.visible = p2_should_be_visible


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())
	ui.hide()


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	ui.hide()


func add_player(id: int):
	var random_position = Vector2(randi_range(50, 750), randi_range(50, 750))
	
	var player_data: Dictionary = {
		"id": id,
		"position": random_position
	}
	
	multiplayer_spawner.spawn(player_data)


func custom_spawn_player(data: Dictionary):
	var new_player = PLAYER_SCENE.instantiate()
	new_player.name = str(data["id"])
	new_player.global_position = data["position"]
	return new_player
