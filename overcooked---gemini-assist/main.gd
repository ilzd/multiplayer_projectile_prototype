extends Node2D

@export var player_scene: PackedScene
@export var apple_scene: PackedScene


func _enter_tree() -> void:
	$PlayerSpawner.spawn_function = _custom_spawn_player

func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)
	
	var apple = apple_scene.instantiate()
	apple.position = Vector2(400, 300)
	$Items.add_child(apple, true)


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()


func spawn_player(id: int):
	var random_pos = Vector2(randi_range(50, 550), randi_range(50, 550))
	
	var spawn_data = {
		"id": id,
		"position": random_pos
	}
	
	$PlayerSpawner.spawn(spawn_data)


func _custom_spawn_player(data: Dictionary):
	var player = player_scene.instantiate()
	player.name = str(data["id"])
	player.position = data["position"]
	return player
